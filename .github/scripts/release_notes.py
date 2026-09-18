#!/usr/bin/env python3
"""
Fetch the Microsoft Learn release notes for a Business Central update window.

The symbol diff answers "what changed in the API surface". A whole class of
upgrade impact never reaches that surface at all:

  * a feature switch becoming mandatory
  * an API version being retired
  * a page or worksheet moving to another app
  * a capability deprecated now for removal two waves later

Microsoft documents those and only those, so Microsoft Learn is the only source.
This script reads them deterministically: the per-update pages have a fixed URL
shape (whatsnew-update-<major>-<minor>), so nothing here searches or guesses -
it computes the update window between the version on the environment and the
target, fetches exactly those pages, and writes what Microsoft said into the
artifact. The report is then grounded in a record that can be audited after the
fact, rather than in whatever a model recalled.

The Microsoft Learn MCP server is public and needs no credentials.

    python .github/scripts/release_notes.py fetch \
        --current-version 28.4.53241.54346 --target-version 28.5.54151.54763 \
        --out-dir upgrade-analysis/report

Network trouble is a warning, never a failure: the rest of the analysis does not
depend on this, and half a report beats no report.
"""

import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.request

MCP_URL = 'https://learn.microsoft.com/api/mcp'
DOCS_ROOT = 'https://learn.microsoft.com/dynamics365/business-central/dev-itpro'

# Fetching every update page of a multi-wave jump would be slow and would bury
# the reader. Past this many, the oldest are dropped and the report says so.
MAX_UPDATES = 8


# --------------------------------------------------------------------------
# The update window - pure, so it can be tested without a network
# --------------------------------------------------------------------------

def parse_version(text):
    parts = [int(x) for x in re.findall(r'\d+', text or '')]
    while len(parts) < 2:
        parts.append(0)
    return parts[0], parts[1]


def build_plan(current_version, target_version, country='w1'):
    """Which Microsoft Learn pages describe this upgrade?

    The updates that will land are the ones after the version on the
    environment, up to and including the target. A major hop also brings in the
    upgrade guide for that major.
    """
    current_major, current_minor = parse_version(current_version)
    target_major, target_minor = parse_version(target_version)

    updates = []
    if target_major == current_major:
        updates = [(target_major, minor)
                   for minor in range(current_minor + 1, target_minor + 1)]
    elif target_major > current_major:
        # Everything already shipped in the old major is already on the
        # environment; what arrives is the new major from .0 up to the target.
        updates = [(target_major, minor) for minor in range(0, target_minor + 1)]

    truncated = 0
    if len(updates) > MAX_UPDATES:
        truncated = len(updates) - MAX_UPDATES
        updates = updates[-MAX_UPDATES:]

    pages = []
    for major, minor in updates:
        pages.append({
            'kind': 'update',
            'version': '%d.%d' % (major, minor),
            'url': '%s/whatsnew/whatsnew-update-%d-%d' % (DOCS_ROOT, major, minor),
        })
    if target_major > current_major:
        pages.append({
            'kind': 'upgrade-guide',
            'version': '%d' % target_major,
            'url': '%s/upgrade/upgrade-overview-v%d' % (DOCS_ROOT, target_major),
        })
    pages.append({
        'kind': 'deprecations',
        'version': 'w1',
        'url': '%s/upgrade/deprecated-features-w1' % DOCS_ROOT,
    })
    country = (country or 'w1').lower()
    if country != 'w1':
        # Some localizations publish their own deprecation list. Ask for it and
        # treat a miss as "not published", which is the common case.
        pages.append({
            'kind': 'deprecations',
            'version': country,
            'url': '%s/upgrade/deprecated-features-%s' % (DOCS_ROOT, country),
            'optional': True,
        })

    return {
        'currentVersion': current_version,
        'targetVersion': target_version,
        'country': country,
        'updates': ['%d.%d' % u for u in updates],
        'updatesTruncated': truncated,
        'pages': pages,
    }


# --------------------------------------------------------------------------
# Splitting the deprecations page down to the waves that matter
# --------------------------------------------------------------------------

WAVE_PATTERN = re.compile(r'(\d{4})\s+release\s+wave\s+(\d)', re.IGNORECASE)
VERSION_IN_HEADING = re.compile(r'version\s+(\d+)', re.IGNORECASE)

# Navigation sections carry no upgrade content. Everything else is kept, dated
# or not - a localization page such as deprecated-features-ch lists features by
# name with no wave heading at all, and dropping those would lose real content.
NAVIGATION_HEADINGS = {'related information', 'see also', 'next steps', 'feedback',
                       'in this article', 'additional resources'}


def split_sections(markdown):
    """[(heading, body)] on '## ' boundaries, preamble first."""
    sections = []
    heading = ''
    body = []
    for line in (markdown or '').splitlines():
        if line.startswith('## ') and not line.startswith('### '):
            sections.append((heading, '\n'.join(body)))
            heading = line[3:].strip()
            body = [line]
        else:
            body.append(line)
    sections.append((heading, '\n'.join(body)))
    return sections


def select_deprecations(markdown, window_waves, target_major):
    """Keep the waves in this upgrade window, plus anything aimed at a later
    version (a removal announced for v30 is an action item now).

    A section that cannot be classified is KEPT and labelled, never dropped -
    silently discarding something Microsoft published is the failure mode this
    whole workflow exists to avoid.
    """
    kept = []
    dropped = 0
    for heading, body in split_sections(markdown):
        if not heading:
            continue
        if heading.strip().lower() in NAVIGATION_HEADINGS:
            continue
        wave_match = WAVE_PATTERN.search(heading)
        version_match = VERSION_IN_HEADING.search(heading)
        wave = ('%s release wave %s' % wave_match.groups()) if wave_match else None
        version = int(version_match.group(1)) if version_match else None

        if wave and wave.lower() in {w.lower() for w in window_waves}:
            relevance = 'in-window'
        elif version is not None and version > target_major:
            relevance = 'future'
        elif wave and window_waves and _wave_key(wave) > max(_wave_key(w) for w in window_waves):
            relevance = 'future'
        elif wave or version is not None:
            dropped += 1
            continue
        else:
            relevance = 'unclassified'

        kept.append({'heading': heading, 'wave': wave, 'version': version,
                     'relevance': relevance, 'markdown': body})
    return kept, dropped


def _wave_key(wave):
    match = WAVE_PATTERN.search(wave or '')
    if not match:
        return (0, 0)
    return (int(match.group(1)), int(match.group(2)))


# --------------------------------------------------------------------------
# The Microsoft Learn MCP client - stdlib only
# --------------------------------------------------------------------------

class LearnClient(object):
    def __init__(self, url=MCP_URL, timeout=90):
        self.url = url
        self.timeout = timeout
        self.session_id = None

    def _post(self, method, params):
        body = json.dumps({'jsonrpc': '2.0', 'id': 1,
                           'method': method, 'params': params}).encode('utf-8')
        headers = {'Content-Type': 'application/json',
                   'Accept': 'application/json, text/event-stream'}
        if self.session_id:
            headers['Mcp-Session-Id'] = self.session_id
        request = urllib.request.Request(self.url, data=body, headers=headers)
        with urllib.request.urlopen(request, timeout=self.timeout) as response:
            if not self.session_id:
                self.session_id = response.headers.get('Mcp-Session-Id')
            return response.read().decode('utf-8', errors='replace')

    @staticmethod
    def _result(raw):
        # The server answers as server-sent events; a plain JSON body is also
        # accepted so a different deployment does not break this.
        for line in raw.splitlines():
            if line.startswith('data:'):
                payload = json.loads(line[5:])
                return payload.get('result', payload)
        try:
            payload = json.loads(raw)
            return payload.get('result', payload)
        except ValueError:
            return {}

    def open(self):
        self._post('initialize', {
            'protocolVersion': '2024-11-05', 'capabilities': {},
            'clientInfo': {'name': 'bc-upgrade-analysis', 'version': '1'}})
        return self

    def fetch(self, url):
        raw = self._post('tools/call',
                         {'name': 'microsoft_docs_fetch', 'arguments': {'url': url}})
        result = self._result(raw)
        if result.get('isError'):
            raise ValueError('the server reported an error for %s' % url)
        text = ''.join(part.get('text', '') for part in result.get('content', []))
        if not text.strip():
            raise ValueError('no content returned for %s' % url)
        return text


# --------------------------------------------------------------------------
# Collect
# --------------------------------------------------------------------------

def first_heading(markdown):
    for line in (markdown or '').splitlines():
        if line.startswith('# '):
            return line[2:].strip()
    return ''


def collect(plan, fetch):
    """Fetch every page in the plan. `fetch` is injected so this is testable."""
    pages = []
    waves = []
    failures = []

    for page in plan['pages']:
        entry = dict(page)
        try:
            markdown = fetch(page['url'])
        except Exception as error:  # noqa: BLE001 - a miss is data, not a crash
            entry['available'] = False
            entry['error'] = str(error)
            if not page.get('optional'):
                failures.append(entry)
            pages.append(entry)
            continue

        entry['available'] = True
        entry['title'] = first_heading(markdown)
        entry['characters'] = len(markdown)
        if page['kind'] == 'update':
            # The wave is stated in the page title, so it is read rather than
            # hard-coded in a table that would rot every six months.
            wave_match = WAVE_PATTERN.search(entry['title'])
            if wave_match:
                wave = '%s release wave %s' % wave_match.groups()
                entry['wave'] = wave
                if wave not in waves:
                    waves.append(wave)
            entry['markdown'] = markdown
        elif page['kind'] == 'deprecations':
            entry['markdown'] = markdown
        else:
            entry['markdown'] = markdown
        pages.append(entry)

    target_major = parse_version(plan['targetVersion'])[0]
    for entry in pages:
        if entry['kind'] != 'deprecations' or not entry.get('available'):
            continue
        sections, dropped = select_deprecations(entry['markdown'], waves, target_major)
        entry['sections'] = sections
        entry['sectionsDroppedAsPast'] = dropped
        # The full page covers a decade of waves; only the selection is kept in
        # the artifact, and the count of what was dropped is kept with it.
        del entry['markdown']

    return {
        'available': any(p.get('available') for p in pages),
        'source': 'Microsoft Learn MCP (%s)' % MCP_URL,
        'currentVersion': plan['currentVersion'],
        'targetVersion': plan['targetVersion'],
        'country': plan['country'],
        'updates': plan['updates'],
        'updatesTruncated': plan['updatesTruncated'],
        'waves': waves,
        'pages': pages,
        'failures': failures,
    }


def render_markdown(notes):
    lines = ['# Microsoft release notes for this upgrade', '']
    lines.append('| | |')
    lines.append('| --- | --- |')
    lines.append('| From | %s |' % notes['currentVersion'])
    lines.append('| To | %s |' % notes['targetVersion'])
    lines.append('| Updates in this window | %s |'
                 % (', '.join(notes['updates']) or 'none'))
    lines.append('| Release wave | %s |' % (', '.join(notes['waves']) or 'unknown'))
    lines.append('| Source | %s |' % notes['source'])
    lines.append('')
    if notes['updatesTruncated']:
        lines.append('> %d older update(s) in this window were not fetched.'
                     % notes['updatesTruncated'])
        lines.append('')
    if not notes['available']:
        lines.append('Microsoft Learn could not be reached. Nothing here is a statement '
                     'about the upgrade - it is a gap in the report.')
        return '\n'.join(lines)

    for page in notes['pages']:
        if page['kind'] == 'deprecations':
            continue
        lines.append('## %s' % (page.get('title') or page['url']))
        lines.append('')
        lines.append('<%s>' % page['url'])
        lines.append('')
        if not page.get('available'):
            lines.append('Could not be fetched: %s' % page.get('error', 'unknown reason'))
            lines.append('')
            continue
        lines.append(page.get('markdown', '').strip())
        lines.append('')

    for page in notes['pages']:
        if page['kind'] != 'deprecations':
            continue
        lines.append('## Deprecations and removals (%s)' % page['version'])
        lines.append('')
        lines.append('<%s>' % page['url'])
        lines.append('')
        if not page.get('available'):
            lines.append('Could not be fetched: %s' % page.get('error', 'unknown reason'))
            lines.append('')
            continue
        for relevance, label in (('in-window', 'Lands in this upgrade'),
                                 ('future', 'Announced for a later version - plan now'),
                                 ('unclassified', 'Could not be dated - read it')):
            group = [s for s in page['sections'] if s['relevance'] == relevance]
            if not group:
                continue
            lines.append('### %s (%d)' % (label, len(group)))
            lines.append('')
            for section in group:
                lines.append(section['markdown'].strip())
                lines.append('')
    return '\n'.join(lines)


# --------------------------------------------------------------------------
# Command
# --------------------------------------------------------------------------

def command_fetch(args):
    plan = build_plan(args.current_version, args.target_version, args.country)

    print('From                : %s' % plan['currentVersion'])
    print('To                  : %s' % plan['targetVersion'])
    print('Updates in window   : %s' % (', '.join(plan['updates']) or 'none'))
    if plan['updatesTruncated']:
        print('::warning::%d older update(s) in this window were not fetched (cap is %d). '
              'The report will say so.' % (plan['updatesTruncated'], MAX_UPDATES))
    print('Pages to fetch      : %d' % len(plan['pages']))
    for page in plan['pages']:
        print('  %-14s %s' % (page['kind'], page['url']))
    print('')

    if not plan['updates'] and args.target_version and args.current_version:
        print('::notice::The target is not newer than the version on the environment, so '
              'there are no update pages to read.')

    client = None
    if not args.offline:
        try:
            client = LearnClient().open()
        except Exception as error:  # noqa: BLE001
            print('::warning::Could not reach the Microsoft Learn MCP server (%s): %s. '
                  'The upgrade report will be missing the feature and deprecation notes, '
                  'which are the only source for changes that have no API footprint.'
                  % (MCP_URL, error))

    def fetch(url):
        if client is None:
            raise ValueError('Microsoft Learn was not reachable')
        return client.fetch(url)

    notes = collect(plan, fetch)

    for page in notes['pages']:
        status = 'ok' if page.get('available') else 'FAILED'
        detail = ('%d chars' % page['characters']) if page.get('available') else page.get('error', '')
        print('  %-6s %-14s %-52s %s' % (status, page['kind'], page['version'], detail))
    if notes['failures']:
        print('::warning::%d Microsoft Learn page(s) could not be read: %s. Those feature '
              'and deprecation notes are missing from the report.'
              % (len(notes['failures']),
                 ', '.join(f['url'] for f in notes['failures'])))

    deprecation_counts = {}
    for page in notes['pages']:
        for section in page.get('sections') or []:
            deprecation_counts[section['relevance']] = \
                deprecation_counts.get(section['relevance'], 0) + 1
    if deprecation_counts:
        print('')
        print('Deprecations kept   : %s'
              % ', '.join('%s %d' % kv for kv in sorted(deprecation_counts.items())))

    os.makedirs(args.out_dir, exist_ok=True)
    json_path = os.path.join(args.out_dir, 'release-notes.json')
    markdown_path = os.path.join(args.out_dir, 'release-notes.md')
    with open(json_path, 'w', encoding='utf-8') as handle:
        json.dump(notes, handle, indent=1, ensure_ascii=False)
    with open(markdown_path, 'w', encoding='utf-8') as handle:
        handle.write(render_markdown(notes))

    print('')
    print('Wrote %s' % json_path)
    print('Wrote %s' % markdown_path)

    github_output = os.environ.get('GITHUB_OUTPUT')
    if github_output:
        with open(github_output, 'a', encoding='utf-8') as handle:
            handle.write('releaseNotesAvailable=%s\n' % str(notes['available']).lower())
            handle.write('releaseNotesUpdates=%s\n' % len(notes['updates']))
            handle.write('deprecationsInWindow=%s\n'
                         % deprecation_counts.get('in-window', 0))
            handle.write('deprecationsFuture=%s\n' % deprecation_counts.get('future', 0))

    # Never fail the run for this: the symbol analysis stands on its own, and a
    # missing section that says it is missing is better than no report.
    return 0


def main():
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding='utf-8', errors='replace')
        except (AttributeError, ValueError):
            pass

    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    fetch = commands.add_parser('fetch', help='fetch the release notes for an upgrade window')
    fetch.add_argument('--current-version', required=True)
    fetch.add_argument('--target-version', required=True)
    fetch.add_argument('--country', default='w1')
    fetch.add_argument('--out-dir', required=True)
    fetch.add_argument('--offline', action='store_true',
                       help='skip the network; used to check the degraded path')
    fetch.set_defaults(handler=command_fetch)

    args = parser.parse_args()
    return args.handler(args)


if __name__ == '__main__':
    sys.exit(main())

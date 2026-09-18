#!/usr/bin/env python3
"""Tests for release_notes.py.

Run with:  python .github/scripts/test_release_notes.py

No network: the fetcher is injected, so the update-window arithmetic and the
deprecation selection are checked against fixtures that mirror the real pages.
"""

import io
import json
import os
import subprocess
import sys
import tempfile

import release_notes as rn


FAILURES = []


def check(name, condition, detail=''):
    if condition:
        print('  PASS  %s' % name)
    else:
        print('  FAIL  %s %s' % (name, detail))
        FAILURES.append(name)


print('Update window')

plan = rn.build_plan('28.4.53241.54346', '28.5.54151.54763')
check('one minor step reads one update page', plan['updates'] == ['28.5'],
      '(got %r)' % plan['updates'])
check('the version on the environment is not re-read',
      '28.4' not in plan['updates'])

plan = rn.build_plan('28.1.0.0', '28.5.0.0')
check('a multi-step jump reads every update in between',
      plan['updates'] == ['28.2', '28.3', '28.4', '28.5'], '(got %r)' % plan['updates'])

plan = rn.build_plan('27.5.0.0', '28.2.0.0')
check('a major hop reads the new major from .0',
      plan['updates'] == ['28.0', '28.1', '28.2'], '(got %r)' % plan['updates'])
check('a major hop also reads the upgrade guide for that major',
      any(p['kind'] == 'upgrade-guide' and p['version'] == '28' for p in plan['pages']))

plan = rn.build_plan('28.5.0.0', '28.5.0.0')
check('no update pages when the target is not newer', plan['updates'] == [])
check('the deprecation list is still read',
      any(p['kind'] == 'deprecations' for p in plan['pages']))

plan = rn.build_plan('28.0.0.0', '28.20.0.0')
check('an unreasonably wide window is capped',
      len(plan['updates']) == rn.MAX_UPDATES and plan['updatesTruncated'] > 0,
      '(got %d updates, %d truncated)' % (len(plan['updates']), plan['updatesTruncated']))
check('the cap keeps the newest updates, not the oldest',
      plan['updates'][-1] == '28.20')

plan = rn.build_plan('28.4.0.0', '28.5.0.0', country='ch')
check('a localization also gets its own deprecation page asked for',
      any(p['kind'] == 'deprecations' and p['version'] == 'ch' for p in plan['pages']))
check('and that page is optional, so a miss is not a failure',
      any(p.get('optional') for p in plan['pages'] if p['version'] == 'ch'))

plan = rn.build_plan('28.4.0.0', '28.5.0.0', country='w1')
check('w1 asks for no second deprecation page',
      sum(1 for p in plan['pages'] if p['kind'] == 'deprecations') == 1)

check('the update URL is deterministic, never searched',
      rn.build_plan('28.4.0.0', '28.5.0.0')['pages'][0]['url'].endswith(
          '/whatsnew/whatsnew-update-28-5'))

print('\nDeprecation selection')

DEPRECATIONS = """# Deprecated features in the application
Intro text.

## Changes in 2027 release wave 1 (version 30.0)
### Finance reports API (beta) (removal)
Gone in v30.

## Changes in 2026 release wave 2
### Something later
Warning only.

## Changes in 2026 release wave 1
### API (v1.0) for Business Central (removal)
Removed in this wave.

## Changes in 2025 release wave 2
### Old thing
Already applied.

## Breaking Changes
Undated but important.

## Related information
Links only.
"""

sections, dropped = rn.select_deprecations(DEPRECATIONS, ['2026 release wave 1'], 28)
by_relevance = {}
for section in sections:
    by_relevance.setdefault(section['relevance'], []).append(section['heading'])

check('the wave this upgrade lands in is kept',
      by_relevance.get('in-window') == ['Changes in 2026 release wave 1'],
      '(got %r)' % by_relevance.get('in-window'))
check('a removal announced for a later version is kept as an action item',
      'Changes in 2027 release wave 1 (version 30.0)' in by_relevance.get('future', []))
check('the next wave is kept too', 'Changes in 2026 release wave 2'
      in by_relevance.get('future', []))
check('waves already on the environment are dropped', dropped == 1,
      '(dropped %d)' % dropped)
check('an undated section is kept, not silently discarded',
      'Breaking Changes' in by_relevance.get('unclassified', []),
      '(got %r)' % by_relevance.get('unclassified'))
check('navigation sections are dropped as noise',
      not any('Related information' in v for v in by_relevance.values()))

# A localization page has no wave headings at all; none of it may be lost.
LOCALIZED = """# Deprecated features
## Physical inventory order
Text.
## Fields marked as ObsoleteState:Pending
Text.
## Related information
Links.
"""
sections, dropped = rn.select_deprecations(LOCALIZED, ['2026 release wave 1'], 28)
check('a page with no wave headings keeps all of its content',
      len(sections) == 2 and dropped == 0, '(got %d sections, %d dropped)'
      % (len(sections), dropped))

print('\nCollect - with the network faked')

UPDATE_PAGE = """# Update 28.5 for Business Central 2026 release wave 1
## Feature changes
Something changed.
"""


def fake_fetch(pages):
    def fetch(url):
        for suffix, body in pages.items():
            if url.endswith(suffix):
                return body
        raise ValueError('404 for %s' % url)
    return fetch


plan = rn.build_plan('28.4.0.0', '28.5.0.0')
notes = rn.collect(plan, fake_fetch({'whatsnew-update-28-5': UPDATE_PAGE,
                                     'deprecated-features-w1': DEPRECATIONS}))
check('the release wave is read from the page title, not hard-coded',
      notes['waves'] == ['2026 release wave 1'], '(got %r)' % notes['waves'])
check('the deprecation wave is matched against the wave that was read',
      any(s['relevance'] == 'in-window'
          for p in notes['pages'] for s in (p.get('sections') or [])))
check('notes are marked available', notes['available'] is True)
check('the full deprecation page is not kept, only the selection',
      all('markdown' not in p for p in notes['pages'] if p['kind'] == 'deprecations'))

notes = rn.collect(plan, fake_fetch({}))
check('every page failing is reported, not silently empty',
      notes['available'] is False and len(notes['failures']) == 2,
      '(available=%r failures=%d)' % (notes['available'], len(notes['failures'])))

notes = rn.collect(rn.build_plan('28.4.0.0', '28.5.0.0', country='ch'),
                   fake_fetch({'whatsnew-update-28-5': UPDATE_PAGE,
                               'deprecated-features-w1': DEPRECATIONS}))
check('a missing localization page is not counted as a failure',
      len(notes['failures']) == 0 and notes['available'] is True,
      '(failures=%d)' % len(notes['failures']))

text = rn.render_markdown(notes)
check('the rendered notes cite the source URL of every page',
      text.count('learn.microsoft.com') >= 2, '(got %d)' % text.count('learn.microsoft.com'))
check('the rendered notes state the version window',
      '28.4.0.0' in text and '28.5.0.0' in text)

notes = rn.collect(plan, fake_fetch({}))
text = rn.render_markdown(notes)
check('an unreachable Learn is stated as a gap, not as an all-clear',
      'gap in the report' in text)

print('\nDegraded path - the real script, offline, must still exit 0')

out_dir = tempfile.mkdtemp()
try:
    environment = dict(os.environ)
    environment.pop('GITHUB_OUTPUT', None)
    completed = subprocess.run(
        [sys.executable, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                      'release_notes.py'),
         'fetch', '--current-version', '28.4.0.0', '--target-version', '28.5.0.0',
         '--out-dir', out_dir, '--offline'],
        env=environment, capture_output=True, text=True, encoding='utf-8', errors='replace')
    check('offline run exits 0 rather than failing the workflow',
          completed.returncode == 0,
          '(exit %s, stderr %r)' % (completed.returncode, completed.stderr[-200:]))
    check('offline run still writes both files',
          os.path.isfile(os.path.join(out_dir, 'release-notes.json'))
          and os.path.isfile(os.path.join(out_dir, 'release-notes.md')))
    with open(os.path.join(out_dir, 'release-notes.json'), encoding='utf-8') as handle:
        offline = json.load(handle)
    check('offline notes are marked unavailable', offline['available'] is False)
    check('offline run warns loudly', '::warning::' in completed.stdout)
finally:
    for name in ('release-notes.json', 'release-notes.md'):
        path = os.path.join(out_dir, name)
        if os.path.isfile(path):
            os.unlink(path)
    os.rmdir(out_dir)

print('')
if FAILURES:
    print('%d test(s) FAILED: %s' % (len(FAILURES), ', '.join(FAILURES)))
    sys.exit(1)
print('All tests passed.')

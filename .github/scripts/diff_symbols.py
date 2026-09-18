#!/usr/bin/env python3
"""
Extract and diff Business Central symbol packages.

This implements PHASE 1 (extraction) and PHASE 2 (structured diff) of
ALGo-App/Instructions/Compare-instruction.md, plus the mechanical part of
PHASE 3 (breaking-change classification).

It lives in the repository rather than inside a workflow step so that it can be
run and tested on its own:

    python .github/scripts/diff_symbols.py selftest --symbols-dir ALGo-App/.alpackages
    python .github/scripts/diff_symbols.py diff --current <dir> --latest <dir> --out-dir <dir>

Design notes that earlier in-workflow versions got wrong:

* Objects are NOT at the root of SymbolReference.json. From BC v22 onwards every
  object lives nested inside "Namespaces", recursively, and the root collections
  are empty. The flattener below walks that tree and attaches the fully
  qualified namespace to each object.
* Object identity is the numeric "Id", not the name. Microsoft moves objects
  between namespaces and occasionally renames them; keying by name turns each of
  those into a bogus removal + addition pair.
* Comparing member NAMES only is blind to the single most common breaking change
  in BC - an event publisher whose signature changed. Members are therefore
  normalised down to a full signature (var-ness, parameter types, return type,
  attributes, visibility) before being compared.
* An empty inventory is an error, never an "everything is fine" result.
"""

import argparse
import io
import json
import os
import sys
import zipfile
from collections import Counter, OrderedDict

# --------------------------------------------------------------------------
# PHASE 1 - extraction
# --------------------------------------------------------------------------

# Object collections, mapped onto the member list a consumer compiles against.
# Names verified against real v28 symbol packages - note EnumTypes /
# EnumExtensionTypes, which older versions of this tooling spelled Enums /
# EnumExtensions and therefore never matched.
OBJECT_KINDS = OrderedDict([
    ('Tables', 'Fields'),
    ('TableExtensions', 'Fields'),
    ('Codeunits', 'Methods'),
    ('Interfaces', 'Methods'),
    ('EnumTypes', 'Values'),
    ('EnumExtensionTypes', 'Values'),
    ('Pages', 'Methods'),
    ('PageExtensions', 'Methods'),
    ('PageCustomizations', None),
    ('Reports', 'Methods'),
    ('ReportExtensions', 'Methods'),
    ('Queries', None),
    ('XmlPorts', None),
    ('ControlAddIns', None),
    ('PermissionSets', None),
    ('PermissionSetExtensions', None),
    ('Profiles', None),
    ('ProfileExtensions', None),
])

# Properties worth diffing, and how a change to each should be read.
# 'breaking'  - can stop our app compiling or change a contract
# 'data'      - silently changes what the data does (higher priority than a compile break)
# 'obsolete'  - deprecation lifecycle
# 'ui'        - cosmetic / surface only
PROPERTY_CATEGORY = {
    'Access': 'breaking',
    'Extensible': 'breaking',
    'TableType': 'breaking',
    'SourceTable': 'breaking',
    'PageType': 'breaking',
    'Scope': 'breaking',
    'AssignmentCompatibility': 'breaking',
    'ObsoleteState': 'obsolete',
    'ObsoleteReason': 'obsolete',
    'ObsoleteTag': 'obsolete',
    'CalcFormula': 'data',
    'FieldClass': 'data',
    'TableRelation': 'data',
    'Permissions': 'data',
    'InherentPermissions': 'data',
    'InherentEntitlements': 'data',
    'DataClassification': 'data',
    'ReplicateData': 'data',
    'DataPerCompany': 'data',
    'Enabled': 'data',
    'Editable': 'data',
    'InsertAllowed': 'data',
    'ModifyAllowed': 'data',
    'DeleteAllowed': 'data',
    'MovedFrom': 'data',
    'MovedTo': 'data',
    'Caption': 'ui',
    'ApplicationArea': 'ui',
    'UsageCategory': 'ui',
}


def read_symbol_reference(app_path):
    """Read SymbolReference.json out of a .app package.

    A .app file is a small NAVX header followed by a plain zip archive, so the
    archive can be opened in memory once the header has been skipped.
    """
    with open(app_path, 'rb') as handle:
        raw = handle.read()

    offset = raw.find(b'PK\x03\x04', 0, 4096)
    if offset < 0:
        raise ValueError('no zip archive found in the package')

    with zipfile.ZipFile(io.BytesIO(raw[offset:])) as archive:
        name = next(
            (n for n in archive.namelist() if n.split('/')[-1] == 'SymbolReference.json'),
            None,
        )
        if name is None:
            raise ValueError('SymbolReference.json not found in the package')
        # The file carries a UTF-8 BOM.
        return json.loads(archive.read(name).decode('utf-8-sig'))


# --------------------------------------------------------------------------
# Normalisation
# --------------------------------------------------------------------------

def type_name(type_definition):
    """Render a TypeDefinition the way it reads in AL: Record "Sales Header"."""
    if not type_definition:
        return ''
    name = type_definition.get('Name', '') or ''
    subtype = type_definition.get('Subtype')
    if subtype and subtype.get('Name'):
        name = '%s "%s"' % (name, subtype['Name'])
    arguments = type_definition.get('TypeArguments')
    if arguments:
        name = '%s of [%s]' % (name, ', '.join(type_name(a) for a in arguments))
    return name


def attribute_map(member):
    """{ IntegrationEvent: 'false,false', Obsolete: 'reason,27.0' }"""
    result = {}
    for attribute in member.get('Attributes') or []:
        name = attribute.get('Name', '')
        arguments = ','.join(
            str(argument.get('Value', '')) for argument in (attribute.get('Arguments') or [])
        )
        result[name] = arguments
    return result


def properties_map(owner):
    result = {}
    for prop in owner.get('Properties') or []:
        name = prop.get('Name')
        if name:
            result[name] = prop.get('Value')
    return result


def normalise_method(method):
    parameters = []
    for parameter in method.get('Parameters') or []:
        parameters.append({
            'name': parameter.get('Name', ''),
            'type': type_name(parameter.get('TypeDefinition')),
            'var': bool(parameter.get('IsVar')),
        })

    flags = [flag for flag in ('IsInternal', 'IsLocal', 'IsProtected') if method.get(flag)]
    if method.get('MethodKind'):
        flags.append('MethodKind=%s' % method['MethodKind'])

    attributes = attribute_map(method)
    return_type = type_name(method.get('ReturnTypeDefinition'))

    rendered = '%s(%s)' % (
        method.get('Name', ''),
        '; '.join(
            '%s%s: %s' % ('var ' if p['var'] else '', p['name'], p['type'])
            for p in parameters
        ),
    )
    if return_type:
        rendered += ': %s' % return_type
    if attributes:
        rendered += ' [%s]' % ','.join(
            '%s(%s)' % (k, v) if v else k for k, v in sorted(attributes.items())
        )
    if flags:
        rendered += ' {%s}' % ','.join(flags)

    return {
        'name': method.get('Name', ''),
        'memberKind': 'method',
        'parameters': parameters,
        'returnType': return_type,
        'attributes': attributes,
        'flags': flags,
        'signature': rendered,
    }


def normalise_field(field):
    props = properties_map(field)
    rendered = '%s: %s' % (field.get('Name', ''), type_name(field.get('TypeDefinition')))
    return {
        'name': field.get('Name', ''),
        'memberKind': 'field',
        'id': field.get('Id'),
        'type': type_name(field.get('TypeDefinition')),
        'properties': props,
        'signature': rendered,
    }


def normalise_value(value):
    # Ordinal is omitted for 0.
    ordinal = value.get('Ordinal', 0)
    return {
        'name': value.get('Name', ''),
        'memberKind': 'value',
        'ordinal': ordinal,
        'properties': properties_map(value),
        'signature': '%s = %s' % (value.get('Name', ''), ordinal),
    }


NORMALISERS = {'Methods': normalise_method, 'Fields': normalise_field, 'Values': normalise_value}


# --------------------------------------------------------------------------
# PHASE 2 - flatten and diff
# --------------------------------------------------------------------------

def flatten(root):
    """Walk the namespace tree and return {key: object record}.

    key is 'Kind/Id' when the object carries an Id, otherwise 'Kind/Name'.
    """
    objects = {}

    def visit(node, namespace):
        for kind, member_key in OBJECT_KINDS.items():
            for obj in node.get(kind) or []:
                name = obj.get('Name')
                if not name:
                    continue
                object_id = obj.get('Id')
                key = '%s/%s' % (kind, object_id if object_id is not None else name)

                members = {}
                if member_key:
                    normalise = NORMALISERS[member_key]
                    for raw_member in obj.get(member_key) or []:
                        if not raw_member.get('Name'):
                            continue
                        member = normalise(raw_member)
                        # AL does not allow overloads inside one object, so the
                        # member name is a stable key.
                        members[member['name']] = member

                objects[key] = {
                    'key': key,
                    'kind': kind,
                    'id': object_id,
                    'name': name,
                    'namespace': namespace,
                    'properties': properties_map(obj),
                    'members': members,
                }

        # Guard: a leaf namespace has no 'Namespaces' key at all, and iterating
        # over the missing value would walk into None.
        for child in node.get('Namespaces') or []:
            child_name = child.get('Name', '')
            visit(child, '%s.%s' % (namespace, child_name) if namespace else child_name)

    visit(root, '')
    return objects


def is_pure_append(old, new):
    """AL lets a subscriber declare a leading subset of the parameters, so
    appending at the end is the only non-breaking parameter change."""
    old_params, new_params = old['parameters'], new['parameters']
    if len(new_params) < len(old_params):
        return False
    for before, after in zip(old_params, new_params):
        if before['name'] != after['name']:
            return False
        if before['type'] != after['type']:
            return False
        if before['var'] != after['var']:
            return False
    return old['returnType'] == new['returnType']


def visibility_rank(member):
    if 'IsLocal' in member['flags']:
        return 0
    if 'IsInternal' in member['flags']:
        return 1
    if 'IsProtected' in member['flags']:
        return 2
    return 3  # public


def classify_signature_change(old, new):
    """Return (category, reasons[])."""
    reasons = []

    if visibility_rank(new) < visibility_rank(old):
        reasons.append('visibility demoted')

    old_obsolete = old['attributes'].get('Obsolete')
    new_obsolete = new['attributes'].get('Obsolete')
    if old_obsolete is None and new_obsolete is not None:
        reasons.append('marked Obsolete')

    old_attrs = set(old['attributes']) - {'Obsolete'}
    new_attrs = set(new['attributes']) - {'Obsolete'}
    if old_attrs - new_attrs:
        reasons.append('attribute(s) removed: %s' % ', '.join(sorted(old_attrs - new_attrs)))

    if old['returnType'] != new['returnType']:
        reasons.append('return type %s -> %s' % (old['returnType'] or '<none>', new['returnType'] or '<none>'))

    if old['parameters'] != new['parameters']:
        if is_pure_append(old, new):
            reasons.append('parameter(s) appended at the end')
        else:
            reasons.append('parameter list changed in place')

    if not reasons:
        # Only the Obsolete reason/tag text moved.
        return 'obsolete', ['obsolete metadata changed']

    breaking = any(
        reason.startswith(('visibility demoted', 'return type', 'parameter list changed'))
        or reason.startswith('attribute(s) removed')
        for reason in reasons
    )
    if breaking:
        return 'breaking', reasons
    if 'marked Obsolete' in reasons:
        return 'obsolete', reasons
    return 'additive', reasons


def diff_properties(old, new):
    changes = []
    for name in sorted(set(old) | set(new)):
        before, after = old.get(name), new.get(name)
        if before == after:
            continue
        category = PROPERTY_CATEGORY.get(name, 'info')
        if name == 'ObsoleteState' and after == 'Removed':
            category = 'breaking'
        if name == 'Extensible' and before in ('1', True) and after not in ('1', True):
            category = 'breaking'
        changes.append({'property': name, 'old': before, 'new': after, 'category': category})
    return changes


def diff_members(old_members, new_members, member_kind):
    removed, added, changed = [], [], []

    for name in sorted(set(old_members) - set(new_members)):
        removed.append({'name': name, 'signature': old_members[name]['signature']})
    for name in sorted(set(new_members) - set(old_members)):
        added.append({'name': name, 'signature': new_members[name]['signature']})

    for name in sorted(set(old_members) & set(new_members)):
        old, new = old_members[name], new_members[name]
        if old['signature'] == new['signature'] and old.get('properties') == new.get('properties'):
            continue

        entry = {
            'name': name,
            'old': old['signature'],
            'new': new['signature'],
        }
        if member_kind == 'Methods':
            category, reasons = classify_signature_change(old, new)
            entry['category'] = category
            entry['reasons'] = reasons
            entry['pureAppend'] = is_pure_append(old, new)
        elif member_kind == 'Fields':
            reasons = []
            category = 'info'
            if old['type'] != new['type']:
                reasons.append('type %s -> %s' % (old['type'], new['type']))
                category = 'breaking'
            property_changes = diff_properties(old.get('properties', {}), new.get('properties', {}))
            for change in property_changes:
                reasons.append('%s %s -> %s' % (change['property'], change['old'], change['new']))
                if change['category'] == 'breaking':
                    category = 'breaking'
                elif change['category'] == 'data' and category != 'breaking':
                    category = 'data'
            entry['category'] = category
            entry['reasons'] = reasons
        else:  # enum values
            reasons = []
            category = 'info'
            if old['ordinal'] != new['ordinal']:
                reasons.append('ordinal %s -> %s' % (old['ordinal'], new['ordinal']))
                category = 'breaking'
            entry['category'] = category
            entry['reasons'] = reasons

        changed.append(entry)

    return removed, added, changed


def diff_objects(old_objects, new_objects):
    result = {
        'removedObjects': [],
        'addedObjects': [],
        'renamedObjects': [],
        'movedObjects': [],
        'changedObjects': [],
    }

    for key in sorted(set(old_objects) - set(new_objects)):
        obj = old_objects[key]
        result['removedObjects'].append({
            'key': key, 'kind': obj['kind'], 'id': obj['id'],
            'name': obj['name'], 'namespace': obj['namespace'],
        })
    for key in sorted(set(new_objects) - set(old_objects)):
        obj = new_objects[key]
        result['addedObjects'].append({
            'key': key, 'kind': obj['kind'], 'id': obj['id'],
            'name': obj['name'], 'namespace': obj['namespace'],
        })

    for key in sorted(set(old_objects) & set(new_objects)):
        old, new = old_objects[key], new_objects[key]

        if old['name'] != new['name']:
            result['renamedObjects'].append({
                'key': key, 'kind': old['kind'], 'id': old['id'],
                'old': old['name'], 'new': new['name'],
            })
        if old['namespace'] != new['namespace']:
            result['movedObjects'].append({
                'key': key, 'kind': old['kind'], 'id': old['id'], 'name': new['name'],
                'old': old['namespace'], 'new': new['namespace'],
            })

        property_changes = diff_properties(old['properties'], new['properties'])
        member_kind = OBJECT_KINDS.get(old['kind'])
        removed, added, changed = diff_members(old['members'], new['members'], member_kind)

        if not (property_changes or removed or added or changed):
            continue

        result['changedObjects'].append({
            'key': key,
            'kind': old['kind'],
            'id': old['id'],
            'name': new['name'],
            'namespace': new['namespace'],
            'propertyChanges': property_changes,
            'removedMembers': removed,
            'addedMembers': added,
            'changedMembers': changed,
        })

    return result


def count_findings(app_delta):
    counter = Counter()
    counter['removedObjects'] = len(app_delta['removedObjects'])
    counter['addedObjects'] = len(app_delta['addedObjects'])
    counter['renamedObjects'] = len(app_delta['renamedObjects'])
    counter['movedObjects'] = len(app_delta['movedObjects'])

    # A removed object is always a compile break for anyone referencing it.
    counter['breaking'] += len(app_delta['removedObjects'])

    for obj in app_delta['changedObjects']:
        for change in obj['propertyChanges']:
            counter[change['category']] += 1
        counter['breaking'] += len(obj['removedMembers'])
        counter['removedMembers'] += len(obj['removedMembers'])
        counter['addedMembers'] += len(obj['addedMembers'])
        for member in obj['changedMembers']:
            counter[member.get('category', 'info')] += 1
            counter['changedMembers'] += 1
    return counter


# --------------------------------------------------------------------------
# Reporting
# --------------------------------------------------------------------------

MAX_ITEMS = 60


def format_list(items):
    shown = items[:MAX_ITEMS]
    text = ', '.join(shown)
    if len(items) > MAX_ITEMS:
        text += ' ... and %d more' % (len(items) - MAX_ITEMS)
    return text


def render_markdown(report):
    lines = []
    lines.append('# Business Central symbol changes')
    lines.append('')
    lines.append('| | |')
    lines.append('| --- | --- |')
    lines.append('| Environment | %s |' % report['environment'])
    lines.append('| Version on environment (old) | %s |' % report['currentVersion'])
    lines.append('| Target version (new) | %s |' % report['targetVersion'])
    lines.append('| Packages compared | %d |' % len(report['apps']))
    lines.append('| Objects read (old / new) | %d / %d |' % (
        report['totals']['oldObjects'], report['totals']['newObjects']))
    lines.append('')
    lines.append('Counts below are mechanical: they say what changed in the symbols, not what '
                 'our own app uses. Scope them against the AL source before acting.')
    lines.append('')
    lines.append('| Package | Old | New | Breaking | Data-behavior | Obsolete | Additive |')
    lines.append('| --- | --- | --- | --- | --- | --- | --- |')
    for app in report['apps']:
        findings = app['findings']
        lines.append('| %s | %s | %s | %d | %d | %d | %d |' % (
            app['app'], app['oldVersion'], app['newVersion'],
            findings.get('breaking', 0), findings.get('data', 0),
            findings.get('obsolete', 0), findings.get('additive', 0)))
    lines.append('')

    for app in report['apps']:
        delta = app['delta']
        lines.append('## %s' % app['app'])
        lines.append('')
        lines.append('%s -> %s' % (app['oldVersion'], app['newVersion']))
        lines.append('')

        if delta['removedObjects']:
            lines.append('### Removed objects (breaking) - %d' % len(delta['removedObjects']))
            lines.append(format_list([
                '%s %s "%s" (%s)' % (o['kind'], o['id'], o['name'], o['namespace'])
                for o in delta['removedObjects']
            ]))
            lines.append('')

        if delta['renamedObjects']:
            lines.append('### Renamed objects - %d' % len(delta['renamedObjects']))
            lines.append(format_list([
                '%s %s: "%s" -> "%s"' % (o['kind'], o['id'], o['old'], o['new'])
                for o in delta['renamedObjects']
            ]))
            lines.append('')

        if delta['movedObjects']:
            lines.append('### Moved to another namespace - %d' % len(delta['movedObjects']))
            lines.append('These are not removals - the object Id is unchanged.')
            lines.append('')
            lines.append(format_list([
                '%s %s "%s": %s -> %s' % (o['kind'], o['id'], o['name'], o['old'] or '<root>', o['new'])
                for o in delta['movedObjects']
            ]))
            lines.append('')

        breaking_objects = [
            obj for obj in delta['changedObjects']
            if obj['removedMembers']
            or any(c['category'] == 'breaking' for c in obj['propertyChanges'])
            or any(m.get('category') == 'breaking' for m in obj['changedMembers'])
        ]
        if breaking_objects:
            lines.append('### Breaking member and property changes - %d object(s)'
                         % len(breaking_objects))
            lines.append('')
            lines.append('| Object | Change | Detail |')
            lines.append('| --- | --- | --- |')
            for obj in breaking_objects[:MAX_ITEMS]:
                label = '%s %s "%s"' % (obj['kind'], obj['id'], obj['name'])
                for change in obj['propertyChanges']:
                    if change['category'] != 'breaking':
                        continue
                    lines.append('| %s | property `%s` | `%s` -> `%s` |' % (
                        label, change['property'], change['old'], change['new']))
                for member in obj['removedMembers'][:10]:
                    lines.append('| %s | member removed | `%s` |' % (label, member['signature']))
                for member in obj['changedMembers']:
                    if member.get('category') != 'breaking':
                        continue
                    lines.append('| %s | signature changed | `%s` -> `%s` (%s) |' % (
                        label, member['old'], member['new'], '; '.join(member.get('reasons', []))))
            if len(breaking_objects) > MAX_ITEMS:
                lines.append('')
                lines.append('%d more breaking object(s) - see symbol-changes.json.'
                             % (len(breaking_objects) - MAX_ITEMS))
            lines.append('')

        data_objects = [
            obj for obj in delta['changedObjects']
            if any(c['category'] == 'data' for c in obj['propertyChanges'])
            or any(m.get('category') == 'data' for m in obj['changedMembers'])
        ]
        if data_objects:
            lines.append('### Data-behavior changes - %d object(s)' % len(data_objects))
            lines.append('')
            lines.append('| Object | Property | Old | New |')
            lines.append('| --- | --- | --- | --- |')
            for obj in data_objects[:MAX_ITEMS]:
                label = '%s %s "%s"' % (obj['kind'], obj['id'], obj['name'])
                for change in obj['propertyChanges']:
                    if change['category'] != 'data':
                        continue
                    lines.append('| %s | %s | `%s` | `%s` |' % (
                        label, change['property'], change['old'], change['new']))
                for member in obj['changedMembers']:
                    if member.get('category') != 'data':
                        continue
                    lines.append('| %s | %s | `%s` | `%s` |' % (
                        label, member['name'], member['old'], member['new']))
            lines.append('')

        added_members = sum(len(obj['addedMembers']) for obj in delta['changedObjects'])
        lines.append('### Additions - %d new object(s), %d new member(s)'
                     % (len(delta['addedObjects']), added_members))
        lines.append('')
        if delta['addedObjects']:
            lines.append(format_list([
                '%s %s "%s"' % (o['kind'], o['id'], o['name']) for o in delta['addedObjects']
            ]))
            lines.append('')

    lines.append('---')
    lines.append('')
    lines.append('The complete, untruncated diff is in symbol-changes.json.')
    return '\n'.join(lines)


# --------------------------------------------------------------------------
# Commands
# --------------------------------------------------------------------------

def list_packages(folder):
    """Every .app file in a folder, sorted."""
    if not os.path.isdir(folder):
        return []
    return [
        os.path.join(folder, entry)
        for entry in sorted(os.listdir(folder))
        if entry.lower().endswith('.app')
    ]


def describe(app_path):
    symbols = read_symbol_reference(app_path)
    return {
        'key': '%s/%s' % (symbols.get('Publisher', ''), symbols.get('Name', '')),
        'version': symbols.get('Version', ''),
        'objects': flatten(symbols),
    }


def command_selftest(args):
    """Parse every package in a folder and refuse to pass on an empty inventory.

    The repository keeps a set of real v28 symbol packages under
    ALGo-App/.alpackages - running the extractor against them is what catches a
    parser that silently stopped finding objects.
    """
    folder = args.symbols_dir
    if not os.path.isdir(folder):
        print('::error::%s does not exist' % folder)
        return 2

    packages = [f for f in sorted(os.listdir(folder)) if f.lower().endswith('.app')]
    if not packages:
        print('::error::no .app packages in %s - the self-test cannot verify the extractor' % folder)
        return 2

    total = 0
    empty = []
    print('Self-test: %d package(s) in %s' % (len(packages), folder))
    for package in packages:
        path = os.path.join(folder, package)
        try:
            info = describe(path)
        except Exception as error:  # noqa: BLE001 - report and keep going
            print('::error::%s could not be parsed - %s' % (package, error))
            return 2

        kinds = Counter(obj['kind'] for obj in info['objects'].values())
        members = sum(len(obj['members']) for obj in info['objects'].values())
        total += len(info['objects'])
        print('  %-52s %s  %5d objects, %6d members  %s' % (
            package, info['version'], len(info['objects']), members,
            ', '.join('%s=%d' % (k, v) for k, v in kinds.most_common(5))))
        if not info['objects']:
            empty.append(package)

    if total == 0:
        print('::error::The extractor found 0 objects across every package. '
              'SymbolReference.json parsing is broken (namespace flattening?).')
        return 2

    # A manifest-only package legitimately carries no objects; all of them being
    # empty is the failure mode this test exists for.
    if empty:
        print('::notice::packages with no objects (expected for manifest-only apps): %s'
              % ', '.join(empty))

    print('Self-test passed: %d objects extracted in total.' % total)
    return 0


def command_diff(args):
    current_packages = list_packages(args.current)
    latest_packages = list_packages(args.latest)
    if not current_packages or not latest_packages:
        print('::error::no .app packages found in %s or %s' % (args.current, args.latest))
        return 2

    # Map both sides by Publisher/Name without holding every parse in memory.
    def key_index(paths, label):
        mapping = {}
        for path in paths:
            try:
                symbols = read_symbol_reference(path)
            except Exception as error:  # noqa: BLE001
                print('::warning::[%s] %s could not be read - %s'
                      % (label, os.path.basename(path), error))
                continue
            mapping['%s/%s' % (symbols.get('Publisher', ''), symbols.get('Name', ''))] = path
        return mapping

    current_files = key_index(current_packages, 'current')
    latest_files = key_index(latest_packages, 'latest')

    report = {
        'environment': args.environment,
        'currentVersion': args.current_version,
        'targetVersion': args.target_version,
        'apps': [],
        'skipped': [],
        'totals': {'oldObjects': 0, 'newObjects': 0},
    }

    for key in sorted(set(current_files) & set(latest_files)):
        old = describe(current_files[key])
        new = describe(latest_files[key])
        report['totals']['oldObjects'] += len(old['objects'])
        report['totals']['newObjects'] += len(new['objects'])

        delta = diff_objects(old['objects'], new['objects'])
        findings = count_findings(delta)
        report['apps'].append({
            'app': key,
            'oldVersion': old['version'],
            'newVersion': new['version'],
            'oldObjectCount': len(old['objects']),
            'newObjectCount': len(new['objects']),
            'findings': dict(findings),
            'delta': delta,
        })
        print('%-44s %s -> %s  %5d -> %5d objects | breaking=%d data=%d obsolete=%d additive=%d'
              % (key, old['version'], new['version'],
                 len(old['objects']), len(new['objects']),
                 findings.get('breaking', 0), findings.get('data', 0),
                 findings.get('obsolete', 0), findings.get('additive', 0)))
        del old, new

    for key in sorted(set(current_files) ^ set(latest_files)):
        side = 'current' if key in current_files else 'latest'
        report['skipped'].append({'app': key, 'reason': 'only present in the %s set' % side})
        print('::warning::%s is only present in the %s set - not compared' % (key, side))

    if not report['apps']:
        print('::error::no package could be compared - the two sets have no package in common')
        return 2

    # The gate this whole script exists for: an empty inventory is a broken
    # parser, not a clean upgrade.
    if report['totals']['oldObjects'] == 0 or report['totals']['newObjects'] == 0:
        print('::error::Extracted 0 objects (old=%d new=%d) from %d package(s). '
              'Refusing to emit an upgrade-safety report from an empty diff.'
              % (report['totals']['oldObjects'], report['totals']['newObjects'],
                 len(report['apps'])))
        return 2

    os.makedirs(args.out_dir, exist_ok=True)
    json_path = os.path.join(args.out_dir, 'symbol-changes.json')
    markdown_path = os.path.join(args.out_dir, 'symbol-changes.md')
    summary_path = os.path.join(args.out_dir, 'summary.json')

    with open(json_path, 'w', encoding='utf-8') as handle:
        json.dump(report, handle, indent=1, ensure_ascii=False)
    with open(markdown_path, 'w', encoding='utf-8') as handle:
        handle.write(render_markdown(report))

    totals = Counter()
    for app in report['apps']:
        totals.update(app['findings'])
    summary = {
        'environment': args.environment,
        'currentVersion': args.current_version,
        'targetVersion': args.target_version,
        'appsCompared': len(report['apps']),
        'oldObjects': report['totals']['oldObjects'],
        'newObjects': report['totals']['newObjects'],
        'breaking': totals.get('breaking', 0),
        'data': totals.get('data', 0),
        'obsolete': totals.get('obsolete', 0),
        'additive': totals.get('additive', 0),
        'removedObjects': totals.get('removedObjects', 0),
        'addedObjects': totals.get('addedObjects', 0),
        'renamedObjects': totals.get('renamedObjects', 0),
        'movedObjects': totals.get('movedObjects', 0),
    }
    with open(summary_path, 'w', encoding='utf-8') as handle:
        json.dump(summary, handle, indent=1)

    print('')
    print('Wrote %s' % json_path)
    print('Wrote %s' % markdown_path)
    print('Wrote %s' % summary_path)

    github_output = os.environ.get('GITHUB_OUTPUT')
    if github_output:
        with open(github_output, 'a', encoding='utf-8') as handle:
            for name, value in summary.items():
                handle.write('%s=%s\n' % (name, value))
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)

    selftest = commands.add_parser('selftest', help='verify the extractor against known packages')
    selftest.add_argument('--symbols-dir', required=True)
    selftest.set_defaults(handler=command_selftest)

    diff = commands.add_parser('diff', help='diff two folders of symbol packages')
    diff.add_argument('--current', required=True, help='symbols for the version on the environment')
    diff.add_argument('--latest', required=True, help='symbols for the target version')
    diff.add_argument('--out-dir', required=True)
    diff.add_argument('--environment', default='')
    diff.add_argument('--current-version', default='')
    diff.add_argument('--target-version', default='')
    diff.set_defaults(handler=command_diff)

    args = parser.parse_args()
    return args.handler(args)


if __name__ == '__main__':
    sys.exit(main())

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
import re
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

    def member_caption(member):
        return (member.get('properties') or {}).get('Caption')

    for name in sorted(set(old_members) - set(new_members)):
        removed.append({'name': name, 'signature': old_members[name]['signature'],
                        'caption': member_caption(old_members[name])})
    for name in sorted(set(new_members) - set(old_members)):
        added.append({'name': name, 'signature': new_members[name]['signature'],
                      'caption': member_caption(new_members[name])})

    for name in sorted(set(old_members) & set(new_members)):
        old, new = old_members[name], new_members[name]
        if old['signature'] == new['signature'] and old.get('properties') == new.get('properties'):
            continue

        entry = {
            'name': name,
            'caption': member_caption(new),
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
            'caption': obj['properties'].get('Caption'),
        })
    for key in sorted(set(new_objects) - set(old_objects)):
        obj = new_objects[key]
        result['addedObjects'].append({
            'key': key, 'kind': obj['kind'], 'id': obj['id'],
            'name': obj['name'], 'namespace': obj['namespace'],
            'caption': obj['properties'].get('Caption'),
        })

    for key in sorted(set(old_objects) & set(new_objects)):
        old, new = old_objects[key], new_objects[key]

        # 'oldName'/'newName' and 'oldNamespace'/'newNamespace' rather than a
        # shared 'old'/'new': the two collections would otherwise use the same
        # field names for different things, which is how a consumer ends up
        # reading a namespace as an object name.
        if old['name'] != new['name']:
            result['renamedObjects'].append({
                'key': key, 'kind': old['kind'], 'id': old['id'],
                'namespace': new['namespace'], 'name': new['name'],
                'oldName': old['name'], 'newName': new['name'],
            })
        if old['namespace'] != new['namespace']:
            result['movedObjects'].append({
                'key': key, 'kind': old['kind'], 'id': old['id'], 'name': new['name'],
                'namespace': new['namespace'],
                'oldNamespace': old['namespace'], 'newNamespace': new['namespace'],
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
            # The user-facing name. Present on 98% of pages and reports and 92%
            # of tables, so a report can say "Posted Sales Invoices" instead of
            # "Sales Invoice List".
            'caption': new['properties'].get('Caption'),
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
                '%s %s: "%s" -> "%s"' % (o['kind'], o['id'], o['oldName'], o['newName'])
                for o in delta['renamedObjects']
            ]))
            lines.append('')

        if delta['movedObjects']:
            lines.append('### Moved to another namespace - %d' % len(delta['movedObjects']))
            lines.append('These are not removals - the object Id is unchanged.')
            lines.append('')
            lines.append(format_list([
                '%s %s "%s": %s -> %s' % (o['kind'], o['id'], o['name'],
                                          o['oldNamespace'] or '<root>', o['newNamespace'])
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
# Business rollup - a functional view over the technical diff
#
# The diff is Microsoft-wide: for a major upgrade it holds thousands of changes
# across the whole product, and 95% of them concern areas a given customer never
# touches. Handing that to a functional consultant is worse than handing them
# nothing. So every finding is placed in one of three tiers and only the first
# two are ever enumerated:
#
#   tier 1  the AL source in this repository actually references it
#   tier 2  it sits in a business area we use (derived from tier 1, plus the
#           businessAreas setting - a customer can use Finance heavily with zero
#           customisation there, and an upgrade change still needs UAT)
#   tier 3  everything else - counted per area, never listed
#
# Findings are also filtered by consequence: only things a user or the data can
# actually notice survive. Namespace moves, renames that keep the Id, internal
# visibility changes and attribute churn are technical facts with no functional
# meaning, and are dropped here rather than being explained away in prose.
#
# Wording is deliberately NOT produced here. Each finding carries a
# consequenceCode and the facts behind it; the report's instruction file owns
# the sentence and the language, so a consultant can change either without
# touching this script.
# --------------------------------------------------------------------------

# Object kinds a user meets in the product, versus kinds that are pure plumbing.
USER_FACING_KINDS = {
    'Pages': 'screen',
    'PageExtensions': 'screen',
    'PageCustomizations': 'screen',
    'Reports': 'report',
    'ReportExtensions': 'report',
    'Tables': 'data',
    'TableExtensions': 'data',
    'EnumTypes': 'choice-list',
    'EnumExtensionTypes': 'choice-list',
    'Profiles': 'role-centre',
    'ProfileExtensions': 'role-centre',
    'PermissionSets': 'permissions',
    'PermissionSetExtensions': 'permissions',
}

# Consequences that stop something working, versus ones that change how it
# behaves, versus additions. Keyed by consequenceCode.
BLOCKER_CODES = {
    'object-removed', 'object-obsoleted', 'field-removed', 'field-type-changed',
    'field-obsoleted', 'enum-value-removed', 'enum-ordinal-changed',
    'enum-not-extensible', 'integration-point-changed', 'method-removed-used',
    'access-restricted',
}
RETEST_CODES = {
    'calcformula-changed', 'tablerelation-changed', 'permissions-changed',
    'dataclassification-changed', 'posting-behaviour-changed', 'caption-changed',
    'screen-behaviour-changed', 'data-scope-changed',
}
OPPORTUNITY_CODES = {'object-added', 'enum-value-added'}

# Property -> consequenceCode, for property-level findings that matter
# functionally. Anything not listed here is technical noise for this report.
PROPERTY_CONSEQUENCE = {
    'CalcFormula': 'calcformula-changed',
    'TableRelation': 'tablerelation-changed',
    'Permissions': 'permissions-changed',
    'InherentPermissions': 'permissions-changed',
    'InherentEntitlements': 'permissions-changed',
    'DataClassification': 'dataclassification-changed',
    'ObsoleteState': 'object-obsoleted',
    'Extensible': 'enum-not-extensible',
    'Access': 'access-restricted',
    'Caption': 'caption-changed',
    'Editable': 'screen-behaviour-changed',
    'InsertAllowed': 'screen-behaviour-changed',
    'ModifyAllowed': 'screen-behaviour-changed',
    'DeleteAllowed': 'screen-behaviour-changed',
    'SourceTable': 'screen-behaviour-changed',
    'PageType': 'screen-behaviour-changed',
    'TableType': 'data-scope-changed',
    'ReplicateData': 'data-scope-changed',
    'DataPerCompany': 'data-scope-changed',
}


def area_of(namespace):
    """Namespace -> business area, the way a consultant groups the product.

    BC namespaces are domain-shaped from v22 on (Microsoft.Sales.Document,
    Microsoft.Inventory.Ledger, ...), so the second segment is the business
    area. System.* is platform plumbing and collapses into one bucket.
    """
    if not namespace:
        return 'Unclassified'
    segments = namespace.split('.')
    if segments[0] == 'System':
        return 'Platform'
    if segments[0] == 'Microsoft' and len(segments) > 1:
        return segments[1]
    return segments[0]


# How our AL source can name a Microsoft object. All four spellings below occur
# in real code and the earlier version of this scanner only matched the first:
#
#   extends "Sales Header"                        quoted
#   extends Item                                  bare identifier - legal when
#                                                 the name needs no quoting
#   extends Microsoft.Sales.Customer."Customer Card"   namespace-qualified
#   extends "Service Invoice line"                a different case to the real
#                                                 object name - AL does not care
#
# Object names are therefore matched case-insensitively throughout, and every
# pattern tolerates an optional namespace prefix.
_NAME = r'(?:[\w]+(?:\.[\w]+)*\.)?(?:"([^"]+)"|([A-Za-z]\w*))'

AL_REFERENCE_PATTERNS = [
    (re.compile(r'\b(?:table|page|report|enum|permissionset|profile)extension\s+\d+\s+'
                r'(?:"[^"]+"|\w+)\s+extends\s+' + _NAME, re.IGNORECASE), 'extends'),
    (re.compile(r'\bRecord\s+' + _NAME, re.IGNORECASE), 'record'),
    (re.compile(r'\b(?:Codeunit|Page|Report|Table|Enum|Query|XmlPort|Interface)::' + _NAME,
                re.IGNORECASE), 'reference'),
    (re.compile(r'SourceTable\s*=\s*' + _NAME, re.IGNORECASE), 'sourcetable'),
]

# The event name is the third argument and may be a quoted string or a bare
# identifier; 44 of the 55 subscriptions in this repository use the bare form,
# which the earlier pattern could not see at all.
#
# The fourth argument matters for table triggers: with ObjectType::Table it is
# the field the subscriber hooks, as in
#   (ObjectType::Table, Database::"Service Header", OnAfterValidateEvent, "Ship-to Code", ...)
# so that subscriber is at risk when the FIELD changes, not when a method does.
# For a codeunit event the argument is an unused '' and there is nothing to read.
AL_EVENT_PATTERN = re.compile(
    r'EventSubscriber\s*\(\s*ObjectType::(\w+)\s*,\s*\w+::' + _NAME +
    r'\s*,\s*(?:\'([^\']*)\'|([A-Za-z]\w*))'
    r'(?:\s*,\s*(?:"([^"]+)"|\'([^\']*)\'))?',
    re.IGNORECASE)

# Our own object declarations, and what they extend.
AL_DECLARATION_PATTERN = re.compile(
    r'^\s*(tableextension|pageextension|reportextension|enumextension|permissionsetextension'
    r'|profileextension|table|page|report|codeunit|enum|query|interface|permissionset|profile)'
    r'\s+(\d+)\s+("(?:[^"]+)"|\w+)(?:\s+extends\s+' + _NAME + r')?',
    re.IGNORECASE)

# A quoted identifier after a dot - field access such as SalesHeader."No.".
# Deliberately loose: it is used only to decide whether a member finding is
# worth showing, never to claim a definite reference.
AL_MEMBER_PATTERN = re.compile(r'\w\s*\.\s*"([^"]+)"')

EXTENSION_KINDS = {'tableextension', 'pageextension', 'reportextension', 'enumextension',
                   'permissionsetextension', 'profileextension'}


def _pick(groups):
    """The first non-empty group of a quoted-or-bare name alternation."""
    for value in groups:
        if value:
            return value
    return ''


def scan_al_source(folder):
    """Inventory our own AL code: what it declares, extends and subscribes to.

    Object names are keyed lower-case because AL is case-insensitive about them,
    and real code does not match the symbol casing - this repository extends
    "Service Invoice line" where Microsoft spells it "Service Invoice Line".
    """
    objects = {}
    events = {}
    members = {}
    extensions = []
    subscriptions = []
    own_objects = []
    files = 0

    for root, _dirs, names in os.walk(folder):
        if any(part in ('.alpackages', '.snapshots', '.output', '.alcache')
               for part in root.split(os.sep)):
            continue
        for name in sorted(names):
            if not name.lower().endswith('.al'):
                continue
            path = os.path.join(root, name)
            files += 1
            try:
                with open(path, encoding='utf-8-sig', errors='replace') as handle:
                    lines = handle.readlines()
            except OSError:
                continue

            relative = os.path.relpath(path, folder).replace(os.sep, '/')
            for number, line in enumerate(lines, 1):
                reference = {'file': relative, 'line': number}

                for pattern, how in AL_REFERENCE_PATTERNS:
                    for match in pattern.findall(line):
                        target = _pick(match if isinstance(match, tuple) else (match,))
                        if target:
                            objects.setdefault(target.lower(), []).append(
                                dict(reference, how=how, name=target))

                for match in AL_EVENT_PATTERN.findall(line):
                    object_type = match[0]
                    host = _pick(match[1:3])
                    event = _pick(match[3:5])
                    element = _pick(match[5:7])
                    if not host or not event:
                        continue
                    subscriptions.append(dict(reference, objectType=object_type, host=host,
                                              event=event, element=element))
                    events.setdefault((host.lower(), event.lower()), []).append(
                        dict(reference, how='subscriber', name=host))
                    objects.setdefault(host.lower(), []).append(
                        dict(reference, how='subscriber', name=host))
                    if element:
                        # The hooked field is a member reference in its own right.
                        members.setdefault(element.lower(), []).append(
                            dict(reference, how='trigger-field', name=element))

                declaration = AL_DECLARATION_PATTERN.match(line)
                if declaration:
                    kind = declaration.group(1).lower()
                    own = {'kind': kind, 'id': declaration.group(2),
                           'name': declaration.group(3).strip('"'), 'file': relative,
                           'line': number}
                    own_objects.append(own)
                    target = _pick(declaration.groups()[3:5])
                    if kind in EXTENSION_KINDS and target:
                        extensions.append(dict(own, target=target))

                for member_name in AL_MEMBER_PATTERN.findall(line):
                    members.setdefault(member_name.lower(), []).append(
                        dict(reference, how='member', name=member_name))

    return {'objects': objects, 'events': events, 'members': members,
            'extensions': extensions, 'subscriptions': subscriptions,
            'ownObjects': own_objects, 'alFiles': files}


def user_label(entry):
    """The Caption when there is one, because that is what the user reads."""
    return entry.get('caption') or entry.get('name') or ''


def make_finding(severity, code, area, obj, facts, references):
    return {
        'severity': severity,
        'consequenceCode': code,
        'area': area,
        'objectKind': obj['kind'],
        'objectSurface': USER_FACING_KINDS.get(obj['kind'], 'technical'),
        'objectId': obj.get('id'),
        'objectName': obj.get('name'),
        'objectLabel': user_label(obj),
        'namespace': obj.get('namespace'),
        'usedByCustomization': bool(references),
        'references': references[:6],
        'facts': facts,
    }


def build_rollup(report, al_index, declared_areas):
    """Turn a symbol-changes report into a tiered, functional view."""
    referenced_objects = al_index['objects']
    referenced_events = al_index['events']
    referenced_members = al_index['members']

    # --- Tier 1 and the areas it implies --------------------------------
    auto_areas = set()
    footprint_by_area = Counter()
    for app in report['apps']:
        delta = app['delta']
        groups = (delta['removedObjects'] + delta['addedObjects'] + delta['changedObjects']
                  + delta['renamedObjects'] + delta['movedObjects'])
        for obj in groups:
            # Every collection carries 'name' and 'namespace'; a rename also
            # carries the old name, and our AL source may still use either.
            names = [obj.get('name'), obj.get('oldName')]
            if any(name and name.lower() in referenced_objects for name in names):
                area = area_of(obj.get('namespace'))
                auto_areas.add(area)
                footprint_by_area[area] += 1

    effective_areas = set(auto_areas) | set(declared_areas)

    # --- Walk every finding ----------------------------------------------
    findings = []
    out_of_scope = Counter()
    suppressed = Counter()

    def references_for(name, member=None):
        # AL is case-insensitive about object and member names, and real code
        # does not match the symbol casing, so every lookup is lower-cased.
        key = (name or '').lower()
        found = list(referenced_objects.get(key, []))
        if member:
            found += referenced_events.get((key, member.lower()), [])
            found += referenced_members.get(member.lower(), [])
        return found

    for app in report['apps']:
        delta = app['delta']

        # Renames and namespace moves keep the object Id: nothing a user or the
        # data can notice. Counted so the report can say they were considered.
        suppressed['renamed'] += len(delta['renamedObjects'])
        suppressed['moved'] += len(delta['movedObjects'])

        for obj in delta['removedObjects']:
            area = area_of(obj['namespace'])
            references = references_for(obj['name'])
            in_scope = bool(references) or (
                area in effective_areas and obj['kind'] in USER_FACING_KINDS)
            if not in_scope:
                out_of_scope[area] += 1
                continue
            findings.append(make_finding(
                'blocker', 'object-removed', area, obj,
                {'removedFrom': app['app'], 'oldVersion': app['oldVersion']}, references))

        for obj in delta['addedObjects']:
            area = area_of(obj['namespace'])
            references = references_for(obj['name'])
            # An addition is only interesting where we work, and only when it is
            # something a user meets.
            if area not in effective_areas or obj['kind'] not in USER_FACING_KINDS:
                out_of_scope[area] += 1
                continue
            findings.append(make_finding(
                'opportunity', 'object-added', area, obj,
                {'addedIn': app['app'], 'newVersion': app['newVersion']}, references))

        for obj in delta['changedObjects']:
            area = area_of(obj['namespace'])
            references = references_for(obj['name'])
            area_in_scope = area in effective_areas
            if not references and not area_in_scope:
                out_of_scope[area] += 1
                continue

            for change in obj['propertyChanges']:
                code = PROPERTY_CONSEQUENCE.get(change['property'])
                if not code:
                    suppressed['technical-property'] += 1
                    continue
                if code == 'object-obsoleted' and change['new'] != 'Removed':
                    code = 'field-obsoleted'
                severity = 'blocker' if code in BLOCKER_CODES else 'retest'
                findings.append(make_finding(
                    severity, code, area, obj,
                    {'property': change['property'], 'old': change['old'],
                     'new': change['new'], 'scope': 'object'}, references))

            for member in obj['removedMembers']:
                member_references = references_for(obj['name'], member['name'])
                is_method = obj['kind'] in ('Codeunits', 'Interfaces', 'Pages',
                                            'PageExtensions', 'Reports', 'ReportExtensions')
                if is_method:
                    # Base Application alone changes tens of thousands of
                    # methods per release. Only the ones our code names can
                    # matter functionally.
                    if not member_references:
                        suppressed['method-not-used'] += 1
                        continue
                    code = 'method-removed-used'
                else:
                    code = ('enum-value-removed'
                            if obj['kind'].startswith('Enum') else 'field-removed')
                    if not member_references and not area_in_scope:
                        out_of_scope[area] += 1
                        continue
                findings.append(make_finding(
                    'blocker', code, area, obj,
                    {'member': member['name'], 'memberLabel': user_label(member),
                     'was': member['signature'], 'scope': 'member'}, member_references))

            for member in obj['changedMembers']:
                member_references = references_for(obj['name'], member['name'])
                category = member.get('category', 'info')
                reasons = member.get('reasons', [])
                is_method = obj['kind'] in ('Codeunits', 'Interfaces', 'Pages',
                                            'PageExtensions', 'Reports', 'ReportExtensions')

                if is_method:
                    if not member_references or category not in ('breaking', 'obsolete'):
                        suppressed['method-not-used'] += 1
                        continue
                    code = 'integration-point-changed'
                    severity = 'blocker' if category == 'breaking' else 'retest'
                elif obj['kind'].startswith('Enum'):
                    if category != 'breaking':
                        suppressed['technical-member'] += 1
                        continue
                    code = 'enum-ordinal-changed'
                    severity = 'blocker'
                else:
                    codes = set()
                    for reason in reasons:
                        head = reason.split(' ')[0]
                        mapped = PROPERTY_CONSEQUENCE.get(head)
                        if mapped:
                            codes.add(mapped)
                    if reason_has_type_change(reasons):
                        codes.add('field-type-changed')
                    if not codes:
                        suppressed['technical-member'] += 1
                        continue
                    code = sorted(codes, key=lambda c: (c not in BLOCKER_CODES, c))[0]
                    severity = 'blocker' if code in BLOCKER_CODES else 'retest'
                    if not member_references and not area_in_scope:
                        out_of_scope[area] += 1
                        continue

                findings.append(make_finding(
                    severity, code, area, obj,
                    {'member': member['name'], 'memberLabel': user_label(member),
                     'old': member['old'], 'new': member['new'],
                     'reasons': reasons, 'scope': 'member'}, member_references))

    return {
        'areas': {
            'derivedFromCode': sorted(auto_areas),
            'declared': sorted(declared_areas),
            'effective': sorted(effective_areas),
        },
        'customizationFootprint': {
            'alFiles': al_index['alFiles'],
            'microsoftObjectsReferenced': len(referenced_objects),
            'changedObjectsWeReference': sum(footprint_by_area.values()),
            'byArea': dict(footprint_by_area.most_common()),
        },
        'findings': findings,
        'outOfScopeByArea': dict(out_of_scope.most_common()),
        'suppressedAsTechnical': dict(suppressed),
    }


def reason_has_type_change(reasons):
    return any(reason.startswith('type ') for reason in reasons)


# --------------------------------------------------------------------------
# Cross-reference: our customization against the diff
#
# The diff answers "what did Microsoft change". This answers the question a
# developer and a consultant actually ask: "what of OURS sits on top of that".
# Every extension point and every event subscription is resolved against the
# compared packages and given one of four states - and 'not-analysed' is a
# first-class answer, never quietly folded into 'unchanged'.
# --------------------------------------------------------------------------

def index_delta_by_name(report):
    """{lower object name: {'removed'|'added'|'changed'|'renamed'|'moved': entry}}"""
    index = {}
    for app in report['apps']:
        delta = app['delta']
        for group, label in (('removedObjects', 'removed'), ('addedObjects', 'added'),
                             ('changedObjects', 'changed'), ('renamedObjects', 'renamed'),
                             ('movedObjects', 'moved')):
            for obj in delta[group]:
                for name in (obj.get('name'), obj.get('oldName')):
                    if name:
                        index.setdefault(name.lower(), {}).setdefault(label, obj)
    return index


def summarise_changed_object(obj):
    counts = Counter()
    counts['propertyChanges'] = len(obj['propertyChanges'])
    counts['removedMembers'] = len(obj['removedMembers'])
    counts['addedMembers'] = len(obj['addedMembers'])
    counts['changedMembers'] = len(obj['changedMembers'])
    for change in obj['propertyChanges']:
        counts[change['category']] += 1
    for member in obj['changedMembers']:
        counts[member.get('category', 'info')] += 1
    counts['breaking'] += len(obj['removedMembers'])
    return dict(counts)


def find_member(obj, name):
    """A member of a changed object, by name, case-insensitively."""
    if not obj or not name:
        return None, None
    needle = name.lower()
    for member in obj['removedMembers']:
        if member['name'].lower() == needle:
            return 'removed', member
    for member in obj['changedMembers']:
        if member['name'].lower() == needle:
            return 'changed', member
    for member in obj['addedMembers']:
        if member['name'].lower() == needle:
            return 'added', member
    return None, None


def cross_reference(al_index, report, object_index):
    """Give every extension point and subscription a state against the diff."""
    delta = index_delta_by_name(report)
    known = object_index.get('objects', {})

    def resolve(name):
        return known.get((name or '').lower())

    extension_surface = []
    for extension in al_index['extensions']:
        target = extension['target']
        meta = resolve(target)
        found = delta.get(target.lower(), {})

        entry = {
            'ourKind': extension['kind'],
            'ourId': extension['id'],
            'ourName': extension['name'],
            'file': extension['file'],
            'line': extension['line'],
            'target': target,
            'targetLabel': (meta or {}).get('caption') or (meta or {}).get('name') or target,
            'targetKind': (meta or {}).get('kind'),
            'targetApp': (meta or {}).get('app'),
            'area': area_of((meta or {}).get('namespace')) if meta else None,
        }

        if meta is None:
            entry['status'] = 'not-analysed'
            entry['reason'] = ('no compared package defines "%s" - it belongs to a package '
                               'that could not be compared' % target)
        elif 'removed' in found:
            entry['status'] = 'removed'
            entry['reason'] = 'the object our extension rides on no longer exists'
        elif 'changed' in found:
            entry['status'] = 'changed'
            entry['summary'] = summarise_changed_object(found['changed'])
        else:
            entry['status'] = 'unchanged'
        extension_surface.append(entry)

    subscriptions = []
    for subscription in al_index['subscriptions']:
        host = subscription['host']
        meta = resolve(host)
        found = delta.get(host.lower(), {})
        changed_object = found.get('changed')

        entry = {
            'file': subscription['file'],
            'line': subscription['line'],
            'objectType': subscription['objectType'],
            'host': host,
            'hostLabel': (meta or {}).get('caption') or (meta or {}).get('name') or host,
            'hostApp': (meta or {}).get('app'),
            'event': subscription['event'],
            'element': subscription['element'],
            'area': area_of((meta or {}).get('namespace')) if meta else None,
        }

        if meta is None:
            entry['status'] = 'not-analysed'
            entry['reason'] = ('no compared package defines "%s" - this subscription could '
                               'not be checked' % host)
            subscriptions.append(entry)
            continue
        if 'removed' in found:
            entry['status'] = 'removed'
            entry['reason'] = 'the object publishing this event no longer exists'
            subscriptions.append(entry)
            continue

        # A table-trigger subscription hangs off a FIELD, not a published
        # method, so that is what has to be checked for it.
        probe = subscription['element'] if subscription['element'] else subscription['event']
        state, member = find_member(changed_object, probe)

        if state == 'removed':
            entry['status'] = 'removed'
            entry['reason'] = '"%s" no longer exists on %s' % (probe, host)
        elif state == 'changed':
            category = member.get('category', 'info')
            entry['reasons'] = member.get('reasons', [])
            if category == 'breaking':
                entry['status'] = 'incompatible'
            elif category == 'obsolete':
                entry['status'] = 'obsoleted'
            else:
                entry['status'] = 'changed'
            entry['old'] = member.get('old')
            entry['new'] = member.get('new')
        elif changed_object is not None:
            entry['status'] = 'unchanged'
            entry['note'] = ('%s changed elsewhere, but not in what this subscription binds to'
                             % host)
        else:
            entry['status'] = 'unchanged'
        subscriptions.append(entry)

    by_file = {}
    for item in extension_surface:
        bucket = by_file.setdefault(item['file'], {'extensions': 0, 'subscriptions': 0,
                                                   'needsAction': 0})
        bucket['extensions'] += 1
        if item['status'] in ('removed', 'not-analysed'):
            bucket['needsAction'] += 1
    for item in subscriptions:
        bucket = by_file.setdefault(item['file'], {'extensions': 0, 'subscriptions': 0,
                                                   'needsAction': 0})
        bucket['subscriptions'] += 1
        if item['status'] in ('removed', 'incompatible', 'not-analysed'):
            bucket['needsAction'] += 1

    return {
        'extensionSurface': extension_surface,
        'eventSubscriptions': subscriptions,
        'byFile': dict(sorted(by_file.items(),
                              key=lambda kv: (-kv[1]['needsAction'], kv[0]))),
        'counts': {
            'ownObjects': len(al_index['ownObjects']),
            'extensionPoints': len(extension_surface),
            'subscriptions': len(subscriptions),
            'extensionsChanged': sum(1 for x in extension_surface if x['status'] == 'changed'),
            'extensionsRemoved': sum(1 for x in extension_surface if x['status'] == 'removed'),
            'extensionsNotAnalysed': sum(1 for x in extension_surface
                                         if x['status'] == 'not-analysed'),
            'subscriptionsIncompatible': sum(1 for x in subscriptions
                                             if x['status'] == 'incompatible'),
            'subscriptionsObsoleted': sum(1 for x in subscriptions
                                          if x['status'] == 'obsoleted'),
            'subscriptionsRemoved': sum(1 for x in subscriptions if x['status'] == 'removed'),
            'subscriptionsNotAnalysed': sum(1 for x in subscriptions
                                            if x['status'] == 'not-analysed'),
        },
    }


BLOCKER_CAP = 0      # no cap - these must all be shown
RETEST_CAP = 300
OPPORTUNITY_CAP = 100


def render_rollup_markdown(rollup, header):
    """A deterministic fallback view. The narrative report is written from the
    JSON by the analysis step; this one is always available even when that
    step is skipped or fails."""
    lines = []
    lines.append('# Functional impact - mechanical rollup')
    lines.append('')
    lines.append('| | |')
    lines.append('| --- | --- |')
    for label, value in header.items():
        lines.append('| %s | %s |' % (label, value))
    lines.append('')
    lines.append('Generated by diff_symbols.py rollup. No wording or judgement is applied '
                 'here - each row states the finding and the facts behind it.')
    lines.append('')

    areas = rollup['areas']
    lines.append('## Scope')
    lines.append('')
    lines.append('- Areas derived from the AL source: %s'
                 % (', '.join(areas['derivedFromCode']) or 'none'))
    lines.append('- Areas declared in settings: %s'
                 % (', '.join(areas['declared']) or 'none'))
    lines.append('- Effective scope: %s' % (', '.join(areas['effective']) or 'none'))
    footprint = rollup['customizationFootprint']
    lines.append('- Customization: %d AL file(s) naming %d Microsoft object(s)'
                 % (footprint['alFiles'], footprint['microsoftObjectsReferenced']))
    lines.append('')

    order = [('blocker', 'Must be handled before the upgrade', BLOCKER_CAP),
             ('retest', 'Needs re-testing', RETEST_CAP),
             ('opportunity', 'New standard capability', OPPORTUNITY_CAP)]
    for severity, title, cap in order:
        rows = [f for f in rollup['findings'] if f['severity'] == severity]
        rows.sort(key=lambda f: (not f['usedByCustomization'], f['area'], f['objectLabel']))
        lines.append('## %s (%d)' % (title, len(rows)))
        lines.append('')
        if not rows:
            lines.append('None.')
            lines.append('')
            continue
        shown = rows if cap == 0 else rows[:cap]
        lines.append('| Area | What | Finding | Used by our app |')
        lines.append('| --- | --- | --- | --- |')
        for finding in shown:
            what = finding['objectLabel']
            if finding['facts'].get('memberLabel') or finding['facts'].get('member'):
                what = '%s / %s' % (what, finding['facts'].get('memberLabel')
                                    or finding['facts']['member'])
            used = 'yes' if finding['usedByCustomization'] else '-'
            if finding['references']:
                used = '%s (%s:%s)' % (used, finding['references'][0]['file'],
                                       finding['references'][0]['line'])
            lines.append('| %s | %s | %s | %s |' % (
                finding['area'], what, finding['consequenceCode'], used))
        if len(rows) > len(shown):
            lines.append('')
            lines.append('%d more - see business-impact.json.' % (len(rows) - len(shown)))
        lines.append('')

    customization = rollup.get('customization')
    affected = rollup.get('affectedCustomization')
    if customization:
        lines.append('## Our customization')
        lines.append('')
        lines.append('| | Total | Changed | Removed | Incompatible | Not analysed |')
        lines.append('| --- | --- | --- | --- | --- | --- |')
        lines.append('| Extension points | %d | %d | %d | - | %d |' % (
            customization['extensionPoints'], customization['extensionsChanged'],
            customization['extensionsRemoved'], customization['extensionsNotAnalysed']))
        lines.append('| Event subscriptions | %d | - | %d | %d | %d |' % (
            customization['subscriptions'], customization['subscriptionsRemoved'],
            customization['subscriptionsIncompatible'],
            customization['subscriptionsNotAnalysed']))
        lines.append('')

    if affected:
        for label, key, columns in (
                ('Extension points affected', 'extensionSurface',
                 ('area', 'targetLabel', 'ourName', 'file', 'status')),
                ('Event subscriptions affected', 'eventSubscriptions',
                 ('area', 'hostLabel', 'event', 'file', 'status'))):
            rows = affected[key]
            lines.append('### %s (%d)' % (label, len(rows)))
            lines.append('')
            if not rows:
                lines.append('None.')
                lines.append('')
                continue
            lines.append('| %s |' % ' | '.join(columns))
            lines.append('| %s |' % ' | '.join('---' for _ in columns))
            for row in rows[:MAX_ITEMS]:
                lines.append('| %s |' % ' | '.join(
                    str(row.get(column) or '-') for column in columns))
            if len(rows) > MAX_ITEMS:
                lines.append('')
                lines.append('%d more - see customization-footprint.json.'
                             % (len(rows) - MAX_ITEMS))
            lines.append('')

    lines.append('## Out of scope - counted, not listed')
    lines.append('')
    out_of_scope = rollup['outOfScopeByArea']
    if out_of_scope:
        lines.append(' · '.join('%s %d' % (area, count) for area, count in out_of_scope.items()))
    else:
        lines.append('None.')
    lines.append('')
    lines.append('## Dropped as technical, with no functional meaning')
    lines.append('')
    suppressed = rollup['suppressedAsTechnical']
    lines.append(' · '.join('%s %d' % (reason, count)
                            for reason, count in suppressed.items()) or 'None.')
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

    Point this at a folder of real symbol packages - typically a local
    ALGo-App/.alpackages - to confirm the extractor still finds objects in
    current Microsoft symbols.

    That folder is gitignored (.alpackages/ and *.app), so a CI runner does not
    have it, and its absence is reported as a skip rather than a failure. The
    binary read path and the namespace flattening are covered without it by
    test_diff_symbols.py, which builds a .app package in memory; and a live run
    is still gated by the 'diff' command, which fails when it extracts nothing.
    """
    folder = args.symbols_dir
    packages = []
    if os.path.isdir(folder):
        packages = [f for f in sorted(os.listdir(folder)) if f.lower().endswith('.app')]

    if not packages:
        reason = 'does not exist' if not os.path.isdir(folder) else 'holds no .app packages'
        print('::notice::Self-test skipped: %s %s. This is expected on a CI runner - the '
              'folder is gitignored. Run this locally against a populated .alpackages to '
              'check the extractor against real symbols.' % (folder, reason))
        return 0

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

    # Which objects exist in the packages that were actually compared. The delta
    # only lists what CHANGED, so without this index a consumer cannot tell
    # "unchanged" from "never looked at" - and for an upgrade report those two
    # answers are worlds apart.
    object_index = {}

    for key in sorted(set(current_files) & set(latest_files)):
        old = describe(current_files[key])
        new = describe(latest_files[key])
        report['totals']['oldObjects'] += len(old['objects'])
        report['totals']['newObjects'] += len(new['objects'])

        for side, objects in (('new', new['objects']), ('old', old['objects'])):
            for obj in objects.values():
                name = (obj['name'] or '').lower()
                if not name:
                    continue
                entry = object_index.get(name)
                if entry is None:
                    object_index[name] = {
                        'app': key, 'kind': obj['kind'], 'id': obj['id'],
                        'name': obj['name'], 'namespace': obj['namespace'],
                        'caption': obj['properties'].get('Caption'),
                        'sides': [side],
                    }
                elif side not in entry['sides']:
                    entry['sides'].append(side)

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
    index_path = os.path.join(args.out_dir, 'object-index.json')

    with open(json_path, 'w', encoding='utf-8') as handle:
        json.dump(report, handle, indent=1, ensure_ascii=False)
    with open(markdown_path, 'w', encoding='utf-8') as handle:
        handle.write(render_markdown(report))
    with open(index_path, 'w', encoding='utf-8') as handle:
        json.dump({'apps': sorted(set(current_files) & set(latest_files)),
                   'objects': object_index}, handle, separators=(',', ':'),
                  ensure_ascii=False)

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
    print('Wrote %s (%d object name(s) across %d package(s))'
          % (index_path, len(object_index), len(report['apps'])))

    github_output = os.environ.get('GITHUB_OUTPUT')
    if github_output:
        with open(github_output, 'a', encoding='utf-8') as handle:
            for name, value in summary.items():
                handle.write('%s=%s\n' % (name, value))
    return 0


def command_rollup(args):
    with open(args.changes, encoding='utf-8') as handle:
        report = json.load(handle)

    al_index = scan_al_source(args.al_source)
    if al_index['alFiles'] == 0:
        print('::warning::No .al files under %s - nothing can be scoped to the customization, '
              'so every finding will fall back to the declared business areas.' % args.al_source)

    declared = [area.strip() for area in (args.business_areas or '').split(',') if area.strip()]

    # A mistyped area name narrows the scope in silence, which is the class of
    # bug this whole workflow exists to remove. Check the declared names against
    # the areas the diff actually contains.
    present = set()
    for app in report['apps']:
        delta = app['delta']
        for group in ('removedObjects', 'addedObjects', 'changedObjects',
                      'renamedObjects', 'movedObjects'):
            for obj in delta[group]:
                present.add(area_of(obj.get('namespace')))
    unknown = [area for area in declared if area not in present]
    if unknown:
        print('::warning::businessAreas contains %d name(s) that do not match any business area '
              'in this diff: %s. Known areas: %s. A mistyped name silently narrows the report.'
              % (len(unknown), ', '.join(unknown), ', '.join(sorted(present))))

    rollup = build_rollup(report, al_index, declared)
    rollup['environment'] = report.get('environment', '')
    rollup['currentVersion'] = report.get('currentVersion', '')
    rollup['targetVersion'] = report.get('targetVersion', '')
    rollup['unknownDeclaredAreas'] = unknown

    coverage_gaps = []
    if args.resolution and os.path.isfile(args.resolution):
        with open(args.resolution, encoding='utf-8') as handle:
            resolution = json.load(handle)
        coverage_gaps = resolution.get('skipped') or []
    rollup['coverageGaps'] = coverage_gaps

    # --- Our own customization, cross-referenced against the diff ------------
    object_index = {'apps': [], 'objects': {}}
    if args.object_index and os.path.isfile(args.object_index):
        with open(args.object_index, encoding='utf-8') as handle:
            object_index = json.load(handle)
    else:
        print('::warning::No object index (%s). Every extension point and subscription will '
              'be reported as "not-analysed", because without it there is no way to tell an '
              'unchanged object from one that was never compared.' % (args.object_index or '-'))

    crossref = cross_reference(al_index, report, object_index)
    rollup['customization'] = crossref['counts']

    footprint = {
        'environment': rollup['environment'],
        'currentVersion': rollup['currentVersion'],
        'targetVersion': rollup['targetVersion'],
        'packagesCompared': object_index.get('apps', []),
        'counts': crossref['counts'],
        'ownObjects': al_index['ownObjects'],
        'extensionSurface': crossref['extensionSurface'],
        'eventSubscriptions': crossref['eventSubscriptions'],
        'byFile': crossref['byFile'],
        'coverageGaps': coverage_gaps,
    }

    # The functional report gets only what is actually affected; the full
    # inventory lives in customization-footprint.json for the technical one.
    affected_states = ('changed', 'removed', 'incompatible', 'obsoleted', 'not-analysed')
    rollup['affectedCustomization'] = {
        'extensionSurface': [x for x in crossref['extensionSurface']
                             if x['status'] in affected_states],
        'eventSubscriptions': [x for x in crossref['eventSubscriptions']
                               if x['status'] in affected_states],
    }

    counts = Counter(finding['severity'] for finding in rollup['findings'])
    counts['findings'] = len(rollup['findings'])
    counts['areasInScope'] = len(rollup['areas']['effective'])
    counts['coverageGaps'] = len(coverage_gaps)
    rollup['counts'] = dict(counts)

    os.makedirs(args.out_dir, exist_ok=True)
    json_path = os.path.join(args.out_dir, 'business-impact.json')
    markdown_path = os.path.join(args.out_dir, 'business-impact.md')
    footprint_path = os.path.join(args.out_dir, 'customization-footprint.json')

    with open(json_path, 'w', encoding='utf-8') as handle:
        json.dump(rollup, handle, indent=1, ensure_ascii=False)
    with open(footprint_path, 'w', encoding='utf-8') as handle:
        json.dump(footprint, handle, indent=1, ensure_ascii=False)
    with open(markdown_path, 'w', encoding='utf-8') as handle:
        handle.write(render_rollup_markdown(rollup, OrderedDict([
            ('Environment', rollup['environment']),
            ('Version on environment', rollup['currentVersion']),
            ('Target version', rollup['targetVersion']),
            ('Packages compared', len(report['apps'])),
            ('Coverage gaps', len(coverage_gaps)),
        ])))

    print('AL files scanned          : %d' % al_index['alFiles'])
    print('Microsoft objects named   : %d' % len(al_index['objects']))
    print('Areas from code           : %s'
          % (', '.join(rollup['areas']['derivedFromCode']) or 'none'))
    print('Areas declared            : %s' % (', '.join(declared) or 'none'))
    print('Effective scope           : %s' % ', '.join(rollup['areas']['effective']))
    print('')
    print('Must handle before upgrade: %d' % counts.get('blocker', 0))
    print('Needs re-testing          : %d' % counts.get('retest', 0))
    print('New capabilities          : %d' % counts.get('opportunity', 0))
    print('Out of scope (counted)    : %d'
          % sum(rollup['outOfScopeByArea'].values()))
    print('Dropped as technical      : %d' % sum(rollup['suppressedAsTechnical'].values()))
    print('')
    footprint_counts = crossref['counts']
    print('--- our customization ---')
    print('Own objects               : %d' % footprint_counts['ownObjects'])
    print('Extension points          : %d (changed %d, removed %d, not analysed %d)'
          % (footprint_counts['extensionPoints'], footprint_counts['extensionsChanged'],
             footprint_counts['extensionsRemoved'], footprint_counts['extensionsNotAnalysed']))
    print('Event subscriptions       : %d (incompatible %d, obsoleted %d, removed %d, '
          'not analysed %d)'
          % (footprint_counts['subscriptions'], footprint_counts['subscriptionsIncompatible'],
             footprint_counts['subscriptionsObsoleted'], footprint_counts['subscriptionsRemoved'],
             footprint_counts['subscriptionsNotAnalysed']))
    print('')
    print('Wrote %s' % json_path)
    print('Wrote %s' % markdown_path)
    print('Wrote %s' % footprint_path)

    github_output = os.environ.get('GITHUB_OUTPUT')
    if github_output:
        with open(github_output, 'a', encoding='utf-8') as handle:
            for name in ('blocker', 'retest', 'opportunity', 'findings',
                         'areasInScope', 'coverageGaps'):
                handle.write('%s=%s\n' % (name, counts.get(name, 0)))
    return 0


def parse_fenced_list(text, language):
    """Read a ```<language> fenced block as a list of lines.

    Used to pull the banned-vocabulary and required-sections lists out of the
    report's instruction file, so the contract a consultant edits is the one the
    workflow actually enforces - rather than a second copy that drifts.
    """
    pattern = re.compile(r'```%s\s*\n(.*?)\n```' % re.escape(language), re.DOTALL)
    match = pattern.search(text)
    if not match:
        return []
    return [line.strip() for line in match.group(1).splitlines() if line.strip()]


def command_checkreport(args):
    """Check a written report against its own instruction file.

    This exists because the two reports are produced in one pass: the single
    lever that keeps the functional report from drifting into developer language
    is a check on the finished text. It reports, it does not fail the run - a
    report with leaked jargon is still worth having.
    """
    if not os.path.isfile(args.report):
        print('::warning::%s was not written - nothing to check.' % args.report)
        return 0
    if not os.path.isfile(args.instruction):
        print('::warning::%s not found - cannot check the report against its contract.'
              % args.instruction)
        return 0

    with open(args.report, encoding='utf-8', errors='replace') as handle:
        report = handle.read()
    with open(args.instruction, encoding='utf-8', errors='replace') as handle:
        instruction = handle.read()

    banned = parse_fenced_list(instruction, 'banned-vocabulary')
    required = parse_fenced_list(instruction, 'required-sections')
    if not banned and not required:
        print('::warning::%s has no banned-vocabulary or required-sections block - '
              'the report cannot be checked.' % args.instruction)
        return 0

    lowered = report.lower()
    lines = report.splitlines()

    leaks = []
    for term in banned:
        needle = term.lower()
        count = lowered.count(needle)
        if not count:
            continue
        first = next((number for number, line in enumerate(lines, 1)
                      if needle in line.lower()), 0)
        leaks.append((term, count, first))

    missing = [heading for heading in required if heading.lower() not in lowered]

    name = os.path.basename(args.report)
    print('Checking %s against %s' % (name, os.path.basename(args.instruction)))
    print('  words checked    : %d' % len(banned))
    print('  sections checked : %d' % len(required))
    print('  size             : %d line(s), %d characters' % (len(lines), len(report)))

    if leaks:
        detail = ', '.join('%s (%dx, first at line %d)' % entry for entry in leaks)
        print('::warning::%s uses %d term(s) its contract bans: %s. The report is still in '
              'the artifact, but it reads as a developer document in those places.'
              % (name, len(leaks), detail))
    else:
        print('  no banned vocabulary found')

    if missing:
        print('::warning::%s is missing %d required section(s): %s.'
              % (name, len(missing), ', '.join(missing)))
    else:
        print('  all required sections present')

    if args.compare_with and os.path.isfile(args.compare_with):
        with open(args.compare_with, encoding='utf-8', errors='replace') as handle:
            other = handle.read()
        # Two reports for two audiences should not be the same document. An
        # identical or near-identical pair is the failure mode of producing both
        # in one pass.
        shared = set(l.strip() for l in lines if len(l.strip()) > 40)
        other_lines = set(l.strip() for l in other.splitlines() if len(l.strip()) > 40)
        overlap = len(shared & other_lines)
        ratio = (overlap / len(shared)) if shared else 0
        print('  overlap with %s : %d of %d substantial line(s) (%.0f%%)'
              % (os.path.basename(args.compare_with), overlap, len(shared), 100 * ratio))
        if ratio > 0.3:
            print('::warning::%s shares %.0f%% of its substantial lines with %s. The two '
                  'reports are meant for different readers - this one looks like a copy.'
                  % (name, 100 * ratio, os.path.basename(args.compare_with)))

    github_output = os.environ.get('GITHUB_OUTPUT')
    if github_output:
        with open(github_output, 'a', encoding='utf-8') as handle:
            handle.write('bannedTerms=%d\n' % len(leaks))
            handle.write('missingSections=%d\n' % len(missing))
    return 0


def main():
    # Object captions, business area names and the section headings in the
    # report contract can all be non-ASCII. On Windows, Python writes stdout in
    # the locale codepage (cp1252 here) when it is redirected, and printing a
    # Vietnamese section name then raises UnicodeEncodeError - which fails the
    # workflow step for no good reason. Ask for UTF-8 explicitly.
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding='utf-8', errors='replace')
        except (AttributeError, ValueError):
            pass

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

    rollup = commands.add_parser(
        'rollup', help='turn a symbol diff into a tiered functional view')
    rollup.add_argument('--changes', required=True, help='symbol-changes.json from "diff"')
    rollup.add_argument('--al-source', required=True, help='folder holding our own .al files')
    rollup.add_argument('--business-areas', default='',
                        help='comma-separated areas the customer uses (e.g. Sales,Finance)')
    rollup.add_argument('--resolution', default='',
                        help='resolution.json, for the coverage-gap list')
    rollup.add_argument('--object-index', default='',
                        help='object-index.json from "diff" - needed to tell an unchanged '
                             'object from one that was never compared')
    rollup.add_argument('--out-dir', required=True)
    rollup.set_defaults(handler=command_rollup)

    checkreport = commands.add_parser(
        'checkreport', help='check a written report against its instruction file')
    checkreport.add_argument('--report', required=True)
    checkreport.add_argument('--instruction', required=True)
    checkreport.add_argument('--compare-with', default='',
                             help='the other audience\'s report, to detect a near-copy')
    checkreport.set_defaults(handler=command_checkreport)

    args = parser.parse_args()
    return args.handler(args)


if __name__ == '__main__':
    sys.exit(main())

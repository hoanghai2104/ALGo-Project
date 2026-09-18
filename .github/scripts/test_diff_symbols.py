#!/usr/bin/env python3
"""Tests for diff_symbols.py.

Run with:  python .github/scripts/test_diff_symbols.py

These cover the cases the previous in-workflow implementation got wrong, so a
regression shows up here instead of as a silently empty upgrade report.
"""

import io
import json
import os
import tempfile
import zipfile

import sys

import diff_symbols as ds


FAILURES = []


def check(name, condition, detail=''):
    if condition:
        print('  PASS  %s' % name)
    else:
        print('  FAIL  %s %s' % (name, detail))
        FAILURES.append(name)


def method(name, params=None, ret=None, attributes=None, **flags):
    entry = {'Name': name, 'Id': abs(hash(name)) % 10**9}
    if params:
        entry['Parameters'] = params
    if ret:
        entry['ReturnTypeDefinition'] = {'Name': ret}
    if attributes:
        entry['Attributes'] = attributes
    entry.update(flags)
    return entry


def param(name, type_name, is_var=False):
    entry = {'Name': name, 'TypeDefinition': {'Name': type_name}}
    if is_var:
        entry['IsVar'] = True
    return entry


def prop(name, value):
    return {'Name': name, 'Value': value}


def base_tree():
    """A symbol tree shaped like a real v28 package: root empty, objects nested."""
    return {
        'Name': 'Test App',
        'Publisher': 'Microsoft',
        'Version': '1.0.0.0',
        'Namespaces': [{
            'Name': 'Microsoft',
            'Namespaces': [{
                'Name': 'Sales',
                'Codeunits': [{
                    'Id': 80,
                    'Name': 'Sales-Post',
                    'Properties': [prop('Access', 'Public')],
                    'Methods': [
                        method('OnBeforePostSalesDoc',
                               [param('SalesHeader', 'Record "Sales Header"', True),
                                param('CommitIsSuppressed', 'Boolean')],
                               attributes=[{'Name': 'IntegrationEvent',
                                            'Arguments': [{'Value': 'false'}, {'Value': 'false'}]}]),
                        method('GetTotal', [param('DocNo', 'Code[20]')], ret='Decimal'),
                        method('Cleanup'),
                    ],
                }],
                'Tables': [{
                    'Id': 36,
                    'Name': 'Sales Header',
                    'Properties': [prop('Caption', 'Sales Header')],
                    'Fields': [
                        {'Id': 1, 'Name': 'No.', 'TypeDefinition': {'Name': 'Code[20]'},
                         'Properties': [prop('Caption', 'No.')]},
                        {'Id': 2, 'Name': 'Amount', 'TypeDefinition': {'Name': 'Decimal'},
                         'Properties': [prop('CalcFormula', 'Sum("Sales Line".Amount WHERE(...))'),
                                        prop('FieldClass', 'FlowField')]},
                    ],
                }],
                'EnumTypes': [{
                    'Id': 100,
                    'Name': 'Sales Document Type',
                    'Properties': [prop('Access', 'Public'), prop('Extensible', '1')],
                    'Values': [
                        {'Name': 'Quote', 'Properties': []},
                        {'Ordinal': 1, 'Name': 'Order', 'Properties': []},
                    ],
                }],
            }],
        }],
    }


def delta_for(mutate):
    old_tree = base_tree()
    new_tree = base_tree()
    mutate(new_tree)
    return ds.diff_objects(ds.flatten(old_tree), ds.flatten(new_tree))


def sales_post(tree):
    return tree['Namespaces'][0]['Namespaces'][0]['Codeunits'][0]


def sales_header(tree):
    return tree['Namespaces'][0]['Namespaces'][0]['Tables'][0]


def doc_type(tree):
    return tree['Namespaces'][0]['Namespaces'][0]['EnumTypes'][0]


def changed(delta, key):
    return next((o for o in delta['changedObjects'] if o['key'] == key), None)


def member(obj, name):
    return next((m for m in obj['changedMembers'] if m['name'] == name), None)


# --------------------------------------------------------------------------

print('Extraction')

flat = ds.flatten(base_tree())
check('objects nested in Namespaces are found', len(flat) == 3, '(got %d)' % len(flat))
check('object is keyed by Id, not name', 'Codeunits/80' in flat)
check('fully qualified namespace is attached',
      flat['Codeunits/80']['namespace'] == 'Microsoft.Sales',
      '(got %r)' % flat['Codeunits/80']['namespace'])
check('EnumTypes is the right collection name', 'EnumTypes/100' in flat)
check('var-ness is part of the signature',
      'var SalesHeader' in flat['Codeunits/80']['members']['OnBeforePostSalesDoc']['signature'])
check('attributes are part of the signature',
      'IntegrationEvent' in flat['Codeunits/80']['members']['OnBeforePostSalesDoc']['signature'])
check('enum ordinal defaults to 0 when absent',
      flat['EnumTypes/100']['members']['Quote']['ordinal'] == 0)

print('\nReading a .app package (NAVX header + zip + BOM)')

# The real symbol packages live under ALGo-App/.alpackages, which is gitignored -
# a CI runner never sees them. So the binary read path is covered by building a
# package here instead: a NAVX-style header followed by a zip, exactly the shape
# read_symbol_reference has to cope with.


def build_app_package(tree, header_size=40, with_bom=True):
    payload = json.dumps(tree).encode('utf-8')
    if with_bom:
        payload = b'\xef\xbb\xbf' + payload

    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, 'w', zipfile.ZIP_DEFLATED) as archive:
        archive.writestr('SymbolReference.json', payload)
        archive.writestr('NavxManifest.xml', '<Package />')

    return bytes(bytearray(range(header_size % 256))[:header_size]) + buffer.getvalue()


def write_temp(data, suffix='.app'):
    handle, path = tempfile.mkstemp(suffix=suffix)
    with os.fdopen(handle, 'wb') as stream:
        stream.write(data)
    return path


package_path = write_temp(build_app_package(base_tree()))
try:
    parsed = ds.read_symbol_reference(package_path)
    check('header is skipped and the zip is opened', parsed.get('Name') == 'Test App')
    check('BOM does not break the JSON parse', parsed.get('Publisher') == 'Microsoft')
    check('objects survive the round trip', len(ds.flatten(parsed)) == 3)
finally:
    os.unlink(package_path)

# A 3-byte header is as valid as a 40-byte one - the reader must search, not assume.
package_path = write_temp(build_app_package(base_tree(), header_size=3, with_bom=False))
try:
    parsed = ds.read_symbol_reference(package_path)
    check('header size is not hard-coded, BOM is optional', len(ds.flatten(parsed)) == 3)
finally:
    os.unlink(package_path)

package_path = write_temp(b'NAVX' + b'\x00' * 200)
try:
    try:
        ds.read_symbol_reference(package_path)
        check('a package with no zip is rejected', False, '(no exception raised)')
    except ValueError as error:
        check('a package with no zip is rejected', 'no zip archive' in str(error))
finally:
    os.unlink(package_path)

buffer = io.BytesIO()
with zipfile.ZipFile(buffer, 'w') as archive:
    archive.writestr('NavxManifest.xml', '<Package />')
package_path = write_temp(b'\x00' * 40 + buffer.getvalue())
try:
    try:
        ds.read_symbol_reference(package_path)
        check('a package without SymbolReference.json is rejected', False, '(no exception raised)')
    except ValueError as error:
        check('a package without SymbolReference.json is rejected',
              'SymbolReference.json not found' in str(error))
finally:
    os.unlink(package_path)

print('\nObject identity')

delta = delta_for(lambda t: t['Namespaces'][0]['Namespaces'][0].__setitem__('Codeunits', []))
check('removed object is reported as removed', len(delta['removedObjects']) == 1)
check('removed object counts as breaking', ds.count_findings(delta)['breaking'] == 1)


def rename(tree):
    sales_post(tree)['Name'] = 'Sales-Post New'


delta = delta_for(rename)
check('rename is a rename, not a removal',
      not delta['removedObjects'] and len(delta['renamedObjects']) == 1)


def move(tree):
    node = tree['Namespaces'][0]['Namespaces'][0]
    moved = node['Codeunits']
    node['Codeunits'] = []
    node['Namespaces'] = [{'Name': 'Document', 'Codeunits': moved}]


delta = delta_for(move)
check('namespace move is a move, not a removal',
      not delta['removedObjects'] and len(delta['movedObjects']) == 1)
check('namespace move is not counted as breaking',
      ds.count_findings(delta)['breaking'] == 0)

print('\nMethod signatures (the case name-only diffing is blind to)')


def append_param(tree):
    sales_post(tree)['Methods'][0]['Parameters'].append(param('IsPreview', 'Boolean'))


delta = delta_for(append_param)
entry = member(changed(delta, 'Codeunits/80'), 'OnBeforePostSalesDoc')
check('appended parameter is detected at all', entry is not None)
check('appended parameter is non-breaking',
      entry and entry['category'] == 'additive' and entry['pureAppend'])


def insert_param(tree):
    sales_post(tree)['Methods'][0]['Parameters'].insert(1, param('IsPreview', 'Boolean'))


entry = member(changed(delta_for(insert_param), 'Codeunits/80'), 'OnBeforePostSalesDoc')
check('parameter inserted in the middle is BREAKING',
      entry and entry['category'] == 'breaking', '(got %r)' % (entry or {}).get('category'))


def flip_var(tree):
    sales_post(tree)['Methods'][0]['Parameters'][1]['IsVar'] = True


entry = member(changed(delta_for(flip_var), 'Codeunits/80'), 'OnBeforePostSalesDoc')
check('value -> var flip is BREAKING',
      entry and entry['category'] == 'breaking', '(got %r)' % (entry or {}).get('category'))


def change_return(tree):
    sales_post(tree)['Methods'][1]['ReturnTypeDefinition'] = {'Name': 'Integer'}


entry = member(changed(delta_for(change_return), 'Codeunits/80'), 'GetTotal')
check('return type change is BREAKING',
      entry and entry['category'] == 'breaking', '(got %r)' % (entry or {}).get('category'))


def demote(tree):
    sales_post(tree)['Methods'][1]['IsInternal'] = True


entry = member(changed(delta_for(demote), 'Codeunits/80'), 'GetTotal')
check('public -> internal is BREAKING',
      entry and entry['category'] == 'breaking', '(got %r)' % (entry or {}).get('category'))


def drop_method(tree):
    sales_post(tree)['Methods'].pop(2)


delta = delta_for(drop_method)
obj = changed(delta, 'Codeunits/80')
check('removed method is reported', obj and len(obj['removedMembers']) == 1)
check('removed method counts as breaking', ds.count_findings(delta)['breaking'] == 1)


def obsolete_method(tree):
    sales_post(tree)['Methods'][1].setdefault('Attributes', []).append(
        {'Name': 'Obsolete', 'Arguments': [{'Value': 'Use GetAmount'}, {'Value': '29.0'}]})


entry = member(changed(delta_for(obsolete_method), 'Codeunits/80'), 'GetTotal')
check('newly obsoleted method is flagged as obsolete, not breaking',
      entry and entry['category'] == 'obsolete', '(got %r)' % (entry or {}).get('category'))

print('\nEnums')


def change_ordinal(tree):
    doc_type(tree)['Values'][1]['Ordinal'] = 5


entry = member(changed(delta_for(change_ordinal), 'EnumTypes/100'), 'Order')
check('enum ordinal change is BREAKING',
      entry and entry['category'] == 'breaking', '(got %r)' % (entry or {}).get('category'))


def drop_extensible(tree):
    doc_type(tree)['Properties'] = [prop('Access', 'Public'), prop('Extensible', '0')]


obj = changed(delta_for(drop_extensible), 'EnumTypes/100')
change = next((c for c in obj['propertyChanges'] if c['property'] == 'Extensible'), None)
check('enum losing Extensible is BREAKING',
      change and change['category'] == 'breaking')

print('\nFields and data behaviour')


def change_calcformula(tree):
    sales_header(tree)['Fields'][1]['Properties'][0] = prop('CalcFormula', 'Sum("Sales Line".Amount WHERE(Type=CONST(Item)))')


entry = member(changed(delta_for(change_calcformula), 'Tables/36'), 'Amount')
check('CalcFormula change is a DATA-behaviour change',
      entry and entry['category'] == 'data', '(got %r)' % (entry or {}).get('category'))


def change_field_type(tree):
    sales_header(tree)['Fields'][0]['TypeDefinition'] = {'Name': 'Code[50]'}


entry = member(changed(delta_for(change_field_type), 'Tables/36'), 'No.')
check('field type change is BREAKING',
      entry and entry['category'] == 'breaking', '(got %r)' % (entry or {}).get('category'))


def obsolete_field(tree):
    sales_header(tree)['Fields'][0]['Properties'].append(prop('ObsoleteState', 'Removed'))


entry = member(changed(delta_for(obsolete_field), 'Tables/36'), 'No.')
check('field ObsoleteState=Removed is BREAKING',
      entry and entry['category'] == 'breaking', '(got %r)' % (entry or {}).get('category'))

print('\nNo-change case')

identical = ds.diff_objects(ds.flatten(base_tree()), ds.flatten(base_tree()))
check('identical trees produce no findings',
      not any(identical[k] for k in identical), '(got %r)' % identical)

print('')
if FAILURES:
    print('%d test(s) FAILED: %s' % (len(FAILURES), ', '.join(FAILURES)))
    sys.exit(1)
print('All tests passed.')

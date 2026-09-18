#!/usr/bin/env python3
"""Tests for diff_symbols.py.

Run with:  python .github/scripts/test_diff_symbols.py

These cover the cases the previous in-workflow implementation got wrong, so a
regression shows up here instead of as a silently empty upgrade report.
"""

import io
import json
import os
import subprocess
import sys
import tempfile
import zipfile

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

print('\nBusiness rollup - namespace to business area')

check('Microsoft.Sales.Document -> Sales', ds.area_of('Microsoft.Sales.Document') == 'Sales')
check('Microsoft.Inventory.Ledger -> Inventory',
      ds.area_of('Microsoft.Inventory.Ledger') == 'Inventory')
check('System.* collapses into Platform', ds.area_of('System.Security.AccessControl') == 'Platform')
check('an empty namespace is Unclassified', ds.area_of('') == 'Unclassified')


def al_index(objects=None, events=None, members=None, files=1):
    """Stand in for a scan of our AL source."""
    return {
        'objects': {name: [{'file': 'Src/X.al', 'line': 10, 'how': 'record'}]
                    for name in (objects or [])},
        'events': {key: [{'file': 'Src/X.al', 'line': 20, 'how': 'subscriber'}]
                   for key in (events or [])},
        'members': {name: [{'file': 'Src/X.al', 'line': 30, 'how': 'member'}]
                    for name in (members or [])},
        'alFiles': files,
    }


def wrap(**delta):
    base = {'removedObjects': [], 'addedObjects': [], 'renamedObjects': [],
            'movedObjects': [], 'changedObjects': []}
    base.update(delta)
    return {'apps': [{'app': 'Microsoft/Base Application', 'oldVersion': '27.0.0.0',
                      'newVersion': '28.0.0.0', 'delta': base}]}


def obj(kind='Tables', name='Sales Header', ns='Microsoft.Sales.Document',
        caption=None, oid=36):
    return {'key': '%s/%s' % (kind, oid), 'kind': kind, 'id': oid, 'name': name,
            'namespace': ns, 'caption': caption}


def changed(props=None, removed_members=None, changed_members=None, **kw):
    entry = obj(**kw)
    entry.update({'propertyChanges': props or [], 'removedMembers': removed_members or [],
                  'addedMembers': [], 'changedMembers': changed_members or []})
    return entry


def only(rollup, severity=None):
    return [f for f in rollup['findings'] if severity is None or f['severity'] == severity]


print('\nBusiness rollup - technical noise is dropped, not explained')

roll = ds.build_rollup(
    wrap(renamedObjects=[{'key': 'Tables/36', 'kind': 'Tables', 'id': 36,
                          'namespace': 'Microsoft.Sales.Document', 'name': 'Sales Hdr',
                          'oldName': 'Sales Header', 'newName': 'Sales Hdr'}],
         movedObjects=[{'key': 'Tables/5900', 'kind': 'Tables', 'id': 5900,
                        'name': 'Service Header', 'namespace': 'Microsoft.Service.Document',
                        'oldNamespace': 'Microsoft.Service',
                        'newNamespace': 'Microsoft.Service.Document'}]),
    al_index(objects=['Sales Header', 'Service Header']), ['Sales'])
check('renames and namespace moves produce no functional finding', not roll['findings'])
check('they are counted as considered-and-dropped',
      roll['suppressedAsTechnical'].get('renamed') == 1
      and roll['suppressedAsTechnical'].get('moved') == 1)
check('a rename/move still counts toward the footprint, under a real area',
      roll['areas']['derivedFromCode'] == ['Sales', 'Service'],
      '(got %r)' % roll['areas']['derivedFromCode'])

roll = ds.build_rollup(
    wrap(changedObjects=[changed(props=[{'property': 'DataCaptionFields', 'old': 'a',
                                         'new': 'b', 'category': 'info'}])]),
    al_index(objects=['Sales Header']), ['Sales'])
check('a purely technical property change is dropped',
      not roll['findings'] and roll['suppressedAsTechnical'].get('technical-property') == 1)

print('\nBusiness rollup - tiering')

removed_page = obj(kind='Pages', name='Sales Order List', caption='Sales Orders', oid=9305)

roll = ds.build_rollup(wrap(removedObjects=[removed_page]),
                       al_index(objects=['Sales Order List']), [])
found = only(roll, 'blocker')
check('tier 1: removal of something our code names is a blocker', len(found) == 1)
check('tier 1: the AL file and line are carried',
      found and found[0]['references'] and found[0]['references'][0]['file'] == 'Src/X.al')
check('tier 1: the area is derived from the code, with nothing declared',
      roll['areas']['derivedFromCode'] == ['Sales'])

roll = ds.build_rollup(wrap(removedObjects=[removed_page]), al_index(), ['Sales'])
check('tier 2: a declared area brings in a removal we do not reference',
      len(only(roll, 'blocker')) == 1)
check('tier 2: it is marked as not used by our app',
      only(roll, 'blocker')[0]['usedByCustomization'] is False)

roll = ds.build_rollup(wrap(removedObjects=[removed_page]), al_index(), ['Finance'])
check('tier 3: out of scope produces no finding, only a count',
      not roll['findings'] and roll['outOfScopeByArea'].get('Sales') == 1)

roll = ds.build_rollup(
    wrap(changedObjects=[changed(kind='Tables', name='VAT Posting Setup',
                                 ns='Microsoft.Finance.VAT', oid=325,
                                 props=[{'property': 'Permissions', 'old': 'r',
                                         'new': 'rm', 'category': 'data'}])]),
    al_index(), ['Finance'])
check('a declared area widens scope where the code has no footprint',
      len(only(roll, 'retest')) == 1 and roll['areas']['declared'] == ['Finance'])

print('\nBusiness rollup - user-visible label and consequence')

roll = ds.build_rollup(
    wrap(changedObjects=[changed(
        caption='Sales Header',
        removed_members=[{'name': 'Technician Name', 'signature': 'Technician Name: Text[50]',
                          'caption': 'Technician'}])]),
    al_index(objects=['Sales Header'], members=['Technician Name']), ['Sales'])
found = only(roll, 'blocker')
check('a removed field is a blocker', len(found) == 1
      and found[0]['consequenceCode'] == 'field-removed')
check('the field Caption is what gets reported',
      found and found[0]['facts']['memberLabel'] == 'Technician')

roll = ds.build_rollup(
    wrap(changedObjects=[changed(changed_members=[
        {'name': 'Amount', 'caption': 'Amount', 'old': 'a', 'new': 'b',
         'category': 'data', 'reasons': ['CalcFormula x -> y']}])]),
    al_index(objects=['Sales Header']), ['Sales'])
found = only(roll, 'retest')
check('a CalcFormula change is re-test, not a blocker',
      len(found) == 1 and found[0]['consequenceCode'] == 'calcformula-changed')

roll = ds.build_rollup(
    wrap(changedObjects=[changed(changed_members=[
        {'name': 'No.', 'caption': 'No.', 'old': 'a', 'new': 'b',
         'category': 'breaking', 'reasons': ['type Code[20] -> Code[50]']}])]),
    al_index(objects=['Sales Header']), ['Sales'])
found = only(roll, 'blocker')
check('a field type change is a blocker',
      len(found) == 1 and found[0]['consequenceCode'] == 'field-type-changed')

roll = ds.build_rollup(
    wrap(changedObjects=[changed(props=[{'property': 'Caption', 'old': 'Sales Order',
                                         'new': 'Sales Document', 'category': 'ui'}])]),
    al_index(objects=['Sales Header']), ['Sales'])
check('a caption change is re-test (documentation and training)',
      len(only(roll, 'retest')) == 1)

print('\nBusiness rollup - methods are shown only where our code uses them')

method_change = {'name': 'OnBeforePostSalesDoc', 'caption': None, 'old': 'a(x)', 'new': 'a(x; y)',
                 'category': 'breaking', 'reasons': ['parameter list changed in place']}

roll = ds.build_rollup(
    wrap(changedObjects=[changed(kind='Codeunits', name='Sales-Post', oid=80,
                                 changed_members=[method_change])]),
    al_index(), ['Sales'])
check('a changed method we do not use is dropped, even in a declared area',
      not roll['findings'] and roll['suppressedAsTechnical'].get('method-not-used') == 1)

roll = ds.build_rollup(
    wrap(changedObjects=[changed(kind='Codeunits', name='Sales-Post', oid=80,
                                 changed_members=[method_change])]),
    al_index(objects=['Sales-Post'], events=[('Sales-Post', 'OnBeforePostSalesDoc')]), ['Sales'])
found = only(roll, 'blocker')
check('a changed integration point we subscribe to is a blocker',
      len(found) == 1 and found[0]['consequenceCode'] == 'integration-point-changed')

print('\nBusiness rollup - additions')

new_page = obj(kind='Pages', name='Reminder Automation Card',
               caption='Reminder Automation', ns='Microsoft.Sales.Reminder', oid=6000)

roll = ds.build_rollup(wrap(addedObjects=[new_page]), al_index(), ['Sales'])
found = only(roll, 'opportunity')
check('a new screen in an area we use is an opportunity',
      len(found) == 1 and found[0]['objectLabel'] == 'Reminder Automation')

roll = ds.build_rollup(wrap(addedObjects=[new_page]), al_index(), ['Finance'])
check('a new screen outside our scope is not reported', not only(roll, 'opportunity'))

roll = ds.build_rollup(
    wrap(addedObjects=[obj(kind='Codeunits', name='Reminder Impl', oid=6001,
                           ns='Microsoft.Sales.Reminder')]),
    al_index(), ['Sales'])
check('a new codeunit is not an opportunity a consultant can act on',
      not roll['findings'])

print('\nBusiness rollup - the markdown fallback renders')

roll = ds.build_rollup(
    wrap(removedObjects=[removed_page],
         addedObjects=[new_page],
         changedObjects=[changed(changed_members=[
             {'name': 'Amount', 'caption': 'Amount', 'old': 'a', 'new': 'b',
              'category': 'data', 'reasons': ['CalcFormula x -> y']}])]),
    al_index(objects=['Sales Header']), ['Sales'])
text = ds.render_rollup_markdown(roll, {'Environment': 'Sandbox'})
check('every severity section is rendered',
      'Must be handled before the upgrade (1)' in text
      and 'Needs re-testing (1)' in text
      and 'New standard capability (1)' in text)
check('the fallback names things by Caption, not by object name',
      'Sales Orders' in text and 'Sales Order List' not in text)

print('\nReport check - the contract a consultant edits is the one enforced')

INSTRUCTION = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                           '..', '..', 'ALGo-App', 'Instructions',
                           'Functional-impact-instruction.md')
INSTRUCTION = os.path.normpath(INSTRUCTION)

check('the functional instruction file exists', os.path.isfile(INSTRUCTION),
      '(looked for %s)' % INSTRUCTION)

if os.path.isfile(INSTRUCTION):
    with open(INSTRUCTION, encoding='utf-8') as handle:
        contract = handle.read()
    banned = ds.parse_fenced_list(contract, 'banned-vocabulary')
    required = ds.parse_fenced_list(contract, 'required-sections')
    check('the banned-vocabulary block is read from the real contract',
          'namespace' in banned and 'ObsoleteState' in banned,
          '(got %r)' % banned)
    check('the required-sections block is read from the real contract',
          len(required) >= 3, '(got %r)' % required)
    # The contract sets the report language. Its required-sections block has to
    # name the headings actually written, or the check warns on every clean run.
    check('required-sections match the headings in the contract\'s own section 5',
          all(heading in contract for heading in required),
          '(not found in section 5: %r)'
          % [h for h in required if h not in contract])
else:
    banned, required = [], []

check('a missing block yields an empty list, not a crash',
      ds.parse_fenced_list('no blocks here', 'banned-vocabulary') == [])


class Args(object):
    def __init__(self, report, instruction, compare_with=''):
        self.report = report
        self.instruction = instruction
        self.compare_with = compare_with


def run_check(report_text, compare_text=None):
    report_path = write_temp(report_text.encode('utf-8'), suffix='.md')
    compare_path = ''
    if compare_text is not None:
        compare_path = write_temp(compare_text.encode('utf-8'), suffix='.md')
    buffer = io.StringIO()
    saved = sys.stdout
    sys.stdout = buffer
    try:
        ds.command_checkreport(Args(report_path, INSTRUCTION, compare_path))
    finally:
        sys.stdout = saved
        os.unlink(report_path)
        if compare_path:
            os.unlink(compare_path)
    return buffer.getvalue()


CLEAN_REPORT = """# Functional impact assessment

## Conclusion
Two items must be handled before the upgrade. Risk level: MEDIUM.

## Must be handled before the upgrade (1)
| # | Business impact | Area | Owner |
| 1 | The "Technician" field on Sales Header has been removed | Sales | Developer |

## Needs re-testing (1)
| # | Process to test | Why | Area | Priority |
| 1 | Create and post a sales order | A calculation changed | Sales | High |

## Scope considered
Sales, Service and Finance were examined.
"""

output = run_check(CLEAN_REPORT)
check('a clean report reports no banned vocabulary',
      'no banned vocabulary found' in output, '(got %r)' % output[-300:])
check('a clean report reports all sections present',
      'all required sections present' in output)

LEAKY = CLEAN_REPORT.replace(
    'The "Technician" field on Sales Header has been removed',
    'The namespace of the codeunit changed and its signature no longer matches')
check('the leak fixture really does differ from the clean one', LEAKY != CLEAN_REPORT)

output = run_check(LEAKY)
check('leaked developer vocabulary is reported',
      '::warning::' in output and 'namespace' in output, '(got %r)' % output[-300:])
check('the leak report gives a line number', 'first at line' in output)

RENAMED_SECTION = CLEAN_REPORT.replace('## Conclusion', '## Summary')
check('the missing-section fixture really does differ from the clean one',
      RENAMED_SECTION != CLEAN_REPORT)

output = run_check(RENAMED_SECTION)
check('a missing required section is reported',
      'missing' in output and 'Conclusion' in output, '(got %r)' % output[-300:])

output = run_check(CLEAN_REPORT, CLEAN_REPORT)
check('a functional report identical to the technical one is reported',
      'looks like a copy' in output, '(got %r)' % output[-400:])

output = run_check(CLEAN_REPORT, '# Technical\n\nSomething entirely different and long enough.\n')
check('two genuinely different reports pass the copy check',
      'looks like a copy' not in output)

output = run_check(CLEAN_REPORT + '\n', None)
check('the copy check is skipped when there is nothing to compare with',
      'overlap with' not in output)

missing_path = os.path.join(os.path.dirname(INSTRUCTION), 'does-not-exist.md')
buffer = io.StringIO()
saved = sys.stdout
sys.stdout = buffer
try:
    code = ds.command_checkreport(Args(missing_path, INSTRUCTION))
finally:
    sys.stdout = saved
check('an unwritten report is a warning, not a failure',
      code == 0 and 'was not written' in buffer.getvalue())

print('\nReport check - non-ASCII output survives a legacy console codepage')

# On Windows, Python writes a redirected stdout in the locale codepage, so
# printing a non-ASCII section name or object caption raised UnicodeEncodeError
# and failed the workflow step. Redirecting stdout to a StringIO inside this
# process cannot catch that, so the real script is run the way the workflow runs
# it, with a legacy codepage forced.
#
# The contract's own language is not what is under test here - it can be
# translated at any time - so this uses a contract with deliberately non-ASCII
# headings. Object captions from a localised Business Central (Écritures,
# Zahlungsavis) reach stdout the same way.
NON_ASCII_CONTRACT = """# Contract

```banned-vocabulary
namespace
```

```required-sections
Kết luận
Écritures comptables
Zahlungsavis prüfen
```
"""

contract_path = write_temp(NON_ASCII_CONTRACT.encode('utf-8'), suffix='.md')
bad_report = write_temp(
    '# Report\n\n## Summary\n\nNothing here matches the contract.\n'.encode('utf-8'),
    suffix='.md')
try:
    environment = dict(os.environ)
    environment['PYTHONIOENCODING'] = 'cp1252'
    environment.pop('GITHUB_OUTPUT', None)
    completed = subprocess.run(
        [sys.executable, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                      'diff_symbols.py'),
         'checkreport', '--report', bad_report, '--instruction', contract_path],
        env=environment, capture_output=True, text=True, encoding='utf-8', errors='replace')
    check('non-ASCII section names do not crash on a cp1252 stdout',
          completed.returncode == 0,
          '(exit %s, stderr tail: %r)' % (completed.returncode, completed.stderr[-300:]))
    check('the missing-section warning is still emitted',
          'missing' in completed.stdout,
          '(stdout: %r)' % completed.stdout[-300:])
finally:
    os.unlink(bad_report)
    os.unlink(contract_path)

print('')
if FAILURES:
    print('%d test(s) FAILED: %s' % (len(FAILURES), ', '.join(FAILURES)))
    sys.exit(1)
print('All tests passed.')

# Prompt: Functional impact of a Business Central upgrade

This file is the **format contract for the functional-consultant report**. It is the
counterpart of `Compare-instruction.md`, which is the contract for the technical report.
A functional consultant owns this file: change the wording, the order, the severity
labels or the output language here, and the workflow follows — no YAML edit needed.

**Output language: English.** To switch, change this line, the wording table in section 4,
and the section headings in the `required-sections` block below so the mechanical check
looks for the headings you actually write. Nothing else depends on it.

---

## 1. Who reads this

A functional consultant preparing an upgrade. They decide:

- which business processes must be re-tested before the upgrade is accepted (UAT scope),
- where numbers or behaviour may change silently,
- what to tell the client and the key users,
- whether a customization can be retired because the standard product now covers it.

They do **not** decide whether the code compiles. That is the technical report's job.

## 2. Input

`business-impact.json`, produced by `.github/scripts/diff_symbols.py rollup`. It is
already filtered and tiered — do not go looking for more findings in the raw symbol
diff, and do not re-derive severity from scratch.

Each finding carries:

| Field | Meaning |
|---|---|
| `severity` | `blocker` / `retest` / `opportunity` |
| `consequenceCode` | what kind of change it is — see the wording table in section 4 |
| `area` | business area, e.g. `Sales`, `Service`, `Finance` |
| `objectLabel` | **the name the user sees on screen** — use this, never `objectName` |
| `objectSurface` | `screen` / `report` / `data` / `choice-list` / `permissions` / `role-centre` |
| `facts` | the concrete before/after, including `memberLabel` for a field |
| `usedByCustomization` | true when our own AL code names it |
| `references` | AL file and line, when it is used by our code |

Also present: `areas` (scope), `customizationFootprint`, `outOfScopeByArea` (counts only),
`suppressedAsTechnical`, `coverageGaps`, `counts`.

The rollup already dropped renames, namespace moves, internal visibility changes and
attribute churn. Do not reintroduce them.

## 3. WRITING RULES

- Write for someone who knows Business Central as a product, not as a codebase.
- Name everything by `objectLabel` and `facts.memberLabel` — what appears on the screen.
- Every row must answer "what changes for the user or for the data", not "what changed
  in the symbols".
- State the business consequence before the cause.
- **Banned vocabulary.** The list below is the single source of truth: the workflow greps
  the finished report for these words and reports a leak as a defect. Edit the list here
  and the check follows. Where a technical fact genuinely matters, name the consequence
  and hand it to the developer — see `integration-point-changed` in the wording table.

<!-- banned-vocabulary: parsed by `diff_symbols.py checkreport`. One term per line. -->
```banned-vocabulary
signature
namespace
ordinal
var parameter
codeunit
object id
IntegrationEvent
EventSubscriber
ObsoleteState
SymbolReference
pure append
breaking change
```

<!-- required-sections: parsed by `diff_symbols.py checkreport`. One heading fragment per
     line. These must match the headings in section 5 - if you translate the report,
     translate these too. -->
```required-sections
Conclusion
Must be handled before the upgrade
Needs re-testing
Scope considered
```

- Quantities: always give the count next to a heading, so the reader can judge size
  before reading.
- Never invent a finding. If `business-impact.json` does not contain it, it does not
  go in the report.
- Never present the report as complete coverage when `coverageGaps` is non-empty.

## 4. Wording table — `consequenceCode` to a sentence

Use these as the pattern; adapt the grammar, keep the meaning. `{label}` is
`objectLabel`, `{member}` is `facts.memberLabel`, `{old}` and `{new}` come from `facts`.

| `consequenceCode` | Sentence |
|---|---|
| `object-removed` | Microsoft has removed {label}. Users will no longer find it where it used to be. |
| `object-obsoleted` | {label} has been marked for removal by Microsoft and will disappear in a later release. |
| `field-removed` | The "{member}" field on {label} has been removed by Microsoft. Data and functionality that rely on it will stop working. |
| `field-obsoleted` | The "{member}" field on {label} is being retired. It needs to be replaced before it disappears. |
| `field-type-changed` | The data type of "{member}" on {label} has changed. Existing data may no longer be valid or may display incorrectly. |
| `calcformula-changed` | How "{member}" on {label} is calculated has changed. **Figures may differ from before even though nobody changed anything.** |
| `tablerelation-changed` | The data relationship behind "{member}" on {label} has changed. Lookups and validation may behave differently. |
| `permissions-changed` | Data access when using {label} has changed. Some users may gain or lose access. |
| `dataclassification-changed` | The data classification of {label} has changed. This can affect compliance reporting and how personal data is handled. |
| `data-scope-changed` | The data scope of {label} has changed (per-company or replication). Re-check this in a multi-company environment. |
| `screen-behaviour-changed` | How {label} behaves has changed (whether records can be edited, added or deleted, or which data it shows). |
| `caption-changed` | The on-screen label changed from "{old}" to "{new}". User documentation and training material need updating. |
| `enum-value-removed` | The "{member}" option on {label} has been removed. Existing records using that option will no longer be valid. |
| `enum-ordinal-changed` | The options behind {label} have been renumbered. Existing data may display the wrong value. |
| `enum-not-extensible` | {label} can no longer be extended. Any custom options added to it will stop working. |
| `access-restricted` | Microsoft has restricted access to {label}. The customization that uses it has to be rewritten. |
| `integration-point-changed` | The integration point the customization relies on in {label} has changed. **A developer must fix this before the upgrade**, otherwise the related functionality will stop running. |
| `method-removed-used` | An internal function the customization calls on {label} has been removed. A developer must replace it before the upgrade. |
| `object-added` | New capability: {label}. |
| `enum-value-added` | {label} has a new option: "{member}". |

## 5. Output structure

Write exactly these sections, in this order. **Omit a section that has no data** — do
not write "nothing here".

```
# Functional impact assessment — upgrade of <environment>
<currentVersion> → <targetVersion> · <date> · coverage: <n>/<n> packages

## Conclusion
Three to five sentences. How many items must be handled first, how many processes need
re-testing, the risk level (LOW / MEDIUM / HIGH) and why. No detail here.

## 🔴 Must be handled before the upgrade  (n)
| # | Business impact | Area | Owner |
One row per finding with severity=blocker. "Owner" is the consultant, a developer, or
both — derive it from usedByCustomization: where the customization uses it, a developer
is needed.
Sort: usedByCustomization=true first, then by area.

## 🟠 Needs re-testing — UAT list  (n)
| # | Process to test | Why | Area | Priority |
This is the table the consultant copies into a test plan, so "Process to test" must be a
concrete business action ("Create and post a sales order", "Print a posted sales
invoice"), not an object name. Merge findings that belong to the same process into one
row.
Priority: High where the customization is involved or where a calculation changed,
Medium otherwise.

## 🟢 Opportunities to retire customization  (n)
| New standard capability | Could replace | Notes |
Only include a row when you can actually see the corresponding customization in
ALGo-App/. If it is merely a new feature with no clear replacement, leave it out rather
than guessing.

## 🔍 Areas that could NOT be checked  (n)
| Package | Why | Residual risk |
Taken from coverageGaps. Mandatory whenever coverageGaps is non-empty.

## Scope considered
A short paragraph: which business areas were examined (areas.effective), which of those
came from the customization and which were declared by the team. Give the number of
changes in areas outside that scope (outOfScopeByArea) as a single total, and say plainly
that those were not assessed.
```

## 6. SELF-CHECK before answering

1. No term from the banned-vocabulary block in section 3 appears in the report.
2. Every object is named by `objectLabel`, not `objectName`.
3. The count in each section heading matches the number of rows in its table.
4. Every row in the UAT table is a business action, not an object name.
5. Where `coverageGaps` is non-empty, the 🔍 section is present.
6. No finding appears that is not in `business-impact.json`.
7. The conclusion gives a risk level and the reason for it, not just a restatement of the
   numbers.

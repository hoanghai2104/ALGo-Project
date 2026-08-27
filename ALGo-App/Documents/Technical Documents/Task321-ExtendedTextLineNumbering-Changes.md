# Task 321 – Extended Text Line Numbering Changes (Specification)

Related GitHub issue(s): #321
Implementation notes: [[Task321-ExtendedTextLineNumbering-Changes]]

## Goal
This task addresses the deviation in line numbering for extended text lines in the SoumissionLine table. The changes involve refactoring how line numbers are calculated when inserting extended text lines, to ensure proper incrementing logic that accounts for existing lines and avoids conflicts.

## Design
The changes modify the line numbering logic in the SoumissionLine table to prevent conflicts when inserting extended text lines. The approach uses a dynamic step calculation based on existing line numbers rather than fixed increments.

## Affected Objects
| Object | Type | ID | Change |
|---|---|---|---|
| SoumissionLine | Table | 50103 | New procedure "ProcessItemExtText", modified "InsertItemExtText" logic |
| SalesQuote | PageExt | 50113 | Changed line number increment from 10 to 10000, setIsHandledExtItem(false), Insert(true) |

## Line Numbering Logic Explanation

The changes implement a dynamic line numbering system for extended text lines to prevent conflicts:

### Commit-by-Commit Logic

1. **Initial Commit (e02d0ea)** - The Fix:
   - Changed line increment from 10 to 10000 in SalesQuote page extension
   - Changed setIsHandledExtItem to false
   - Changed Insert() to Insert(true)

2. **Refactor Commit (9b2cd35)** - Simplification:
   - Simplified line number calculation from complex logic to `LineNo := Rec."Line No"`
   - Changed increment from 10000 to 10000 for each extended text line

3. **Adjustment Commit (ec36bf9)** - Dynamic Step Calculation:
   - Introduced dynamic step calculation based on existing line numbers
   - Calculates step as `(next_line - current_line) / 100`
   - Ensures step is at least 1 to prevent conflicts

### Final Logic Flow

1. **Start with current line number**: `LineNo := Rec."Line No"`
2. **Calculate optimal step size**:
   - Find the first existing line number greater than current line
   - Calculate step as `(next_line - current_line) / 100`
   - Ensure step is at least 1
3. **Insert extended text lines with calculated step**: `LineNo += step`

### Benefits of This Approach

- **Prevents Conflicts**: Calculates step based on existing lines to avoid overlapping line numbers
- **Maintains Readability**: Each extended text line gets reasonable increment spacing
- **Handles Edge Cases**: Works with gaps in line numbering or no existing lines
- **Scalable**: Adapts to current table state

---
description: Audit DAX measures for WTW naming conventions, performance anti-patterns, and correctness
argument-hint: [optional file path, measure name, or paste DAX inline]
---

You are running a **WTW DAX Quality Review**.

**Load `references/dax-patterns.md` first** — it is the authoritative spec for naming, performance, WTW thresholds, and standard patterns.

## Scope

- If `$ARGUMENTS` is a file path, review all measures in that file.
- If `$ARGUMENTS` is a measure name, ask for the DAX to review.
- If the user pasted DAX inline, review that.
- Otherwise, review the code currently open in the IDE (`<ide_selection>`).

## Checks

Run all that apply. Mark each ✓ (pass), ✗ (fail), or — (not applicable).

### Naming
1. Measure names: `[Title Case]` — e.g. `[Sales YTD]`, `[Variance vs Target]`
2. DAX variables: `_camelCase` prefix — e.g. `_currentSales`, `_targetValue`
3. Calculated columns: `Title Case` without brackets
4. No abbreviations beyond standard WTW set (YTD, QTD, MTD, YoY, MoM, vs, %)

### Safety
5. All division uses `DIVIDE(numerator, denominator, 0)` — never the `/` operator
6. Measures that can return BLANK have explicit handling (`IF(ISBLANK(...), 0, ...)` or deliberate `RETURN BLANK()`)
7. No hardcoded year or date literals — use `TODAY()`, `MAX(Dim_Date[Date])`, or a variable

### Performance
8. No `FILTER(TableName, ...)` inside CALCULATE where a column filter or `KEEPFILTERS` would do
9. `SUMX` / `COUNTX` / `AVERAGEX` used only when row-by-row context is required — prefer `SUM`, `COUNT`, `AVERAGE` for simple aggregation
10. No nested CALCULATE where a single CALCULATE with multiple filters suffices
11. Variables used to avoid re-evaluating the same expression more than once

### WTW Patterns
12. Performance level detection uses the correct five thresholds: ≥115% → Outstanding, ≥100% → Met, ≥90% → Near, ≥80% → Below, <80% → Critical
13. Performance color hex codes match exactly: Outstanding `#16A34A`, Met `#22C55E`, Near `#F59E0B`, Below `#EF4444`, Critical `#DC2626`
14. WTW Corporate Purple used for brand accents: `#7F35B2` — not `#7C3AED` or any approximation
15. Time intelligence uses `Dim_Date[Date]` as the date column — not a fact table date column

## Output

```
## DAX Review — <measure name or file>

### Summary
✓ N passing  ✗ N failing  — N not applicable

### Findings
| Check | Result | Detail |
|-------|--------|--------|
| Naming — variables | ✗ | `_CurrentValue` should be `_currentValue` (camelCase) |
| Safety — DIVIDE | ✓ | |
| Performance — SUMX | ✗ | Line 14: `SUMX(fact_transactions, ...)` — no row context needed, use SUM |
...

### Recommended fixes
[List each fix with the exact before/after DAX line]
```

Be specific — quote the exact variable or expression that fails. Do not modify any files unless the user asks.

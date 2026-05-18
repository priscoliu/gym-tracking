---
description: Run all five WTW review commands in a single pass — color, typography, structure, accessibility, and DAX
argument-hint: [file path or 'all']
---

You are running a **WTW Full Report Audit** — all review commands in one pass.

## Scope

- If `$ARGUMENTS` is a file path, audit that file.
- If `$ARGUMENTS` is `all`, audit every changed file in the working tree (`git diff`).
- Otherwise, audit the file open in the IDE (`<ide_selection>`). Ask if ambiguous.

## Execution

Run the five reviews. Where checks are independent, run them in parallel to be fast.

1. Load and follow `commands/color-review.md` — full color audit
2. Load and follow `commands/typography-review.md` — full typography audit
3. Load and follow `commands/structure-review.md` — full structure audit
4. Load and follow `commands/accessibility-review.md` — full accessibility audit
5. Load and follow `commands/dax-review.md` — full DAX quality audit (skip if target has no DAX)

## Output

Return a single consolidated report. Lead with critical blockers before the per-section breakdown.

```
## WTW Full Audit — <file path>
Reviewed: <timestamp>

---
### Critical blockers (fix before publish)
- [Section] [Issue] — [location]

---
### Color          [PASS / N issues]
[findings, or "All checks passed"]

### Typography     [PASS / N issues]
[findings, or "All checks passed"]

### Structure      [PASS / N issues]
[findings, or "All checks passed"]

### Accessibility  [PASS / N issues]
[findings, or "All checks passed"]

### DAX Quality    [PASS / N issues / SKIPPED]
[findings, or "All checks passed"]

---
Summary: Critical N  |  Warnings N  |  Clean N
```

Do not modify any files. If the user wants fixes applied, direct them to `/wtw-powerbi:brand-color-fix` for color, or ask which findings to address.

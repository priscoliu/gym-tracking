---
description: Audit typography (fonts, sizes, weights, hierarchy) against WTW brand spec
argument-hint: [optional file path]
---

You are running a **WTW Typography Review** against the authoritative design system at:
`C:\Users\LiuPr\.claude\skills\wtw-powerbi\references\wtw-brand-design-system.md`

**Load that file first**. Section 9 (Typography) is the spec.

## Scope

- If `$ARGUMENTS` is a file path, review it. Otherwise review the file open in the IDE.
- Applies to HTML cards (DAX-generated), CSS, and any embedded fonts in measure expressions.

## Checks

1. **Font family** — every HTML card must use `font-family: 'Segoe UI', sans-serif;`. Graphik is print-only and not available in Power BI. Flag anything else (Inter, Roboto, system-ui as primary, etc.).
2. **Live text minimum size** — 16px. Flag any `font-size` below 16px on body/data text (axis/legend labels may be 11–14px per spec).
3. **Embedded text minimum** — 18px when text is part of an image/SVG that won't be selectable.
4. **Title hierarchy** — chart title is Semibold 24px/32px in GM-900 (`#171718`); subtitle is Regular 18px/24px in GM-700 (`#414244`). Flag deviations.
5. **Caption / source / copyright** — caption 14px/20px GM-900; source/copyright 12px/16px GM-700.
6. **Weight rule** — body Regular (400), titles Semibold (600), KPI hero values Bold (700). Flag heavy weights used on body text.
7. **All-caps in source** — labels written as `CROSS-SELL RATE` directly in the markup. Should be sentence case in source + `text-transform: uppercase` in CSS. (Better for screen readers and easier to change.)
8. **Text on busy backgrounds** — flag any text positioned over chart grid lines, multi-color bars, or other patterned regions without a solid backing.
9. **Rotated text** — flag any `transform: rotate()` greater than 0deg on label text. WTW spec: keep text horizontal where possible.

## Output

```
## Typography Review — <file path>

### Summary
✓ Passing | ✗ Failing | ⚠ Worth fixing

### Findings
| Location | Element | Found | Issue | Suggested fix |
|----------|---------|-------|-------|----------------|

### Hierarchy check
...

### Suggestions for accessibility
...
```

Quote line numbers. Reference the design system section for each finding. Do not modify files.

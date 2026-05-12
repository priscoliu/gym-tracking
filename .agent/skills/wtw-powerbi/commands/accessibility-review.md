---
description: WCAG AA accessibility audit against WTW design system + Power BI a11y rules
argument-hint: [optional file path]
---

You are running a **WTW Accessibility Review** (WCAG AA) against the authoritative design system at:
`C:\Users\LiuPr\.claude\skills\wtw-powerbi\references\wtw-brand-design-system.md`

**Load that file first**. Section 10 (Accessibility) is the spec.

## Scope

- If `$ARGUMENTS` is a file path, review it. Otherwise review the file open in the IDE.
- Be **honest about what this audit can and cannot reach**:
  - **Can audit (HTML/DAX cards)**: contrast, color-only meaning, text size/orientation, text obscured, semantic HTML, missing alt-text in HTML viewer cards.
  - **Cannot audit from code**: native Power BI visual aria-labels, tab focus rings, bookmark button keyboard state — these live in Power BI's accessibility pane, not in DAX. Flag them as findings but mark them `[Power BI a11y pane — fix outside code]`.

## Checks

### Contrast

1. **Text on color fills** — every text/background pair must meet 4.5:1 (normal text) or 3:1 (large text ≥18pt or ≥14pt bold). Reference: WTW Ultraviolet 500+ for text on white, GM-400+ for graphic objects.
2. **Graphic objects** — bars, lines, dots, icons need 3:1 against their background.
3. **Adjacent colored shapes** — if more than 3 solid colors touch each other (including background), check whether outlines are used to separate them.

### Color-not-alone

4. Wherever color signals meaning (status, performance, category):
   - Is there a paired **text label**, **icon**, or **shape**?
   - Flag: red/green only; light/dark only; purple density only.

### Text accessibility

5. **Live text ≥16px** (the actual rendered HTML text).
6. **Embedded text ≥18px** (text inside an image/SVG).
7. **Text horizontal** wherever possible; flag rotated axis labels >0deg.
8. **Text not obscured** — not placed over grid lines, busy color regions, or competing data points without a solid backing.

### Semantic HTML (for HTML cards)

9. **Tables use `<table>`** with `<th scope="col">` and `<th scope="row">` — not `<div>` grids.
10. **Lists use `<ul>` / `<ol>`** — not `<div>` rows.
11. **Headings use `<h1>`–`<h6>`** — not styled `<div>` text.
12. **Legends with meaning** — if a legend uses color swatches, include value ranges in text ("Low (0–25%) → High (75–100%)"), not just swatches.

### Complex visualizations

13. If the chart has 4+ overlapping categories, does it offer:
    - Direct data labels (preferred over legend)?
    - **Patterns/textures** in addition to color?
    - **Different line types** for line charts?
    - **Markers** at data points?
    - A **data table fallback** or **tooltips** to expose values?

### Power BI native visuals (out of code scope)

14. Native bar/column/line charts — note that aria-labels, alt text, and tab focus must be set in Power BI's accessibility pane (visual properties → General → Alt text). Flag them with `[Power BI a11y pane]` so the user knows where to fix.

## Output

```
## Accessibility Review — <file path>

### WCAG AA Pass/Fail Summary
- Contrast: ✓ / ✗
- Color-not-alone: ✓ / ✗
- Text size: ✓ / ✗
- Semantic HTML: ✓ / ✗

### Findings (in DAX/HTML — fixable in code)
| Location | WCAG ref | Issue | Suggested fix |

### Findings (Power BI a11y pane — fix outside code)
| Visual | Issue | Where to fix |

### Worth fixing | Out of scope
Recommendation on what to tackle first; what to skip in this Power BI report context.
```

Be **practical** about ROI — for an internal Power BI report (vs public web app), not every WCAG finding has equal value. Mark findings as **must-fix** / **worth-fixing** / **low ROI**. Do not modify files.

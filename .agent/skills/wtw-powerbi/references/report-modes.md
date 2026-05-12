# WTW Report Modes

Pick one mode before opening Power BI Desktop. The mode sets canvas size, density, colour emphasis, font scale, and page structure. All other design decisions flow from this choice.

---

## Mode 1 — Executive

**When to use**: C-suite audience, single most-important number, screen share or TV display, 30-second decision support.

| Setting | Value |
|---------|-------|
| **Canvas** | 1280 × 720px |
| **Visuals per page** | ≤ 6 |
| **Font scale** | Large — `display-xl` (54px) for hero KPI, `display-sm` (24px) for secondaries |
| **Colour emphasis** | WTW Purple dominant — purple hero card, white/grey secondary cards |
| **Data density** | Low — one chart max per page, generous whitespace |

**Page structure**:
```
┌──────────────────────────────────────────────────────────────┐
│  HERO KPI CARD (full-width or 8-col)   │  CONTEXT TEXT       │
├──────────────────────────────────────────────────────────────┤
│  TREND CHART (8-col)                  │  2 × KPI CARDS (4-col)│
└──────────────────────────────────────────────────────────────┘
```

**Style rules**:
- Purple gradient header card occupies top-left hero position
- At most one slicer (date range) — position top-right or in filter panel
- No axis labels if data labels are on
- No legends if only one series
- Shadow: glow effect — set shadow colour to `#7F35B2` at 30% opacity on the purple hero card

---

## Mode 2 — Operational

**When to use**: Analyst or operational team, daily monitoring, many metrics, embedded in Teams or Power BI Service, drill-down expected.

| Setting | Value |
|---------|-------|
| **Canvas** | 1440 × 1080px |
| **Visuals per page** | 8–15 |
| **Font scale** | Medium-small — `display-sm` (24px) for KPIs, `text-sm` (14px) for table text |
| **Colour emphasis** | Neutral base — performance colours (green/cyan/amber/red) drive attention |
| **Data density** | High — dense tables, sparklines, multiple charts |

**Page structure**:
```
┌─────────────────────────────────────────────────────────────────────┐
│  FILTER PANEL (full-width, collapsible)                             │
├─────────────────────────────────────────────────────────────────────┤
│  KPI STRIP (4–6 KPIs across full width)                             │
├───────────────────────────────┬─────────────────────────────────────┤
│  TABLE / MATRIX (7-col)       │  CHART (5-col)                      │
│                               │  CHART (5-col)                      │
└───────────────────────────────┴─────────────────────────────────────┘
```

**Style rules**:
- WTW Purple used as accent only (header bar, selected row highlight, outstanding badge)
- Table alternating rows: `#FFFFFF` / `#F9FAFB`
- Performance colour badges on every achievement column
- Slicers: chip-style, horizontal layout, top of page
- Progress bars optional — use only where target tracking is the primary story

---

## Mode 3 — Presentation

**When to use**: Slides-style report for stakeholder meetings, printed output, or embedded in PowerPoint via live embed. One story per page.

| Setting | Value |
|---------|-------|
| **Canvas** | 1280 × 720px |
| **Visuals per page** | ≤ 4 |
| **Font scale** | Medium-large — `display-md` (30px) for section values, `display-lg` (36px) for page title |
| **Colour emphasis** | Purple headers + white cards — alternates page-by-page for rhythm |
| **Data density** | Medium — one key insight per page, supporting context beneath |

**Page structure**:
```
┌──────────────────────────────────────────────────────────────┐
│  PURPLE HEADER BAR (full-width, 80px tall)                   │
│  Page title (36px white) + page number                       │
├──────────────────────────────────────────────────────────────┤
│  MAIN VISUAL (full-width or 8-col)                           │
├──────────────────────────────────────────────────────────────┤
│  SUPPORTING KPI (4-col) │ SUPPORTING KPI (4-col) │ CONTEXT   │
└──────────────────────────────────────────────────────────────┘
```

**Style rules**:
- Purple header bar spans full canvas width, contains title + subtitle in white
- One chart dominates; supporting KPIs are secondary and smaller
- Avoid slicers on presentation pages — apply filters at report level instead
- Use modal pop-up pattern (see [design-standards.md](design-standards.md)) for methodology notes instead of footnotes on the canvas
- No gridlines, no axis titles

---

## Mode Selection Checklist

| Question | → Executive | → Operational | → Presentation |
|----------|-------------|---------------|----------------|
| Audience | C-suite | Analyst / Ops team | Mixed stakeholder group |
| Consumption | TV / screen share | Embedded / desktop | Meeting / print / embed in PPT |
| Metric count | 1–3 hero metrics | Many metrics + drill-down | 1 key insight per slide |
| Interaction expected? | Minimal | Heavy filtering + drill | None / light |
| Print/export needed? | No | No | Yes |

---

## Applying a Mode

Once the mode is chosen:

1. Set canvas size in **View → Page view → Custom** (or report settings)
2. Apply the matching grid from [design-standards.md](design-standards.md)
3. Use colours from [color-system.md](color-system.md) with the mode's emphasis rules
4. Reference spacing tokens from [tokens.md](tokens.md)

---
description: Scaffold a new WTW-branded Power BI report page — interactive setup that returns layout spec and starter measures
argument-hint: [optional: 'executive' | 'operational' | 'presentation']
---

You are running a **WTW Report Scaffold** — interactive setup for a new report page.

**Load these files first** before asking the user anything:
- `references/report-modes.md` — canvas sizes, density, font scale per mode
- `references/design-values.md` — spacing tokens, color variables
- `references/color-system.md` — Corporate vs Indigo palette decision

## Step 1 — Gather requirements

If `$ARGUMENTS` names a mode (`executive`, `operational`, `presentation`), skip to Step 2.

Otherwise ask the user (one message, all questions together):

1. **Report mode** — Executive (C-suite, ≤6 visuals, 1280×720) / Operational (analyst team, 8–15 visuals, 1440×1080) / Presentation (story-per-page, ≤4 visuals, 1280×720)?
2. **Domain / audience** — who will use this page and what decision does it support?
3. **Primary palette** — Corporate (WTW Purple, external/executive) or Indigo (CRM/Sales ops)?
4. **KPI strip** — how many top-line KPI cards across the top? (3 / 4 / 5 / none)
5. **Key measures available** — list any measures already in the model that should appear on this page.

## Step 2 — Generate scaffold

Based on the chosen mode from `references/report-modes.md`, output:

### A. Page spec (plain English, easy to follow in Power BI Desktop)

```
Page: <name>
Canvas: <W>×<H>px
Mode: <mode>
Palette: <Corporate | Indigo>

Layout zones:
  [Header]    H: 60px  — page title + subtitle + date slicer
  [KPI strip] H: 120px — N cards, equal width, ~<W/N>px each
  [Body]      H: remaining — <describe zones based on mode>
  [Footer]    H: 40px  — source line + last-refreshed stamp

Margins: 60px left/right  Gutter: 16px between cards
```

### B. Starter measure list

List the measures to create first, in order, before building visuals:

| Priority | Measure name | Pattern to use | Notes |
|----------|-------------|----------------|-------|
| 1 | [e.g. Sales YTD] | YTD from dax-patterns.md | Base measure |
| 2 | [e.g. Sales vs Target %] | vs Target | Drives color logic |
| 3 | [e.g. Performance Color] | Performance detection | For KPI card fill |

### C. Asset recommendation

Name the closest existing card template from `assets/cards/` that matches the page purpose. If none fits, suggest starting from `assets/wtw-card-template.html`.

### D. Pre-flight checklist

Before building any visual, confirm:
- [ ] Canvas size set in Power BI Desktop → View → Page size
- [ ] `Dim_Date` table present in the model
- [ ] Base measure (`[Sales Total]` or equivalent) exists and is tested
- [ ] Palette variable block copied from `references/color-system.md` — Corporate or Indigo

---

Do not generate full DAX until the user confirms the scaffold. Then offer to build the starter measures one at a time.

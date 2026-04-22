---
name: wtw-powerbi
description: WTW-branded Power BI design system for professional reports. Use when creating or reviewing Power BI reports, HTML card components (DAX-generated), KPI scorecards, performance measures, DAX patterns (YTD, YoY, vs Target, color coding), Power Query M code for Fabric Lakehouse connections, semantic model design (star schema, Dim_Date), or any WTW-branded visual layout (purple color system, grid, typography, shadows, dark mode). Also use when building a WTW design system or applying brand guidelines to any report or dashboard.
---

# WTW Power BI Design System

Professional design system for WTW-branded Power BI reports. Prioritise clarity, brand consistency, and performance-based visual feedback.

## WTW Brand Philosophy

WTW reports should communicate authority and precision. Every visual choice earns its place — no decoration for its own sake. The WTW purple signals performance excellence; other colors communicate health. Dense data is made readable through hierarchy, not simplification. Reports should feel like tools, not slideshows.

**Guard against generic AI aesthetics**: Avoid centered layouts with purple gradient banners, uniform rounded corners on everything, Inter/Roboto fonts, and KPI cards that show a single number with no comparison context.

## Brand Essentials

- **Primary color**: WTW Corporate Purple `#7F35B2`
- **Canvas**: `1280×720px` (presentations) or `1440×1080px` (complex reports)
- **Grid**: 12-column, 60–80px side margins
- **Font**: Segoe UI — Regular (400) for body, Semibold (600) for titles, Bold (700) for KPI values

Full design values reference: [references/design-values.md](references/design-values.md)

## Reference Guides

### Design Values

- **All values in one place**: See [references/design-values.md](references/design-values.md)
  - CSS variables, color palette, spacing scale, typography, shadows, border radii

### Color System

- **Two palettes available**: Corporate (WTW Purple `#7F35B2`) and Indigo (`#4f46e5`) — see [references/color-system.md](references/color-system.md) for full palette definitions and DAX blocks.
- **Default**: Corporate palette for brand-aligned reports; Indigo for operational dashboards and leaderboards.
- **CRITICAL**: Whenever you are triggered to review or apply anything related to **color**, you MUST FIRST ask the user which palette they want: Corporate or Indigo.
- **Complete palette**: See [references/color-system.md](references/color-system.md)
  - Performance color thresholds (115% / 100% / 90% / 80%)
  - Gradient definitions, neutral text hierarchy
  - Dark mode / dark canvas palette
  - Accessibility (WCAG AA pre-validated combinations)

### Report Modes
- **Pick a mode first**: See [references/report-modes.md](references/report-modes.md)
  - Executive (1280×720, ≤6 visuals, purple dominant, large font scale)
  - Operational (1440×1080, 8–15 visuals, performance colours, dense tables)
  - Presentation (1280×720, ≤4 visuals, purple header bars, one story per page)

### Design Standards
- **Layout & Spacing Systems**: See [references/design-standards.md](references/design-standards.md)
  - **CRITICAL**: When asked to review or apply Spacing, Borders, & Shadows, **ALWAYS ASK** the user which style they prefer:
    - **Corporate**: Strict 16px padding, 8px outer radius, tight (4px/8px) base spacing. Shadows use strict multi-layered elevation (`box-shadow: 0 2px 4px rgba(0,0,0,0.02), 0 8px 16px rgba(0,0,0,0.04), 0 24px 32px rgba(0,0,0,0.06);`).
    - **Modern**: Breathable 32px padding, 20px border radius, generous gaps (24px). Shadows use soft ambient depth (`box-shadow: 0 20px 40px -8px rgba(0,0,0,0.08);`).
  - 12-column grid calculations, standard card widths
  - Modal pop-up pattern, minimize redundancy rules

### DAX Patterns
- **Measures & logic**: See [references/dax-patterns.md](references/dax-patterns.md)
  - Performance detection, color mapping, gradient variables
  - YTD, QTD, MTD, YoY, MoM, vs Target measures
  - Status badges, dynamic titles, number formatting
  - DAX optimisation best practices

### HTML Card Workflow

- **CRITICAL — follow this before building any card**: See [references/html-card-workflow.md](references/html-card-workflow.md)
  - Step 1: Choose palette (Corporate or Indigo)
  - Step 2: Paste the full DAX variable block (exact shadow/color tokens)
  - Step 3: Choose layout mode (fixed size vs auto-scale)
  - Steps 4–7: KPI font sizes, shadow values, number formatting, CSS strategy
  - Step 8: Final verification checklist (12 items)

### HTML Cards
- **DAX-generated components**: See [references/html-cards.md](references/html-cards.md)
  - Container structure, grid layouts (2/3/4-column)
  - Progress bars with benchmark lines, status badges
  - Summary panels, typography patterns
  - Complete Executive Summary Card example
  - **Catalogue patterns**: Tile with values breakdown, cluster bar chart, two-zone layout, performance-tinted insight panel, sticky matrix with JS pagination

### Components
- **Extended UI library**: See [references/components.md](references/components.md)
  - Page headers, navigation bars, filter panels
  - Data tables, alert banners, loading skeletons, tooltips

### Interactions & Animation
- **Motion patterns**: See [references/interactions.md](references/interactions.md)
  - CSS transitions, hover states
  - Progress bar animations, loading states
  - Micro-interactions for HTML cards

### Data Modeling
- **Semantic model design**: See [references/data-modeling.md](references/data-modeling.md)
  - Star schema decision tree, fact/dimension patterns
  - Dim_Date calendar template (Australian FY)
  - Role-playing dimensions, multi-fact relationships
  - Rollup row handling, validation checklist

### Power Query (M Code)
- **Lakehouse connection patterns**: See [references/power-query.md](references/power-query.md)
  - Lakehouse connection boilerplate, column operations
  - Type casting, currency cleaning, null handling
  - Filtering, unpivoting, standard fact table recipe

## Assets

All asset files are ready-to-use DAX measures or HTML scaffolds. Copy the content directly into Power BI Desktop.

### HTML Scaffolds

| File | Description |
|------|-------------|
| `assets/wtw-card-template.html` | Standalone HTML scaffold with all WTW design values pre-wired (use for browser preview/prototyping) |

### Card Templates (`assets/cards/`)

| File | Description | Key patterns |
|------|-------------|--------------|
| `pipeline-health-scorecard.dax` | 3-metric KPI grid (NB Sufficiency, Pipeline Momentum, Won to Target) + performance-tinted insight panel | KPI grid, dynamic color, insight text |
| `zest-sales-summary-1.dax` | Full-height card: YTD premium + quotes, funnel KPIs, commission badge, scrollable product breakdown | Scrollable section, badge, funnel |
| `zest-card-2-hierarchy.dax` | Two-zone layout: light top (alerts/issues) + dark bottom (change orders) | Dual-zone, dark panel, status rows |

### Table Templates (`assets/tables/`)

| File | Description | Key patterns |
|------|-------------|--------------|
| `html-client-matrix.dax` | Sticky dual-column matrix: Group \| Client \| LoB columns with C/P output per LoB | Grouped rows, sticky headers, accent `#7F35B2` |

### Chart Templates (`assets/charts/`)

| File | Description | Key patterns |
|------|-------------|--------------|
| `top30-won-client-chart.dax` | Rank-ordered horizontal bar chart, hidden scrollbar, toned-down headers | Top-N bars, `RANKX`, horizontal layout |

### Title Templates (`assets/titles/`)

| File | Description | Key patterns |
|------|-------------|--------------|
| `leads-overview.dax` | Enhanced page title (463×63px) with inline summary stats | Compact KPI strip, replaces plain text title |

## Publishing Checklist

- [ ] All visuals aligned to 12-column grid
- [ ] Consistent font sizes (typography scale)
- [ ] Multi-layer shadows applied
- [ ] Visual padding set to 16px
- [ ] All visuals labeled in Selection pane
- [ ] Date range visible on canvas
- [ ] KPIs include comparison context (target + prior period)
- [ ] Performance colors follow standard thresholds
- [ ] Decimal places appropriate for metric type
- [ ] Performance Analyzer run (no visual >3s load)
- [ ] Cross-filtering behaviour tested

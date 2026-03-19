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

- **Primary color**: WTW Corporate Purple `#7C3AED`
- **Canvas**: `1280×720px` (presentations) or `1440×1080px` (complex reports)
- **Grid**: 12-column, 60–80px side margins
- **Font**: Segoe UI — Regular (400) for body, Semibold (600) for titles, Bold (700) for KPI values

Full token reference: [references/tokens.md](references/tokens.md)

## Reference Guides

### Design Tokens
- **All values in one place**: See [references/tokens.md](references/tokens.md)
  - CSS variables, color palette, spacing scale, typography, shadows, border radii

### Color System
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
- **Layout & spacing**: See [references/design-standards.md](references/design-standards.md)
  - 12-column grid calculations, standard card widths
  - Spacing system (4px/8px base units), visual padding
  - Shadow system, border radius, modal pop-up pattern, minimize redundancy rules

### DAX Patterns
- **Measures & logic**: See [references/dax-patterns.md](references/dax-patterns.md)
  - Performance detection, color mapping, gradient variables
  - YTD, QTD, MTD, YoY, MoM, vs Target measures
  - Status badges, dynamic titles, number formatting
  - DAX optimisation best practices

### HTML Cards
- **DAX-generated components**: See [references/html-cards.md](references/html-cards.md)
  - Container structure, grid layouts (2/3/4-column)
  - Progress bars with benchmark lines, status badges
  - Summary panels, typography patterns
  - Complete Executive Summary Card example

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

- **Starter template**: `assets/wtw-card-template.html` — HTML scaffold with all WTW tokens pre-wired

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

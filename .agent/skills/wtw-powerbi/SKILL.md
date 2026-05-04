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

## Template Fidelity — Match the Source Exactly

When a user references an existing template ("build a card like `zest-sales-summary-1`", "use the same layout as the pipeline scorecard", "based on this card") or asks to reproduce anything from `assets/`, the new output **must look identical** to the source — same proportions, same spacing, same shadow, same fonts, same flex ratios. Drift here is the most common reason a freshly-built card "looks different from my template" even though the user expected it the same.

How to apply this every time:

1. **Start by reading the template DAX file as the base** — open the file under `assets/cards/`, `assets/tables/`, etc. Do not retype the structure from memory and do not paraphrase the CSS. If the template has 32 lines of CSS in the `<style>` block, the new measure should have those same 32 lines verbatim.
2. **Modify only what was explicitly requested** — measure references, copy, headings, the specific values the user named. Everything else stays.
3. **Treat every unspecified design value as load-bearing.** Padding (`16px`), border radius (`12px` vs `20px`), hero KPI (`24px / 700`), shadow tokens (`_shadowOuter` / `_shadowInner`), flex ratios, color stops, font-family fallback (`'Segoe UI', sans-serif`), opacity steps, label font size (`12px`) — all were chosen deliberately. A 12px → 14px swap, or `0.1` → `0.08` shadow opacity, will visibly shift the card.
4. **If a token in the template looks wrong, surface it and ask before changing.** Never silently substitute one design token for another, "round up" a value, replace `'Segoe UI'` with `Inter`, swap multi-layer shadows for a single soft shadow, or merge two flex children into one.
5. **Preserve the variable block exactly.** The DAX `VAR` block at the top (Step 2 of the build workflow) is the contract — copy it verbatim from the chosen palette. Do not omit unused variables; do not reorder.

Allowed deviations without asking: (a) values the user explicitly requested, (b) measure references that must change, (c) text content / copy. Everything else requires confirmation.

Why this rule is here: previous cards built "from the same template" silently changed hero KPI font (24px → 20px), shadow opacity (`0.1` → `0.08`), padding (16px → 12px), and font-family (Segoe UI → Inter). Each was a small judgment call by the model; together they made the new card visibly off-brand.

## Reference Guides

### Design Values

- **All values in one place**: See [references/design-values.md](references/design-values.md)
  - CSS variables, color palette, spacing scale, typography, shadows, border radii

### Color System

- **Two palettes available**: Corporate (WTW Purple `#7F35B2`) and Indigo (`#4f46e5`) — see [references/color-system.md](references/color-system.md) for full palette definitions and DAX blocks.
- **Default to Corporate** for brand-aligned, executive, and external-facing reports. Switch to Indigo when the user mentions CRM, sales operations, pipeline, leaderboards, or asks explicitly. Only ask which palette to use when the context is genuinely ambiguous (e.g., a generic "build me a dashboard" with no domain hint).
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
  - **Default to Corporate** spacing (16px padding, 8px outer radius, tight 4/8px base, multi-layered elevation: `box-shadow: 0 2px 4px rgba(0,0,0,0.02), 0 8px 16px rgba(0,0,0,0.04), 0 24px 32px rgba(0,0,0,0.06);`). Switch to **Modern** (32px padding, 20px radius, generous 24px gaps, soft ambient `box-shadow: 0 20px 40px -8px rgba(0,0,0,0.08);`) only when the user asks for a "breathable", "modern", "marketing", or "landing-page" feel. Ask only if the context is ambiguous.
  - 12-column grid calculations, standard card widths
  - Modal pop-up pattern, minimize redundancy rules

### DAX Patterns
- **Measures & logic**: See [references/dax-patterns.md](references/dax-patterns.md)
  - Performance detection, color mapping, gradient variables
  - YTD, QTD, MTD, YoY, MoM, vs Target measures
  - Status badges, dynamic titles, number formatting
  - DAX optimisation best practices

### HTML Card Workflow

- **Canonical build workflow** — every HTML card measure follows the steps in [references/html-card-workflow.md](references/html-card-workflow.md). The default path handles HTML provided by the user (e.g., from Gemini); the template path applies when starting from `assets/cards/`.
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

### Stakeholder Presentation
- **Dashboard storytelling framework**: See [references/presenting.md](references/presenting.md)
  - McKinsey Pyramid Principle + ABT narrative + "So What?" test
  - Act 1 / 2 / 3 script structure with fill-in-the-blank Loom template
  - How to frame each visual as a decision tool, not a status update

## Assets

All asset files are ready-to-use DAX measures or HTML scaffolds. Copy the content directly into Power BI Desktop.

### HTML Scaffolds

| File | Story it tells | Technical notes |
|------|---------------|-----------------|
| `assets/wtw-card-template.html` | Blank canvas — no story yet. Use this to prototype any new card in a browser before writing DAX. Pre-wires all WTW design tokens (colors, fonts, spacing, shadows). | Standalone HTML; no Power BI required for preview |

### Card Templates (`assets/cards/`)

| File | Story it tells | Key patterns |
|------|---------------|--------------|
| `pipeline-health-scorecard.dax` | *"Is the sales pipeline healthy enough to hit target?"* — Three performance dials (NB Sufficiency, Pipeline Momentum, Won to Target) in a single glance, colour-coded red/amber/green. A tinted insight panel at the bottom translates the numbers into a plain-language verdict. | KPI grid, dynamic color, insight text |
| `zest-sales-summary-1.dax` | *"How is the Zest book performing this year?"* — YTD premium and quote volume up top, funnel KPIs in the middle, commission badge, and a scrollable product breakdown below so every line of business is visible without leaving the page. | Scrollable section, badge, funnel |
| `zest-card-2-hierarchy.dax` | *"What needs fixing and what's changing in Zest operations?"* — Two-zone layout separates urgency: alerts and open issues in the light top zone, change orders in the dark bottom zone. Readers scan the top for action, the bottom for context. | Dual-zone, dark panel, status rows |
| `loom-class-distribution.dax` | *"How deep is our product penetration across the portfolio?"* — Horizontal bar chart shows the split between clients holding 1 / 2 / 3 / 4+ product classes. The KPI strip beneath surfaces penetration rate, 1-LOB concentration, avg revenue per client, and avg LOBs — the four levers of a cross-sell strategy. | Bar chart, opacity steps, fact-derived client base |
| `loom-client-lookup.dax` | *"What do we know about this client, and what should we sell them next?"* — Profile card for a single selected client. Shows identity metadata, revenue, product lines held as purple pills, and whitespace gaps as outlined pills. The whitespace section is the conversation starter before any client meeting. | Guard pattern, `EXCEPT()` whitespace, `flex:1` last section |

### Table Templates (`assets/tables/`)

| File | Story it tells | Key patterns |
|------|---------------|--------------|
| `html-client-matrix.dax` | *"Which clients hold which lines of business, and what type of cover?"* — Sticky matrix with Group and Client as fixed left columns, each LoB as a column header. Each cell shows C (current) or P (pipeline), making gaps in coverage immediately visible across a large book. | Grouped rows, sticky headers, accent `#7F35B2` |
| `loom-penetration-heatmap.dax` | *"Which product classes are underrepresented in each client segment?"* — Native matrix visual powered by a pre-aggregated calculated table instead of the fact table. `Penetrate` dots mark held products; `Segment Penetration Rate` fills cells with a purple gradient to show where the whitespace is densest by segment. Fast enough to render without a filter. | Pre-aggregated table, `COUNTROWS(FILTER())`, gradient CF |

### Chart Templates (`assets/charts/`)

| File | Story it tells | Key patterns |
|------|---------------|--------------|
| `top30-won-client-chart.dax` | *"Who are our biggest wins, and how do they rank?"* — Horizontal bar chart of the top 30 won clients by revenue, rank-ordered. Gives account managers an immediate league table without opening a full report. | Top-N bars, `RANKX`, horizontal layout |

### Title Templates (`assets/titles/`)

| File | Story it tells | Key patterns |
|------|---------------|--------------|
| `leads-overview.dax` | *"What page am I on, and what's the headline number?"* — Replaces a plain text title with an enhanced header that embeds 2–3 inline summary stats (e.g. total leads, conversion rate). Sets context before the reader looks at any visual. | Compact KPI strip, replaces plain text title |

## Publishing Checklist

End-of-task review before handing a report to a stakeholder — see [references/publishing-checklist.md](references/publishing-checklist.md) for the full list (layout, typography, color/shadows, hygiene, performance).

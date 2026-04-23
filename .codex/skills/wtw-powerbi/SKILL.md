---
name: wtw-powerbi
description: WTW-branded Power BI reporting, DAX measures, HTML card visuals, KPI scorecards, semantic modeling, Power Query M, and dashboard layout work. Use when creating, editing, or reviewing Power BI reports, WTW design system decisions, KPI cards, branded layouts, Fabric Lakehouse Power Query patterns, or DAX logic for targets, time intelligence, and performance colours.
---

# WTW Power BI

Use this skill to produce WTW-style Power BI work that feels credible, structured, and consulting-grade.

Keep the output light-mode-first, data-dense, and intentional. Avoid generic BI defaults and avoid decorative AI-looking treatments.

## Non-Negotiables

- Use WTW Corporate Purple `#7F35B2` as the primary brand accent
- Prefer white canvas and restrained colour use
- Make hierarchy through layout, typography, and weight before colour
- Include comparison context in KPI outputs when possible: target, prior period, or change
- Avoid emojis in code, DAX, comments, titles, and report scaffolding
- Avoid startup-style gradients, centered hero banners, and oversized decorative chrome

## Ask Before Styling

If the task is materially about colour, ask which palette to use:

- Corporate
- Indigo

If the task is materially about spacing, borders, or shadows, ask which style to use:

- Corporate
- Modern

If the user does not care, default to:

- Palette: Corporate
- Style: Corporate

## Default Design Baseline

- Canvas: `1280x720` for presentation-style pages, `1440x1080` for operational pages
- Grid: 12-column layout with `60-80px` side margins
- Font: Segoe UI
- KPI emphasis: bold numeric value, compact supporting context, restrained labels
- Theme: light mode only unless the user explicitly asks otherwise

## Working Order

1. Identify the report mode: executive, operational, or presentation.
2. Identify the required output: DAX, HTML card, semantic model guidance, or page layout.
3. Confirm palette or style only if the task depends on them.
4. Build a strong information hierarchy before adding decorative treatment.
5. Check that the result feels like a premium internal consulting deliverable.

## Report Modes

### Executive

Use for senior stakeholders, summary pages, and small visual counts.

- Keep to a few visuals
- Use larger numeric emphasis
- Let purple drive hierarchy sparingly

### Operational

Use for dense tracking pages, analyst workflows, and tables.

- Fit more visuals on canvas
- Prioritise clarity, alignment, and scanability
- Use performance colours deliberately, not constantly

### Presentation

Use for storytelling pages and slide-like report tabs.

- Keep one message per page
- Use stronger section framing
- Reduce clutter and secondary data

## DAX Guidance

Use DAX that is readable, explicit, and performant.

- Prefer measures with clear business names
- Keep variable naming consistent
- Use `_camelCase` for DAX variables
- Include time-intelligence, target, and variance context when relevant
- Format numbers appropriately for currency, counts, ratios, and percentages

Common patterns to support:

- YTD, QTD, MTD
- YoY and MoM
- vs Target
- performance state and colour mapping
- dynamic titles
- HTML card string output

## HTML Card Guidance

When building DAX-generated HTML cards:

- Start with the content structure before styling details
- Use tight, consistent spacing and a clear type scale
- Show status, change, and benchmark context where useful
- Keep cards compact and legible inside Power BI visuals
- Use shadows and radii conservatively

Prefer patterns like:

- KPI grids
- progress bars with targets
- summary panels
- sticky matrices
- compact title strips

## Semantic Modeling Guidance

Prefer star-schema thinking.

- Use clear fact and dimension roles
- Keep dimensions conformed where possible
- Treat date modeling as a first-class concern
- Watch for ambiguous relationships and over-connected models

When the user asks for model advice, bias toward:

- clean dimension tables
- clear grain
- explicit measures
- minimal relationship complexity

## Power Query Guidance

Use clean, robust M patterns for Lakehouse-connected work.

- Cast explicitly
- Handle nulls safely
- Clean currencies and numeric fields carefully
- Keep transformations auditable

## Reference Material

Use the shared source material from the Claude/Antigravity setup as needed:

- `.agent/skills/wtw-powerbi/references/design-values.md`
- `.agent/skills/wtw-powerbi/references/color-system.md`
- `.agent/skills/wtw-powerbi/references/design-standards.md`
- `.agent/skills/wtw-powerbi/references/dax-patterns.md`
- `.agent/skills/wtw-powerbi/references/html-card-workflow.md`
- `.agent/skills/wtw-powerbi/references/html-cards.md`
- `.agent/skills/wtw-powerbi/references/data-modeling.md`
- `.agent/skills/wtw-powerbi/references/power-query.md`

Use the shared assets folder when the task needs an existing scaffold:

- `.agent/skills/wtw-powerbi/assets/`

## Final Checks

Before finishing:

- Check alignment and spacing consistency
- Check that the result uses purple as signal, not wallpaper
- Check that KPI visuals include business context, not just a single number
- Check that the work does not look like a default Power BI canvas

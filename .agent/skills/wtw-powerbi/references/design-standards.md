# Power BI Design Standards

Complete guide to grid system, spacing, typography, and visual styling for WTW Power BI reports.

## Pre-Build Design Thinking

Answer these before opening Power BI Desktop. The answers determine canvas size, layout density, colour emphasis, and typography scale.

| Question | Impact |
|----------|--------|
| **Who is the primary audience?** Executive, analyst, or operational team? | Canvas size, visual count, font scale |
| **What is the primary action?** What should they *do* after viewing this report? | Which visual gets the hero position (top-left) |
| **What is the single most important number?** The one metric that must be immediately visible | Hero KPI card sizing and colour |
| **What is the density requirement?** Big-picture overview, or data-dense drill-down? | Layout mode — see [report-modes.md](report-modes.md) |
| **How will this be consumed?** Screen share, embedded in Teams, printed, TV display? | Canvas size, font minimum, dark/light mode |
| **Are there existing reports this must be consistent with?** | Report mode, colour palette, page structure |

Pick a **report mode** from [report-modes.md](report-modes.md) before proceeding to layout.

---

## Canvas & Grid System

### Standard Canvas Sizes

| Canvas Type | Dimensions | Use Case |
|-------------|------------|----------|
| **Presentations & Dashboards** | 1280 x 720px | Standard presentations, executive dashboards |
| **Complex Reports** | 1440 x 1080px | Detailed analytical reports with many visuals |

### 12-Column Grid System

Power BI reports should align to a 12-column grid for clean, professional layouts.

**1440px Canvas**:
- **Total Width**: 1440px
- **Side Margins**: 80px each side
- **Content Area**: 1280px (1440 - 160)
- **Gutter**: 26px between columns
- **Column Width**: ~83px

**1280px Canvas**:
- **Total Width**: 1280px
- **Side Margins**: 60px each side
- **Content Area**: 1160px (1280 - 120)
- **Gutter**: 24px between columns
- **Column Width**: ~75px

**Key Principle**: All visuals should align to grid columns for clean, professional layouts.

### Standard Card Widths (Grid-Aligned)

Based on 1280px canvas with 12-column grid:

| Columns Span | Width | Use Case | Example |
|--------------|-------|----------|---------|
| 3 columns | 268px | Single KPI card | Revenue KPI |
| 4 columns | 364px | Compact scorecard | 3-metric card |
| 6 columns | 580px | Executive summary card ✓ | Performance scorecard |
| 8 columns | 796px | Wide analytical card | Trend analysis |
| 12 columns | 1160px | Full-width dashboard banner | Page header |

**Height Recommendations**:
- KPI Cards: `320-400px`
- Scorecards: `300-350px`
- Executive Summary: `350-450px`
- Full-width banners: `200-250px`

## Spacing & Padding Standards

Use **4px or 8px base units** for all spacing to maintain consistency.

### Vertical Spacing

| Setting | Value | Usage |
|---------|-------|-------|
| **Vertical Page Margin** | 54px (48px alternate) | Empty space at top/bottom of report page |
| **Section Padding** | 32px | Vertical gap between major visual groups |
| **Visual Padding** | 16px | Internal padding for all native visuals (charts, tables) |
| **Card Padding** | 20px | Internal padding for HTML card containers |

### Horizontal Spacing

| Setting | Value | Usage |
|---------|-------|-------|
| **Side Margins** | 60-80px | Left/right page margins |
| **Visual Gutter** | 24-26px | Space between adjacent visuals |
| **Grid Gap (HTML)** | 12px | Gap between grid items in HTML cards |

## Typography System

### Font Size Scale

Use **pixels (px)** for consistency with Power BI settings.

| Variable | Pixels | Points | Use Case |
|----------|--------|--------|----------|
| `text-xs` | 12px | 8.25pt | Axis labels, footer text, captions |
| `text-sm` | 14px | 10.5pt | Body text, descriptions, secondary KPI labels |
| `text-md` | 16px | 12pt | Visual titles, subtitles, paragraph text |
| `text-lg` | 18px | 13.5pt | Sub-headings, larger visual titles, card values |
| `display-sm` | 24px | 18pt | Main KPI values, small display headings |
| `display-md` | 30px | 22.5pt | Medium display headings, key metrics |
| `display-lg` | 36px | 27pt | Large dashboard titles, primary headings |
| `display-xl` | 54px | 40.5pt | High-impact numbers on dedicated cards |
| `display-2xl` | 72px | 54pt | Hero titles on large overview dashboards |

### Typography Guidelines

**Accessibility**:
- Default body text: **16px (12pt)** minimum
- Minimum readable size: **12px (9pt)** — use sparingly
- High-contrast text: Use `#1E293B` on white backgrounds

**Font Families**:
- Primary: **Segoe UI** (Power BI default)
- Web/HTML cards: **Segoe UI, Inter, system-ui, sans-serif**

**Font Weights**:
- Regular (400): Body text, labels
- Semibold (600): Visual titles, sub-headings
- Bold (700): KPI values, headings, status badges

## Shadows & Visual Styling

### Multi-Layer Shadow System (Recommended)

**Outer Container Shadow** (premium, elevated look):
```css
box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1),
            0 4px 6px -2px rgba(0, 0, 0, 0.05);
```

**Use for**: Main card containers, HTML scorecard wrappers, elevated panels

**Inner Card Shadow** (subtle depth):
```css
box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1),
            0 1px 2px 0 rgba(0, 0, 0, 0.06);
```

**Use for**: Individual metric cards within containers, nested elements

### Single Soft Shadow (Alternative)

For native Power BI visuals, use these settings:

| Property | Default (Harsh) | Recommended (Soft) |
|----------|-----------------|---------------------|
| **Color** | Black | Light Gray |
| **Angle** | 45° | 90° (straight down) |
| **Distance** | 10px | 4px |
| **Size** | 3px | 1px |
| **Blur** | 10px | 8px |
| **Transparency** | 70% | 70% |

**Pro Tips**:
- Use multi-layer shadows for premium HTML cards
- Use single soft shadow for simple native visuals
- **Glow effect**: When a visual has a coloured background (e.g., a WTW purple header card), set the shadow colour to match the visual's theme colour. This creates a subtle glow that integrates the visual into the canvas instead of making it look pasted on.
- Never use harsh black shadows — always use soft rgba or light-gray shadows

## Borders & Visual Effects

### Border System

**Light Border** (subtle separation):
```css
border: 1px solid #F3F4F6;
```

**Medium Border** (standard separation):
```css
border: 1px solid #E5E7EB;
```

**Themed Border** (performance-colored with opacity):
```css
border: 1px solid #7C3AED20;  /* 20 = ~12% opacity */
```

### Border Radius

| Element | Border Radius | Use Case |
|---------|---------------|----------|
| **Outer Containers** | 12px | Main card containers |
| **Inner Cards** | 8px | Nested metric cards |
| **Progress Bars** | 5px | Progress bar tracks |
| **Status Badges** | 8px | Small status indicators |
| **Buttons** | 6px | Interactive elements |

## Background Patterns

### Gradient Backgrounds

**Container Background** (subtle gradient):
```css
background: linear-gradient(145deg, #FFFFFF 0%, #F9FAFB 100%);
```

**Performance Bar Gradients** (see color-system.md for full palette):
```css
/* Outstanding (WTW Purple) */
background: linear-gradient(135deg, #8B5CF6 0%, #7C3AED 100%);

/* Target Met (Green) */
background: linear-gradient(135deg, #10B981 0%, #059669 100%);

/* Near Target (Cyan) */
background: linear-gradient(135deg, #06B6D4 0%, #0891B2 100%);
```

### Tinted Backgrounds

**Subtle Tinted Background** (for summary panels):
```css
background: linear-gradient(135deg, #F3F4F6 0%, rgba(255,255,255,0.8) 100%);
border: 1px solid #7C3AED25;
```

## Visual Organization Best Practices

### Selection Pane Naming

Use consistent naming convention: `[Section] - [Visual Type] - [Description]`

**Examples**:
- `Header - Card - Total Revenue`
- `KPIs - Card - Sales vs Target`
- `Charts - Line Chart - Monthly Trend`
- `Tables - Matrix - Product Details`
- `Filters - Slicer - Date Range`

**Benefits**:
- Easy navigation in Selection pane
- Logical grouping of related visuals
- Clear documentation for maintenance

### Visual Limits per Page

- **Optimal**: ≤10 visuals for best performance
- **Maximum**: ≤15 visuals for acceptable performance
- **If exceeding 15**: Consider using bookmarks for multiple view states instead of separate pages

### Minimize Redundancy

Remove visual noise caused by duplicated information:
- **Hide axis titles** when the visual title already states the metric (e.g., don't show "Month" on the X-axis if the title says "Monthly Revenue")
- **Hide axis values** when data labels already show the numbers
- **Remove legends** when there is only one data series, or when the series are clearly labelled directly
- **Remove gridlines** on bar/column charts when data labels are enabled

The goal is to surface data, not labels about labels.

### Modal Pop-up Pattern (Info Overlays)

Use bookmark-driven modal overlays for supplementary content — business logic explanations, data dictionary, refresh schedule, calculation notes — instead of adding clutter to the main canvas.

**How to build it**:
1. Create a floating panel (rectangle + text/visuals) with WTW card styling, positioned over the canvas
2. Add a close button (✕) as a native Button visual
3. Create two bookmarks: `Modal_Open` (panel visible) and `Modal_Closed` (panel hidden)
4. Add a small info icon (ℹ) button on the report canvas — assign action → Bookmark → `Modal_Open`
5. Assign the close button action → Bookmark → `Modal_Closed`
6. Layer order: modal panel must sit above all other visuals (top of Selection pane)

**Modal styling** (match WTW card system):
```
Background: #FFFFFF
Border: 1px solid #E5E7EB
Border-radius: 12px
Shadow: 0 20px 40px rgba(0,0,0,0.15)  ← stronger than card shadow to lift above canvas
Padding: 24px
Width: ~500–700px (centred on canvas)
```

**When to use modals vs canvas text**:
- ✅ Modal: business rule definitions, source system notes, refresh cadence, calculation methodology
- ✅ Canvas: active date range, data currency warning, key filter indicator
- ❌ Never put lengthy explanatory text directly on the canvas — it competes with the data

### Z-Index / Layer Order

Standard layering from back to front:
1. Background shapes/rectangles
2. Main visuals (charts, tables)
3. Overlays (modal popups)
4. Filters/slicers (if floating)

## Accessibility Guidelines

See [color-system.md](color-system.md) for full WCAG AA contrast ratios, pre-validated color combinations, and accessibility best practices.

**Key rules**:
- Never rely solely on color — always add text labels + icons
- Ensure slicers and buttons are keyboard-accessible

## Performance Optimization

### Visual Limits

- Limit visuals per page: ≤15 for optimal performance
- Use bookmarks for multiple view states instead of creating many pages
- Minimize use of custom visuals (they're slower than native visuals)

### Data Model

- Use **star schema architecture**
- Implement proper relationships (avoid bi-directional unless necessary)
- Create dedicated **date table with calendar hierarchy**
- Remove unused columns from model

### DAX Optimization

- Use **variables** to avoid recalculation (`VAR _variable = ...`)
- **Filter early** in calculation context
- Use `SELECTEDVALUE()` instead of `VALUES()` for single value checks
- Avoid complex calculated columns (use measures instead)

## Two-Pass Refinement

Build first, refine second. After the initial layout is complete, do a dedicated refinement pass **before** publishing.

**The rule**: On the refinement pass, do not add any new visuals, cards, or elements. Only adjust what already exists.

Ask for each element:
- Does this spacing feel tight? Loosen it.
- Is this font size consistent with its neighbours?
- Does this card's shadow match the depth of the cards beside it?
- Is this colour doing a job, or is it decorative noise?
- Would removing this label make the visual cleaner without losing meaning?

**Signs you need a refinement pass**:
- Two KPI cards at slightly different heights
- Inconsistent border radii across cards
- One visual uses 14px labels, another uses 12px
- A legend that duplicates information already in the title
- Axis labels that can't be read without squinting

The goal is cohesion — the report should look like one deliberate design decision, not a collection of individually-built visuals.

---

## Checklist: Design Standards Compliance

**Pre-build** (answer before starting):
- [ ] Report mode selected — see [report-modes.md](report-modes.md)
- [ ] Primary audience and action identified
- [ ] Hero metric decided

**Build**:
- [ ] Canvas size is standard (1280x720 or 1440x1080)
- [ ] All visuals align to 12-column grid
- [ ] Spacing uses 4px/8px base units
- [ ] Typography uses standard scale (12px → 72px)
- [ ] Shadows applied (multi-layer or soft single)
- [ ] Visual padding set to 16px
- [ ] Selection pane uses consistent naming
- [ ] Visual count per page ≤15

**Refinement pass** (before publishing):
- [ ] All card heights consistent within each row
- [ ] Font sizes consistent across equivalent elements
- [ ] No axis titles duplicating the visual title
- [ ] No redundant legends
- [ ] Shadow depth consistent across cards
- [ ] WCAG AA contrast ratios met
- [ ] Performance Analyzer shows no visual >3s load time

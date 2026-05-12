# WTW Design Tokens

Single source of truth for all WTW design values. Copy the CSS block into any HTML card template. Use the DAX block to define variables at the top of any measure.

## Table of Contents
1. [CSS Variables](#css-variables)
2. [Colors](#colors)
3. [Typography](#typography)
4. [Spacing](#spacing)
5. [Shadows](#shadows)
6. [Borders & Radius](#borders--radius)
7. [DAX Variable Block](#dax-variable-block)

---

## CSS Variables

Paste this into the `<style>` block of any WTW HTML template (standalone HTML, not DAX):

```css
:root {
  /* === Brand === */
  --wtw-purple:        #7F35B2;
  --wtw-purple-light:  #995BC5;
  --wtw-purple-dark:   #611E90;
  --wtw-purple-bg:     #F5F3FF;

  /* === Performance Colors === */
  --color-outstanding: #7F35B2;
  --color-target-met:  #059669;
  --color-near-target: #0891B2;
  --color-below:       #F59E0B;
  --color-critical:    #DC2626;

  /* === Performance Backgrounds === */
  --bg-outstanding:    #F3F4F6;
  --bg-target-met:     #ECFDF5;
  --bg-near-target:    #F0F9FF;
  --bg-below:          #FFFBEB;
  --bg-critical:       #FEF2F2;

  /* === Text Hierarchy === */
  --text-primary:   #1E293B;
  --text-secondary: #6B7280;
  --text-tertiary:  #334155;
  --text-body:      #4B5563;
  --text-muted:     #9CA3AF;

  /* === Borders & Surfaces === */
  --border-light:   #F3F4F6;
  --border-medium:  #E5E7EB;
  --border-dark:    #374151;
  --bg-white:       #FFFFFF;
  --bg-alt:         #F9FAFB;
  --bg-gray:        #F3F4F6;

  /* === Typography === */
  --font-family: 'Segoe UI', Inter, system-ui, sans-serif;
  --text-xs:     12px;
  --text-sm:     14px;
  --text-md:     16px;
  --text-lg:     18px;
  --display-sm:  24px;
  --display-md:  30px;
  --display-lg:  36px;
  --display-xl:  54px;
  --display-2xl: 72px;

  /* === Spacing (4px base) === */
  --space-1:  4px;
  --space-2:  8px;
  --space-3:  12px;
  --space-4:  16px;
  --space-5:  20px;
  --space-6:  24px;
  --space-8:  32px;
  --space-10: 40px;
  --space-14: 54px;

  /* === Shadows === */
  --shadow-outer: 0 10px 15px -3px rgba(0,0,0,0.1), 0 4px 6px -2px rgba(0,0,0,0.05);
  --shadow-inner: 0 1px 3px 0 rgba(0,0,0,0.1), 0 1px 2px 0 rgba(0,0,0,0.06);
  --shadow-soft:  0 4px 8px rgba(0,0,0,0.04);

  /* === Border Radius === */
  --radius-sm:  6px;
  --radius-md:  8px;
  --radius-lg:  12px;
  --radius-pill: 99px;

  /* === Canvas === */
  --canvas-standard: 1280px;
  --canvas-wide:     1440px;
  --margin-side-sm:  60px;
  --margin-side-lg:  80px;
}
```

---

## Colors

### Brand Purple

| Token | Hex | Use |
|-------|-----|-----|
| `--wtw-purple` | `#7F35B2` | Primary brand, outstanding performance, CTAs |
| `--wtw-purple-light` | `#995BC5` | Gradient start, lighter accents |
| `--wtw-purple-dark` | `#611E90` | Hover states, pressed states |
| `--wtw-purple-bg` | `#F5F3FF` | Subtle background tint |

### Performance Colors

| Level | Threshold | Color | Hex | Background |
|-------|-----------|-------|-----|------------|
| Outstanding | ≥115% | WTW Purple | `#7F35B2` | `#F3F4F6` |
| Target Met | 100–114% | Green | `#059669` | `#ECFDF5` |
| Near Target | 90–99% | Cyan | `#0891B2` | `#F0F9FF` |
| Below Target | 80–89% | Amber | `#F59E0B` | `#FFFBEB` |
| Critical | <80% | Red | `#DC2626` | `#FEF2F2` |

### Performance Gradients

```
outstanding: linear-gradient(135deg, #995BC5 0%, #7F35B2 100%)
target_met:  linear-gradient(135deg, #10B981 0%, #059669 100%)
near_target: linear-gradient(135deg, #06B6D4 0%, #0891B2 100%)
below:       linear-gradient(135deg, #FBBF24 0%, #F59E0B 100%)
critical:    linear-gradient(135deg, #F87171 0%, #DC2626 100%)
```

### Text Hierarchy

| Token | Hex | Use |
|-------|-----|-----|
| `--text-primary` | `#1E293B` | Headings, main values |
| `--text-tertiary` | `#334155` | Sub-headings |
| `--text-body` | `#4B5563` | Body text |
| `--text-secondary` | `#6B7280` | Labels, axis text |
| `--text-muted` | `#9CA3AF` | Captions, hints |

### Multi-Category Chart Palette

Order: `#7F35B2` → `#059669` → `#0891B2` → `#F59E0B` → `#EC4899` → `#995BC5`
- Reserve `#DC2626` for critical/negative data only
- Limit to 5–6 colors per chart

---

## Typography

| Token | px | Use |
|-------|----|-----|
| `--text-xs` | 12 | Axis labels, captions |
| `--text-sm` | 14 | Body text, secondary labels |
| `--text-md` | 16 | Visual titles, paragraphs |
| `--text-lg` | 18 | Sub-headings, card values |
| `--display-sm` | 24 | Main KPI values |
| `--display-md` | 30 | Medium headings |
| `--display-lg` | 36 | Dashboard titles |
| `--display-xl` | 54 | High-impact hero numbers |
| `--display-2xl` | 72 | Large overview dashboards |

**Weights**: Regular 400 (body) · Semibold 600 (titles) · Bold 700 (KPI values, badges)

---

## Spacing

Base unit: **4px**. All spacing is a multiple of 4.

| Token | Value | Use |
|-------|-------|-----|
| `--space-1` | 4px | Micro gaps |
| `--space-2` | 8px | Inner tight spacing |
| `--space-3` | 12px | Grid gap between items |
| `--space-4` | 16px | Visual padding (standard) |
| `--space-5` | 20px | Card padding |
| `--space-6` | 24px | Visual gutter between cards |
| `--space-8` | 32px | Section padding |
| `--space-12` | 48px | Page top/bottom margin (compact) |
| `--space-14` | 54px | Page top/bottom margin (standard) |

---

## Shadows

| Token | Value | Use |
|-------|-------|-----|
| `--shadow-outer` | `0 10px 15px -3px rgba(0,0,0,0.1), 0 4px 6px -2px rgba(0,0,0,0.05)` | Main card containers |
| `--shadow-inner` | `0 1px 3px 0 rgba(0,0,0,0.1), 0 1px 2px 0 rgba(0,0,0,0.06)` | Nested metric cards |
| `--shadow-soft` | `0 4px 8px rgba(0,0,0,0.04)` | Subtle hover lift |

**Never use harsh black shadows.** Always use soft rgba shadows.

---

## Borders & Radius

| Token | Value | Use |
|-------|-------|-----|
| `--border-light` | `#F3F4F6` | Subtle dividers |
| `--border-medium` | `#E5E7EB` | Standard borders |
| `--border-dark` | `#374151` | Benchmark lines |
| `--radius-sm` | 6px | Buttons |
| `--radius-md` | 8px | Inner cards, badges |
| `--radius-lg` | 12px | Outer containers |
| `--radius-pill` | 99px | Pills, tags |

**Themed border with opacity** (performance-colored):
```css
border: 1px solid #7F35B220;  /* 20 = ~12% opacity */
border: 1px solid #7F35B225;  /* 25 = ~15% opacity */
```

---

## DAX Variable Block

Paste at the top of any DAX measure that uses WTW styling:

```dax
-- Brand
VAR _wtwPurple      = "#7F35B2"
VAR _wtwPurpleLight = "#995BC5"
VAR _wtwPurpleDark  = "#611E90"

-- Text hierarchy
VAR _textPrimary   = "#1E293B"
VAR _textSecondary = "#6B7280"
VAR _textTertiary  = "#334155"
VAR _textBody      = "#4B5563"
VAR _textMuted     = "#9CA3AF"

-- Surfaces
VAR _bgAlt        = "#F9FAFB"
VAR _borderLight  = "#F3F4F6"
VAR _borderMedium = "#E5E7EB"

-- Shadows
VAR _outerShadow = "0 10px 15px -3px rgba(0,0,0,0.1), 0 4px 6px -2px rgba(0,0,0,0.05)"
VAR _innerShadow = "0 1px 3px 0 rgba(0,0,0,0.1), 0 1px 2px 0 rgba(0,0,0,0.06)"
```

For performance-based color variables, use the standard detection block from [dax-patterns.md](dax-patterns.md).

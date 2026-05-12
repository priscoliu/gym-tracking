# WTW Design Values

Single source of truth for all WTW design values. Copy the CSS block into any HTML card template. Use the DAX block to define variables at the top of any measure.

> **Renamed from `tokens.md`** — "design values" is more plain-English and accurate. "Tokens" is framework jargon (design system tooling) that doesn't match how these values are actually used in DAX/HTML card measures.

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
  /* === Brand (WTW Ultraviolet — see wtw-brand-design-system.md for full 0–990 scale) === */
  --wtw-purple:        #7F35B2;   /* UV-600 = brand purple */
  --wtw-purple-light:  #995BC5;   /* UV-500 */
  --wtw-purple-dark:   #611E90;   /* UV-700 */
  --wtw-purple-bg:     #F5F0FB;   /* near UV-50 — light tint */

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
  --text-primary:   #181B1D;
  --text-secondary: #485257;
  --text-tertiary:  #606E74;
  --text-body:      #485257;
  --text-muted:     #9CA3AF;

  /* === Borders & Surfaces === */
  --border-light:   #F3F4F6;
  --border-medium:  #E5E7EB;
  --border-dark:    #374151;
  --bg-white:       #FFFFFF;
  --bg-alt:         #F9FAFB;
  --bg-gray:        #F3F4F6;

  /* === Typography === */
  /* Fonts: Segoe UI (regular/body), Segoe UI Semibold (titles/headers) */
  --font-family:          'Segoe UI';
  --font-family-semibold: 'Segoe UI Semibold';
  /* Sizes mapped from theme pt values (1pt = 1.333px) */
  --text-xs:     12px;   /* 9pt  — axis, table rows, filter text */
  --text-sm:     14px;   /* 10.5pt — labels, slicers, subtitles, buttons */
  --text-md:     16px;   /* 12pt — visual titles, textbox */
  --text-lg:     24px;   /* 18pt — card values */
  --display-sm:  28px;   /* 21pt — KPI indicator */
  --display-md:  32px;   /* 24pt — medium headings */
  --display-lg:  36px;   /* 27pt — dashboard titles */
  --display-xl:  54px;   /* 40.5pt — hero numbers */
  --display-2xl: 72px;   /* 54pt — large overview */

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

  /* === Border Radius (brand default = 10px when borders are used) === */
  --radius-sm:      6px;
  --radius-md:      8px;
  --radius-default: 10px;   /* WTW brand default for any container border */
  --radius-lg:      12px;   /* legacy templates only — prefer --radius-default for new work */
  --radius-pill:    99px;

  /* === Advanced element colors === */
  --color-first-level:   #485257;
  --color-second-level:  #485257;
  --color-third-level:   #F1F3F4;
  --color-fourth-level:  #606E74;
  --color-background:    #FFFFFF;
  --color-surface-light: #F1F3F4;
  --color-surface-alt:   #F7F8F8;
  --color-border:        #AEB8BD;
  --color-border-grid:   #E4E7E9;
  --color-border-header: #C9D0D3;

  /* === Canvas === */
  --canvas-standard: 1280px;
  --canvas-wide:     1440px;
  --margin-side-sm:  60px;
  --margin-side-lg:  80px;
}
```

---

## Colors

### Brand Purple (WTW Ultraviolet)

| Name | Hex | Level | Use |
|------|-----|-------|-----|
| WTW Purple | `#7F35B2` | UV-600 | Primary brand, outstanding performance, CTAs |
| Purple Light | `#995BC5` | UV-500 | Gradient start, lighter accents — minimum level for **text** on white (4.5:1) |
| Purple Dark | `#611E90` | UV-700 | Hover states, pressed states |
| Purple Darkest | `#521380` | UV-750 | Categorical color #1 in the official order |
| Purple Bg | `#F5F0FB` | ~UV-50 | Subtle background tint |

Full 0–990 Ultraviolet scale and all color combinations: [wtw-brand-design-system.md](wtw-brand-design-system.md). For semantic brand colors (WTW Success / Error / Submarine) see the same file.

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

| Name | Hex | Use |
|------|-----|-----|
| Primary | `#181B1D` | Headings, KPI values, main text |
| Secondary | `#485257` | Labels, body, slicers, tooltips |
| Tertiary | `#606E74` | Muted labels, outspace text |
| Body | `#485257` | Body text (same as secondary) |
| Muted | `#9CA3AF` | Captions, hints |

### Chart Palettes

Two palettes available — see [color-system.md](color-system.md) for full details.

**Corporate** (WTW brand-aligned): `#7F35B2` → `#059669` → `#0891B2` → `#F59E0B` → `#EC4899` → `#995BC5`

**Indigo** (modern / operational): `#4f46e5` → `#5ce1ff` → `#e5e7eb` → `#f59e0b` → `#10b981` → `#ef4444` → …

- Reserve `#DC2626` for critical/negative data only
- Limit to 5–6 colors per chart

---

## Typography

| Size | px | pt equiv | Font | Use |
|------|----|----------|------|-----|
| `--text-xs` | 12 | 9pt | Segoe UI | Axis labels, table rows, filter text |
| `--text-sm` | 14 | 10.5pt | Segoe UI | Labels, slicers, subtitles, buttons |
| `--text-md` | 16 | 12pt | Segoe UI Semibold | Visual titles, textbox |
| `--text-lg` | 24 | 18pt | Segoe UI Bold | Card values |
| `--display-sm` | 28 | 21pt | Segoe UI Bold | KPI indicator |
| `--display-md` | 32 | 24pt | Segoe UI Bold | Medium headings |
| `--display-lg` | 36 | 27pt | Segoe UI Bold | Dashboard titles |
| `--display-xl` | 54 | 40.5pt | Segoe UI Bold | Hero numbers |
| `--display-2xl` | 72 | 54pt | Segoe UI Bold | Large overview |

**Weights**: Regular (body/labels) · Semibold (titles, column headers, selected states) · Bold (KPI values)

---

## Spacing

Base unit: **4px**. All spacing is a multiple of 4.

| Name | Value | Use |
|------|-------|-----|
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

| Name | Value | Use |
|------|-------|-----|
| `--shadow-outer` | `0 10px 15px -3px rgba(0,0,0,0.1), 0 4px 6px -2px rgba(0,0,0,0.05)` | Main card containers |
| `--shadow-inner` | `0 1px 3px 0 rgba(0,0,0,0.1), 0 1px 2px 0 rgba(0,0,0,0.06)` | Nested metric cards |
| `--shadow-soft` | `0 4px 8px rgba(0,0,0,0.04)` | Subtle hover lift |

**Never use harsh black shadows.** Always use soft rgba shadows.

---

## Borders & Radius

| Name | Value | Use |
|------|-------|-----|
| `--border-light` | `#F3F4F6` | Subtle dividers (≈ Gray Matter Light) |
| `--border-medium` | `#E5E7EB` | Standard borders |
| `--border-functional` | `#8F9194` | **Brand minimum for functional borders — meets 3:1 on white (GM-400)** |
| `--border-dark` | `#374151` | Benchmark lines, emphasis |
| `--radius-sm` | 6px | Buttons |
| `--radius-md` | 8px | Inner cards, badges |
| `--radius-default` | 10px | **Brand default — use for any container border** |
| `--radius-lg` | 12px | Legacy templates only |
| `--radius-pill` | 99px | Pills, tags |

> **Brand default**: borders are **OFF** unless they serve a purpose (separation, contrast). When used, prefer `--radius-default` (10px) and `--border-functional` color or darker.

**Themed border with opacity** (performance-colored):

```css
border: 1px solid #7F35B220;  /* 20 = ~12% opacity */
border: 1px solid #7F35B225;  /* 25 = ~15% opacity */
```

---

## DAX Variable Block

Paste at the top of any DAX measure that uses WTW styling:

```dax
-- Brand (WTW Ultraviolet — see wtw-brand-design-system.md for full 0–990 scale)
VAR _wtwPurple      = "#7F35B2"   -- UV-600 (brand purple)
VAR _wtwPurpleLight = "#995BC5"   -- UV-500
VAR _wtwPurpleDark  = "#611E90"   -- UV-700

-- Text hierarchy
VAR _textPrimary   = "#181B1D"
VAR _textSecondary = "#485257"
VAR _textTertiary  = "#606E74"
VAR _textBody      = "#485257"
VAR _textMuted     = "#9CA3AF"

-- Surfaces & borders
VAR _bgWhite      = "#FFFFFF"
VAR _bgLight      = "#F1F3F4"
VAR _bgAlt        = "#F7F8F8"
VAR _borderColor  = "#AEB8BD"
VAR _borderGrid   = "#E4E7E9"
VAR _borderHeader = "#C9D0D3"

-- Shadows
VAR _outerShadow = "0 10px 15px -3px rgba(0,0,0,0.1),0 4px 6px -2px rgba(0,0,0,0.05)"
VAR _innerShadow = "0 1px 3px 0 rgba(0,0,0,0.1),0 1px 2px 0 rgba(0,0,0,0.06)"
```

For the Indigo palette variable block, see [dax-patterns.md](dax-patterns.md#standard-dax-variable-block).

For performance-based color variables, see [color-system.md](color-system.md).

# HTML Card Build Workflow

Mandatory checklist for every HTML card measure. Follow these steps in order — they exist because inconsistencies were found across cards when patterns were applied ad-hoc.

---

## Default Path vs. Template Path

**Default (HTML-handoff)**: User provides HTML designed externally (e.g. by Gemini) → connect to semantic model → adapt to WTW standards → convert to DAX. Follow **Step 0 → Steps 1–8**.

**Template path**: User explicitly asks to build from WTW templates. Skip Step 0, go straight to **Step 1**.

---

## Step 0 — HTML Handoff (Default Path)

User provides raw HTML. Do the following before touching DAX:

### 0a — Read the HTML

Understand the layout: zones, KPI positions, which values are static placeholders vs. dynamic data.

### 0b — Connect to Semantic Model

Ask the user (or read from MCP if a model is open):
- Which **table** holds the measure? (e.g. `New Business Calculation`)
- Which **measures** map to each placeholder value in the HTML?
- Are there any **filters or time intelligence** needed (YTD, slicer context)?

Use `mcp__powerbi-modeling__measure_operations` to read existing measures from the live model before writing anything new.

### 0c — Audit Against WTW Standards

Check the HTML for drift from the design system. Flag and fix:

| Check | What to look for | Fix |
|-------|-----------------|-----|
| Brand color | Any purple that isn't `#7F35B2` (Corporate) or `#4f46e5` (Indigo) | Replace with correct var |
| Font | `Inter`, `Roboto`, `system-ui` only | Add `'Segoe UI',` as first font |
| KPI font size | Hero KPI < 24px | Bump to 24px / 700 |
| Shadows | Hard black shadows, or `rgba(0,0,0,0.08)` | Replace with token values |
| Hardcoded colors | Any hex in inline style that should be a variable | Move to DAX var block |
| Generic aesthetics | Centered layout, gradient banner, uniform rounded corners everywhere | Restructure if needed |

### 0d — Convert to DAX String

1. Paste the full DAX variable block (Step 2 below) at the top
2. Replace all hardcoded hex values with DAX variable references
3. Replace static placeholder text/numbers with `& [MeasureName] &` references
4. Move all static CSS into a `VAR _css = "<style>...</style>"` block
5. Keep inline `style=` only for values that change per row or per DAX calculation
6. End with `RETURN _css & _html`

---

## Step 1 — Palette Choice

Ask: **Corporate or Indigo?**

- **Corporate** — WTW brand-aligned. Use for executive dashboards and external-facing reports.
- **Indigo** — Modern operational palette. Use for internal sales, pipeline, and CRM reports.

Do not proceed until this is decided. The variable block in Step 2 depends on it.

---

## Step 2 — Paste the DAX Variable Block

Every HTML card measure starts with the full variable block. No exceptions. Copy the correct block below into the top of the measure before writing any HTML.

### Corporate Palette Variable Block

```dax
-- === WTW DESIGN VALUES (Corporate) ===
VAR _c1     = "#7F35B2"   -- WTW Corporate Purple (primary / outstanding)
VAR _c2     = "#059669"   -- Green (target met)
VAR _c3     = "#0891B2"   -- Cyan (near target)
VAR _c4     = "#F59E0B"   -- Amber (below target)
VAR _c5     = "#DC2626"   -- Red (critical)
VAR _cWon   = "#22C55E"   -- Won revenue
VAR _cOpen  = "#22D3EE"   -- Open est. revenue

VAR _textPrimary   = "#181B1D"
VAR _textSecondary = "#485257"
VAR _textTertiary  = "#606E74"
VAR _textMuted     = "#9CA3AF"

VAR _bgWhite      = "#FFFFFF"
VAR _bgLight      = "#F1F3F4"
VAR _bgAlt        = "#F7F8F8"
VAR _borderColor  = "#AEB8BD"
VAR _borderGrid   = "#E4E7E9"
VAR _borderHeader = "#C9D0D3"

VAR _shadowOuter = "0 10px 15px -3px rgba(0,0,0,0.1),0 4px 6px -2px rgba(0,0,0,0.05)"
VAR _shadowInner = "0 1px 3px 0 rgba(0,0,0,0.1),0 1px 2px 0 rgba(0,0,0,0.06)"
```

### Indigo Palette Variable Block

```dax
-- === WTW DESIGN VALUES (Indigo) ===
VAR _c1      = "#4f46e5"   -- Indigo (primary)
VAR _c2      = "#22D3EE"   -- Cyan
VAR _c3      = "#e5e7eb"   -- Light grey
VAR _c4      = "#f59e0b"   -- Amber
VAR _c5      = "#10b981"   -- Emerald
VAR _c6      = "#ef4444"   -- Red
VAR _c7      = "#8b5cf6"   -- Violet
VAR _c8      = "#f97316"   -- Orange
VAR _c9      = "#06b6d4"   -- Sky
VAR _c10     = "#84cc16"   -- Lime
VAR _c11     = "#ec4899"   -- Pink
VAR _c12     = "#14b8a6"   -- Teal
VAR _cFallbk = "#9CA3AF"   -- Fallback grey
VAR _cWon    = "#22C55E"   -- Won revenue
VAR _cOpen   = "#22D3EE"   -- Open est. revenue

VAR _textPrimary   = "#181B1D"
VAR _textSecondary = "#485257"
VAR _textTertiary  = "#606E74"
VAR _textMuted     = "#9CA3AF"

VAR _bgWhite      = "#FFFFFF"
VAR _bgLight      = "#F1F3F4"
VAR _bgAlt        = "#F7F8F8"
VAR _borderColor  = "#AEB8BD"
VAR _borderGrid   = "#E4E7E9"
VAR _borderHeader = "#C9D0D3"

VAR _shadowOuter = "0 10px 15px -3px rgba(0,0,0,0.1),0 4px 6px -2px rgba(0,0,0,0.05)"
VAR _shadowInner = "0 1px 3px 0 rgba(0,0,0,0.1),0 1px 2px 0 rgba(0,0,0,0.06)"
```

---

## Step 3 — Layout Mode

Pick one. The choice determines the card's root structure.

### A) Fixed Size

Use when: the visual frame is locked (e.g., a 500×270 scorecard, a 463×63 title bar).

```dax
-- Root element: explicit pixel dimensions
"<div style='width:500px;height:270px;font-family:Segoe UI,sans-serif;box-sizing:border-box;padding:16px;background:" & _bgWhite & ";border-radius:12px;box-shadow:" & _shadowOuter & ";'>"
```

### B) Auto-Scale (CSS Class approach)

Use when: the card should resize with the Power BI visual frame.

```dax
VAR _css =
"<style>" &
"html,body{margin:0;padding:0;width:100%;height:100%;overflow:hidden;}" &
"*{box-sizing:border-box;margin:0;padding:0;}" &
".wrap{width:100%;height:100vh;padding:6px 16px 24px 16px;}" &
".card{width:100%;height:100%;font-family:'Segoe UI',sans-serif;background:" & _bgWhite & ";border-radius:20px;" &
      "box-shadow:" & _shadowOuter & ";padding:16px;display:flex;flex-direction:column;overflow:hidden;}" &
"</style>"
```

**Rule**: Fixed sections → `flex-shrink:0`. Scrollable/expanding sections → `flex:1; min-height:0`.

---

## Step 4 — KPI Values

Standard sizes. Never deviate from these without a reason:

| Element | Font size | Weight | Color variable |
|---------|-----------|--------|----------------|
| Hero KPI (main number) | `24px` | `700` | `_textPrimary` |
| Large KPI (dashboard) | `36px` | `700` | `_textPrimary` or performance color |
| Section sub-value | `16px` | `700` | `_textPrimary` |
| KPI label | `12px` | `400` | `_textMuted` |
| Section heading | `13px` | `600` | `_textPrimary` |
| Body / row text | `12px` | `400` | `_textSecondary` |

---

## Step 5 — Shadow Values

Use the variables from Step 2. Never hard-code shadow values.

```dax
-- Outer container shadow
"box-shadow:" & _shadowOuter & ";"
-- = 0 10px 15px -3px rgba(0,0,0,0.1), 0 4px 6px -2px rgba(0,0,0,0.05)

-- Inner card / nested element shadow
"box-shadow:" & _shadowInner & ";"
-- = 0 1px 3px 0 rgba(0,0,0,0.1), 0 1px 2px 0 rgba(0,0,0,0.06)
```

Do not use `rgba(0,0,0,0.08)` or any other values — those have drifted from the token spec.

---

## Step 6 — Number Formatting

Use the standard formatter. Apply consistently to all currency values in the card.

```dax
-- Smart $K / $M formatter (positive values)
VAR _fmt =
    IF(_val >= 1E6, "$" & FORMAT(_val / 1E6, "0.#") & "M",
    IF(_val >= 1E3, "$" & FORMAT(_val / 1E3, "0.#") & "K",
        "$" & FORMAT(_val, "#,##0")))

-- Accounting format (positive → $X, negative → ($X))
VAR _fmtAcct =
    IF(_val >= 0,
        "$" & FORMAT(_val / 1E3, "0.0") & "K",
        "($" & FORMAT(ABS(_val) / 1E3, "0.0") & "K)")
```

---

## Step 7 — CSS Strategy

Follow this rule: **`<style>` block for all static classes; inline style only for DAX-dynamic values.**

| Use `<style>` class for | Use inline `style=` for |
|------------------------|------------------------|
| Layout structure, flex/grid | Colors from DAX variables |
| Hover states (`:hover` pseudo) | Widths/heights computed in DAX |
| Scrollbar styling | Dynamic `background`, `color`, `border-color` |
| Transitions and animations | Conditional `display:none/block` |
| Repeated typography rules | Any value that changes per row |

Always include the full CSS reset in the `<style>` block:

```css
*{box-sizing:border-box;margin:0;padding:0;}
html,body{margin:0;padding:0;width:100%;height:100%;overflow:hidden;}
```

---

## Step 8 — Final Verification Checklist

Before saving the measure:

- [ ] DAX variable block at the top (Step 2) — correct palette
- [ ] No hard-coded hex colors in HTML — all colors use `_c1`, `_textPrimary` etc.
- [ ] KPI font sizes follow Step 4 table (hero = 24px, not 20px)
- [ ] Shadow uses `_shadowOuter` / `_shadowInner` variables (not manual rgba values)
- [ ] Number formatting uses standard `$K/$M` formatter
- [ ] CSS reset `*{box-sizing:border-box;margin:0;padding:0}` present
- [ ] Wrapper padding accounts for shadow bleed (`padding:6px 16px 24px 16px`)
- [ ] Scrollable sections use `flex:1; min-height:0` (not fixed `height:`)
- [ ] Fixed sections use `flex-shrink:0`
- [ ] No emojis in measure name, comments, or labels (only in HTML output badges/icons if intended)
- [ ] Measure name follows `Title Case` convention

---

## Step 0c (addendum) — Never Change Colors Without Asking

**CRITICAL**: When adapting an existing HTML card (from Gemini or another source), do **not** change any color values — palette, performance colors, text hierarchy — without explicitly asking the user first. Present the existing colors, flag any drift from WTW standards, and wait for confirmation before substituting. This includes "outstanding" performance color: user may intentionally use a non-WTW color for a specific card.

---

## Quick Reference — Why These Rules Exist

| Rule | Reason |
|------|--------|
| Variable block at top | Without it, colors drift between measures — discovered when `#7C3AED` (wrong purple) was in several measures instead of `#7F35B2` |
| 24px KPI (not 20px) | `HTML_Revenue_By_Colleague` was built at 20px; `HTML_Pipeline_Breakdown` at 24px — fixed to 24px as standard |
| Token shadow values | Measures used `rgba(0,0,0,0.08)` instead of token `rgba(0,0,0,0.1)` — drift introduced during initial builds |
| `<style>` block over inline | Inline style cannot do `:hover`, `::-webkit-scrollbar`, or transitions — discovered when hover was needed on bar chart rows |
| Flex isolation on scroll | Without `min-height:0` on the scroll container, the flexbox overflow bug makes the card taller than its frame |
| Never change colors silently | `HTML_Executive_KPI_Card` had its outstanding color changed from `#7C3AED` to `#7F35B2` without asking — always flag and confirm first |

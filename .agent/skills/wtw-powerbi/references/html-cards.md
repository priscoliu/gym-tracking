# HTML Card Components (DAX-Generated)

Complete guide to creating professional HTML cards using DAX for Power BI reports. These components use HTML/CSS within DAX measures to create custom visualizations.

## Overview

HTML cards are created by:
1. Writing a DAX measure that returns HTML markup
2. Displaying the measure in a **Table visual** or **Card visual**
3. Enabling **HTML content** in Format pane → Values → Display units

**Benefits**:
- Full control over layout and styling
- Multi-layer shadows and gradients
- Performance-based dynamic coloring
- Responsive grid layouts
- Professional WTW branding

## Standard Container Structure

### Outer Container (Main Card Wrapper)

```dax
-- Container wrapper with premium shadow and gradient background
VAR _containerWidth = "580px"   -- 6-column grid width
VAR _containerHeight = "350px"  -- Standard executive summary height

VAR _containerHTML =
"<div style='
    width: " & _containerWidth & ";
    height: " & _containerHeight & ";
    padding: 20px;
    background: linear-gradient(145deg, #FFFFFF 0%, #F9FAFB 100%);
    border-radius: 12px;
    font-family: Segoe UI, Inter, system-ui, sans-serif;
    color: #111827;
    border: 1px solid #E5E7EB;
    box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
    box-sizing: border-box;
'>"
```

**Key Properties**:
- `width/height`: Use grid-aligned widths (268px, 364px, 580px, 796px, 1160px)
- `padding`: 20px standard padding
- `background`: Subtle gradient (white to light gray)
- `border-radius`: 12px for outer containers
- `box-shadow`: Multi-layer shadow for premium depth
- `box-sizing: border-box`: Ensures padding is included in width/height

### Inner Card (Nested Element)

```dax
-- Individual metric card with subtle shadow
VAR _innerCardHTML =
"<div style='
    background: #FFFFFF;
    padding: 12px;
    border-radius: 8px;
    border: 1px solid #F3F4F6;
    box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
    text-align: center;
'>"
```

**Key Properties**:
- `background`: Pure white (#FFFFFF)
- `padding`: 12px (smaller than outer container)
- `border-radius`: 8px (smaller than outer container)
- `box-shadow`: Subtle inner shadow

## Auto-Scale Layout (Responsive)

By default, cards use fixed pixel dimensions. For cards that should **fill and scale with the Power BI visual frame** when resized, use the auto-scale pattern instead.

**How it works:** `html/body` fill the iframe, a wrapper div absorbs shadow bleed via padding, and the card fills 100% of the remaining wrapper content area via flexbox.

```css
/* CSS block — use <style> tag approach (see Best Practices) */
html, body { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; }
*          { margin: 0; padding: 0; box-sizing: border-box; }  /* full reset — required */
.wrap      { width: 100%; height: 100vh; padding: 8px 28px 56px 28px; }
.sc        { width: 100%; height: 100%; display: flex; flex-direction: column; }
```

**Key rules:**
- `height: 100vh` on `.wrap` equals the visual frame height inside the Power BI iframe
- `width: 100%` on `.sc` stretches to fill the visual width automatically
- `height: 100%` on `.sc` fills the wrapper's content area (frame minus padding)
- `display: flex; flex-direction: column` on `.sc` enables vertical space distribution
- Fixed sections use `flex-shrink: 0` — they never compress
- Scrollable/expandable sections use `flex: 1; min-height: 0` — they absorb all remaining height

**Vertically stretching a section to fill remaining space:**
```css
.fixed-section  { flex-shrink: 0; }   /* header, KPI strip — never compress */
.flex-section   { flex: 1; display: flex; flex-direction: column; min-height: 0; }
.scrollable     { flex: 1; overflow-y: auto; min-height: 0; }
```

> **Note:** Remove any hardcoded `height` from the Power BI visual format pane — the card no longer needs it when using auto-scale.

---

## Shadow Clipping Prevention

Power BI clips HTML visual content at the visual's bounding box. `box-shadow` renders **outside** the element bounds, so deep shadows get hard-cropped by the frame edge.

**The fix:** wrap the card in a container whose padding gives the shadow room to bleed, keeping the shadow fully inside the visual frame.

**Shadow math:**
```
Shadow layer:   0  offset-y  blur  color
─────────────────────────────────────────
Layer 1:        0    2px      4px   rgba(0,0,0,.02)   →  ~6px  below element
Layer 2:        0    8px     16px   rgba(0,0,0,.04)   →  ~24px below element
Layer 3:        0   12px     20px   rgba(0,0,0,.05)   →  ~32px below element  ← deepest

Sides (no X offset, 20px blur):               →  ~16px left/right
```

**Wrapper padding formula:**
```
bottom padding ≥ max(offset-y) + max(blur)  →  12 + 20 = 32px → use 24px (shadow near-invisible at edge)
side padding   ≥ max(blur)                  →  20px → use 16px
top padding    = small safety margin        →  6px
```

**Standard wrapper for the WTW corporate shadow:**
```css
.wrap { padding: 6px 16px 24px 16px; }
```

> **Critical:** The `*{margin:0;padding:0}` CSS reset MUST cover all elements — not just `html,body`. Without it, browser defaults (e.g. `<ul>` gets `padding-left: 40px`) will misalign list-based content inside the card.

---

## Grid Layouts

### 4-Column Metrics Grid

```dax
VAR _gridHTML =
"<div style='
    display: grid;
    grid-template-columns: 1fr 1fr 1fr 1fr;
    gap: 12px;
    margin-bottom: 20px;
'>"
```

**Use case**: Four equal-width metric cards (e.g., Q1, Q2, Q3, Q4 results)

**Complete example**:
```dax
Quarterly Metrics Card =
VAR _containerHTML = "<div style='width: 580px; padding: 20px; background: #FFFFFF; border-radius: 12px;'>"
VAR _gridHTML = "<div style='display: grid; grid-template-columns: 1fr 1fr 1fr 1fr; gap: 12px;'>"

VAR _q1 = FORMAT([Q1 Sales], "$#,##0,K")
VAR _q2 = FORMAT([Q2 Sales], "$#,##0,K")
VAR _q3 = FORMAT([Q3 Sales], "$#,##0,K")
VAR _q4 = FORMAT([Q4 Sales], "$#,##0,K")

RETURN
    _containerHTML &
    _gridHTML &
    "<div style='text-align: center;'><div style='font-size: 12px; color: #6B7280;'>Q1</div><div style='font-size: 20px; font-weight: 700;'>" & _q1 & "</div></div>" &
    "<div style='text-align: center;'><div style='font-size: 12px; color: #6B7280;'>Q2</div><div style='font-size: 20px; font-weight: 700;'>" & _q2 & "</div></div>" &
    "<div style='text-align: center;'><div style='font-size: 12px; color: #6B7280;'>Q3</div><div style='font-size: 20px; font-weight: 700;'>" & _q3 & "</div></div>" &
    "<div style='text-align: center;'><div style='font-size: 12px; color: #6B7280;'>Q4</div><div style='font-size: 20px; font-weight: 700;'>" & _q4 & "</div></div>" &
    "</div></div>"
```

### 3-Column Metrics Grid

```dax
VAR _gridHTML =
"<div style='
    display: grid;
    grid-template-columns: 1fr 1fr 1fr;
    gap: 12px;
    margin-bottom: 20px;
'>"
```

**Use case**: Three equal-width metric cards (e.g., Actual, Target, Variance)

### 2-Column Layout

```dax
VAR _gridHTML =
"<div style='
    display: grid;
    grid-template-columns: 2fr 1fr;
    gap: 16px;
'>"
```

**Use case**: Main content (left, 2/3 width) + sidebar summary (right, 1/3 width)

## Progress Bar with Benchmark

### Basic Progress Bar

```dax
VAR _progressPercent = DIVIDE([Actual], [Target], 0)
VAR _progressWidthPercent = MIN(_progressPercent, 1) * 100
VAR _progressWidthCSS = FORMAT(_progressWidthPercent, "0.0") & "%"

VAR _progressBarHTML =
"<div style='
    width: 100%;
    height: 10px;
    background: #F1F5F9;
    border-radius: 5px;
    position: relative;
    overflow: hidden;
'>
    <div style='
        width: " & _progressWidthCSS & ";
        height: 100%;
        background: " & _gradientFill & ";
        border-radius: 5px;
        transition: width 1.2s ease-out;
    '></div>
</div>"
```

### Progress Bar with Benchmark Line

```dax
VAR _progressPercent = DIVIDE([Actual], [Max Value], 0)
VAR _progressWidthPercent = MIN(_progressPercent, 1) * 100
VAR _progressWidthCSS = FORMAT(_progressWidthPercent, "0.0") & "%"

VAR _benchmarkPercent = DIVIDE([Benchmark], [Max Value], 0)
VAR _benchmarkPositionPercent = _benchmarkPercent * 100
VAR _benchmarkPositionCSS = FORMAT(_benchmarkPositionPercent, "0.0") & "%"

VAR _progressBarHTML =
"<div style='
    width: 100%;
    height: 10px;
    background: #F1F5F9;
    border-radius: 5px;
    position: relative;
    overflow: visible;
'>
    <!-- Filled portion -->
    <div style='
        width: " & _progressWidthCSS & ";
        height: 100%;
        background: " & _gradientFill & ";
        border-radius: 5px;
        transition: width 1.2s ease-out;
    '></div>

    <!-- Benchmark line -->
    <div style='
        position: absolute;
        left: " & _benchmarkPositionCSS & ";
        top: -1px;
        bottom: -1px;
        width: 2px;
        background: #374151;
        border-radius: 2px;
        box-shadow: 0 0 4px rgba(55, 65, 81, 0.4);
    '></div>
</div>"
```

**Use case**: Show actual progress with a benchmark/target line (e.g., actual sales vs target)

## Status Badge (Top-Right Corner)

```dax
VAR _achievementRatio = DIVIDE([Actual], [Target], 0)

VAR _performanceLevel =
    SWITCH(
        TRUE(),
        _achievementRatio >= 1.15, "outstanding",
        _achievementRatio >= 1.0, "target_met",
        _achievementRatio >= 0.9, "near_target",
        _achievementRatio >= 0.8, "below_target",
        "critical"
    )

VAR _primaryColor =
    SWITCH(
        _performanceLevel,
        "outstanding", "#7C3AED",
        "target_met", "#059669",
        "near_target", "#0891B2",
        "below_target", "#F59E0B",
        "#DC2626"
    )

VAR _backgroundTint =
    SWITCH(
        _performanceLevel,
        "outstanding", "#F3F4F6",
        "target_met", "#ECFDF5",
        "near_target", "#F0F9FF",
        "below_target", "#FFFBEB",
        "#FEF2F2"
    )

VAR _statusIcon =
    SWITCH(
        _performanceLevel,
        "outstanding", "⭐",
        "target_met", "🎯",
        "near_target", "📈",
        "below_target", "⚠️",
        "🚨"
    )

VAR _statusText =
    SWITCH(
        _performanceLevel,
        "outstanding", "OUTSTANDING",
        "target_met", "ON TARGET",
        "near_target", "APPROACHING",
        "below_target", "BELOW TARGET",
        "CRITICAL"
    )

VAR _statusBadgeHTML =
"<div style='
    position: absolute;
    top: 16px;
    right: 16px;
    background: " & _backgroundTint & ";
    color: " & _primaryColor & ";
    padding: 6px 12px;
    border-radius: 8px;
    font-size: 8px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    border: 1px solid " & _primaryColor & "20;
'>" & _statusIcon & " " & _statusText & "</div>"
```

**Placement**: Use `position: absolute` on parent container, badge sits in top-right

## Summary Panel (Bottom Section)

```dax
VAR _summaryHTML =
"<div style='
    background: linear-gradient(135deg, " & _backgroundTint & " 0%, rgba(255,255,255,0.8) 100%);
    border: 1px solid " & _primaryColor & "25;
    border-radius: 8px;
    padding: 12px 16px;
    margin-top: 16px;
'>"
```

**Use case**: Bottom summary panel with gradient background and themed border

**Complete example**:
```dax
VAR _summaryHTML =
    "<div style='background: linear-gradient(135deg, #F3F4F6 0%, rgba(255,255,255,0.8) 100%); border: 1px solid #7C3AED25; border-radius: 8px; padding: 12px 16px;'>" &
    "<div style='display: flex; justify-content: space-between; align-items: center;'>" &
    "<div>" &
    "<div style='font-size: 10px; color: #6B7280; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px;'>Key Insight</div>" &
    "<div style='font-size: 12px; color: #1E293B; line-height: 1.4;'>Sales exceeded target by 15% driven by strong Q4 performance in APAC region.</div>" &
    "</div>" &
    "</div>" &
    "</div>"
```

## Typography Patterns

### Heading + Value + Label

```dax
VAR _headingHTML =
"<div style='
    font-size: 14px;
    font-weight: 600;
    color: #1E293B;
    margin-bottom: 8px;
'>Sales Performance</div>"

VAR _valueHTML =
"<div style='
    font-size: 36px;
    font-weight: 700;
    color: " & _primaryColor & ";
    line-height: 1;
    margin-bottom: 4px;
'>" & FORMAT([Sales Total], "$#,##0,K") & "</div>"

VAR _labelHTML =
"<div style='
    font-size: 12px;
    color: #6B7280;
    text-transform: uppercase;
    letter-spacing: 0.5px;
'>Total Sales</div>"
```

### Metric with Context (Value + Comparison)

```dax
VAR _actualValue = [Sales Total]
VAR _targetValue = [Sales Target]
VAR _variance = _actualValue - _targetValue
VAR _variancePct = DIVIDE(_variance, _targetValue, 0)

VAR _valueHTML =
"<div style='font-size: 30px; font-weight: 700; color: #1E293B;'>" & FORMAT(_actualValue, "$#,##0") & "</div>"

VAR _contextHTML =
"<div style='font-size: 12px; color: #6B7280; margin-top: 4px;'>" &
"Target: " & FORMAT(_targetValue, "$#,##0") & " " &
"<span style='color: " & _primaryColor & "; font-weight: 600;'>(" & FORMAT(_variancePct, "+0.0%;-0.0%") & ")</span>" &
"</div>"
```

## Complete Card Examples

### Sales Summary Card (Auto-Scale, Production Example)

This example shows the **complete workflow**: create base measures, create YTD measures, then create the HTML card that references them.

#### Step 1: Create Base Measures

```dax
// Core metric measures (in "Core Metrics" table)
Sales Total Premium = SUM(fact_sales[Premium])
Sales Commission = SUM(fact_sales[Commission])
Sales Policy Count = DISTINCTCOUNT(fact_sales[PolicyID])
Sales Quotes Count = DISTINCTCOUNT(fact_quotes[QuoteID])
```

#### Step 2: Create YTD Measures

**IMPORTANT**: YTD measures require a date table relationship. HTML cards should **always reference YTD/time-intelligence measures**, not base measures directly.

```dax
// YTD measures (in "Core Metrics" table, displayFolder: "SME Sales\YTD")
Sales Premium YTD = TOTALYTD([Sales Total Premium], dim_date[Date])
Sales Commission YTD = TOTALYTD([Sales Commission], dim_date[Date])
Sales Quotes YTD = TOTALYTD([Sales Quotes Count], dim_date[Date])
```

#### Step 3: Create HTML Card Measure

The card measure references the YTD measures created in Step 2:

```dax
Sales Summary Card =
// -- YTD measures (use these for the card) ----------------------------
VAR _totalPremiumYTD = [Sales Premium YTD]
VAR _commissionYTD   = [Sales Commission YTD]
VAR _quotesCountYTD  = [Sales Quotes YTD]

// -- Other measures ----------------------------------------------------
VAR _commPct        = [Sales Commission %]
VAR _policyCount    = [Sales Policy Count]
VAR _clientCount    = [Sales Client Count]
VAR _avgPremium     = [Sales Avg Premium]
VAR _nbMixPct       = [Sales NB Mix %]
VAR _premiumWTD     = [Sales Premium WTD]
VAR _quotesWTD      = [Sales Quotes WTD]

// -- Smart currency format (absolute) -----------------------------------
VAR _fmtTotal =
    IF( _totalPremiumYTD >= 1000000,
        "$" & FORMAT( _totalPremiumYTD / 1000000, "0.##" ) & "M",
    IF( _totalPremiumYTD >= 1000,
        "$" & FORMAT( _totalPremiumYTD / 1000, "0.#" ) & "K",
        "$" & FORMAT( _totalPremiumYTD, "#,##0" ) ) )

VAR _fmtComm =
    IF( _commissionYTD >= 1000000,
        "$" & FORMAT( _commissionYTD / 1000000, "0.##" ) & "M",
    IF( _commissionYTD >= 1000,
        "$" & FORMAT( _commissionYTD / 1000, "0.#" ) & "K",
        "$" & FORMAT( _commissionYTD, "#,##0" ) ) )

// ... (rest of formatting logic)

// -- CSS with auto-scale layout -----------------------------------------
VAR _css =
    "<style>"
    & "html,body{margin:0;padding:0;width:100%;height:100%;overflow:hidden}"
    & "*{margin:0;padding:0;box-sizing:border-box}"
    & ".wrap{width:100%;height:100vh;padding:6px 16px 24px 16px}"
    & ".sc{width:100%;height:100%;background:#fff;border-radius:20px;padding:32px;font-family:'Segoe UI',system-ui,sans-serif;box-shadow:0 2px 4px rgba(0,0,0,.02),0 8px 16px rgba(0,0,0,.04),0 12px 20px rgba(0,0,0,.05);display:flex;flex-direction:column}"
    & ".hdr{display:flex;justify-content:space-between;align-items:center;margin-bottom:24px;flex-shrink:0}"
    & "/* ... more CSS classes ... */"
    & "</style>"

// -- HTML ---------------------------------------------------------------
VAR _html =
    "<div class='wrap'><div class='sc'>"
    & "<div class='hdr'>"
      & "<div class='mg'>"
        & "<div>"
          & "<span class='mlb'>Sales YTD</span>"
          & "<div class='mv'>" & _fmtTotal & "</div>"
          & "<div class='md'>" & _arrow & _fmtWTD & " <span class='mper'>WTD</span></div>"
        & "</div>"
      & "</div>"
    & "</div>"
    & "<!-- ... more HTML ... -->"
    & "</div></div>"

RETURN _css & _html
```

**Key principle**: The HTML card measure should **only format and display** data. All calculation logic (YTD, WTD, ratios, etc.) should be in separate reusable measures.

### Executive Summary Card (6-column, 580px, Fixed Size)

```dax
Executive Summary Card =
VAR _actual = [Sales Total]
VAR _target = [Sales Target]
VAR _achievementRatio = DIVIDE(_actual, _target, 0)

-- Performance detection
VAR _performanceLevel =
    SWITCH(TRUE(), _achievementRatio >= 1.15, "outstanding", _achievementRatio >= 1.0, "target_met", _achievementRatio >= 0.9, "near_target", _achievementRatio >= 0.8, "below_target", "critical")

-- Colors
VAR _primaryColor = SWITCH(_performanceLevel, "outstanding", "#7C3AED", "target_met", "#059669", "near_target", "#0891B2", "below_target", "#F59E0B", "#DC2626")
VAR _backgroundTint = SWITCH(_performanceLevel, "outstanding", "#F3F4F6", "target_met", "#ECFDF5", "near_target", "#F0F9FF", "below_target", "#FFFBEB", "#FEF2F2")
VAR _gradientFill = SWITCH(_performanceLevel, "outstanding", "linear-gradient(135deg, #8B5CF6 0%, #7C3AED 100%)", "target_met", "linear-gradient(135deg, #10B981 0%, #059669 100%)", "near_target", "linear-gradient(135deg, #06B6D4 0%, #0891B2 100%)", "below_target", "linear-gradient(135deg, #FBBF24 0%, #F59E0B 100%)", "linear-gradient(135deg, #F87171 0%, #DC2626 100%)")

-- Metrics
VAR _progressPercent = MIN(_achievementRatio, 1)
VAR _progressWidthCSS = FORMAT(_progressPercent * 100, "0.0") & "%"
VAR _variance = _actual - _target
VAR _variancePct = DIVIDE(_variance, _target, 0)

-- Status badge
VAR _statusIcon = SWITCH(_performanceLevel, "outstanding", "⭐", "target_met", "🎯", "near_target", "📈", "below_target", "⚠️", "🚨")
VAR _statusText = SWITCH(_performanceLevel, "outstanding", "OUTSTANDING", "target_met", "ON TARGET", "near_target", "APPROACHING", "below_target", "BELOW TARGET", "CRITICAL")

RETURN
"<div style='width: 580px; height: 350px; padding: 20px; background: linear-gradient(145deg, #FFFFFF 0%, #F9FAFB 100%); border-radius: 12px; font-family: Segoe UI, system-ui, sans-serif; position: relative; border: 1px solid #E5E7EB; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05); box-sizing: border-box;'>" &

"<!-- Status Badge -->" &
"<div style='position: absolute; top: 16px; right: 16px; background: " & _backgroundTint & "; color: " & _primaryColor & "; padding: 6px 12px; border-radius: 8px; font-size: 8px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; border: 1px solid " & _primaryColor & "20;'>" & _statusIcon & " " & _statusText & "</div>" &

"<!-- Title -->" &
"<div style='font-size: 14px; font-weight: 600; color: #1E293B; margin-bottom: 16px;'>Sales Performance</div>" &

"<!-- Main Value -->" &
"<div style='font-size: 54px; font-weight: 700; color: " & _primaryColor & "; line-height: 1; margin-bottom: 8px;'>" & FORMAT(_actual, "$#,##0,,'M'") & "</div>" &

"<!-- Label -->" &
"<div style='font-size: 12px; color: #6B7280; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 20px;'>Total Sales</div>" &

"<!-- Progress Bar -->" &
"<div style='margin-bottom: 20px;'>" &
"<div style='display: flex; justify-content: space-between; margin-bottom: 8px;'>" &
"<div style='font-size: 11px; color: #6B7280;'>Achievement</div>" &
"<div style='font-size: 11px; font-weight: 600; color: " & _primaryColor & ";'>" & FORMAT(_achievementRatio, "0%") & "</div>" &
"</div>" &
"<div style='width: 100%; height: 10px; background: #F1F5F9; border-radius: 5px; overflow: hidden;'>" &
"<div style='width: " & _progressWidthCSS & "; height: 100%; background: " & _gradientFill & "; border-radius: 5px;'></div>" &
"</div>" &
"</div>" &

"<!-- Summary Panel -->" &
"<div style='background: linear-gradient(135deg, " & _backgroundTint & " 0%, rgba(255,255,255,0.8) 100%); border: 1px solid " & _primaryColor & "25; border-radius: 8px; padding: 12px 16px;'>" &
"<div style='display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 12px;'>" &
"<div style='text-align: center;'>" &
"<div style='font-size: 10px; color: #6B7280; margin-bottom: 4px;'>ACTUAL</div>" &
"<div style='font-size: 16px; font-weight: 700; color: #1E293B;'>" & FORMAT(_actual, "$#,##0,K") & "</div>" &
"</div>" &
"<div style='text-align: center;'>" &
"<div style='font-size: 10px; color: #6B7280; margin-bottom: 4px;'>TARGET</div>" &
"<div style='font-size: 16px; font-weight: 700; color: #1E293B;'>" & FORMAT(_target, "$#,##0,K") & "</div>" &
"</div>" &
"<div style='text-align: center;'>" &
"<div style='font-size: 10px; color: #6B7280; margin-bottom: 4px;'>VARIANCE</div>" &
"<div style='font-size: 16px; font-weight: 700; color: " & _primaryColor & ";'>" & FORMAT(_variancePct, "+0%;-0%") & "</div>" &
"</div>" &
"</div>" &
"</div>" &

"</div>"
```

## Best Practices

### HTML/CSS Guidelines

1. **Prefer `<style>` tag + CSS classes over inline styles** — The Power BI HTML visual is a full iframe; `<style>` tags work. CSS classes produce far shorter DAX strings, are easier to maintain, and enable pseudo-elements (`::-webkit-scrollbar`, `:hover`) that inline styles cannot do. Use inline styles only for dynamic DAX values (colors, widths, percentages).
2. **Always include a full CSS reset** — `*{margin:0;padding:0;box-sizing:border-box}` must cover `*`, not just `html,body`. Missing this causes browser defaults (e.g. `ul` indent) to misalign content.
3. **Close all tags** — HTML must be well-formed
4. **Use `box-sizing: border-box`** — Includes padding in width/height
5. **Test on different canvas sizes** — Use auto-scale layout for resizable visuals

### Performance Tips

1. **Minimize DAX complexity** — Pre-calculate values in variables
2. **Use FORMAT() for numbers** — Consistent formatting across cards
3. **Limit nested HTML** — Keep structure flat when possible
4. **Reuse color variables** — Define once, use multiple times
5. **Cache calculated fields** — Store repeated calculations in variables

### Accessibility

1. **Use semantic color coding** — Don't rely solely on color
2. **Include text labels** — Always pair icons with text
3. **Maintain contrast ratios** — Test with WebAIM Contrast Checker
4. **Use readable font sizes** — Minimum 12px for body text

## Checklist: HTML Card Implementation

Before deploying HTML cards, verify:
- [ ] CSS reset: `*{margin:0;padding:0;box-sizing:border-box}` covers ALL elements (not just `html,body`)
- [ ] All HTML tags properly closed
- [ ] Shadow clipping: wrapper padding ≥ shadow reach (`8px 28px 56px 28px` for WTW corporate shadow)
- [ ] Auto-scale: `html/body` at `100%`, `.wrap` at `100vh`, `.sc` at `width:100%;height:100%` if resizable
- [ ] Fixed sections: `flex-shrink:0` | Expanding sections: `flex:1;min-height:0`
- [ ] `<style>` tag used for static CSS classes; inline styles only for DAX-dynamic values
- [ ] Multi-layer shadows applied (outer + inner)
- [ ] Performance colors from standard palette
- [ ] Typography uses standard scale (12px → 72px)
- [ ] Text contrast meets WCAG AA (4.5:1)
- [ ] Numbers formatted consistently with smart FORMAT() (exact / K / M based on magnitude)
- [ ] DAX variables used to avoid recalculation

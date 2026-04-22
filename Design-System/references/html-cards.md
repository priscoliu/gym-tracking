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

### Sales Detail Table Card (Auto-Scale, Transaction List)

A professional transaction table with sticky header, WTW typography, and accessibility features. Ideal for showing recent sales, policies, or any row-level data with multiple columns.

**Features**:
- Auto-scale layout (fills visual frame)
- Sticky header that stays visible when scrolling
- Tabular numerals for perfect column alignment
- Text overflow handling (ellipsis for long names)
- Empty state messaging
- Full ARIA accessibility
- Hover and focus states
- Reduced motion support

**Data structure**: Works with any fact table containing transaction-level data.

```dax
Sales Detail Table Card =
VAR _maxRows = 15

-- Get top N rows from fact table, sorted by date
VAR _tableData =
    ADDCOLUMNS(
        TOPN(
            _maxRows,
            fact_sales,
            fact_sales[TransactionDate], DESC
        ),
        "@PolicyNum", fact_sales[PolicyNumber],
        "@ProductClass", fact_sales[ProductClass],
        "@InsuredName", fact_sales[InsuredName],
        "@Date", fact_sales[TransactionDate],
        "@BasePrem", fact_sales[BasePremium],
        "@TotalPrem", fact_sales[TotalPremium],
        "@Commission", fact_sales[Commission]
    )

VAR _rowCount = COUNTROWS(_tableData)

-- Build table rows using CONCATENATEX
VAR _tableRows =
    CONCATENATEX(
        _tableData,
        VAR _basePrem = [@BasePrem]
        VAR _totalPrem = [@TotalPrem]
        VAR _comm = [@Commission]
        VAR _dt = [@Date]
        VAR _insured = [@InsuredName]
        VAR _policy = [@PolicyNum]
        VAR _product = [@ProductClass]

        -- Format currency values
        VAR _fmtBase = IF(ISBLANK(_basePrem) || _basePrem = 0, "$0", "$" & FORMAT(_basePrem, "#,##0"))
        VAR _fmtTotal = IF(ISBLANK(_totalPrem) || _totalPrem = 0, "$0", "$" & FORMAT(_totalPrem, "#,##0"))
        VAR _fmtComm = IF(ISBLANK(_comm) || _comm = 0, "$0", "$" & FORMAT(_comm, "#,##0"))
        VAR _fmtDate = FORMAT(_dt, "DD-MMM-YY")

        RETURN
        "<tr>"
            & "<td class='name-cell'>"
                & "<div class='insured-name'>" & _insured & "</div>"
                & "<div class='policy-info'>" & _policy & " • " & _product & "</div>"
            & "</td>"
            & "<td class='date-cell'>" & _fmtDate & "</td>"
            & "<td class='num-cell'>" & _fmtBase & "</td>"
            & "<td class='num-cell'>" & _fmtTotal & "</td>"
            & "<td class='num-cell'>" & _fmtComm & "</td>"
        & "</tr>",
        "",           -- Empty delimiter for HTML rows
        [@Date], DESC -- Sort by date descending
    )

-- Calculate footer totals
VAR _totalBasePrem = SUMX(_tableData, [@BasePrem])
VAR _totalTotalPrem = SUMX(_tableData, [@TotalPrem])
VAR _totalComm = SUMX(_tableData, [@Commission])

VAR _fmtTotalBase = IF(_totalBasePrem = 0, "$0", "$" & FORMAT(_totalBasePrem, "#,##0"))
VAR _fmtTotalTotal = IF(_totalTotalPrem = 0, "$0", "$" & FORMAT(_totalTotalPrem, "#,##0"))
VAR _fmtTotalComm = IF(_totalComm = 0, "$0", "$" & FORMAT(_totalComm, "#,##0"))

RETURN
"<style>
/* Base wrapper - uses 4px grid system */
.sales-table-wrapper {
    font-family: 'Segoe UI', Inter, system-ui, sans-serif;
    padding: 20px;
    background: #FFFFFF;
    height: 100vh;
    box-sizing: border-box;
    overflow: hidden;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
}

/* Header - WTW --text-lg (18px) / 600 */
.table-header {
    font-size: 18px;
    font-weight: 600;
    color: #1E293B;
    margin-bottom: 16px;
    letter-spacing: -0.025em;
    line-height: 1.2;
}

/* Container with refined shadows */
.table-container {
    background: #FFFFFF;
    border-radius: 12px;
    border: 1px solid #E5E7EB;
    overflow: hidden;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04), 0 1px 2px rgba(0, 0, 0, 0.02);
    max-height: calc(100vh - 80px);
    overflow-y: auto;
}

.sales-table {
    width: 100%;
    border-collapse: collapse;
}

/* Sticky header with proper z-index layering */
.sales-table thead {
    position: sticky;
    top: 0;
    background: #FAFAFA;
    z-index: 10;
    box-shadow: 0 1px 0 #E5E7EB;
}

/* Column headers - WTW --text-xs (12px) / 600 */
.sales-table th {
    padding: 12px 16px;
    text-align: left;
    font-weight: 600;
    font-size: 12px;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    color: #6B7280;
    white-space: nowrap;
}

.sales-table th.num-col {
    text-align: right;
}

/* Body rows - smooth transitions */
.sales-table tbody tr {
    border-bottom: 1px solid #F3F4F6;
    transition: background-color 180ms ease-out;
    cursor: default;
}

.sales-table tbody tr:hover {
    background: #FAFAFA;
}

.sales-table tbody tr:focus-within {
    background: #F3F4F6;
    outline: 2px solid #7C3AED;
    outline-offset: -2px;
}

.sales-table tbody tr:last-child {
    border-bottom: none;
}

/* Name cell - refined spacing on 4px grid */
.name-cell {
    padding: 12px 16px;
    max-width: 300px;
}

/* Insured name - WTW --text-sm (14px) / 600 */
.insured-name {
    font-weight: 600;
    font-size: 14px;
    color: #1E293B;
    margin-bottom: 4px;
    line-height: 1.4;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

/* Policy info - WTW --text-xs (12px) / 400 */
.policy-info {
    font-size: 12px;
    font-weight: 400;
    color: #6B7280;
    line-height: 1.4;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

/* Date and number cells - WTW --text-sm (14px) / 400 */
.date-cell {
    padding: 12px 16px;
    font-size: 14px;
    font-weight: 400;
    color: #4B5563;
    white-space: nowrap;
    font-variant-numeric: tabular-nums;
}

.num-cell {
    padding: 12px 16px;
    text-align: right;
    font-size: 14px;
    font-weight: 400;
    font-variant-numeric: tabular-nums;
    color: #4B5563;
    white-space: nowrap;
}

/* Footer - refined with proper hierarchy */
.table-footer {
    background: #FAFAFA;
    border-top: 2px solid #7C3AED;
}

/* Footer label - WTW --text-sm (14px) / 600 */
.table-footer td {
    padding: 16px;
    font-weight: 600;
    font-size: 14px;
    color: #1E293B;
}

/* Footer values - WTW --text-lg (18px) / 700 for emphasis */
.table-footer .num-cell {
    font-size: 18px;
    font-weight: 700;
    color: #7C3AED;
}

/* Refined scrollbar - macOS style */
.table-container::-webkit-scrollbar {
    width: 10px;
}

.table-container::-webkit-scrollbar-track {
    background: transparent;
}

.table-container::-webkit-scrollbar-thumb {
    background: rgba(0, 0, 0, 0.12);
    border-radius: 6px;
    border: 2px solid #FFFFFF;
}

.table-container::-webkit-scrollbar-thumb:hover {
    background: rgba(0, 0, 0, 0.18);
}

/* Empty state - graceful handling */
.empty-state {
    padding: 48px 24px;
    text-align: center;
    color: #6B7280;
    font-size: 14px;
}

/* Reduced motion support */
@media (prefers-reduced-motion: reduce) {
    .sales-table tbody tr {
        transition: none;
    }
}

/* High contrast mode support */
@media (prefers-contrast: high) {
    .sales-table thead {
        border-bottom: 2px solid currentColor;
    }
    .table-container {
        border-width: 2px;
    }
}
</style>

<div class='sales-table-wrapper' role='region' aria-label='Recent Sales Transactions'>
    <div class='table-header'>Recent Transactions</div>
    <div class='table-container'>"
        & IF(
            _rowCount = 0,
            "<div class='empty-state'>No transactions found</div>",
            "<table class='sales-table' role='table'>
                <thead>
                    <tr role='row'>
                        <th role='columnheader'>Insured / Policy</th>
                        <th role='columnheader'>Date</th>
                        <th class='num-col' role='columnheader'>Base Premium</th>
                        <th class='num-col' role='columnheader'>Total Premium</th>
                        <th class='num-col' role='columnheader'>Commission</th>
                    </tr>
                </thead>
                <tbody>"
                & _tableRows
                & "</tbody>
                <tfoot class='table-footer'>
                    <tr role='row'>
                        <td colspan='2'>Total (" & _rowCount & " transactions)</td>
                        <td class='num-cell'>" & _fmtTotalBase & "</td>
                        <td class='num-cell'>" & _fmtTotalTotal & "</td>
                        <td class='num-cell'>" & _fmtTotalComm & "</td>
                    </tr>
                </tfoot>
            </table>"
        )
        & "</div>
</div>"
```

**Customization guide**:
- **Row limit**: Change `_maxRows` variable (default: 15)
- **Columns**: Modify ADDCOLUMNS to match your fact table structure
- **Header labels**: Update `<th>` text in thead
- **Date format**: Change `FORMAT(_dt, "DD-MMM-YY")` to your preferred format
- **Footer totals**: Add/remove columns as needed
- **Empty state**: Customize message in `<div class='empty-state'>`

**Typography compliance**:
- Header: 18px/600 (--text-lg)
- Column headers: 12px/600 UPPERCASE (--text-xs)
- Primary text: 14px/600 (--text-sm)
- Secondary text: 12px/400 (--text-xs)
- Body cells: 14px/400 (--text-sm)
- Footer totals: 18px/700 (--text-lg) - emphasized

**Key features**:
- `font-variant-numeric: tabular-nums` ensures perfect column alignment
- `text-overflow: ellipsis` handles very long names gracefully
- `position: sticky` on thead keeps headers visible when scrolling
- `role` attributes provide full accessibility for screen readers
- Footer shows row count for context (e.g., "Total (15 transactions)")

---

## Catalogue Patterns

Production patterns extracted from asset files. Use these as starting points — copy the structural approach, swap in your measures and field names.

---

### Tile with Values Breakdown

**Asset**: `assets/titles/leads-overview.dax` · **Dimensions**: 463×63px (fixed)

Replace a plain Power BI text title visual with a compact header that shows the page title plus inline metric pills. The fixed height keeps it anchored to the page layout without scrolling.

**Key techniques:**
- `SELECTEDVALUE(DimDate[Calendar Year], "All Years")` — context-aware period label that adapts to slicer selection
- Metric pills use `font-weight:600; color:_highlightColor` inline, separated by pipe `|` characters
- Fixed `width:463px; height:63px` — size must match the Power BI visual frame exactly
- `overflow:hidden` prevents content bleed if the measure returns more text than expected

```dax
Tile_Example =
VAR _highlightColor = "#7F35B2"    -- WTW Corporate Purple
VAR _textPrimary    = "#374151"
VAR _textSecondary  = "#6B7280"

VAR _selectedYear = SELECTEDVALUE('DimDate'[Calendar Year], "All Years")

-- Metric values (reference your measures here)
VAR _total    = [Total Count]
VAR _open     = [Open Count]
VAR _fmtTotal = IF(_total >= 1000, FORMAT(_total / 1000, "#,0.0") & "K", FORMAT(_total, "#,0"))
VAR _fmtOpen  = IF(_open  >= 1000, FORMAT(_open  / 1000, "#,0.0") & "K", FORMAT(_open,  "#,0"))

RETURN
"<div style='width:463px;height:63px;font-family:Segoe UI,sans-serif;display:flex;flex-direction:column;box-sizing:border-box;overflow:hidden;'>" &
  "<div style='padding:8px 16px 6px 16px;'>" &
    "<div style='font-size:16px;font-weight:700;color:" & _textPrimary & ";'>Page Title</div>" &
    "<div style='font-size:11px;color:" & _textSecondary & ";line-height:1.3;margin-top:2px;'>" &
      "<span style='font-weight:600;'>In " & _selectedYear & ":</span> " &
      "<span style='color:" & _highlightColor & ";font-weight:600;'>" & _fmtTotal & "</span> total | " &
      "<span style='color:" & _highlightColor & ";font-weight:600;'>" & _fmtOpen  & "</span> open" &
    "</div>" &
  "</div>" &
"</div>"
```

---

### Cluster Bar Chart Design

**Asset**: `assets/charts/top30-won-client-chart.dax` · **Dimensions**: auto-scale

Rank-ordered horizontal bar chart. Bars are proportional to the max value in the dataset. Works for any top-N ranking — clients, products, regions. Requires the `<style>` tag approach (CSS pseudo-classes can't be done inline).

**Key techniques:**
- `RANKX(ALL(Table[Field]), CALCULATE([Measure]), , DESC, DENSE)` — ranks all rows across filter context
- `FILTER(..., [@Rank] <= 30 && [@Value] > 0)` — top-N guard, excludes zeroes
- `DIVIDE(_rev, _maxRevenue) * 100` — bar width as percentage of max, always 0–100%
- `.bar-row:hover` CSS class changes bar color and value color — impossible without `<style>` tag

```dax
Chart_Example =
VAR _primaryColor    = "#94A3B8"   -- Neutral slate bars (no palette competition with main card)
VAR _hoverColor      = "#475569"
VAR _hoverValueColor = "#10B981"
VAR _barBg           = "#E5E7EB"
VAR _textPrimary     = "#374151"
VAR _textSecondary   = "#6B7280"

VAR _data =
    ADDCOLUMNS(
        VALUES(Table[Name]),
        "@Value", CALCULATE([Your Measure]),
        "@Rank",  RANKX(ALL(Table[Name]), CALCULATE([Your Measure]), , DESC, DENSE)
    )

VAR _topN    = FILTER(_data, [@Rank] <= 30 && [@Value] > 0)
VAR _maxVal  = MAXX(_topN, [@Value])

VAR _styles =
    "<style>" &
    ".bar-row { transition: all 0.2s ease; }" &
    ".bar-row:hover { background:#F8FAFC; border-radius:4px; margin-left:-4px; margin-right:-4px; padding-left:4px; padding-right:4px; }" &
    ".bar-row:hover .bar-fill { background:" & _hoverColor & " !important; }" &
    ".bar-row:hover .val-txt { color:" & _hoverValueColor & " !important; font-weight:700 !important; }" &
    ".bar-fill { transition: all 0.2s ease; }" &
    ".val-txt  { transition: all 0.2s ease; }" &
    ".sc { scrollbar-width:thin; scrollbar-color:#D1D5DB transparent; }" &
    ".sc::-webkit-scrollbar { width:4px; }" &
    ".sc::-webkit-scrollbar-thumb { background:#D1D5DB; border-radius:2px; }" &
    "</style>"

VAR _rows =
    CONCATENATEX(
        _topN,
        VAR _name = Table[Name]
        VAR _val  = [@Value]
        VAR _pct  = FORMAT(DIVIDE(_val, _maxVal) * 100, "0.0")
        VAR _fmt  = IF(_val >= 1E6, FORMAT(_val/1E6,"#,0.0M"), IF(_val >= 1E3, FORMAT(_val/1E3,"#,0.0K"), FORMAT(_val,"#,0")))
        RETURN
        "<div class='bar-row' style='margin-bottom:10px;'>" &
          "<div style='display:flex;justify-content:space-between;margin-bottom:3px;'>" &
            "<span style='font-size:10px;color:" & _textPrimary & ";overflow:hidden;text-overflow:ellipsis;max-width:70%;'>" & _name & "</span>" &
            "<span class='val-txt' style='font-size:10px;color:" & _textSecondary & ";font-weight:600;'>" & _fmt & "</span>" &
          "</div>" &
          "<div style='height:5px;background:" & _barBg & ";border-radius:3px;overflow:hidden;'>" &
            "<div class='bar-fill' style='height:100%;width:" & _pct & "%;background:" & _primaryColor & ";border-radius:3px;'></div>" &
          "</div>" &
        "</div>",
        "",
        [@Rank], ASC
    )

RETURN
_styles &
"<div class='sc' style='width:100%;height:100%;padding:10px 14px;box-sizing:border-box;font-family:Segoe UI,sans-serif;overflow-y:auto;'>" &
  _rows &
"</div>"
```

**Customization**: Change `<= 30` to any N. Change `_primaryColor` to match your card's palette.

---

### Two-Zone Layout (Light Top + Dark Panel)

**Asset**: `assets/cards/zest-card-2-hierarchy.dax` · **Dimensions**: auto-scale

Splits the card into a light upper section (primary KPI + context detail) and a dark lower panel (`#212836`) for secondary/operational data. The dark zone uses `flex:1; min-height:0` to absorb all remaining height.

**Key techniques:**
- `.top { flex-shrink:0 }` — light zone stays fixed height, never compresses
- `.btm { flex:1; min-height:0 }` — dark zone fills all remaining vertical space
- Dark zone has its own typography tokens: `#FFFFFF` headings, `#D1D5DB` labels, `#8B95A5` muted
- Status mini-bars: `SUMMARIZE` + `CONCATENATEX` on a status field, color-coded dot per status
- `grid-template-columns:1fr 1fr 1fr` summary tiles anchored at bottom with `margin-top:auto`
- Dynamic badge: `_badgeBg / _badgeTxt / _badgeLabel` driven by severity (critical > elevated > open > clear)

```dax
-- Two-zone structure (CSS class approach)
VAR _css =
"<style>" &
"html,body{margin:0;padding:0;width:100%;height:100%;overflow:hidden;}" &
"*{box-sizing:border-box;margin:0;padding:0;}" &
".wrap{width:100%;height:100vh;padding:6px 16px 24px 16px;}" &
".card{width:100%;height:100%;font-family:'Segoe UI',sans-serif;background:#FFFFFF;border-radius:20px;" &
      "box-shadow:0 10px 15px -3px rgba(0,0,0,.1),0 4px 6px -2px rgba(0,0,0,.05);padding:16px;" &
      "display:flex;flex-direction:column;gap:10px;overflow:hidden;}" &
-- TOP ZONE (light)
".top{flex-shrink:0;}" &
-- BOTTOM ZONE (dark)
".btm{flex:1;min-height:0;background:#212836;border-radius:14px;padding:12px 14px;display:flex;flex-direction:column;}" &
".bttl{font-size:13px;font-weight:600;color:#FFFFFF;}" &
".bsub{font-size:11px;color:#8B95A5;}" &
-- Summary tiles anchored to bottom of dark zone
".grid3{display:grid;grid-template-columns:1fr 1fr 1fr;gap:6px;margin-top:auto;}" &
".tile{background:#F6F4EE;padding:8px 10px;border-radius:8px;}" &
".tlbl{font-size:10px;color:#6B7280;margin-bottom:3px;}" &
".tval{font-size:16px;font-weight:700;color:#1E2536;}" &
"</style>"

VAR _html =
"<div class='wrap'><div class='card'>" &
-- Light top zone
"<div class='top'>... KPI + detail box ...</div>" &
-- Dark bottom zone
"<div class='btm'>" &
  "<div class='bttl'>Section Title</div>" &
  "<!-- status rows, delivery rows -->" &
  "<div class='grid3'>" &
    "<div class='tile'><div class='tlbl'>Metric A</div><div class='tval'>" & _valA & "</div></div>" &
    "<div class='tile'><div class='tlbl'>Metric B</div><div class='tval'>" & _valB & "</div></div>" &
    "<div class='tile'><div class='tlbl'>Metric C</div><div class='tval'>" & _valC & "</div></div>" &
  "</div>" &
"</div>" &
"</div></div>"
```

**Status row pattern** (colored dot + label + count + mini bar):
```dax
VAR _statusRows =
    CONCATENATEX(
        ADDCOLUMNS(
            SUMMARIZE(FactTable, FactTable[Status]),
            "_cnt",  CALCULATE(COUNTROWS(FactTable)),
            "_sort", SWITCH(FactTable[Status], "Open", 1, "Closed", 2, 99),
            "_clr",  SWITCH(FactTable[Status], "Open", "#F59E0B", "Closed", "#22C55E", "#8B95A5"),
            "_pct",  FORMAT(CONVERT(DIVIDE(CALCULATE(COUNTROWS(FactTable)), IF(_total > 0, _total, 1)) * 100, INTEGER), "0")
        ),
        "<div style='margin-bottom:6px;'>" &
          "<div style='display:flex;justify-content:space-between;align-items:center;margin-bottom:3px;'>" &
            "<div style='display:flex;align-items:center;gap:6px;'>" &
              "<div style='width:7px;height:7px;border-radius:50%;background:" & [_clr] & ";'></div>" &
              "<span style='font-size:12px;color:#D1D5DB;'>" & FactTable[Status] & "</span>" &
            "</div>" &
            "<span style='font-size:13px;font-weight:700;color:#FFFFFF;'>" & FORMAT([_cnt], "#,##0") & "</span>" &
          "</div>" &
          "<div style='height:3px;background:#384661;border-radius:2px;'>" &
            "<div style='height:100%;width:" & [_pct] & "%;background:" & [_clr] & ";border-radius:2px;'></div>" &
          "</div>" &
        "</div>",
        "",
        [_sort]
    )
```

---

### Performance-Tinted Insight Panel

**Asset**: `assets/cards/pipeline-health-scorecard.dax` · **Dimensions**: 500×270px (fixed)

3-metric KPI grid with a dynamic insight panel whose background tint and text change based on which metric is weakest. Ideal for pipeline health, goal tracking, or any multi-KPI status card.

**Key techniques:**
- 5-level performance detection per metric: `SWITCH(TRUE(), ratio >= 1.15, "outstanding", ...)`
- **Insight text is dynamic**: pre-written strings chosen by `SWITCH` based on which metric falls below threshold
- `background` of insight panel is the tint color of the worst-performing metric
- MoM delta arrows: `IF(_change >= 0, "▲", "▼")` + color `#22C55E` / `#EF4444`
- Fixed pixel dimensions — set Power BI visual to exactly `500×270` and lock aspect ratio

```dax
-- Performance detection (run for each metric)
VAR _ratio = DIVIDE(_actual, _target, 0)

VAR _level =
    SWITCH(TRUE(),
        _ratio >= 1.15, "outstanding",
        _ratio >= 1.0,  "target_met",
        _ratio >= 0.9,  "near_target",
        _ratio >= 0.8,  "below_target",
        "critical"
    )

VAR _color =
    SWITCH(_level,
        "outstanding", "#7F35B2",
        "target_met",  "#22C55E",
        "near_target", "#0891B2",
        "below_target","#F59E0B",
                       "#DC2626"
    )

VAR _tint =
    SWITCH(_level,
        "outstanding", "#F5F0FB",
        "target_met",  "#ECFDF5",
        "near_target", "#F0F9FF",
        "below_target","#FFFBEB",
                       "#FEF2F2"
    )

-- Dynamic insight: pick the most important observation
VAR _worstLevel = ... -- compare all metric levels, return the worst
VAR _insightText =
    SWITCH(_worstLevel,
        "critical",     "Pipeline is critically short. Immediate action required to close gap.",
        "below_target", "Pipeline below target. Focus on converting open opportunities.",
        "near_target",  "Pipeline approaching target. Monitor momentum closely.",
                        "Pipeline on track. Continue current activity levels."
    )

-- Insight panel (tinted by worst metric)
VAR _insightPanel =
    "<div style='background:" & _worstTint & ";border-radius:8px;padding:10px 12px;margin-top:8px;'>" &
      "<div style='font-size:9px;text-transform:uppercase;letter-spacing:0.5px;color:" & _worstColor & ";font-weight:700;margin-bottom:4px;'>Insight</div>" &
      "<div style='font-size:11px;color:#374151;line-height:1.5;'>" & _insightText & "</div>" &
    "</div>"
```

**3-metric KPI grid structure:**
```dax
"<div style='display:grid;grid-template-columns:1fr 1fr 1fr;gap:8px;'>" &
  "<div style='text-align:center;padding:8px;background:#F9FAFB;border-radius:8px;'>" &
    "<div style='font-size:9px;color:#9CA3AF;text-transform:uppercase;letter-spacing:0.5px;margin-bottom:4px;'>Metric A</div>" &
    "<div style='font-size:22px;font-weight:700;color:" & _colorA & ";'>" & _fmtA & "</div>" &
    "<div style='font-size:10px;color:" & IF(_changeA >= 0, "#22C55E", "#EF4444") & ";margin-top:2px;'>" &
      IF(_changeA >= 0, "▲", "▼") & " " & FORMAT(ABS(_changeA), "0.0%") & " MoM" &
    "</div>" &
  "</div>" &
  "... repeat for B and C ..." &
"</div>"
```

---

### Sticky Matrix with JS Pagination

**Asset**: `assets/tables/html-client-matrix.dax` · **Dimensions**: auto-scale

A two-level grouped table (Group → Client) with sticky headers and client-side JS pagination. `rowspan` collapses repeated group values into a single merged cell. Pagination is a `<script>` block embedded in the DAX string — no server round-trips.

**Key techniques:**
- 3-level `CONCATENATEX`: outer (groups) → inner (clients within group) → innermost (LoB values per client)
- `rowspan` on group cell: only the first client row of each group renders the group cell, subsequent rows omit it
- `<script>` tag injected via DAX string: sets `display:none` on rows outside current page range, updates page indicator text
- Sticky header: `position:sticky; top:0; z-index:10` on `<thead>`
- Sort order on `SUMMARIZE` result uses an additional `_sort` column in `ADDCOLUMNS`

```dax
-- Group-level outer loop
VAR _groups =
    ADDCOLUMNS(
        SUMMARIZE(FactTable, DimGroup[GroupName]),
        "_sort", MIN(DimGroup[SortOrder]),
        "_clientCount", CALCULATE(DISTINCTCOUNT(DimClient[ClientID]))
    )

VAR _tableRows =
    CONCATENATEX(
        _groups,
        -- Client-level inner loop
        VAR _groupName = DimGroup[GroupName]
        VAR _clients =
            ADDCOLUMNS(
                CALCULATETABLE(SUMMARIZE(FactTable, DimClient[ClientName]), DimGroup[GroupName] = _groupName),
                "_isFirst", 1   -- mark first client per group for rowspan logic
            )
        VAR _clientCount = COUNTROWS(_clients)
        VAR _clientRows =
            CONCATENATEX(
                _clients,
                VAR _isFirst    = [@_isFirst]
                VAR _clientName = DimClient[ClientName]
                RETURN
                -- Group cell only on first client row
                "<tr>" &
                IF(_isFirst = 1,
                    "<td rowspan='" & _clientCount & "' style='...'>" & _groupName & "</td>",
                    ""   -- empty string omits the cell on subsequent rows
                ) &
                "<td style='...'>" & _clientName & "</td>" &
                -- LoB value columns ...
                "</tr>",
                "",
                DimClient[ClientName], ASC
            )
        RETURN _clientRows,
        "",
        [_sort], ASC
    )

-- Pagination script (inject after table, before closing </div>)
VAR _pageScript =
    "<script>" &
    "var pg=1,rpp=30;" &
    "function showPage(p){" &
      "var rows=document.querySelectorAll('tr.data-row');" &
      "var s=(p-1)*rpp,e=s+rpp;" &
      "rows.forEach(function(r,i){r.style.display=i>=s&&i<e?'':'none';});" &
      "document.getElementById('pg-indicator').textContent='Page '+p+' of '+Math.ceil(rows.length/rpp);" &
      "pg=p;" &
    "}" &
    "showPage(1);" &
    "</script>"
```

**Important**: Assign class `data-row` to every `<tr>` in tbody so the pagination script can target them.

---



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

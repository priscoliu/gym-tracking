# WTW Component Library

Extended HTML component patterns for WTW-branded Power BI reports and standalone dashboards.

All components assume WTW design tokens. For DAX measures, use inline styles. For standalone HTML, use CSS variables from [tokens.md](tokens.md).

## Table of Contents
1. [Page Header](#page-header)
2. [Navigation Bar](#navigation-bar)
3. [Section Divider](#section-divider)
4. [Filter Panel](#filter-panel)
5. [Data Table](#data-table)
6. [Alert Banner](#alert-banner)
7. [Loading Skeleton](#loading-skeleton)
8. [Tooltip](#tooltip)
9. [Trend Indicator](#trend-indicator)
10. [Icon Badge](#icon-badge)
11. [Comparison Row](#comparison-row)
12. [Multi-KPI Strip](#multi-kpi-strip)

---

## Page Header

Full-width report header with logo zone, title, and date context.

```dax
Page Header =
VAR _reportTitle = "Sales Performance Dashboard"
VAR _periodLabel = SELECTEDVALUE('Date'[FiscalYearLabel], "All Periods")
VAR _refreshDate = FORMAT(TODAY(), "DD MMM YYYY")

RETURN
"<div style='
    width: 1160px;
    padding: 16px 24px;
    background: linear-gradient(135deg, #7C3AED 0%, #6D28D9 100%);
    border-radius: 12px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-family: Segoe UI, system-ui, sans-serif;
    box-shadow: 0 4px 12px rgba(124,58,237,0.3);
'>" &

"<div>" &
"<div style='font-size: 11px; color: rgba(255,255,255,0.7); text-transform: uppercase; letter-spacing: 1px; margin-bottom: 4px;'>WTW</div>" &
"<div style='font-size: 22px; font-weight: 700; color: #FFFFFF;'>" & _reportTitle & "</div>" &
"</div>" &

"<div style='text-align: right;'>" &
"<div style='font-size: 18px; font-weight: 600; color: #FFFFFF;'>" & _periodLabel & "</div>" &
"<div style='font-size: 11px; color: rgba(255,255,255,0.6); margin-top: 2px;'>Refreshed " & _refreshDate & "</div>" &
"</div>" &

"</div>"
```

---

## Navigation Bar

Horizontal tab-style navigation for multi-section reports (use with bookmarks).

```html
<!-- Standalone HTML version -->
<nav style="
    display: flex;
    gap: 4px;
    padding: 4px;
    background: #F3F4F6;
    border-radius: 10px;
    width: fit-content;
">
  <button style="padding: 8px 16px; border-radius: 8px; border: none; background: #7C3AED; color: #fff; font-weight: 600; font-size: 14px; cursor: pointer;">Overview</button>
  <button style="padding: 8px 16px; border-radius: 8px; border: none; background: transparent; color: #6B7280; font-size: 14px; cursor: pointer;">By Region</button>
  <button style="padding: 8px 16px; border-radius: 8px; border: none; background: transparent; color: #6B7280; font-size: 14px; cursor: pointer;">Detail</button>
</nav>
```

**Power BI implementation**: Use native Button visuals styled with WTW brand colors. Apply bookmarks for page navigation. Do NOT replicate in DAX HTML — native buttons are more accessible.

---

## Section Divider

Visual separator between report sections, with optional label.

```dax
Section Divider =
VAR _label = "Regional Breakdown"
RETURN
"<div style='
    display: flex;
    align-items: center;
    gap: 12px;
    margin: 4px 0;
    font-family: Segoe UI, system-ui, sans-serif;
'>" &
"<div style='flex: 1; height: 1px; background: #E5E7EB;'></div>" &
"<div style='font-size: 11px; font-weight: 600; color: #6B7280; text-transform: uppercase; letter-spacing: 1px; white-space: nowrap;'>" & _label & "</div>" &
"<div style='flex: 1; height: 1px; background: #E5E7EB;'></div>" &
"</div>"
```

---

## Filter Panel

Compact display of active filter selections. Place at top of report near slicers.

```dax
Active Filters =
VAR _period   = SELECTEDVALUE('Date'[FiscalYearLabel], "All Years")
VAR _region   = SELECTEDVALUE(Dim_Region[RegionName], "All Regions")
VAR _product  = SELECTEDVALUE(Dim_Product[ProductName], "All Products")

RETURN
"<div style='
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
    font-family: Segoe UI, system-ui, sans-serif;
    align-items: center;
'>" &
"<div style='font-size: 11px; color: #9CA3AF; text-transform: uppercase; letter-spacing: 0.5px;'>Filters:</div>" &

-- Render each filter chip
"<div style='padding: 4px 10px; background: #F5F3FF; border: 1px solid #7C3AED25; border-radius: 99px; font-size: 12px; font-weight: 600; color: #7C3AED;'>" & _period & "</div>" &
"<div style='padding: 4px 10px; background: #F9FAFB; border: 1px solid #E5E7EB; border-radius: 99px; font-size: 12px; color: #4B5563;'>" & _region & "</div>" &
"<div style='padding: 4px 10px; background: #F9FAFB; border: 1px solid #E5E7EB; border-radius: 99px; font-size: 12px; color: #4B5563;'>" & _product & "</div>" &

"</div>"
```

---

## Data Table

Clean WTW-branded table with alternating rows and performance-colored cells.

```dax
Summary Table =
-- Build table rows from a summarized measure
VAR _tableData = SUMMARIZE(
    Fact_Sales,
    Dim_Region[RegionName],
    "Actual", [Sales Total],
    "Target", [Sales Target],
    "Ratio", DIVIDE([Sales Total], [Sales Target], 0)
)

VAR _headerRow =
"<tr style='background: #F9FAFB;'>" &
"<th style='padding: 10px 12px; text-align: left; font-size: 12px; font-weight: 600; color: #1E293B; border-bottom: 2px solid #E5E7EB;'>Region</th>" &
"<th style='padding: 10px 12px; text-align: right; font-size: 12px; font-weight: 600; color: #1E293B; border-bottom: 2px solid #E5E7EB;'>Actual</th>" &
"<th style='padding: 10px 12px; text-align: right; font-size: 12px; font-weight: 600; color: #1E293B; border-bottom: 2px solid #E5E7EB;'>Target</th>" &
"<th style='padding: 10px 12px; text-align: right; font-size: 12px; font-weight: 600; color: #1E293B; border-bottom: 2px solid #E5E7EB;'>Achiev.</th>" &
"</tr>"

VAR _rows = CONCATENATEX(
    _tableData,
    VAR _ratio  = [Ratio]
    VAR _color  = SWITCH(TRUE(), _ratio >= 1.15, "#7C3AED", _ratio >= 1.0, "#059669", _ratio >= 0.9, "#0891B2", _ratio >= 0.8, "#F59E0B", "#DC2626")
    VAR _bg     = IF(MOD(RANKX(_tableData, [Actual],, DESC, DENSE), 2) = 0, "#F9FAFB", "#FFFFFF")
    RETURN
    "<tr style='background: " & _bg & ";'>" &
    "<td style='padding: 9px 12px; font-size: 13px; color: #1E293B; border-bottom: 1px solid #F3F4F6;'>" & [RegionName] & "</td>" &
    "<td style='padding: 9px 12px; text-align: right; font-size: 13px; font-weight: 600; color: #1E293B; border-bottom: 1px solid #F3F4F6;'>" & FORMAT([Actual], "$#,##0,K") & "</td>" &
    "<td style='padding: 9px 12px; text-align: right; font-size: 13px; color: #6B7280; border-bottom: 1px solid #F3F4F6;'>" & FORMAT([Target], "$#,##0,K") & "</td>" &
    "<td style='padding: 9px 12px; text-align: right; font-size: 13px; font-weight: 700; color: " & _color & "; border-bottom: 1px solid #F3F4F6;'>" & FORMAT(_ratio, "0%") & "</td>" &
    "</tr>",
    ""
)

RETURN
"<div style='width: 580px; font-family: Segoe UI, system-ui, sans-serif; border-radius: 12px; overflow: hidden; border: 1px solid #E5E7EB; box-shadow: 0 1px 3px rgba(0,0,0,0.1);'>" &
"<table style='width: 100%; border-collapse: collapse;'>" &
"<thead>" & _headerRow & "</thead>" &
"<tbody>" & _rows & "</tbody>" &
"</table>" &
"</div>"
```

---

## Alert Banner

Full-width contextual alert for important report messages.

```dax
-- Severity: "info" | "warning" | "critical" | "success"
Alert Banner =
VAR _severity = "warning"
VAR _message  = "Data last refreshed 3 days ago. Results may not reflect current period."

VAR _icon  = SWITCH(_severity, "info", "ℹ️", "warning", "⚠️", "critical", "🚨", "✅")
VAR _color = SWITCH(_severity, "info", "#0891B2", "warning", "#F59E0B", "critical", "#DC2626", "#059669")
VAR _bg    = SWITCH(_severity, "info", "#F0F9FF", "warning", "#FFFBEB", "critical", "#FEF2F2", "#ECFDF5")

RETURN
"<div style='
    width: 100%;
    padding: 12px 16px;
    background: " & _bg & ";
    border-left: 4px solid " & _color & ";
    border-radius: 0 8px 8px 0;
    display: flex;
    align-items: flex-start;
    gap: 10px;
    font-family: Segoe UI, system-ui, sans-serif;
'>" &
"<div style='font-size: 16px; flex-shrink: 0; margin-top: 1px;'>" & _icon & "</div>" &
"<div style='font-size: 13px; color: #1E293B; line-height: 1.5;'>" & _message & "</div>" &
"</div>"
```

---

## Loading Skeleton

Static placeholder shown when a page/card is loading (standalone HTML only).

```html
<style>
@keyframes shimmer {
  0%   { background-position: -400px 0; }
  100% { background-position: 400px 0; }
}
.skel {
  background: linear-gradient(90deg, #F3F4F6 25%, #E9EAEC 50%, #F3F4F6 75%);
  background-size: 400px 100%;
  animation: shimmer 1.4s infinite ease-in-out;
  border-radius: 4px;
}
</style>

<!-- KPI Card Skeleton -->
<div style="width: 268px; padding: 20px; background: #fff; border-radius: 12px; border: 1px solid #E5E7EB;">
  <div class="skel" style="height: 12px; width: 55%; margin-bottom: 14px;"></div>
  <div class="skel" style="height: 40px; width: 70%; margin-bottom: 10px;"></div>
  <div class="skel" style="height: 10px; width: 100%; margin-bottom: 6px;"></div>
  <div class="skel" style="height: 10px; width: 65%;"></div>
</div>
```

---

## Tooltip

Hover tooltip for additional context on a metric.

```html
<div style="position: relative; display: inline-block;">
  <span style="font-size: 12px; color: #6B7280; cursor: help; border-bottom: 1px dashed #9CA3AF;">
    GWP
  </span>
  <div style="
    position: absolute;
    bottom: calc(100% + 8px);
    left: 50%;
    transform: translateX(-50%);
    background: #1E293B;
    color: #fff;
    padding: 6px 10px;
    border-radius: 6px;
    font-size: 11px;
    white-space: nowrap;
    pointer-events: none;
    z-index: 10;
    box-shadow: 0 4px 8px rgba(0,0,0,0.15);
  ">
    Gross Written Premium
    <!-- Caret -->
    <div style="position: absolute; top: 100%; left: 50%; transform: translateX(-50%);
      border: 5px solid transparent; border-top-color: #1E293B;"></div>
  </div>
</div>
```

---

## Trend Indicator

Compact inline indicator for variance / change direction.

```dax
Trend Indicator =
VAR _value   = [Sales YoY %]
VAR _arrow   = IF(_value >= 0, "▲", "▼")
VAR _color   = IF(_value >= 0, "#059669", "#DC2626")
VAR _formatted = FORMAT(ABS(_value), "0.0%")

RETURN
"<span style='
    display: inline-flex;
    align-items: center;
    gap: 3px;
    font-size: 13px;
    font-weight: 600;
    color: " & _color & ";
'>" & _arrow & " " & _formatted & " vs LY</span>"
```

---

## Icon Badge

Small labeled badge with icon — for category tags, status, or type indicators.

```dax
Icon Badge =
VAR _label = "Renewal"
VAR _icon  = "🔄"
-- Style options: "default" | "purple" | "green" | "gray"
VAR _style = "purple"

VAR _bg    = SWITCH(_style, "purple", "#F5F3FF", "green", "#ECFDF5", "#F3F4F6")
VAR _color = SWITCH(_style, "purple", "#7C3AED", "green", "#059669", "#4B5563")
VAR _border = SWITCH(_style, "purple", "#7C3AED25", "green", "#05966925", "#E5E7EB")

RETURN
"<span style='
    display: inline-flex;
    align-items: center;
    gap: 5px;
    padding: 3px 9px;
    background: " & _bg & ";
    border: 1px solid " & _border & ";
    border-radius: 99px;
    font-size: 11px;
    font-weight: 600;
    color: " & _color & ";
    font-family: Segoe UI, system-ui, sans-serif;
'>" & _icon & " " & _label & "</span>"
```

---

## Comparison Row

Horizontal row comparing two values side by side with divider.

```dax
Comparison Row =
VAR _labelA  = "Current Year"
VAR _valueA  = FORMAT([Sales Total], "$#,##0,K")
VAR _labelB  = "Prior Year"
VAR _valueB  = FORMAT(CALCULATE([Sales Total], SAMEPERIODLASTYEAR('Date'[Date])), "$#,##0,K")
VAR _trend   = [Sales YoY %]
VAR _trendColor = IF(_trend >= 0, "#059669", "#DC2626")
VAR _trendText  = IF(_trend >= 0, "▲ ", "▼ ") & FORMAT(ABS(_trend), "0.0%")

RETURN
"<div style='
    display: flex;
    align-items: center;
    padding: 12px 0;
    border-bottom: 1px solid #F3F4F6;
    font-family: Segoe UI, system-ui, sans-serif;
'>" &

-- Left value
"<div style='flex: 1;'>" &
"<div style='font-size: 10px; color: #9CA3AF; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 2px;'>" & _labelA & "</div>" &
"<div style='font-size: 20px; font-weight: 700; color: #1E293B;'>" & _valueA & "</div>" &
"</div>" &

-- Centre delta
"<div style='text-align: center; padding: 0 16px;'>" &
"<div style='font-size: 13px; font-weight: 700; color: " & _trendColor & ";'>" & _trendText & "</div>" &
"<div style='font-size: 10px; color: #9CA3AF;'>YoY</div>" &
"</div>" &

-- Right value
"<div style='flex: 1; text-align: right;'>" &
"<div style='font-size: 10px; color: #9CA3AF; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 2px;'>" & _labelB & "</div>" &
"<div style='font-size: 20px; font-weight: 700; color: #6B7280;'>" & _valueB & "</div>" &
"</div>" &

"</div>"
```

---

## Multi-KPI Strip

Horizontal row of compact KPI chips — ideal for report sub-headers.

```dax
KPI Strip =
VAR _metrics = {
    ("GWP",       FORMAT([GWP Total], "$#,##0,K"),     DIVIDE([GWP Total], [GWP Target], 0)),
    ("Policies",  FORMAT([Policy Count], "#,##0"),      DIVIDE([Policy Count], [Policy Target], 0)),
    ("Retention", FORMAT([Retention Rate], "0.0%"),     [Retention Rate] / 0.9),
    ("NPS",       FORMAT([NPS Score], "0"),             [NPS Score] / 60)
}

RETURN
"<div style='display: flex; gap: 8px; font-family: Segoe UI, system-ui, sans-serif;'>" &
CONCATENATEX(
    _metrics,
    VAR _lbl   = [Value1]
    VAR _val   = [Value2]
    VAR _ratio = [Value3]
    VAR _color = SWITCH(TRUE(), _ratio >= 1.15, "#7C3AED", _ratio >= 1.0, "#059669", _ratio >= 0.9, "#0891B2", _ratio >= 0.8, "#F59E0B", "#DC2626")
    RETURN
    "<div style='padding: 8px 14px; background: #FFFFFF; border: 1px solid #E5E7EB; border-radius: 8px; text-align: center; box-shadow: 0 1px 2px rgba(0,0,0,0.05);'>" &
    "<div style='font-size: 10px; color: #9CA3AF; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 3px;'>" & _lbl & "</div>" &
    "<div style='font-size: 16px; font-weight: 700; color: " & _color & ";'>" & _val & "</div>" &
    "</div>",
    ""
) &
"</div>"
```

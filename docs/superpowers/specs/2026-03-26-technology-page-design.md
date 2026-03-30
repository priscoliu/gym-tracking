# Technology Page — Design Spec
**Date**: 2026-03-26
**Project**: Zest Management Dashboard — SME Power BI
**Page**: Technology (Page 3)
**Status**: Awaiting user review

---

## 1. Stakeholder Brief

> Number of open issues with uBind and their criticality
> Backlog
> Change orders: open COs, spend to date on ongoing COs, status including delivery dates

---

## 2. Source Data (Confirmed via MCP — 2026-03-26)

### fact_issues (16 rows total)
| Status | IsOpen | Count | Avg DaysOpen |
|--------|--------|-------|-------------|
| Open | TRUE | 1 | 51 days |
| Fixed | FALSE | 13 | 15.3 days avg, 60 days max |
| Non Issue | FALSE | 2 | — |

**Only open issue**: UBSUP-12887 — "WTW - BDX report | Missing information", raised 2026-01-28, Reporter: Louie, 51 days open.

**Columns**: TicketNumber, RaisedDateKey, RaisedDate, FixedDate, Status, IsOpen, DaysOpen, Description, Reporter
**Relationships**: `RaisedDateKey` → `dim_date[DateKey]` (active)
**No client/product linkage** — date slicer is the only meaningful filter

### fact_change_orders (8 rows total)
| Status | IsOpen | CostType | Count |
|--------|--------|----------|-------|
| Open | TRUE | Time and Materials | 1 (CO 27) |
| Open | TRUE | Fixed | 1 (CO 29) |
| Closed | FALSE | Fixed | 6 |

**Open change orders detail:**

| CR | Description | CostType | Spend / Budget | Target UAT | Due Note |
|----|-------------|----------|----------------|------------|----------|
| CO 27 | iQumulate premium funding hosted form — NB only | T&M | **$29,067.75 of $17,137** (170% — OVER) | Week of 24 Nov 2025 | 6–8 weeks from approval |
| CO 29 | Monthly Price Estimate / Remove Chubb Monthly Loading | Fixed | N.A | Same timing as CO 27 | 1 week from approval — 23 Dec 2025 |

**CompletionPct column** stores spend as raw text (`"$29,067.75 of $17,137"`) — requires DAX string parsing to extract numbers.
**No cost amount column** — ApprovedCost was removed from source by stakeholder.
**Columns**: ChangeRequestNumber, ChangeRequestDesc, Status, IsOpen, ApprovedDateKey, ApprovedDate, TargetReleaseUAT (text), ActualReleaseProd, DueDateNote, CostType, CompletionPct (text)

---

## 3. Canvas & Layout

**Canvas**: 1280×720px (16:9, Executive/Presentation mode)
**Mode**: Option A — left KPI card, right stacked tables
**Margins**: 16px all sides
**Page title + date slicer**: top strip ~40px

```
┌──────────────────────────────────────────────────────────────────┐
│  Technology                          [Date Range Slicer]         │
├──────────────────┬───────────────────────────────────────────────┤
│                  │  CHANGE ORDERS TABLE                          │
│  TECH SUMMARY    │  CR# | Description | Status | Type | Spend    │
│  HTML KPI Card   │  Target UAT | Actual Prod | Due Note         │
│  ~390px wide     │  ~8 rows, ~290px tall                        │
│  ~650px tall     ├───────────────────────────────────────────────┤
│                  │  ISSUES TABLE                                 │
│                  │  Ticket | Description | Criticality | Status  │
│                  │  Reporter | Raised | Fixed | Days Open        │
│                  │  ~16 rows, ~320px tall                       │
└──────────────────┴───────────────────────────────────────────────┘
```

**Column split**: Left 390px / Right 874px (16px gap)
**Right split**: Change Orders ~290px / Issues ~330px (12px gap between)

---

## 4. HTML KPI Card Design

**Style reference**: White-top / dark-bottom card (user-provided template)
**Width**: 390px | **Height**: ~650px
**Card wrapper**: white `#FFFFFF`, `border-radius: 24px`, soft shadow

### 4a. Top Section — Issues (white background)

| Element | Content | Style |
|---------|---------|-------|
| Pre-title | `uBind Issues` | 0.65rem, uppercase, `#9CA3AF` |
| Title | `Backlog Status` | 1.25rem, `#1E2536` |
| Badge | `1 CRITICAL` | Red background `#FEE2E2`, red text `#DC2626` (replaces green trend badge) |
| Main KPI | `1` | 3.5rem bold, `#1E2536` |
| Subtitle | `UBSUP-12887 · BDX Report · 51 days open` | 0.85rem, `#6B7280` |
| Callout box | Criticality breakdown | Warm beige `#F4EFE6` |

**Callout box content** — three inline tiers:
```
● Critical  1    >30 days
● Elevated  0    15–30 days
● Normal    0    <15 days
```
Each tier shows a colored dot, count, and day range. Counts driven by DAX measures.

### 4b. Bottom Section — Change Orders (dark `#212836`)

| Element | Content | Style |
|---------|---------|-------|
| Section title | `Change Orders` | 0.95rem, white |
| Subtitle | `8 total · 2 open` | 0.75rem, `#8B95A5` |
| Status dot | Amber `#F59E0B` (not green — COs are open/at risk) | 6px dot |
| Chart area | Budget vs Spend bar comparison | SVG, 110px tall |
| Chart note | `iQumulate CO is $11,931 over budget (170%)` | 0.75rem, white |
| KPI grid | 3 tiles | Light `#F6F4EE` tiles on dark bg |

**KPI grid tiles:**
| Tile 1 | Tile 2 | Tile 3 |
|--------|--------|--------|
| Open COs: **2** | Closed COs: **6** | T&M Spend: **$29,068** |

### 4c. Spend Bar Chart (SVG — dark section)

Two vertical rounded-rect bars using the same style as reference template:

```
     Budget    Spent
       │         │
       │       ████  ← overspend zone (red, above dashed line)
     ████      ████
     ████      ████  ← budget-equivalent zone (both bars)
  ─ ─ ─ ─ ─ ─ ─ ─  ← dashed line at budget level (100%)
  $17,137   $29,068
```

- **Budget bar**: `#384661` (dark navy), height = proportional to budget value
- **Spend bar**: Two-segment — budget zone `#384661`, overspend zone `#DC2626` (red)
- **Dashed line**: white dashed horizontal at budget height — `stroke-dasharray="4 3"`
- **X-axis labels**: `Budget` · `Spent`
- Bar width ~50px each, `rx="8"` (rounded corners), matching template style
- Colours follow gradient palette from template (`--col-1` through `--col-8`)

**Note on data extraction**: Spend (`$29,067.75`) and budget (`$17,137`) are parsed from the raw text `"$29,067.75 of $17,137"` stored in `fact_change_orders[CompletionPct]` using DAX string functions. If parsing fails (e.g. "N.A"), the chart section falls back to showing "Spend data not available".

---

## 5. Right-Side Tables

### 5a. Change Orders Table (top right)

**Visual type**: Power BI Table visual
**Height**: ~290px | **Width**: ~874px
**Rows**: 8 (all change orders)
**Sort**: Status (Open first), then ApprovedDate descending

| Column | Source | Notes |
|--------|--------|-------|
| CR # | `ChangeRequestNumber` | |
| Description | `ChangeRequestDesc` | Truncate to ~200px width |
| Status | DAX badge measure | Green `Closed` / Amber `Open` pill |
| Type | `CostType` | |
| Spend / Budget | `CompletionPct` | Raw text as-is (e.g. `$29,067.75 of $17,137`) |
| Approved | `ApprovedDate` | Short date format `dd MMM yyyy` |
| Target UAT | `TargetReleaseUAT` | Text as-is |
| Actual Prod | `ActualReleaseProd` | Short date, blank if null |
| Due Note | `DueDateNote` | Text as-is |

**Conditional formatting**: Row background amber-tint for IsOpen = TRUE rows.

### 5b. Issues Table (bottom right)

**Visual type**: Power BI Table visual
**Height**: ~330px | **Width**: ~874px
**Rows**: 16 (all issues)
**Sort**: IsOpen (TRUE first), then DaysOpen descending

| Column | Source | Notes |
|--------|--------|-------|
| Ticket # | `TicketNumber` | |
| Description | `Description` | Truncate to ~250px |
| Status | `Status` | Conditional colour: Open=red, Fixed=green, Non Issue=grey |
| Criticality | DAX calculated column | Critical / Elevated / Normal / — (for closed) |
| Reporter | `Reporter` | |
| Raised | `RaisedDate` | Short date |
| Fixed | `FixedDate` | Short date, blank if null |
| Days Open | `DaysOpen` | Right-aligned, blank if null |

**Criticality logic** (DAX calculated column on fact_issues):
```
Criticality =
IF(
    fact_issues[IsOpen] = TRUE(),
    SWITCH(
        TRUE(),
        fact_issues[DaysOpen] > 30, "Critical",
        fact_issues[DaysOpen] >= 15, "Elevated",
        "Normal"
    ),
    "—"
)
```
**Conditional formatting on Criticality**: Critical = red text, Elevated = amber, Normal = green, — = grey.

---

## 6. DAX Measures to Create

**Table**: `Core Metrics` | **Display folder**: `SME Tech\`

### SME Tech\Issues
```
Tech Issues Open Count =
CALCULATE(COUNTROWS(fact_issues), fact_issues[IsOpen] = TRUE())

Tech Issues Total Count =
COUNTROWS(fact_issues)

Tech Issues Closed Count =
CALCULATE(COUNTROWS(fact_issues), fact_issues[IsOpen] = FALSE())

Tech Issues Critical Count =
CALCULATE(COUNTROWS(fact_issues), fact_issues[IsOpen] = TRUE(), fact_issues[DaysOpen] > 30)

Tech Issues Elevated Count =
CALCULATE(COUNTROWS(fact_issues), fact_issues[IsOpen] = TRUE(), fact_issues[DaysOpen] >= 15, fact_issues[DaysOpen] <= 30)

Tech Issues Normal Count =
CALCULATE(COUNTROWS(fact_issues), fact_issues[IsOpen] = TRUE(), fact_issues[DaysOpen] < 15)
```

### SME Tech\Change Orders
```
Tech CO Open Count =
CALCULATE(COUNTROWS(fact_change_orders), fact_change_orders[IsOpen] = TRUE())

Tech CO Total Count =
COUNTROWS(fact_change_orders)

Tech CO Closed Count =
CALCULATE(COUNTROWS(fact_change_orders), fact_change_orders[IsOpen] = FALSE())
```

### SME Tech\Spend (DAX string parsing)
```
Tech TM Spend =
VAR _raw = CALCULATE(
    MAX(fact_change_orders[CompletionPct]),
    fact_change_orders[CostType] = "Time and Materials",
    fact_change_orders[IsOpen] = TRUE()
)
VAR _ofPos = SEARCH(" of ", _raw, 1, 0)
VAR _spendText = LEFT(_raw, _ofPos - 1)
VAR _spend = VALUE(TRIM(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(_spendText, "$", ""), ",", ""), " ", "")))
RETURN IF(_ofPos > 0, _spend, BLANK())
-- FORMAT: $#,##0

Tech TM Budget =
VAR _raw = CALCULATE(
    MAX(fact_change_orders[CompletionPct]),
    fact_change_orders[CostType] = "Time and Materials",
    fact_change_orders[IsOpen] = TRUE()
)
VAR _ofPos = SEARCH(" of ", _raw, 1, 0)
VAR _budgetText = MID(_raw, _ofPos + 4, LEN(_raw))
VAR _budget = VALUE(TRIM(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(_budgetText, "$", ""), ",", ""), " ", "")))
RETURN IF(_ofPos > 0, _budget, BLANK())
-- FORMAT: $#,##0

Tech TM Overrun =
[Tech TM Spend] - [Tech TM Budget]
-- FORMAT: $#,##0

Tech TM Overrun Pct =
DIVIDE([Tech TM Spend], [Tech TM Budget], BLANK())
-- FORMAT: 0%
```

### SME Tech\HTML Cards
```
Tech Summary Card =
-- Full DAX HTML string measure (to be written in implementation)
-- Inputs: all Tech measures above + WTW design tokens
-- Outputs: white-top/dark-bottom card per Section 4 above
```

---

## 7. Calculated Column

**Table**: `fact_issues`
**Column name**: `Criticality`
**Logic**: Critical (>30d open) / Elevated (15–30d open) / Normal (<15d open) / — (closed)
See Section 5b for full DAX.

---

## 8. Filters & Slicers

| Slicer | Field | Scope |
|--------|-------|-------|
| Date Range | `dim_date[Date]` | Affects both tables via DateKey relationships |

No client, product, or status slicers — dataset is too small and has no client linkage.

---

## 9. Known Constraints & Risks

| Item | Risk | Mitigation |
|------|------|------------|
| Spend stored as text | DAX parsing brittle if format changes | Parse with SEARCH+MID; fallback to BLANK() if format unexpected |
| TargetReleaseUAT is text not date | Can't sort/filter as date | Display as-is in table; note to stakeholder |
| Only 1 open issue | Card may look sparse if issue is resolved | Card always renders all 3 criticality tiers (even at 0) |
| CompletionPct = "N.A" for Fixed COs | No spend data for CO 29 | Show "Fixed price" label instead of spend |
| CO 27 overdue | Target UAT was Nov 2025, still open Mar 2026 | Highlight row; note in card |

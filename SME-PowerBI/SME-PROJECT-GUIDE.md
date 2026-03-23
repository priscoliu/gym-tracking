# SME Power BI Project — Complete Guide

> **Last Updated**: 2026-03-20
> **Power BI File**: Zest Management Dashboard
> **Lakehouse ID**: `0ebd6604-a5db-4624-b535-497cd55663c1`
> **Workspace ID**: `76ec20c3-c400-415a-99c6-708f8207d5f9`
> **MCP Connection**: `PBIDesktop-Zest Management Dashboard-61511`

---

## 1. Semantic Model — Star Schema (Lean)

### Tables

| Table | Type | Columns | Source | Status |
|-------|------|:-------:|--------|:------:|
| `fact_sales` | Fact | 10 | `src_sales_marketing` | ✅ Loaded |
| `fact_quotes` | Fact | 11 | `src_quotes_uBind` | ✅ Loaded |
| `fact_issues` | Fact | 9 | `src_issue_technology` | ✅ Loaded |
| `fact_change_orders` | Fact | 11 | `src_change_technology` | ✅ Loaded |
| `fact_project_tasks` | Fact | 20 | `src_project_delivery` | ✅ Loaded |
| `dim_date` | Dimension | 13 | Generated (M code) | ✅ Loaded |
| `dim_clients` | Dimension | 9 | `src_quotes_uBind` + `src_sales_marketing` | ✅ Loaded |

### Fact Table Columns

#### fact_sales (10 columns)
```
InsuredName          (text)    — FK → dim_clients[InsuredName]
PolicyNumber         (text)
TransactionDateKey   (int64)  — FK → dim_date[DateKey]
TransactionDate      (date)
TransactionType      (text)   — New Business | Renewal | Endorsement | Cancellation
ProductClass         (text)   — e.g. Workers Compensation, Management Liability
InvoiceNumber        (text)
BasePremium          (currency)
TotalPremium         (currency)
Commission           (currency)
```

#### fact_quotes (11 columns)
```
InsuredName          (text)    — FK → dim_clients[InsuredName]
QuoteReference       (text)
CreationDateKey      (int64)  — FK → dim_date[DateKey]
CreationDate         (date)
LastModifiedDate     (date)
QuoteType            (text)   — NewBusiness | Renewal
QuoteStatus          (text)   — Incomplete | Approved | Declined | Complete | Assessment | Cancellation
IsConverted          (logical) — TRUE if QuoteStatus = "Complete"
PolicyNumber         (text)
BasePremium          (currency)
TotalPremium         (currency)
```

#### fact_issues (9 columns)
```
TicketNumber         (text)
RaisedDateKey        (int64)  — FK → dim_date[DateKey]
RaisedDate           (date)
FixedDate            (date)
Status               (text)
IsOpen               (logical)
DaysOpen             (int)
Description          (text)
Reporter             (text)
```

#### fact_change_orders (11 columns)
```
ChangeRequestNumber  (text)
ChangeRequestDesc    (text)
Status               (text)
IsOpen               (logical)
ApprovedDateKey      (int64)  — FK → dim_date[DateKey]
ApprovedDate         (date)
TargetReleaseUAT     (text)
ActualReleaseProd    (date)
DueDateNote          (text)   — source: "Due date _Based on change order_"
CostType             (text)
CompletionPct        (text)
```

> **Note**: `ApprovedCost` and `Requirements and Acceptance Criteria` columns were removed from source by stakeholder (not in cleaned dataset).

#### fact_project_tasks (20 columns)
```
TaskName             (text)
StartDateKey         (int64)  — FK → dim_date[DateKey]
Start                (date)
Finish               (date)
ActualFinish         (date)
EffectiveFinish      (date)   — ActualFinish if not null, else Finish
Duration             (number) — parsed from "84 days?"
ActualDuration       (number)
PctComplete          (number)
MilestoneHorizon     (text)   — 30/60/90/Beyond/Complete
DaysUntilFinish      (int)
IsCritical           (logical)
IsDelayed            (logical)
BaselineStart        (date)
BaselineFinish       (date)
TaskMode             (text)
ResourceNames        (text)
Critical             (int)
Predecessors         (int)
Notes                (text)
```

### Dimension Table Columns

#### dim_date (13 columns)
```
DateKey              (int64)  — PK, YYYYMMDD format
Date                 (date)
Year                 (int)
Quarter              (text)
Month                (int)
MonthName            (text)
YearMonthSort        (int)
WeekNumber           (int)
WeekStartDate        (date)
FiscalYear           (int)
FiscalYearLabel      (text)
IsWTD                (logical)
IsYTD                (logical)
```

#### dim_clients (9 columns)
```
InsuredName          (text)   — PK, UPPER(TRIM(cleaned))
Street               (text)
City                 (text)
State                (text)
Postcode             (text)
GNAF                 (text)
Occupation           (text)
Revenue              (text)
ClientKey            (int)   — row number
```

---

## 2. Relationships (Active)

| From Table | From Column | → | To Table | To Column | Cardinality |
|-----------|-------------|---|----------|-----------|:-----------:|
| fact_sales | TransactionDateKey | → | dim_date | DateKey | Many:1 |
| fact_quotes | CreationDateKey | → | dim_date | DateKey | Many:1 |
| fact_issues | RaisedDateKey | → | dim_date | DateKey | Many:1 |
| fact_change_orders | ApprovedDateKey | → | dim_date | DateKey | Many:1 |
| fact_project_tasks | StartDateKey | → | dim_date | DateKey | Many:1 |
| fact_sales | InsuredName | → | dim_clients | InsuredName | Many:1 |
| fact_quotes | InsuredName | → | dim_clients | InsuredName | Many:1 |

> All relationships are single-direction cross-filter (Fact → Dim).
> Power BI also auto-created 14+ LocalDateTable relationships on every date column — these are redundant but harmless.

---

## 3. DAX Measures — To Create in `Core Metrics` Table

### SME Sales\Base

```dax
Sales Total Premium =
SUM(fact_sales[TotalPremium])
-- FORMAT: $#,##0

Sales Base Premium =
SUM(fact_sales[BasePremium])
-- FORMAT: $#,##0

Sales Commission =
SUM(fact_sales[Commission])
-- FORMAT: $#,##0
```

### SME Sales\Counts

```dax
Sales Policy Count =
DISTINCTCOUNT(fact_sales[PolicyNumber])
-- FORMAT: #,##0

Sales Transaction Count =
COUNTROWS(fact_sales)
-- FORMAT: #,##0

Sales Client Count =
DISTINCTCOUNT(fact_sales[InsuredName])
-- FORMAT: #,##0

Sales NB Count =
CALCULATE([Sales Transaction Count], fact_sales[TransactionType] = "New Business")
-- FORMAT: #,##0

Sales Renewal Count =
CALCULATE([Sales Transaction Count], fact_sales[TransactionType] = "Renewal")
-- FORMAT: #,##0
```

### SME Sales\Averages

```dax
Sales Avg Premium =
DIVIDE([Sales Total Premium], [Sales Policy Count], 0)
-- FORMAT: $#,##0
```

### SME Sales\Ratios

```dax
Sales Commission % =
DIVIDE([Sales Commission], [Sales Total Premium], 0)
-- FORMAT: 0.0%

Sales Retention Rate =
DIVIDE([Sales Renewal Count], [Sales Renewal Count] + [Sales NB Count], 0)
-- FORMAT: 0.0%

Sales NB Mix % =
DIVIDE([Sales New Business], [Sales Total Premium], 0)
-- FORMAT: 0.0%
```

### SME Sales\By Type

```dax
Sales New Business =
CALCULATE([Sales Total Premium], fact_sales[TransactionType] = "New Business")
-- FORMAT: $#,##0

Sales Renewals =
CALCULATE([Sales Total Premium], fact_sales[TransactionType] = "Renewal")
-- FORMAT: $#,##0

Sales Endorsements =
CALCULATE([Sales Total Premium], fact_sales[TransactionType] = "Endorsement")
-- FORMAT: $#,##0

Sales Cancellations =
CALCULATE([Sales Total Premium], fact_sales[TransactionType] = "Cancellation")
-- FORMAT: $#,##0
```

---

## 4. HTML KPI Card — Sales Summary (WTW Design System)

This card should be created as a DAX measure in `Core Metrics` table, display folder `SME Sales\HTML Cards`.

### Design Specifications
- **Width**: 580px (6-column grid)
- **Font**: Segoe UI
- **Primary color**: WTW Purple `#7C3AED`
- **Layout**: Header + 4-column metric grid + transaction type breakdown
- **Shadows**: Multi-layer (outer: `0 10px 15px -3px rgba(0,0,0,0.1)`)

### DAX Measure

```dax
Sales Summary Card =
// ─── DATA ───
VAR _totalPremium = [Sales Total Premium]
VAR _basePremium = [Sales Base Premium]
VAR _commission = [Sales Commission]
VAR _policyCount = [Sales Policy Count]
VAR _txnCount = [Sales Transaction Count]
VAR _clientCount = [Sales Client Count]
VAR _avgPremium = [Sales Avg Premium]
VAR _commPct = [Sales Commission %]
VAR _nbPremium = [Sales New Business]
VAR _renewalPremium = [Sales Renewals]
VAR _endorsePremium = [Sales Endorsements]
VAR _cancelPremium = [Sales Cancellations]
VAR _retentionRate = [Sales Retention Rate]
VAR _nbMix = [Sales NB Mix %]

// ─── FORMAT ───
VAR _fmtTotal = FORMAT(_totalPremium, "$#,##0")
VAR _fmtBase = FORMAT(_basePremium, "$#,##0")
VAR _fmtComm = FORMAT(_commission, "$#,##0")
VAR _fmtPolicies = FORMAT(_policyCount, "#,##0")
VAR _fmtTxns = FORMAT(_txnCount, "#,##0")
VAR _fmtClients = FORMAT(_clientCount, "#,##0")
VAR _fmtAvg = FORMAT(_avgPremium, "$#,##0")
VAR _fmtCommPct = FORMAT(_commPct, "0.0%")
VAR _fmtNB = FORMAT(_nbPremium, "$#,##0")
VAR _fmtRenewal = FORMAT(_renewalPremium, "$#,##0")
VAR _fmtEndorse = FORMAT(_endorsePremium, "$#,##0")
VAR _fmtCancel = FORMAT(_cancelPremium, "$#,##0")
VAR _fmtRetention = FORMAT(_retentionRate, "0.0%")
VAR _fmtNBMix = FORMAT(_nbMix, "0.0%")

// ─── WTW TOKENS ───
VAR _wtwPurple = "#7C3AED"
VAR _textPrimary = "#1E293B"
VAR _textSecondary = "#6B7280"
VAR _textMuted = "#9CA3AF"
VAR _borderMedium = "#E5E7EB"
VAR _bgAlt = "#F9FAFB"
VAR _green = "#059669"
VAR _amber = "#F59E0B"
VAR _red = "#DC2626"

// ─── NB vs Renewal mix bar widths ───
VAR _nbBarWidth = FORMAT(DIVIDE(_nbPremium, _totalPremium, 0) * 100, "0.0") & "%"
VAR _renewBarWidth = FORMAT(DIVIDE(_renewalPremium, _totalPremium, 0) * 100, "0.0") & "%"

RETURN
"<div style='width: 580px; padding: 20px; background: linear-gradient(145deg, #FFFFFF 0%, " & _bgAlt & " 100%); border-radius: 12px; font-family: Segoe UI, system-ui, sans-serif; border: 1px solid " & _borderMedium & "; box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1), 0 4px 6px -2px rgba(0,0,0,0.05); box-sizing: border-box;'>" &

"<!-- Header -->" &
"<div style='display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;'>" &
"<div style='font-size: 14px; font-weight: 600; color: " & _textPrimary & ";'>Sales Summary</div>" &
"<div style='font-size: 10px; color: " & _textMuted & "; text-transform: uppercase; letter-spacing: 0.5px;'>ALL PERIODS</div>" &
"</div>" &

"<!-- Hero Value -->" &
"<div style='font-size: 42px; font-weight: 700; color: " & _wtwPurple & "; line-height: 1; margin-bottom: 4px;'>" & _fmtTotal & "</div>" &
"<div style='font-size: 12px; color: " & _textSecondary & "; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 20px;'>TOTAL PREMIUM</div>" &

"<!-- 4-Column Metrics Grid -->" &
"<div style='display: grid; grid-template-columns: 1fr 1fr 1fr 1fr; gap: 10px; margin-bottom: 20px;'>" &

"<div style='background: #FFFFFF; padding: 10px; border-radius: 8px; border: 1px solid #F3F4F6; box-shadow: 0 1px 3px rgba(0,0,0,0.06); text-align: center;'>" &
"<div style='font-size: 10px; color: " & _textSecondary & "; margin-bottom: 4px;'>POLICIES</div>" &
"<div style='font-size: 20px; font-weight: 700; color: " & _textPrimary & ";'>" & _fmtPolicies & "</div>" &
"</div>" &

"<div style='background: #FFFFFF; padding: 10px; border-radius: 8px; border: 1px solid #F3F4F6; box-shadow: 0 1px 3px rgba(0,0,0,0.06); text-align: center;'>" &
"<div style='font-size: 10px; color: " & _textSecondary & "; margin-bottom: 4px;'>CLIENTS</div>" &
"<div style='font-size: 20px; font-weight: 700; color: " & _textPrimary & ";'>" & _fmtClients & "</div>" &
"</div>" &

"<div style='background: #FFFFFF; padding: 10px; border-radius: 8px; border: 1px solid #F3F4F6; box-shadow: 0 1px 3px rgba(0,0,0,0.06); text-align: center;'>" &
"<div style='font-size: 10px; color: " & _textSecondary & "; margin-bottom: 4px;'>AVG PREMIUM</div>" &
"<div style='font-size: 20px; font-weight: 700; color: " & _textPrimary & ";'>" & _fmtAvg & "</div>" &
"</div>" &

"<div style='background: #FFFFFF; padding: 10px; border-radius: 8px; border: 1px solid #F3F4F6; box-shadow: 0 1px 3px rgba(0,0,0,0.06); text-align: center;'>" &
"<div style='font-size: 10px; color: " & _textSecondary & "; margin-bottom: 4px;'>COMMISSION</div>" &
"<div style='font-size: 20px; font-weight: 700; color: " & _green & ";'>" & _fmtCommPct & "</div>" &
"</div>" &

"</div>" &

"<!-- NB vs Renewal Mix Bar -->" &
"<div style='margin-bottom: 16px;'>" &
"<div style='display: flex; justify-content: space-between; margin-bottom: 6px;'>" &
"<div style='font-size: 11px; color: " & _textSecondary & ";'>Business Mix</div>" &
"<div style='font-size: 11px; color: " & _textSecondary & ";'>Retention: <span style='font-weight: 600; color: " & _wtwPurple & ";'>" & _fmtRetention & "</span></div>" &
"</div>" &
"<div style='display: flex; height: 10px; border-radius: 5px; overflow: hidden;'>" &
"<div style='width: " & _nbBarWidth & "; background: linear-gradient(135deg, #8B5CF6 0%, #7C3AED 100%);' title='New Business'></div>" &
"<div style='width: " & _renewBarWidth & "; background: linear-gradient(135deg, #10B981 0%, #059669 100%);' title='Renewals'></div>" &
"</div>" &
"<div style='display: flex; justify-content: space-between; margin-top: 4px;'>" &
"<div style='font-size: 9px; color: " & _wtwPurple & "; font-weight: 600;'>NB " & _fmtNBMix & "</div>" &
"<div style='font-size: 9px; color: " & _green & "; font-weight: 600;'>Renewals</div>" &
"</div>" &
"</div>" &

"<!-- Transaction Type Summary -->" &
"<div style='background: linear-gradient(135deg, #F5F3FF 0%, rgba(255,255,255,0.8) 100%); border: 1px solid #7C3AED20; border-radius: 8px; padding: 12px 16px;'>" &
"<div style='display: grid; grid-template-columns: 1fr 1fr 1fr 1fr; gap: 8px;'>" &

"<div style='text-align: center;'>" &
"<div style='font-size: 9px; color: " & _textSecondary & "; margin-bottom: 2px;'>NEW BIZ</div>" &
"<div style='font-size: 14px; font-weight: 700; color: " & _wtwPurple & ";'>" & _fmtNB & "</div>" &
"</div>" &

"<div style='text-align: center;'>" &
"<div style='font-size: 9px; color: " & _textSecondary & "; margin-bottom: 2px;'>RENEWALS</div>" &
"<div style='font-size: 14px; font-weight: 700; color: " & _green & ";'>" & _fmtRenewal & "</div>" &
"</div>" &

"<div style='text-align: center;'>" &
"<div style='font-size: 9px; color: " & _textSecondary & "; margin-bottom: 2px;'>ENDORSE</div>" &
"<div style='font-size: 14px; font-weight: 700; color: " & _amber & ";'>" & _fmtEndorse & "</div>" &
"</div>" &

"<div style='text-align: center;'>" &
"<div style='font-size: 9px; color: " & _textSecondary & "; margin-bottom: 2px;'>CANCEL</div>" &
"<div style='font-size: 14px; font-weight: 700; color: " & _red & ";'>" & _fmtCancel & "</div>" &
"</div>" &

"</div>" &
"</div>" &

"</div>"
```

### How to Use the HTML Card
1. Create the `Sales Summary Card` measure in Power BI
2. Add a **Table visual** to the canvas
3. Drag the measure into the Values field
4. In Format pane → Values → toggle **"URL icon"** → select **"Image URL"** or enable HTML rendering
5. For **New Visual** (HTML Content visual from AppSource), just drop the measure in

---

## 5. Existing Measures (127 total)

The model already has 127 measures across these tables:

| Table | Measure Count | Purpose |
|-------|:------------:|---------|
| Core Metrics | 56 | Revenue, pipeline, win rates, YoY, rankings |
| Visualizations | 29 | HTML cards, SVG images, conditional formatting |
| CRM & Activities | 22 | Leads, activities, conversions |
| UI Controls | 19 | Slicer selections, dynamic titles |
| Top Values | 1 | TopN helper |

These are **from the Zest CRM dashboard** (existing). The new SME Sales measures should go into `Core Metrics` under `SME Sales\` display folders to keep them separate.

---

## 6. M Code Files

All in: `SME-PowerBI/` folder

| File | Status | Key Changes |
|------|:------:|-------------|
| `fact_sales.m` | ✅ Updated | Added `InsuredName` (UPPER TRIM), `TransactionDateKey` (YYYYMMDD int) |
| `fact_quotes.m` | ✅ Updated | Added `InsuredName`, `CreationDateKey`, `IsConverted` flag |
| `fact_issues.m` | ✅ Updated | Added `RaisedDateKey` |
| `fact_change_orders.m` | ✅ Updated | Added `ApprovedDateKey`, removed `ApprovedCost` & `Requirements` (dropped from source), renamed `Due date` → `Due date _Based on change order_` |
| `fact_project_tasks.m` | ✅ Updated | Added `StartDateKey` |
| `dim_date.m` | ✅ No change needed | Already had DateKey, FiscalYear, IsYTD |
| `dim_clients.m` | ✅ Updated | Fixed missing `clean_sales_marketing` ref → now reads `src_sales_marketing` directly from lakehouse |

---

## 7. Stakeholder Answers (Confirmed)

| Question | Answer |
|----------|--------|
| Change Order Status blanks | Stakeholder cleaned the dataset — Status column is now populated |
| Change Order delivery dates | Use `Due date _Based on change order_` column |
| Backlogs definition | Open issue tickets only (fact_issues where IsOpen = TRUE) |

---

## 8. Outstanding Questions (Unanswered)

| # | Question | Impact |
|---|----------|--------|
| 1 | **YTD = Calendar Year or Financial Year (Jul–Jun)?** | dim_date[IsYTD] calculation |
| 2 | **"Revenue Split - Tas2" clarification** | Unknown if needed |
| 3 | **Sales → ProductName mapping** — using Risk Class? | Product slicer accuracy |
| 4 | **Include Declined/Incomplete quotes in totals?** | Quote conversion rate calc |
| 5 | **What defines a "Sale"?** Complete quote vs. Sales table row? | Cross-table reconciliation |

---

## 9. Design Decisions (Rationale)

| Decision | Rationale |
|----------|-----------|
| **2 dim tables only** (date + clients) | ProductClass, TransactionType, QuoteStatus all have <20 distinct values — live as columns on fact tables |
| **DateKey as YYYYMMDD integer** | Standard pattern for star schema, efficient joins, sortable |
| **InsuredName as client FK** (not ID) | Source data has no client ID, text matching is the only option. UPPER(TRIM(CLEAN())) applied for consistency |
| **Lean fact tables** | 10-20 columns each, only essential measures and FKs |
| **No SQL views** | User chose to keep M code in Power Query instead of SQL endpoint views |

---

## 10. Client Name Matching Warning

⚠️ **Known Risk**: The `InsuredName` FK between fact_sales/fact_quotes and dim_clients relies on text matching after UPPER + TRIM + CLEAN. Variations like:
- `"HARRISON, ALICIA T/AS ONTRACK INJURY SOLUTIONS"` (Sales)
- `"ONTRACK INJURY SOLUTIONS"` (Quotes)

...will **NOT match**. If precise cross-table client analysis is critical, a manual mapping table may be needed.

---

## 11. WTW Power BI Design System Reference

The project uses the WTW design system skill located at:
```
.agent/skills/wtw-powerbi/
```

### Key Files
- `SKILL.md` — Overview + philosophy
- `references/tokens.md` — Color palette, typography, spacing, shadows
- `references/dax-patterns.md` — DAX naming, variables, performance detection
- `references/html-cards.md` — HTML card structure, grids, progress bars
- `references/color-system.md` — Performance thresholds + WCAG
- `references/design-standards.md` — 12-column grid, card widths
- `references/data-modeling.md` — Star schema patterns

### Key Tokens
```
Primary Purple:     #7C3AED
Text Primary:       #1E293B
Text Secondary:     #6B7280
Text Muted:         #9CA3AF
Border Medium:      #E5E7EB
Outstanding:        #7C3AED (≥115%)
Target Met:         #059669 (100-114%)
Near Target:        #0891B2 (90-99%)
Below Target:       #F59E0B (80-89%)
Critical:           #DC2626 (<80%)
Font:               Segoe UI
Outer Shadow:       0 10px 15px -3px rgba(0,0,0,0.1), 0 4px 6px -2px rgba(0,0,0,0.05)
Inner Shadow:       0 1px 3px 0 rgba(0,0,0,0.1), 0 1px 2px 0 rgba(0,0,0,0.06)
```

---

## 12. Next Steps

1. **Create DAX measures** — Use the 16 measures in Section 3 above, put them in `Core Metrics` table under `SME Sales\` folders
2. **Create HTML KPI card** — Use the `Sales Summary Card` DAX from Section 4
3. **Build Sales Summary page** — Layout with the KPI card + charts:
   - Premium by Transaction Type (bar chart)
   - Premium by Product Class (bar chart)
   - Premium over time by Month (line chart)
   - Top 10 Clients by Premium (horizontal bar)
4. **Answer outstanding questions** — Especially YTD definition (Q1) and quote inclusion (Q4)
5. **Build remaining pages** — Quotes, Technology (Issues + Change Orders), Delivery (Project Tasks)
6. **Add time intelligence** — YTD, MoM, YoY measures once Q1 is answered

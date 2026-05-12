# DAX Patterns & Best Practices

Complete guide to DAX naming conventions, variables, performance detection logic, and standard measure patterns for WTW Power BI reports.

## Table of Contents

| Section | What's inside | Jump to when |
|---------|--------------|--------------|
| [DAX Naming Conventions](#dax-naming-conventions) | Measure / variable / column naming rules | Starting a new measure or refactor |
| [Performance Level Detection](#performance-level-detection) | SWITCH logic mapping % to "Outstanding/Met/Near/Below/Critical" | Building any KPI with a target |
| [Standard Color Variables (HTML Cards)](#standard-color-variables-html-cards) | `_c1` … `_c5`, text + background tokens | At the top of every HTML card measure |
| [Standard Measure Patterns](#standard-measure-patterns) | YTD, QTD, MTD, YoY, MoM, vs Target, prior-period | Building time intelligence measures |
| [KPI Card Measures](#kpi-card-measures) | Returning HTML for a single KPI tile | Building a tile in a dashboard |
| [Number Formatting](#number-formatting) | $K / $M / accounting-format helpers | Any currency value in HTML output |
| [DAX Formatting Standards](#dax-formatting-standards-mandatory) | Indentation, line breaks, casing | Reviewing or normalising DAX style |
| [DAX Optimization Best Practices](#dax-optimization-best-practices) | Variables over recalculation, avoid `FILTER(table)`, etc. | Slow measure or model running >3s |
| [Common Patterns Cheat Sheet](#common-patterns-cheat-sheet) | One-line snippets for frequent tasks | Looking up a familiar pattern |
| [HTML Card Patterns](#html-card-patterns) | DAX → HTML string assembly recipes | Composing a multi-section card |
| [Cross-Sell & Whitespace Analysis](#cross-sell--whitespace-analysis) | `EXCEPT()` / penetration logic | Building a "what's missing" view |
| [Pre-Aggregated Calculated Table (Matrix Performance)](#pre-aggregated-calculated-table-matrix-performance) | Calculated table to speed up matrix visuals | Matrix loads slowly, need to pre-roll |
| [Checklist: DAX Best Practices](#checklist-dax-best-practices) | Quick review list | End-of-task self-check |

## DAX Naming Conventions

### Measures

**Format**: `[Measure Name]` — Always use square brackets

**Examples**:
- `[Sales Total]`
- `[Sales YoY %]`
- `[Sales vs Target]`
- `[Margin %]`
- `[Customer Count Distinct]`

**Guidelines**:
- Use descriptive names that indicate what the measure calculates
- Include context like "YoY", "vs Target", "%" in the name
- Use Title Case for readability
- Keep names concise but clear (2-4 words ideal)

### Calculated Columns

**Format**: Column Name (no brackets)

**Examples**:
- `Sales Year`
- `Customer Segment`
- `Product Category`
- `Full Name`

**Guidelines**:
- Use Title Case (PascalCase with spaces)
- Be descriptive but concise
- Avoid brackets (brackets are for measures only)

### Variables

**Format**: `_variableName` — Underscore prefix, camelCase

**Examples**:
```dax
VAR _currentYearSales = [Sales Total]
VAR _priorYearSales = CALCULATE([Sales Total], SAMEPERIODLASTYEAR('Date'[Date]))
VAR _achievementRatio = DIVIDE(_currentYearSales, [Sales Target], 0)
VAR _performanceLevel = SWITCH(TRUE(), _achievementRatio >= 1.15, "outstanding", ...)
```

**Guidelines**:
- Always start with underscore `_`
- Use camelCase (first word lowercase, subsequent words capitalized)
- Be descriptive — variable names should indicate what they store
- Use meaningful prefixes: `_current`, `_prior`, `_total`, `_selected`

## Performance Level Detection

Standard pattern for categorizing performance based on achievement ratio.

### Basic Performance Detection

```dax
Performance Level =
VAR _actual = [Sales Total]
VAR _target = [Sales Target]
VAR _achievementRatio = DIVIDE(_actual, _target, 0)
VAR _performanceLevel =
    SWITCH(
        TRUE(),
        _achievementRatio >= 1.15, "outstanding",
        _achievementRatio >= 1.0, "target_met",
        _achievementRatio >= 0.9, "near_target",
        _achievementRatio >= 0.8, "below_target",
        "critical"
    )
RETURN
    _performanceLevel
```

**Thresholds**:
- **≥115%** → `"outstanding"` — Exceptional performance
- **100-114%** → `"target_met"` — Goal achieved
- **90-99%** → `"near_target"` — Approaching goal
- **80-89%** → `"below_target"` — Needs attention
- **<80%** → `"critical"` — Urgent action required

### Performance with Color Mapping

```dax
Performance Color =
VAR _achievementRatio = DIVIDE([Sales Total], [Sales Target], 0)
VAR _primaryColor =
    SWITCH(
        TRUE(),
        _achievementRatio >= 1.15, "#7F35B2",  -- WTW Purple (outstanding)
        _achievementRatio >= 1.0, "#059669",   -- Green (target met)
        _achievementRatio >= 0.9, "#0891B2",   -- Cyan (near target)
        _achievementRatio >= 0.8, "#F59E0B",   -- Amber (below target)
        "#DC2626"                               -- Red (critical)
    )
RETURN
    _primaryColor
```

## Standard Color Variables (HTML Cards)

### WTW Color Palette

```dax
-- Performance-based primary colors
VAR _primaryColor =
    SWITCH(
        _performanceLevel,
        "outstanding", "#7F35B2",  -- WTW Purple
        "target_met", "#059669",   -- Green
        "near_target", "#0891B2",  -- Cyan
        "below_target", "#F59E0B", -- Amber
        "#DC2626"                  -- Red (critical)
    )

-- Background tints (subtle, 5% opacity)
VAR _backgroundTint =
    SWITCH(
        _performanceLevel,
        "outstanding", "#F3F4F6",  -- Light Gray
        "target_met", "#ECFDF5",   -- Light Green
        "near_target", "#F0F9FF",  -- Light Blue
        "below_target", "#FFFBEB", -- Light Amber
        "#FEF2F2"                  -- Light Red
    )

-- Gradient fills for bars/cards
VAR _gradientFill =
    SWITCH(
        _performanceLevel,
        "outstanding", "linear-gradient(135deg, #995BC5 0%, #7F35B2 100%)",
        "target_met", "linear-gradient(135deg, #10B981 0%, #059669 100%)",
        "near_target", "linear-gradient(135deg, #06B6D4 0%, #0891B2 100%)",
        "below_target", "linear-gradient(135deg, #FBBF24 0%, #F59E0B 100%)",
        "linear-gradient(135deg, #F87171 0%, #DC2626 100%)"
    )
```

### Text Color Hierarchy (Neutral)

```dax
VAR _textPrimary = "#1E293B"    -- Headings, important text
VAR _textSecondary = "#6B7280"  -- Labels, descriptions
VAR _textTertiary = "#334155"   -- Sub-headings
VAR _textBody = "#4B5563"       -- Body text, paragraphs
VAR _textMuted = "#9CA3AF"      -- Captions, hints
```

### Shadow System

```dax
-- Outer container (premium depth)
VAR _outerShadow = "0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)"

-- Inner cards (subtle)
VAR _innerShadow = "0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06)"
```

### Border System

```dax
VAR _borderLight = "1px solid #F3F4F6"
VAR _borderMedium = "1px solid #E5E7EB"
VAR _borderThemed = "1px solid " & _primaryColor & "20"  -- 20 = ~12% opacity
```

## Standard Measure Patterns

### Time Intelligence

#### Year-to-Date (YTD)

```dax
Sales YTD =
CALCULATE(
    [Sales Total],
    DATESYTD('Date'[Date])
)
```

#### Quarter-to-Date (QTD)

```dax
Sales QTD =
CALCULATE(
    [Sales Total],
    DATESQTD('Date'[Date])
)
```

#### Month-to-Date (MTD)

```dax
Sales MTD =
CALCULATE(
    [Sales Total],
    DATESMTD('Date'[Date])
)
```

### Year-over-Year (YoY) Comparison

```dax
Sales YoY =
VAR _currentYearSales = [Sales Total]
VAR _priorYearSales =
    CALCULATE(
        [Sales Total],
        SAMEPERIODLASTYEAR('Date'[Date])
    )
RETURN
    _currentYearSales - _priorYearSales
```

```dax
Sales YoY % =
VAR _currentYearSales = [Sales Total]
VAR _priorYearSales =
    CALCULATE(
        [Sales Total],
        SAMEPERIODLASTYEAR('Date'[Date])
    )
RETURN
    DIVIDE(_currentYearSales - _priorYearSales, _priorYearSales, 0)
```

### Month-over-Month (MoM) Comparison

```dax
Sales MoM =
VAR _currentMonthSales = [Sales Total]
VAR _priorMonthSales =
    CALCULATE(
        [Sales Total],
        DATEADD('Date'[Date], -1, MONTH)
    )
RETURN
    _currentMonthSales - _priorMonthSales
```

```dax
Sales MoM % =
VAR _currentMonthSales = [Sales Total]
VAR _priorMonthSales =
    CALCULATE(
        [Sales Total],
        DATEADD('Date'[Date], -1, MONTH)
    )
RETURN
    DIVIDE(_currentMonthSales - _priorMonthSales, _priorMonthSales, 0)
```

### vs Target Measures

```dax
Sales vs Target =
VAR _actual = [Sales Total]
VAR _target = [Sales Target]
RETURN
    _actual - _target
```

```dax
Sales vs Target % =
VAR _actual = [Sales Total]
VAR _target = [Sales Target]
VAR _variance = _actual - _target
RETURN
    DIVIDE(_variance, _target, 0)
```

```dax
Achievement Ratio =
DIVIDE([Sales Total], [Sales Target], 0)
```

### Ranking

```dax
Product Rank =
RANKX(
    ALL('Product'[Product Name]),
    [Sales Total],
    ,
    DESC,
    DENSE
)
```

```dax
Top N Products =
VAR _topN = 10
VAR _rank = [Product Rank]
RETURN
    IF(_rank <= _topN, [Sales Total], BLANK())
```

### Running Totals

```dax
Sales Running Total =
CALCULATE(
    [Sales Total],
    FILTER(
        ALL('Date'[Date]),
        'Date'[Date] <= MAX('Date'[Date])
    )
)
```

### Dynamic Period Selection

```dax
Sales Dynamic Period =
VAR _selectedPeriod = SELECTEDVALUE('Period Slicer'[Period])
RETURN
    SWITCH(
        _selectedPeriod,
        "MTD", [Sales MTD],
        "QTD", [Sales QTD],
        "YTD", [Sales YTD],
        [Sales Total]
    )
```

## KPI Card Measures

### KPI Card with Context

```dax
Sales KPI Card =
VAR _current = [Sales Total]
VAR _target = [Sales Target]
VAR _prior = CALCULATE([Sales Total], SAMEPERIODLASTYEAR('Date'[Date]))
VAR _vsTarget = _current - _target
VAR _vsTargetPct = DIVIDE(_vsTarget, _target, 0)
VAR _vsPrior = _current - _prior
VAR _vsPriorPct = DIVIDE(_vsPrior, _prior, 0)
RETURN
    "Current: " & FORMAT(_current, "$#,##0") & "
" &
    "Target: " & FORMAT(_target, "$#,##0") & " (" & FORMAT(_vsTargetPct, "+0.0%;-0.0%") & ")
" &
    "vs LY: " & FORMAT(_prior, "$#,##0") & " (" & FORMAT(_vsPriorPct, "+0.0%;-0.0%") & ")"
```

**Output Example**:
```
Current: $12,500,000
Target: $15,000,000 (-16.7%)
vs LY: $10,000,000 (+25.0%)
```

### Dynamic Title with Filter Context

```dax
Dynamic Title =
VAR _selectedPeriod = SELECTEDVALUE('Date'[Year Month])
VAR _defaultTitle = "Sales Performance Dashboard"
RETURN
    IF(
        ISFILTERED('Date'[Year Month]),
        _defaultTitle & " - " & _selectedPeriod,
        _defaultTitle & " - All Periods"
    )
```

### Status Badge

```dax
Status Badge =
VAR _achievementRatio = DIVIDE([Sales Total], [Sales Target], 0)
VAR _icon =
    SWITCH(
        TRUE(),
        _achievementRatio >= 1.15, "⭐",
        _achievementRatio >= 1.0, "🎯",
        _achievementRatio >= 0.9, "📈",
        _achievementRatio >= 0.8, "⚠️",
        "🚨"
    )
VAR _text =
    SWITCH(
        TRUE(),
        _achievementRatio >= 1.15, "OUTSTANDING",
        _achievementRatio >= 1.0, "TARGET ACHIEVED",
        _achievementRatio >= 0.9, "APPROACHING TARGET",
        _achievementRatio >= 0.8, "BELOW EXPECTATION",
        "REQUIRES ATTENTION"
    )
RETURN
    _icon & " " & _text
```

## Number Formatting

### Format Strings

```dax
-- Currency (no decimals)
FORMAT([Sales Total], "$#,##0")

-- Currency (2 decimals)
FORMAT([Margin], "$#,##0.00")

-- Percentage (1 decimal)
FORMAT([Growth Rate], "0.0%")

-- Percentage (0 decimals)
FORMAT([Achievement], "0%")

-- Thousands (K suffix)
FORMAT([Revenue], "#,##0,K")

-- Millions (M suffix)
FORMAT([Revenue], "$#,##0.0,,'M'")

-- With positive/negative indicators
FORMAT([Variance], "+$#,##0;-$#,##0;$0")

-- Percentage with positive/negative
FORMAT([YoY %], "+0.0%;-0.0%;0.0%")
```

### Conditional Formatting Expression

```dax
-- Use in conditional formatting rules
Sales Color =
VAR _variance = [Sales vs Target %]
RETURN
    SWITCH(
        TRUE(),
        _variance >= 0.15, "#7F35B2",  -- WTW Purple
        _variance >= 0.10, "#059669",  -- Green
        _variance >= 0, "#0891B2",     -- Cyan
        _variance >= -0.10, "#F59E0B", -- Amber
        "#DC2626"                       -- Red
    )
```

## DAX Formatting Standards (Mandatory)

### Rule 1 — Always declare variables first

Every non-trivial measure must open with VAR declarations before any RETURN logic. The only exception is a pure single-aggregation with no conditional logic (e.g. `SUM(Table[Col])`, `DISTINCTCOUNT(Table[Col])`).

**❌ BAD**:
```dax
Global Client Count YoY % =
DIVIDE([Client Count] - [Global Client Count PY], [Global Client Count PY])
```

**✅ GOOD**:
```dax
Global Client Count YoY % =
VAR _current = [Client Count]
VAR _prior = [Global Client Count PY]
RETURN
    DIVIDE(_current - _prior, _prior)
```

### Rule 2 — Capture every measure reference in a VAR before use

Any `[Measure]` reference must be assigned to a `_variable` before it is used in logic. Never reference the same measure twice inline — always capture it once.

**❌ BAD** (`[Global Client Count PY]` evaluated twice):
```dax
DIVIDE([Client Count] - [Global Client Count PY], [Global Client Count PY])
```

**✅ GOOD**:
```dax
VAR _current = [Client Count]
VAR _prior = [Global Client Count PY]
RETURN DIVIDE(_current - _prior, _prior)
```

---

## DAX Optimization Best Practices

### Use Variables

**❌ BAD** (recalculates [Sales Total] 3 times):
```dax
Sales Analysis =
[Sales Total] - [Sales Target] +
([Sales Total] * 0.1) +
IF([Sales Total] > 1000000, 100, 0)
```

**✅ GOOD** (calculates [Sales Total] once):
```dax
Sales Analysis =
VAR _sales = [Sales Total]
VAR _target = [Sales Target]
VAR _variance = _sales - _target
VAR _bonus = _sales * 0.1
VAR _incentive = IF(_sales > 1000000, 100, 0)
RETURN
    _variance + _bonus + _incentive
```

### Filter Early

**❌ BAD** (filters after calculation):
```dax
Large Sales =
SUMX(
    Sales,
    IF(Sales[Amount] > 1000, Sales[Amount], 0)
)
```

**✅ GOOD** (filters before calculation):
```dax
Large Sales =
CALCULATE(
    SUM(Sales[Amount]),
    Sales[Amount] > 1000
)
```

### Use SELECTEDVALUE for Single Values

**❌ BAD**:
```dax
Selected Product =
IF(
    HASONEVALUE('Product'[Product Name]),
    VALUES('Product'[Product Name]),
    "Multiple"
)
```

**✅ GOOD**:
```dax
Selected Product =
SELECTEDVALUE('Product'[Product Name], "Multiple")
```

### Field Parameter Slicers in HTML Cards

**Problem**: `SELECTEDVALUE('Parameter'[Parameter])` throws a composite key error in HTML card visuals because the visual has no field well — DAX cannot resolve the hidden RowNumber key that field parameter tables use.

**✅ Solution — use `MAXX(ALLSELECTED(...))`**:
```dax
VAR _selectedParam =
    MAXX(ALLSELECTED('Parameter'), 'Parameter'[Parameter])
VAR _param =
    IF(ISBLANK(_selectedParam), "DefaultValue", _selectedParam)
```

This aggregates over the slicer selection without requiring the composite key. Works in HTML cards, card visuals, and any visual without a field well.

**Important**: Set the Parameter slicer to **single-select** mode. If multiple values are selected, `MAXX` returns the last alphabetically.

**Pattern for dynamic dimension switching**:
```dax
-- Build all branches tagged with a Dim identifier
VAR _allData =
    UNION(
        SELECTCOLUMNS(VALUES('Table'[ColA]), "Label", 'Table'[ColA], "Revenue", CALCULATE([Measure]), "Dim", "ColA"),
        SELECTCOLUMNS(VALUES('Table'[ColB]), "Label", 'Table'[ColB], "Revenue", CALCULATE([Measure]), "Dim", "ColB")
    )
-- Then filter to the selected parameter
VAR _rawData =
    FILTER(_allData, [Dim] = _param)
```

Use `UNION` + `SELECTCOLUMNS` (not `SWITCH` returning tables) — all branches must share the same column schema (`Label`, `Revenue`, `Dim`). `SWITCH` returning tables causes "expression refers to multiple columns" errors.

### Rule 3 — Large models: pre-aggregate with SUMMARIZE, never FILTER/SUMX over fact VALUES

On models with 100M+ rows, **never** call a measure inside `FILTER(VALUES(fact[Key]), [Measure])` or `SUMX(VALUES(fact[Key]), [Measure])`. Each row triggers a full context transition — a separate storage engine query per client/product/key.

**❌ BAD** (one storage engine round-trip per unique GlobalPartyId):
```dax
Clients with 1 LOB =
VAR _clients =
    FILTER(
        VALUES(gold_salesops_fact_transaction[GlobalPartyId]),
        [Client Product count] = 1
    )
RETURN COUNTROWS(_clients)
```

**✅ GOOD** (single vectorized fact scan, no context transitions):
```dax
Clients with 1 LOB =
VAR _clientSummary =
    ADDCOLUMNS(
        SUMMARIZE(
            gold_salesops_fact_transaction,
            gold_salesops_fact_transaction[GlobalPartyId]
        ),
        "_classCount",
        CALCULATE(
            DISTINCTCOUNT(gold_salesops_fact_transaction[GlobalProductClassId]),
            NOT ISBLANK(gold_salesops_fact_transaction[GlobalProductClassId])
        )
    )
RETURN
    COUNTROWS(FILTER(_clientSummary, [_classCount] = 1))
```

When you need a simple count of unique (key1, key2) pairs (e.g. total LOB-client associations), use SUMMARIZE directly — no ADDCOLUMNS needed:

```dax
LOB Count =
VAR _pairs =
    SUMMARIZE(
        FILTER(fact, NOT ISBLANK(fact[ProductClassId])),
        fact[PartyId],
        fact[ProductClassId]
    )
RETURN COUNTROWS(_pairs)
```

**Anti-patterns that cause "expression services limit" errors on large models**:
- `FILTER(VALUES(fact[Key]), [Measure])` — context transition per row
- `SUMX(VALUES(fact[Key]), [Measure])` — context transition per row
- `ADDCOLUMNS(VALUES(dim[Key]), "_col", [Measure])` when dim has many rows
- Nested `CONCATENATEX` + `INTERSECT` over large virtual tables (flatten to SUMMARIZE first)

### Avoid Calculated Columns When Possible

**❌ BAD** (calculated column — evaluated for every row in table):
```dax
Sales[Year] = YEAR(Sales[Date])
```

**✅ GOOD** (measure — evaluated only when needed):
```dax
Sales Year = YEAR(MAX(Sales[Date]))
```

**Exception**: Calculated columns are OK for:
- Grouping/segmentation columns used in slicers
- Columns needed for relationships
- Static categorization logic

## Common Patterns Cheat Sheet

| Pattern | DAX Code |
|---------|----------|
| **Safe Division** | `DIVIDE([Numerator], [Denominator], 0)` |
| **Check if Filtered** | `IF(ISFILTERED('Table'[Column]), "Filtered", "All")` |
| **Single Selected Value** | `SELECTEDVALUE('Table'[Column], "Default")` |
| **Count Distinct** | `DISTINCTCOUNT('Table'[Column])` |
| **Count Rows** | `COUNTROWS('Table')` |
| **Max/Min Date** | `MAX('Date'[Date])` or `MIN('Date'[Date])` |
| **Previous Period** | `CALCULATE([Measure], DATEADD('Date'[Date], -1, MONTH))` |
| **Year Over Year** | `CALCULATE([Measure], SAMEPERIODLASTYEAR('Date'[Date]))` |
| **All Records (ignore filters)** | `CALCULATE([Measure], ALL('Table'))` |
| **% of Total** | `DIVIDE([Measure], CALCULATE([Measure], ALL('Table')))` |

---

## HTML Card Patterns

### Standard DAX Variable Block

Paste at the top of any HTML card measure. Choose Corporate or Indigo palette (see color-system.md).

```dax
-- === Indigo Palette ===
VAR _c1 = "#4f46e5" VAR _c2 = "#5ce1ff" VAR _c3 = "#e5e7eb" VAR _c4 = "#f59e0b"
VAR _c5 = "#10b981" VAR _c6 = "#ef4444" VAR _c7 = "#8b5cf6" VAR _c8 = "#f97316"
VAR _c9 = "#06b6d4" VAR _c10 = "#84cc16" VAR _c11 = "#ec4899" VAR _c12 = "#14b8a6"
VAR _cFallbk = "#94a3b8"
VAR _cWon  = "#22C55E"   -- Won Revenue green
VAR _cOpen = "#22D3EE"   -- Open Pipeline cyan
-- === Text Hierarchy ===
VAR _textPrimary   = "#181B1D"
VAR _textSecondary = "#485257"
VAR _textMuted     = "#9CA3AF"
VAR _textBody      = "#606E74"
-- === Surfaces & Borders ===
VAR _bgWhite      = "#FFFFFF"
VAR _bgChart      = "#F8FAFC"
VAR _borderLight  = "#F3F4F6"
VAR _borderMedium = "#E4E7E9"
-- === Shadows (token-matched) ===
VAR _shadowOuter = "0 10px 15px -3px rgba(0,0,0,0.1),0 4px 6px -2px rgba(0,0,0,0.05)"
VAR _shadowInner = "0 1px 3px rgba(0,0,0,0.04),0 4px 12px rgba(0,0,0,0.04)"
-- === Typography (font-size strings for CSS) ===
VAR _fs2xs = "0.5625rem"  -- 9px  micro labels
VAR _fsXs  = "0.6875rem"  -- 11px captions, badges, muted hints
VAR _fsSm  = "0.75rem"    -- 12px labels, sub-values
VAR _fsMd  = "0.875rem"   -- 14px body text
VAR _fsLg  = "1rem"       -- 16px secondary values
VAR _fsXl  = "1.25rem"    -- 20px card values (small KPIs, N/A states)
VAR _fs2xl = "1.5rem"     -- 24px KPI values
VAR _fs3xl = "1.75rem"    -- 28px hero values, primary KPI
-- === Border Radius (radius strings for CSS) ===
VAR _radSm   = "4px"     -- tags, inner chips
VAR _radMd   = "8px"     -- cards, panels, chart areas
VAR _radLg   = "12px"    -- outer containers
VAR _radXl   = "16px"    -- feature cards, modals
VAR _radFull = "9999px"  -- pill badges, progress bars
```

**Typography scale** maps to Segoe UI weights:
- `_fs2xs` / `_fsXs` — always paired with `font-weight:600` (uppercase labels) or `font-weight:400` (hints)
- `_fsSm` — labels and sub-values, `font-weight:400`–`600`
- `_fsMd` — body, list text, `font-weight:400`
- `_fsLg`–`_fs3xl` — KPI values, always `font-weight:700`; use `letter-spacing:-0.02em` at `_fs2xl`+

**Radius conventions** (Corporate style — do not mix freely):
- `_radSm` → badges, status chips, progress bar track
- `_radMd` → inner card sections, chart area backgrounds
- `_radLg` → card outer shells when a visible background is used
- `_radFull` → pill badges and circular progress arcs

---

### Stacked Pill Bar Chart (HTML)

Pixel-height bars driven entirely by DAX math. Used in `HTML_Revenue_By_Colleague`.

**How it works:**

- `_safeMax` = auto-scaled ceiling of the tallest bar (Won + Open) × 1.1, rounded to a clean step
- Each bar's pixel height = `DIVIDE(value, _safeMax) * _chartH`, minimum 5px so zero-values stay invisible
- Bars stack bottom-up inside a `flex-direction:column; justify-content:flex-end` container
- A unique `_RowNum` (rank + name tiebreaker × 0.0001) drives sort order and last-column border detection — avoids Dense rank ties breaking the right-edge border

```dax
VAR _chartH = 140   -- chart area height in px
VAR _pillW  = 8     -- bar width in px

-- Scale denominator
VAR _maxBar    = MAXX(_sorted, COALESCE([_Won], 0) + COALESCE([_Open], 0))
VAR _maxRaw    = MAX(_maxBar, 1)
VAR _magnitude = POWER(10, INT(LOG10(_maxRaw)))
VAR _stepSize  = IF((_maxRaw / _magnitude) <= 5, _magnitude / 2, _magnitude)
VAR _safeMax   = CEILING(_maxRaw * 1.1, _stepSize)

-- Unique row number (breaks Dense rank ties for border logic)
VAR _withRow =
    ADDCOLUMNS(
        _sorted,
        "_RowNum",
        RANKX(
            _sorted,
            [_Rank] + RANKX(_sorted, [Colleague], , ASC, SKIP) * 0.0001,
            , ASC, SKIP
        )
    )

-- Per-column rendering (inside CONCATENATEX over _withRow):
VAR _wonPx  = IF(_won  > 0, MAX(ROUND(DIVIDE(_won,  _safeMax) * _chartH, 0), 5), 0)
VAR _openPx = IF(_open > 0, MAX(ROUND(DIVIDE(_open, _safeMax) * _chartH, 0), 5), 0)
VAR _gapPx  = IF(_wonPx > 0 && _openPx > 0, 5, 0)   -- gap between segments
VAR _isLast = [_RowNum] = _count                      -- true only for the very last column
```

**Won label** — centered inside bar (frosted pill bg, only if bar ≥ 16px):
```dax
VAR _wonCenterY = ROUND(_chartH - _wonPx / 2, 0)
-- HTML: position:absolute; top:{_wonCenterY}px; left:50%; transform:translate(-50%,-50%)
--       background:rgba(255,255,255,0.55); border-radius:3px; padding:1px 3px
```

**Open label** — above top of open segment (only if open bar exists):
```dax
VAR _openLabelY = MAX(_chartH - (_wonPx + _openPx + _gapPx) - 4, 0)
-- HTML: position:absolute; top:{_openLabelY}px; left:50%; transform:translate(-50%,-100%)
```

**Column wrapper** — `align-items:center` keeps bar + name centered; border-right on all except last:
```dax
"<div style='display:flex;flex-direction:column;align-items:center;flex-shrink:0;min-width:56px;" &
IF(NOT(_isLast), "border-right:1px solid rgba(0,0,0,0.07);padding-right:10px;margin-right:4px;", "") & "'>"
```

**Bar div** — subtle glow via box-shadow at 20% opacity:
```dax
"<div style='width:" & _pillW & "px;border-radius:9999px;background:" & _cWon & ";" &
"box-shadow:0 0 5px 1px rgba(34,197,94,0.2);height:" & _wonPx & "px;flex-shrink:0;'></div>"
```

**Chart wrapper** — `#F8FAFC` bg, horizontal scroll, thin scrollbar, bottom padding prevents scrollbar covering x-axis names:
```dax
"<div style='background:#F8FAFC;border-radius:8px;padding:14px 12px 0;height:212px;overflow-x:auto;overflow-y:hidden;'>" &
"<div style='display:flex;align-items:flex-end;gap:0;min-height:194px;padding-bottom:18px;'>"
-- Scrollbar CSS: ::-webkit-scrollbar{width:4px;height:4px;}
```

---

### KPI Strip (4-column grid)

```dax
VAR _kpi =
    "<div style='display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin-bottom:12px;flex-shrink:0;'>" &
    -- Each cell:
    "<div>" &
    "<span style='display:block;font-size:24px;font-weight:700;color:#181B1D;font-family:Segoe UI,sans-serif;" &
    "letter-spacing:-0.02em;line-height:1;margin-bottom:4px;'>" & _fmtValue & "</span>" &
    "<span style='display:block;font-size:12px;font-weight:400;color:#9CA3AF;font-family:Segoe UI,sans-serif;'>" & _label & "</span>" &
    "</div>" &
    "</div>"
```

- Value: 24px / 700 / `#181B1D` / `letter-spacing:-0.02em`
- Label: 12px / 400 / `#9CA3AF` — sits below value

---

### Scrollable Table (flex-isolated)

Table scrolls independently; header/KPI/chart sections never scroll.

```dax
-- Container layout
"<div style='overflow:hidden;display:flex;flex-direction:column;height:530px;padding:16px 20px;'>"
--   header    flex-shrink:0
--   kpi grid  flex-shrink:0
--   chart     flex-shrink:0
--   table     flex:1; min-height:0; overflow-y:auto   ← absorbs remaining height

-- Header row
VAR _tblHdr =
    "<div style='display:flex;align-items:center;padding:0 0 6px;margin-bottom:2px;'>" &
    "<div style='width:24%;font-size:12px;font-weight:400;color:#9CA3AF;font-family:Segoe UI,sans-serif;'>Colleague</div>" &
    -- fixed-width numeric cols:
    "<div style='width:19%;font-size:12px;font-weight:400;color:#9CA3AF;font-family:Segoe UI,sans-serif;'>Business Target</div>" &
    -- right-aligned last col (accounting gap):
    "<div style='width:19%;font-size:12px;font-weight:400;color:#9CA3AF;font-family:Segoe UI,sans-serif;text-align:right;padding-right:10px;'>Business Gap</div>" &
    "</div>"

-- Data row (border-bottom on all except last)
"<div style='display:flex;align-items:center;padding:6px 0;" &
IF(NOT(_isLast), "border-bottom:1px solid #F3F4F6;", "") & "'>" &
"<div style='width:24%;font-size:11px;color:#485257;font-weight:400;font-family:Segoe UI,sans-serif;'>" & _name & "</div>" &
"<div style='width:19%;color:#181B1D;font-family:Segoe UI,sans-serif;font-size:11px;font-weight:600;'>" & _value & "</div>" &
"</div>"
```

**Accounting gap format** (positive plain, negative in parentheses):

```dax
VAR _absG = ABS(_gap)
VAR _gAmt = IF(_absG >= 1000000, "$" & FORMAT(_absG / 1000000, "0.0") & "M", "$" & FORMAT(_absG / 1000, "#,0") & "K")
VAR _fmtG = IF(_gap = 0, "—", IF(_gap > 0, _gAmt, "(" & _gAmt & ")"))
```

**Standard $K/$M formatter:**

```dax
VAR _fmt = IF(_val = 0, "—", IF(_val >= 1000000, "$" & FORMAT(_val / 1000000, "0.0") & "M", "$" & FORMAT(_val / 1000, "#,0") & "K"))
```

---

## Cross-Sell & Whitespace Analysis

Patterns for deriving which products a client holds and identifying gap (whitespace) opportunities. These patterns apply to any portfolio penetration or cross-sell analysis, not just CRB.

### Why NOT to use VALUES(dim[Column]) for held products

`VALUES(dim_product[GlobalProductClass])` traverses the relationship from the current filter context and returns **all** product classes linked to the selected client via any fact row — including rows with $0 or null revenue. This produces false positives: a client appears to "hold" every class they have ever been associated with, regardless of actual earned revenue.

**Always derive held products from the fact table with an explicit revenue filter.**

### Held products (fact-derived)

```dax
VAR _heldClasses =
    SUMMARIZE(
        FILTER(
            fact_transaction,
            fact_transaction[Revenue] > 0
                && NOT ISBLANK(fact_transaction[ProductClassId])
        ),
        dim_product[GlobalProductClass]
    )
```

`SUMMARIZE` over a filtered fact table returns only the product classes where the client has actual positive revenue. Column lineage from `dim_product` is preserved, enabling `EXCEPT()` to work correctly downstream.

### Whitespace (gap analysis)

```dax
VAR _allClasses =
    FILTER(
        ALL(dim_product[GlobalProductClass]),
        NOT ISBLANK(dim_product[GlobalProductClass])
    )

VAR _whitespace      = EXCEPT(_allClasses, _heldClasses)
VAR _whitespaceCount = COUNTROWS(_whitespace)
```

`EXCEPT` returns every class in `_allClasses` that is not in `_heldClasses`. `ALL()` removes the current filter context so every possible product class is always in scope as a potential whitespace opportunity.

### LOB / class count (always revenue-filtered)

```dax
VAR _lobCount =
    CALCULATE(
        DISTINCTCOUNT(fact_transaction[ProductLineId]),
        fact_transaction[Revenue] > 0,
        NOT ISBLANK(fact_transaction[ProductLineId])
    )
```

Always add `Revenue > 0` to LOB and class counts. Without it, $0-revenue rows inflate the count and give misleading density metrics.

---

## Pre-Aggregated Calculated Table (Matrix Performance)

### The problem

A matrix visual evaluates its measure in every cell's filter context. A `Penetrate` measure using `SUM(fact[Revenue])` fires one storage engine query per cell. At 5,000 clients × 15 product classes = 75,000 separate fact table scans per render — causing slow load and 10M row limit errors when the Top N filter is removed.

### The fix: pre-aggregate at model refresh

Create a **hidden calculated table** that stores only the (client, product class) pairs with real revenue. The matrix measure does a fast `COUNTROWS(FILTER(small_table))` — no fact table scan per cell.

**Step 1 — Calculated table (set Hidden = true in model)**

```dax
PenetrationMatrix =
SUMMARIZE(
    FILTER(
        fact_transaction,
        fact_transaction[Revenue] > 0
            && NOT ISBLANK(fact_transaction[ProductClassId])
    ),
    dim_client[ClientName],
    dim_product[GlobalProductClass]
)
```

**Step 2 — Matrix measure**

```dax
Penetrate =
VAR _client = SELECTEDVALUE(dim_client[ClientName])
VAR _class  = SELECTEDVALUE(dim_product[GlobalProductClass])
RETURN
IF(
    COUNTROWS(
        FILTER(
            PenetrationMatrix,
            PenetrationMatrix[ClientName]          = _client
                && PenetrationMatrix[GlobalProductClass] = _class
        )
    ) > 0,
    "P"
)
```

**Step 3 — Reference from HTML card with TREATAS**

When the same table is used inside an HTML card for `_heldClasses`, remap column lineage with `TREATAS` so `EXCEPT()` resolves correctly:

```dax
VAR _selectedClient = SELECTEDVALUE(dim_client[ClientName])
VAR _heldClasses =
    TREATAS(
        CALCULATETABLE(
            VALUES(PenetrationMatrix[GlobalProductClass]),
            PenetrationMatrix[ClientName] = _selectedClient
        ),
        dim_product[GlobalProductClass]
    )
```

**Performance comparison**

| Approach | Fact scans per render (5K × 15) | Behaviour |
|---|---|---|
| `SUM(fact[Revenue])` per cell | 75,000 | Slow / times out |
| `COUNTROWS(FILTER(PenetrationMatrix))` | 0 | Fast |

Keep the Top N visual filter as a guard — even with a pre-aggregated table, rendering more than 10M cells hits Power BI's visual row limit regardless of measure speed.

---

## Checklist: DAX Best Practices

Before publishing measures, verify:
- [ ] Measures use `[Square Brackets]`
- [ ] Variables use `_underscoreCamelCase`
- [ ] **Every non-trivial measure opens with VAR declarations** (Rule 1)
- [ ] **Every `[Measure]` reference is captured in a VAR before use** (Rule 2)
- [ ] Variables used to avoid recalculation
- [ ] No `FILTER(VALUES(fact[Key]), [Measure])` or `SUMX(VALUES(fact[Key]), [Measure])` on large tables (Rule 3)
- [ ] Pre-aggregation uses `SUMMARIZE` or `ADDCOLUMNS(SUMMARIZE(...))` instead of context-transitioning iterations
- [ ] Filters applied early in calculation context
- [ ] `DIVIDE()` used instead of `/` for safe division
- [ ] `SELECTEDVALUE()` used for single value checks
- [ ] Format strings defined in measures (not just visual formatting)
- [ ] Descriptive measure names with context (YoY, vs Target, %)
- [ ] Performance detection logic uses standard thresholds
- [ ] Conditional formatting uses performance color palette

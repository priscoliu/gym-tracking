-- ============================================================
-- SME Power BI — SQL Views (Fabric SQL Endpoint)
-- Converts all M code to SQL views
-- Source: Lakehouse 0ebd6604-a5db-4624-b535-497cd55663c1
-- ============================================================
-- NOTE: Replace LAKEHOUSE_NAME if using cross-lakehouse queries.
--       If running in the lakehouse SQL endpoint directly, just use dbo.
-- ============================================================


-- ============================================================
-- FACT_SALES
-- Source: src_sales_marketing
-- Grain: One row per policy transaction line (excl "Policy" rollup)
-- ============================================================

CREATE OR ALTER VIEW dbo.fact_sales AS
SELECT
    TRIM([Policy Number])                          AS PolicyNumber,
    CAST([Transaction Date] AS DATE)               AS TransactionDate,
    TRIM([Transaction Type])                       AS TransactionType,
    TRIM([Risk Class])                             AS ProductClass,
    TRIM([Invoice Number / Closing Reference])     AS InvoiceNumber,
    COALESCE(CAST([Base Premium] AS DECIMAL(18,2)), 0)  AS BasePremium,
    COALESCE(CAST([TOTAL] AS DECIMAL(18,2)), 0)         AS TotalPremium,
    COALESCE(CAST([Commission] AS DECIMAL(18,2)), 0)    AS Commission

FROM dbo.src_sales_marketing

WHERE TRIM(COALESCE([Risk Class], '')) <> 'Policy';  -- filter rollup rows
GO


-- ============================================================
-- FACT_QUOTES
-- Source: src_quote_marketing
-- Grain: One row per quote (excl test data)
-- ============================================================

CREATE OR ALTER VIEW dbo.fact_quotes AS
SELECT
    TRIM(QuoteType)                                AS QuoteType,
    CAST(CreationDate AS DATE)                     AS CreationDate,
    CAST(LastModifiedDate AS DATE)                 AS LastModifiedDate,
    TRIM(PolicyNumber)                             AS PolicyNumber,
    TRIM(QuoteReference)                           AS QuoteReference,
    TRIM(QuoteStatus)                              AS QuoteStatus,
    COALESCE(CAST(
        REPLACE(REPLACE(REPLACE(BasePremium, '$', ''), ',', ''), ' ', '')
        AS DECIMAL(18,2)), 0)                      AS BasePremium,
    COALESCE(CAST(
        REPLACE(REPLACE(REPLACE(TotalPremium, '$', ''), ',', ''), ' ', '')
        AS DECIMAL(18,2)), 0)                      AS TotalPremium

FROM dbo.src_quote_marketing

WHERE COALESCE(TestData, '') <> 'Yes';
GO


-- ============================================================
-- FACT_ISSUES
-- Source: src_issue_technology
-- Grain: One row per issue ticket
-- Backlog = IsOpen = 1 (open tickets only per boss)
-- ============================================================

CREATE OR ALTER VIEW dbo.fact_issues AS
SELECT
    TRIM([Ticket Number])                          AS TicketNumber,
    CAST([Date] AS DATE)                           AS RaisedDate,
    CAST([Date Fixed] AS DATE)                     AS FixedDate,
    TRIM([Status])                                 AS Status,
    TRIM([Description])                            AS Description,
    TRIM([Reporter])                               AS Reporter,

    -- IsOpen flag
    CASE WHEN TRIM([Status]) = 'Open' THEN 1 ELSE 0 END
                                                   AS IsOpen,

    -- DaysOpen: if fixed use fixed-raised, if open use today-raised
    CASE
        WHEN [Date Fixed] IS NOT NULL
            THEN DATEDIFF(DAY, [Date], [Date Fixed])
        WHEN TRIM([Status]) = 'Open'
            THEN DATEDIFF(DAY, [Date], GETDATE())
        ELSE NULL
    END                                            AS DaysOpen

FROM dbo.src_issue_technology

WHERE TRIM(COALESCE([Ticket Number], '')) <> '';
GO


-- ============================================================
-- FACT_CHANGE_ORDERS
-- Source: src_change_technology
-- Grain: One row per change request
-- Status has been cleaned by stakeholder (no more blanks)
-- Due date = DueDateNote (delivery date per boss)
-- ============================================================

CREATE OR ALTER VIEW dbo.fact_change_orders AS
SELECT
    TRIM([Change Request Number])                  AS ChangeRequestNumber,
    TRIM([Change Request])                         AS ChangeRequestDesc,
    TRIM([Status])                                 AS Status,
    CAST([Approved date] AS DATE)                  AS ApprovedDate,
    TRIM([Target Release Date to UAT])             AS TargetReleaseUAT,
    CAST([Release Date _Actual Release to Prod_] AS DATE)
                                                   AS ActualReleaseProd,
    TRIM([Due date])                               AS DueDateNote,
    COALESCE(CAST([Approved Cost] AS DECIMAL(18,2)), 0)
                                                   AS ApprovedCost,
    TRIM([Cost Type])                              AS CostType,
    TRIM([% Completion | Time and Materials])      AS CompletionPct,
    TRIM([Requirements and Acceptance Criteria])   AS Requirements,

    -- IsOpen: anything not Completed/Closed/Cancelled
    CASE
        WHEN TRIM([Status]) IN ('Completed', 'Closed', 'Cancelled') THEN 0
        ELSE 1
    END                                            AS IsOpen

FROM dbo.src_change_technology

WHERE TRIM(COALESCE([Change Request Number], '')) <> '';
GO


-- ============================================================
-- FACT_PROJECT_TASKS
-- Source: src_project_delivery
-- Grain: One row per project task
-- Dates are "Thu 12/04/25" format — parse in SQL
-- Duration is "84 days?" format — extract number
-- ============================================================

CREATE OR ALTER VIEW dbo.fact_project_tasks AS
SELECT
    TRIM([Task Name])                              AS TaskName,

    -- Parse dates: strip day prefix ("Thu "), then cast
    TRY_CAST(
        CASE
            WHEN [Start] LIKE '[A-Z][a-z][a-z] %'
                THEN SUBSTRING([Start], 5, LEN([Start]))
            ELSE [Start]
        END AS DATE)                               AS StartDate,

    TRY_CAST(
        CASE
            WHEN [Finish] LIKE '[A-Z][a-z][a-z] %'
                THEN SUBSTRING([Finish], 5, LEN([Finish]))
            ELSE [Finish]
        END AS DATE)                               AS FinishDate,

    TRY_CAST(
        CASE
            WHEN [Actual Finish] LIKE '[A-Z][a-z][a-z] %'
                THEN SUBSTRING([Actual Finish], 5, LEN([Actual Finish]))
            ELSE [Actual Finish]
        END AS DATE)                               AS ActualFinish,

    TRY_CAST(
        CASE
            WHEN [Baseline Deliverable Start] LIKE '[A-Z][a-z][a-z] %'
                THEN SUBSTRING([Baseline Deliverable Start], 5, LEN([Baseline Deliverable Start]))
            ELSE [Baseline Deliverable Start]
        END AS DATE)                               AS BaselineStart,

    TRY_CAST(
        CASE
            WHEN [Baseline Deliverable Finish] LIKE '[A-Z][a-z][a-z] %'
                THEN SUBSTRING([Baseline Deliverable Finish], 5, LEN([Baseline Deliverable Finish]))
            ELSE [Baseline Deliverable Finish]
        END AS DATE)                               AS BaselineFinish,

    -- Parse duration: "84 days?" → 84
    TRY_CAST(
        REPLACE(REPLACE(REPLACE(TRIM(COALESCE([Duration], '')), 'days', ''), 'day', ''), '?', '')
        AS INT)                                    AS Duration,

    [% Complete]                                   AS PctComplete,
    TRIM([Task Mode])                              AS TaskMode,
    TRIM([Resource Names])                         AS ResourceNames,
    TRY_CAST([Predecessors] AS INT)                AS Predecessors,
    TRIM([Notes])                                  AS Notes,

    -- IsCritical flag
    CASE WHEN TRIM([Critical]) = 'Yes' THEN 1 ELSE 0 END
                                                   AS IsCritical,

    -- EffectiveFinish: ActualFinish overrides planned Finish
    COALESCE(
        TRY_CAST(CASE WHEN [Actual Finish] LIKE '[A-Z][a-z][a-z] %'
            THEN SUBSTRING([Actual Finish], 5, LEN([Actual Finish]))
            ELSE [Actual Finish] END AS DATE),
        TRY_CAST(CASE WHEN [Finish] LIKE '[A-Z][a-z][a-z] %'
            THEN SUBSTRING([Finish], 5, LEN([Finish]))
            ELSE [Finish] END AS DATE)
    )                                              AS EffectiveFinish,

    -- MilestoneHorizon (30/60/90 days)
    CASE
        WHEN COALESCE(
            TRY_CAST(CASE WHEN [Actual Finish] LIKE '[A-Z][a-z][a-z] %'
                THEN SUBSTRING([Actual Finish], 5, LEN([Actual Finish]))
                ELSE [Actual Finish] END AS DATE),
            TRY_CAST(CASE WHEN [Finish] LIKE '[A-Z][a-z][a-z] %'
                THEN SUBSTRING([Finish], 5, LEN([Finish]))
                ELSE [Finish] END AS DATE)
        ) IS NULL THEN NULL
        WHEN DATEDIFF(DAY, GETDATE(), COALESCE(
            TRY_CAST(CASE WHEN [Actual Finish] LIKE '[A-Z][a-z][a-z] %'
                THEN SUBSTRING([Actual Finish], 5, LEN([Actual Finish]))
                ELSE [Actual Finish] END AS DATE),
            TRY_CAST(CASE WHEN [Finish] LIKE '[A-Z][a-z][a-z] %'
                THEN SUBSTRING([Finish], 5, LEN([Finish]))
                ELSE [Finish] END AS DATE)
        )) < 0 THEN 'Overdue'
        WHEN DATEDIFF(DAY, GETDATE(), COALESCE(
            TRY_CAST(CASE WHEN [Actual Finish] LIKE '[A-Z][a-z][a-z] %'
                THEN SUBSTRING([Actual Finish], 5, LEN([Actual Finish]))
                ELSE [Actual Finish] END AS DATE),
            TRY_CAST(CASE WHEN [Finish] LIKE '[A-Z][a-z][a-z] %'
                THEN SUBSTRING([Finish], 5, LEN([Finish]))
                ELSE [Finish] END AS DATE)
        )) <= 30 THEN 'Next 30 Days'
        WHEN DATEDIFF(DAY, GETDATE(), COALESCE(
            TRY_CAST(CASE WHEN [Actual Finish] LIKE '[A-Z][a-z][a-z] %'
                THEN SUBSTRING([Actual Finish], 5, LEN([Actual Finish]))
                ELSE [Actual Finish] END AS DATE),
            TRY_CAST(CASE WHEN [Finish] LIKE '[A-Z][a-z][a-z] %'
                THEN SUBSTRING([Finish], 5, LEN([Finish]))
                ELSE [Finish] END AS DATE)
        )) <= 60 THEN 'Next 60 Days'
        WHEN DATEDIFF(DAY, GETDATE(), COALESCE(
            TRY_CAST(CASE WHEN [Actual Finish] LIKE '[A-Z][a-z][a-z] %'
                THEN SUBSTRING([Actual Finish], 5, LEN([Actual Finish]))
                ELSE [Actual Finish] END AS DATE),
            TRY_CAST(CASE WHEN [Finish] LIKE '[A-Z][a-z][a-z] %'
                THEN SUBSTRING([Finish], 5, LEN([Finish]))
                ELSE [Finish] END AS DATE)
        )) <= 90 THEN 'Next 90 Days'
        ELSE 'Beyond 90 Days'
    END                                            AS MilestoneHorizon,

    -- DaysUntilFinish
    DATEDIFF(DAY, GETDATE(), COALESCE(
        TRY_CAST(CASE WHEN [Actual Finish] LIKE '[A-Z][a-z][a-z] %'
            THEN SUBSTRING([Actual Finish], 5, LEN([Actual Finish]))
            ELSE [Actual Finish] END AS DATE),
        TRY_CAST(CASE WHEN [Finish] LIKE '[A-Z][a-z][a-z] %'
            THEN SUBSTRING([Finish], 5, LEN([Finish]))
            ELSE [Finish] END AS DATE)
    ))                                             AS DaysUntilFinish,

    -- IsDelayed (EffectiveFinish > BaselineFinish)
    CASE
        WHEN COALESCE(
            TRY_CAST(CASE WHEN [Actual Finish] LIKE '[A-Z][a-z][a-z] %'
                THEN SUBSTRING([Actual Finish], 5, LEN([Actual Finish]))
                ELSE [Actual Finish] END AS DATE),
            TRY_CAST(CASE WHEN [Finish] LIKE '[A-Z][a-z][a-z] %'
                THEN SUBSTRING([Finish], 5, LEN([Finish]))
                ELSE [Finish] END AS DATE)
        ) > TRY_CAST(CASE WHEN [Baseline Deliverable Finish] LIKE '[A-Z][a-z][a-z] %'
            THEN SUBSTRING([Baseline Deliverable Finish], 5, LEN([Baseline Deliverable Finish]))
            ELSE [Baseline Deliverable Finish] END AS DATE)
        THEN 1 ELSE 0
    END                                            AS IsDelayed

FROM dbo.src_project_delivery

WHERE TRIM(COALESCE([Task Name], '')) <> '';
GO


-- ============================================================
-- DIM_CLIENTS
-- Source: src_quote_marketing LEFT JOIN src_sales_marketing
-- Grain: One row per distinct insured name
-- ============================================================

CREATE OR ALTER VIEW dbo.dim_clients AS
WITH insured_list AS (
    SELECT DISTINCT
        UPPER(TRIM(Insured))                       AS InsuredName,
        TRIM(REPLACE(COALESCE(NumberOfEmployees, ''), '''', ''))
                                                   AS EmployeeRange
    FROM dbo.src_quote_marketing
    WHERE TRIM(COALESCE(Insured, '')) <> ''
      AND COALESCE(TestData, '') <> 'Yes'
),
sales_address AS (
    SELECT DISTINCT
        UPPER(TRIM([Insured Name]))                AS InsuredName,
        TRIM([Street No_])                         AS StreetNumber,
        TRIM([Street Name])                        AS StreetName,
        TRIM([City/Suburb])                        AS City,
        UPPER(TRIM([State]))                       AS State,
        TRIM([Postcode])                           AS Postcode,
        TRIM([GNAF])                               AS GNAF,
        TRIM([Occupation_])                        AS Occupation,
        [Revenue]                                  AS InsuredRevenue
    FROM dbo.src_sales_marketing
    WHERE TRIM(COALESCE([Insured Name], '')) <> ''
)

SELECT
    ROW_NUMBER() OVER (ORDER BY i.InsuredName)     AS ClientKey,
    i.InsuredName,
    i.EmployeeRange,
    s.StreetNumber,
    s.StreetName,
    s.City,
    s.State,
    s.Postcode,
    s.GNAF,
    s.Occupation,
    s.InsuredRevenue

FROM insured_list i
LEFT JOIN sales_address s
    ON i.InsuredName = s.InsuredName;
GO


-- ============================================================
-- DIM_DATE
-- Generated calendar: Jun 2025 to Jun 2026
-- Australian FY (Jul-Jun)
-- ============================================================

CREATE OR ALTER VIEW dbo.dim_date AS
WITH date_spine AS (
    SELECT CAST('2025-06-01' AS DATE) AS dt
    UNION ALL
    SELECT DATEADD(DAY, 1, dt) FROM date_spine WHERE dt < '2026-06-30'
)

SELECT
    YEAR(dt) * 10000 + MONTH(dt) * 100 + DAY(dt)  AS DateKey,
    dt                                             AS [Date],
    YEAR(dt)                                       AS [Year],
    MONTH(dt)                                      AS [Month],
    DATENAME(MONTH, dt)                            AS MonthName,
    'Q' + CAST(DATEPART(QUARTER, dt) AS VARCHAR)   AS [Quarter],
    DATEPART(ISO_WEEK, dt)                         AS WeekNumber,
    DATEADD(DAY, 1 - DATEPART(WEEKDAY,
        DATEADD(DAY, -1, dt)), DATEADD(DAY, -1, dt))
                                                   AS WeekStartDate,

    -- Australian FY: Jul 2025 = FY2026
    CASE
        WHEN MONTH(dt) >= 7 THEN YEAR(dt) + 1
        ELSE YEAR(dt)
    END                                            AS FiscalYear,

    'FY' + RIGHT(CAST(
        CASE WHEN MONTH(dt) >= 7 THEN YEAR(dt) + 1 ELSE YEAR(dt) END
        AS VARCHAR), 2)                            AS FiscalYearLabel,

    YEAR(dt) * 100 + MONTH(dt)                     AS YearMonthSort

FROM date_spine

OPTION (MAXRECURSION 500);
GO

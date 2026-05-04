# Legacy CIS — Source Schema & Transformation Reference

**Source:** SharePoint Personal OneDrive CSV
`https://wtwonlineau-my.sharepoint.com/personal/prisco_liu_willistowerswatson_com/Documents/Apps/Microsoft Power Query/Uploaded Files/Legacy CIS 1.csv`

**Used by:** `stg_crm_legacy_cis` (DBT staging) → all `int_crm_*` intermediate models

---

## Power Query Transformation Summary

The M script does the following before landing the data:

1. Reads 43-column CSV, promotes headers
2. Casts column types (see table below)
3. Drops 17 trailing empty/junk columns (`""`, `_1` … `_17`)
4. Renames and reorders columns to match the CRM Bronze schema convention

No filtering, no row-level logic — purely structural cleanup.
**All business logic (dedup, left_anti join, Legacy key generation) belongs in DBT `int_crm_*` models.**

---

## Final Column Schema (after Power Query, before Lakehouse)

| Final Column Name | Original CSV Name | Type | Notes |
| :--- | :--- | :--- | :--- |
| `OpptyID` | `OpptyID` | `Int64` | Natural key — join to `src_crm_opportunity.OpptyID` |
| `OpptyName` | `OpptySummary` | `text` | Renamed |
| `OpptyOwner` | `Opportunity Owner` | `text` | Renamed |
| `ColleagueInvolved` | `Colleague Involved` | `text` | Renamed |
| `LobProductClass` | `ProductClass` | `text` | Renamed — matches `src_crm_opportunity.LobProductClass` |
| `Service` | `ProductSubClass` | `text` | Renamed — matches `src_crm_opportunity.Service` |
| `OpptyStatus` | `OpptyStatus` | `text` | |
| `OpptyState` | `OpptyState` | `text` | |
| `First Income Date` | `First Income Date` | `date` | Space in name — quote with backticks in Spark SQL |
| `Likelihood of Win` | `Likelihood of Win` | `Int64` | Space in name — no `%` suffix (already numeric) |
| `Frequency` | `Frequency` | `text` | |
| `CreatedOn` | `CreatedOn` | `date` | |
| `ReportingOffice` | `Service Office` | `text` | Renamed |
| `ReportingOfficeCountry` | `Finance Level` | `text` | Renamed — Finance Level maps to country in legacy |
| `ReportingOfficeRegion` | `Service Region` | `text` | Renamed |
| `ProfitCenter` | `Profit Center` | `text` | Renamed — space removed |
| `Est. Revenue (USD)` | `Est. Revenue (USD)` | `Int64` | Special chars — quote with backticks in Spark SQL |
| `Wt. Revenue (USD)` | `Wt. Revenue (USD)` | `Int64` | Special chars — quote with backticks in Spark SQL |
| `CCY` | `CCY` | `text` | |
| `Account` | `Account` | `text` | Join key for `int_crm_account` dedup |
| `GCID` | `GCID` | `Int64` | Join key for `int_crm_account` dedup — cast to string in DBT |
| `Tiers` | `Tiers` | `text` | |
| `Industry (Account Name) (Account)` | `Industry (Account Name) (Account)` | `text` | Long name — alias in DBT as `Industry` |
| `CloseDate` | `CloseDate` | `date` | |
| `Data Version` | `Data Version` | `text` | Space in name — quote with backticks in Spark SQL |

**Dropped columns (junk):** `""`, `_1` through `_17` — 17 trailing empty columns from CSV export artifact.

---

## DBT Staging Model Notes (`stg_crm_legacy_cis`)

The staging model should:

1. Cast `OpptyID` and `GCID` to `VARCHAR` — Bronze schema uses `Int64` but all joins
   in intermediate models use string comparison (`CAST(OpptyID AS VARCHAR(255))`).
2. Alias the long/special-char column names to clean DBT-safe names:

   | Raw column | DBT alias |
   | :--- | :--- |
   | `` `First Income Date` `` | `FirstIncomeDate` |
   | `` `Likelihood of Win` `` | `LikelihoodOfWin` |
   | `` `Est. Revenue (USD)` `` | `EstRevenueUsd` |
   | `` `Wt. Revenue (USD)` `` | `WtRevenueUsd` |
   | `` `Industry (Account Name) (Account)` `` | `Industry` |
   | `` `Data Version` `` | `DataVersion` |

3. No filtering — pass all rows through. Row exclusion (left_anti join vs `src_crm_opportunity`)
   happens in `int_crm_opportunity_unified`, not here.

---

## Columns Missing vs. `src_crm_opportunity` Schema

Legacy CIS does not have equivalents for these `src_crm_opportunity` columns.
DBT intermediate models must `NULL`-fill them when unioning:

| Missing column | Filled with |
| :--- | :--- |
| `MainKey` | Generated: `CAST(OpptyID AS VARCHAR) + '_' + SHA2(CONCAT(ColleagueInvolved, CreatedOn), 256)` |
| `PipelinePhase` | `NULL` |
| `Description` | `NULL` |
| `FormName` | `NULL` |
| `OpptyType` | `NULL` |
| `OpptySubType` | `NULL` |
| `ModifiedOn` | `NULL` |
| `DataSource` | `'Legacy CIS'` (literal) |

---

## Shortcut Setup (Stage 0.1)

Since the file lives in SharePoint/OneDrive, set up a **OneLake shortcut** in
`APAC_CRM_Analytics_LH` pointing to the CSV, or ingest via a single pipeline
copy activity using the SharePoint connector with the Power Query transformations
above applied at source.

**Target table name:** `src_crm_legacy_cis`
**Target Lakehouse:** `APAC_CRM_Analytics_LH`

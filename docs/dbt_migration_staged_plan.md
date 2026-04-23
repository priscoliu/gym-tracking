# DBT Migration: Staged Implementation Plan — CRM & Sales Star Schema (APAC Sales Operations)

**Last updated:** 2026-04-22
**Stack:** Microsoft Fabric · Delta Lake · dbt-fabric · Power BI Direct Lake
**Target workspaces:** `APAC_CRM_Analytics_LH` (Bronze) · `APAC_Reporting_LH` (Silver) · `The_Global_Loom` (Gold)

---

## Architecture Summary

```text
D365 CRM (SQL Server)
    │
    ▼
[Fabric Data Pipeline]          ← Bronze: raw extraction only, no transformation
    │
    ▼
APAC_CRM_Analytics_LH           ← Bronze Lakehouse
    │
    ▼
[DBT — dbt-fabric]              ← All transformation: staging → intermediate → marts
    │
    ▼
The_Global_Loom                 ← Gold Lakehouse (star schema)
    │
    ▼
Power BI (Direct Lake)          ← reads Gold Delta tables, no import
```

**What this replaces:**

| Old | New |
| :--- | :--- |
| `APAC Sales Model.ipynb` | DBT intermediate models |
| `02_silver_notebook_crm_crb.ipynb` | DBT mart models (fact + dims) |
| 9 CRB split tables (Singapore, HK, India...) | Power BI filter context on `dim_territory` |
| Dataflow-managed mapping tables (no naming convention) | DBT seeds (small) + renamed Lakehouse tables (large) |
| STEP 3B MERGE write-back | DBT `dbt test --severity warn` unmapped key report |

---

## Stage 0: Pre-conditions (do before any DBT work)

### 0.1 Bronze — Missing Tables

Two copy activities need to be added to `01_bronze_pipeline_crm.json`:

| Activity | Source | Target table | Status |
| :--- | :--- | :--- | :--- |
| Copy Legacy CIS | SharePoint / static Excel | `src_crm_legacy_cis` | **MISSING** |
| Copy Workers (raw) | `rs_workers` D365 table | `src_crm_workers` | **MISSING** |

`src_crm_legacy_cis` schema expected (from SQL views):
`OpptyID, OpptyName, OpptyOwner, ColleagueInvolved, LobProductClass, Service, ReportingOffice, ReportingOfficeCountry, ReportingOfficeRegion, ProfitCenter, CreatedOn, FirstIncomeDate, LikelihoodOfWin, Frequency, EstRevenueUSD, WtRevenueUSD, Tiers, GCID, Account, Industry_Account_Name_Account_`

### 0.2 Reference Tables — Rename in Lakehouse

All mapping tables currently managed by Dataflow need renaming before DBT can source them.
Large tables (>200 rows) stay in Lakehouse; small tables become DBT seeds.

| Current name (Dataflow) | New name | Size | Disposition |
| :--- | :--- | :--- | :--- |
| `CRB_Sub Product Class to GLOB Mapping` | `ref_crb_glob_subproduct` | 824 rows | OneLake shortcut |
| `CRB_Profit Center to GLOB Mapping` | `ref_crb_glob_profitcenter` | 850 rows | OneLake shortcut |
| `Profit Center to Business Mapping` | `ref_apac_pc_business` | unknown | OneLake shortcut |
| `Product to Business Mapping` | `ref_apac_product_business` | unknown | OneLake shortcut |
| `Service Owner Office Mapping` | `ref_apac_office_country` | unknown | OneLake shortcut |
| `CRB_Pipeline Phase Mapping` | `ref_crb_pipeline_phase` | 19 rows | **DBT seed** |
| `Frequency Mapping` | `ref_apac_frequency` | unknown | **DBT seed** |
| `CRB_Exchange Rate` | `ref_crb_fx_rates` | 180 rows | **DBT seed** |
| `CRB_Assumed Pipeline` | `ref_crb_assumed_pipeline` | 12 rows | **DBT seed** |

**Action:** rename via Fabric Lakehouse UI or T-SQL `EXEC sp_rename`. Drop Dataflow dependencies after rename confirmed.

### 0.3 DBT Project Setup

```text
dbt_apac_crm/
├── dbt_project.yml
├── profiles.yml
├── seeds/
│   ├── ref_crb_pipeline_phase.csv
│   ├── ref_apac_frequency.csv
│   ├── ref_crb_fx_rates.csv
│   └── ref_crb_assumed_pipeline.csv
├── models/
│   ├── staging/
│   ├── intermediate/
│   └── marts/
└── tests/
    └── unmapped_keys.yml
```

`profiles.yml` (dbt-fabric, Fabric Spark endpoint):

```yaml
apac_crm:
  target: dev
  outputs:
    dev:
      type: fabric
      server: <workspace-id>.datawarehouse.fabric.microsoft.com
      database: APAC_Reporting_LH
      schema: dbo
      authentication: cli
      threads: 4
```

---

## Stage 1: Staging Models (DBT views — no compute until downstream runs)

**Goal:** 1:1 read from Bronze. No logic. Type casts only.
**Materialization:** `view`
**Target schema:** `APAC_Reporting_LH` (intermediate staging, not exposed to Power BI)

### Models

| DBT model | Source table | Have SQL? | Status |
| :--- | :--- | :--- | :--- |
| `stg_crm_opportunity` | `src_crm_opportunity` | `02_silver_clean_crm_opportunity_unified.sql` (partial) | **Ready to write** |
| `stg_crm_sales` | `src_crm_sales` | None — new table | **Ready to write** |
| `stg_crm_account` | `src_crm_account` | `02_silver_clean_crm_account.sql` (Bronze half) | **Ready to write** |
| `stg_crm_users` | `src_crm_users` | `02_silver_clean_crm_users.sql` (Bronze half) | **Ready to write** |
| `stg_crm_product` | `src_crm_product` | `02_silver_clean_crm_product.sql` (Bronze half) | **Ready to write** |
| `stg_crm_profitcenter` | `src_crm_profitcenter` | `02_silver_clean_crm_profitcenter.sql` (Bronze half) | **Ready to write** |
| `stg_crm_legacy_cis` | `src_crm_legacy_cis` | All SQL views use it as source | **Blocked — Bronze table missing** |
| `stg_crm_tags` | `src_crm_tags` | None | **Ready to write** |
| `stg_crm_bridge_account_tags` | `src_crm_bridge_account_tags` | None | **Ready to write** |
| `stg_ref_glob_subproduct` | `ref_crb_glob_subproduct` | None | **Blocked — rename pending** |
| `stg_ref_glob_profitcenter` | `ref_crb_glob_profitcenter` | None | **Blocked — rename pending** |
| `stg_ref_pc_business` | `ref_apac_pc_business` | None | **Blocked — rename pending** |
| `stg_ref_product_business` | `ref_apac_product_business` | None | **Blocked — rename pending** |
| `stg_ref_office_country` | `ref_apac_office_country` | None | **Blocked — rename pending** |

**Seeds (no source table needed — CSV in repo):**
- `ref_crb_pipeline_phase` — export from `CRB_Pipeline Phase Mapping` (19 rows)
- `ref_apac_frequency` — export from `Frequency Mapping`
- `ref_crb_fx_rates` — export from `CRB_Exchange Rate` (180 rows)
- `ref_crb_assumed_pipeline` — export from `CRB_Assumed Pipeline` (12 rows)

**`sources.yml` declares all Bronze tables as sources with freshness checks.**

---

## Stage 2: Intermediate Models (DBT tables — Silver logic)

**Goal:** Merge Bronze + Legacy CIS, deduplicate, apply stable surrogate keys.
**Materialization:** `table`
**Target schema:** `APAC_Reporting_LH`

All four dimension intermediates follow the same pattern from the SQL views:
- Bronze rows pass through with native keys
- Legacy CIS rows appended where not already in Bronze (matched on GCID or name)
- Stable surrogate key: `SHA2(natural_key, 256)` — replaces non-deterministic `ROW_NUMBER()`

### Models

| DBT model | Was (SQL view) | Source SQL file | Depends on | Status |
| :--- | :--- | :--- | :--- | :--- |
| `int_crm_account` | `clean_crm_account` | `02_silver_clean_crm_account.sql` | `stg_crm_account`, `stg_crm_legacy_cis` | **Blocked — Legacy CIS missing** |
| `int_crm_users` | `clean_crm_users` | `02_silver_clean_crm_users.sql` | `stg_crm_users`, `stg_crm_legacy_cis` | **Blocked — Legacy CIS missing** |
| `int_crm_product` | `clean_crm_product` | `02_silver_clean_crm_product.sql` | `stg_crm_product`, `stg_crm_legacy_cis` | **Blocked — Legacy CIS missing** |
| `int_crm_profitcenter` | `clean_crm_profitcenter` | `02_silver_clean_crm_profitcenter.sql` | `stg_crm_profitcenter`, `stg_crm_legacy_cis` | **Blocked — Legacy CIS missing** |
| `int_crm_opportunity_unified` | `clean_crm_opportunity_unified` | `02_silver_clean_crm_opportunity_unified.sql` | `stg_crm_opportunity`, `stg_crm_legacy_cis` | **Blocked — Legacy CIS missing** |

### Key changes from SQL views to DBT

| SQL view issue | DBT fix |
| :--- | :--- |
| `ROW_NUMBER()` legacy keys — non-deterministic | `SHA2(CONCAT(GCID, AccountName), 256)` — stable on re-runs |
| `NOT EXISTS` subquery | `LEFT ANTI JOIN` pattern in Fabric SQL |
| Hard-coded Asia Specialty profit center list | `LEFT JOIN ref_apac_pc_business` — table-driven |
| Hard-coded country exclusion list | Seed table `ref_crm_excluded_countries` |
| Hard-coded expiry date `'2025-10-13'` | DBT variable `{{ var('expiry_date') }}` |

---

## Stage 3: Mart Models — Dimensions (DBT tables — Gold)

**Goal:** Final dimension tables for Power BI Direct Lake.
**Materialization:** `table`
**Target schema:** `The_Global_Loom`

These replace the dimension logic currently baked into `APAC Sales Model.ipynb` (workers join, profit center mapping, product mapping).

| DBT model | Grain | Key source SQL | Depends on | Status |
| :--- | :--- | :--- | :--- | :--- |
| `dim_account` | `AccountKey` | `02_silver_clean_crm_account.sql` | `int_crm_account` | **Blocked — Stage 2** |
| `dim_user` | `UserKey` | `02_silver_clean_crm_users.sql` | `int_crm_users` | **Blocked — Stage 2** |
| `dim_product` | `ProductClassKey` | `02_silver_clean_crm_product.sql` | `int_crm_product`, `stg_ref_glob_subproduct` | **Blocked — Stage 2 + rename** |
| `dim_profitcenter` | `ProfitcenterKey` | `02_silver_clean_crm_profitcenter.sql` | `int_crm_profitcenter`, `stg_ref_pc_business` | **Blocked — Stage 2 + rename** |
| `dim_pipeline_phase` | `D365PipelinePhase` | `02_silver_clean_crm_opportunity.sql` (join) | `ref_crb_pipeline_phase` (seed) | **Ready once seed exported** |
| `dim_frequency` | `CRMFrequency` | `02_silver_clean_crm_opportunity.sql` (join) | `ref_apac_frequency` (seed) | **Ready once seed exported** |
| `dim_territory` | `Country` | Finance Level logic in APAC Sales Model | `int_crm_opportunity_unified` | **Blocked — Stage 2** |
| `bridge_account_tags` | `AccountID + TagID` | Bronze passthrough | `stg_crm_bridge_account_tags`, `stg_crm_tags` | **Ready — no Legacy CIS dependency** |

**`dim_territory` replaces the 9 CRB split tables.** It holds `Country`, `ServiceRegion`, `FinanceLevel`, `AsiaSpecialtyFlag`. Power BI filters on this dimension instead of loading 9 separate tables.

---

## Stage 4: Mart Models — Facts (DBT incremental — Gold)

**Goal:** Final fact tables for Power BI Direct Lake.
**Materialization:** `incremental` (on `MainKey`) for the sales fact; `table` for opportunity.
**Target schema:** `The_Global_Loom`

| DBT model | Grain | Replaces | Depends on | Status |
| :--- | :--- | :--- | :--- | :--- |
| `fact_crm_sales` | `MainKey` (transaction line) | `src_crm_sales` passthrough + revenue measures | `stg_crm_sales`, `int_crm_opportunity_unified`, all dims | **Blocked — Stages 2 + 3** |
| `fact_crm_opportunity` | `MainKey` | `APAC Sales Model.ipynb` output + CRB notebook filter | `int_crm_opportunity_unified`, `dim_profitcenter`, `dim_user`, `stg_ref_glob_*`, `ref_crb_assumed_pipeline` | **Blocked — Stages 2 + 3** |

### `fact_crm_opportunity` column map (old notebook → DBT model)

| Old notebook column | DBT column | Source |
| :--- | :--- | :--- |
| `Account` | `AccountName` | `stg_crm_opportunity` |
| `GUID` | `OpportunityGUID` | `stg_crm_opportunity` |
| `OpptyID` | `OpportunityId` | `stg_crm_opportunity` |
| `Finance_Level` | → `dim_territory.Country` | `int_crm_opportunity_unified` enrichment |
| `Owner_Business_Name` | → `dim_user.BusinessName` | `dim_user` join on `ColleagueInvolvedKey` |
| `Owner_Segment_Lob_Name` | → `dim_user.SegmentLob` | `dim_user` join |
| `GLOBs` | `GlobMapping` | `stg_ref_glob_subproduct` / `stg_ref_glob_profitcenter` join |
| `Pipeline_Category` | `PipelineCategory` | `'Assumed Pipeline'` flag from seed join |
| `ANZ_OpptyType` | `AnzOpptyType` | Derived in model (Frequency + OpptyType logic) |
| `Est__Revenue__USD_` | `EstRevenueUsd` | `stg_crm_sales` join on `MainKey` |
| `Wt__Revenue__USD_` | `WtRevenueUsd` | `stg_crm_sales` join on `MainKey` |

---

## Stage 5: DBT Tests — Unmapped Key Detection

**Goal:** Replace the STEP 3B MERGE write-back with DBT relationship tests.
**Runs:** after every `dbt run` as `dbt test --severity warn`

```yaml
# tests/unmapped_keys.yml
models:
  - name: fact_crm_opportunity
    columns:
      - name: ProductSubClass
        tests:
          - relationships:
              to: ref('stg_ref_glob_subproduct')
              field: D365ProductSubClass
              severity: warn
              name: warn_unmapped_subproduct_glob

      - name: ProfitCenter
        tests:
          - relationships:
              to: ref('stg_ref_glob_profitcenter')
              field: D365ProfitCenter
              severity: warn
              name: warn_unmapped_profitcenter_glob

      - name: PipelinePhase
        tests:
          - relationships:
              to: ref('ref_crb_pipeline_phase')
              field: D365PipelinePhase
              severity: warn
              name: warn_unmapped_pipeline_phase
```

When `dbt test` runs, any new unmapped values print to the run log with the exact values. You update the seed CSV or Lakehouse table, re-run `dbt seed` + `dbt run`, done.

---

## Progress Tracker

| Stage | Deliverable | Blocked by | Status |
| :--- | :--- | :--- | :--- |
| **0.1** | Add `src_crm_legacy_cis` to Bronze pipeline | — | Not started |
| **0.2** | Rename 9 mapping tables in Lakehouse | — | Not started |
| **0.3** | Scaffold DBT project, export 4 seeds | — | Not started |
| **1** | 9 staging models + `sources.yml` | Stage 0 (partial) | Not started |
| **2** | 5 intermediate models | Stage 0.1 (Legacy CIS) | Not started |
| **3** | 8 dimension mart models | Stage 2 | Not started |
| **4** | 2 fact mart models | Stages 2 + 3 | Not started |
| **5** | DBT relationship tests | Stage 4 | Not started |
| — | Retire `APAC Sales Model.ipynb` | Stage 4 validated | Not started |
| — | Retire `02_silver_notebook_crm_crb.ipynb` | Stage 4 validated | Not started |
| — | Power BI models → Direct Lake on Gold | Stage 4 | Not started |

---

## What We Have vs. What We Need

### Have (can convert directly to DBT)

| Asset | Type | Maps to |
| :--- | :--- | :--- |
| `02_silver_clean_crm_account.sql` | SQL view | `int_crm_account` (Bronze half done; fix ROW_NUMBER → SHA2) |
| `02_silver_clean_crm_users.sql` | SQL view | `int_crm_users` (same pattern) |
| `02_silver_clean_crm_product.sql` | SQL view | `int_crm_product` (same pattern) |
| `02_silver_clean_crm_profitcenter.sql` | SQL view | `int_crm_profitcenter` (same pattern) |
| `02_silver_clean_crm_opportunity_unified.sql` | SQL view | `int_crm_opportunity_unified` |
| `02_silver_clean_crm_opportunity.sql` | SQL view | `fact_crm_opportunity` (enrichment + classification logic) |
| `02_silver_master_crm_sales.sql` | SQL view | `fact_crm_sales` (revenue + FK grain) |
| `APAC Sales Model.ipynb` | Notebook | Enrichment logic → `fact_crm_opportunity` joins |
| `02_silver_notebook_crm_crb.ipynb` | Notebook | CRB filter → Power BI `dim_territory` slice |
| `src_crm_opportunity` | Bronze table | `stg_crm_opportunity` |
| `src_crm_sales` | Bronze table | `stg_crm_sales` |
| `src_crm_account` | Bronze table | `stg_crm_account` |
| `src_crm_users` | Bronze table | `stg_crm_users` |
| `src_crm_product` | Bronze table | `stg_crm_product` |
| `src_crm_profitcenter` | Bronze table | `stg_crm_profitcenter` |
| `src_crm_tags` | Bronze table | `stg_crm_tags` |
| `src_crm_bridge_account_tags` | Bronze table | `bridge_account_tags` |

### Need (gaps to close before DBT can run end-to-end)

| Gap | Required for | Action |
| :--- | :--- | :--- |
| `src_crm_legacy_cis` | All `int_crm_*` models + `fact_crm_opportunity` | Add Bronze copy activity |
| `ref_crb_glob_subproduct` (renamed) | `dim_product`, `fact_crm_opportunity` | Rename in Lakehouse |
| `ref_crb_glob_profitcenter` (renamed) | `dim_profitcenter`, `fact_crm_opportunity` | Rename in Lakehouse |
| `ref_apac_pc_business` (renamed) | `dim_profitcenter` | Rename in Lakehouse |
| `ref_apac_product_business` (renamed) | `dim_product` | Rename in Lakehouse |
| `ref_apac_office_country` (renamed) | `fact_crm_opportunity` Finance Level enrichment | Rename in Lakehouse |
| `ref_crb_pipeline_phase.csv` | `dim_pipeline_phase`, `fact_crm_opportunity` | Export 19-row table → DBT seed |
| `ref_apac_frequency.csv` | `fact_crm_opportunity` | Export → DBT seed |
| `ref_crb_fx_rates.csv` | `fact_crm_opportunity` assumed pipeline | Export 180-row table → DBT seed |
| `ref_crb_assumed_pipeline.csv` | `fact_crm_opportunity` | Export 12-row table → DBT seed |
| DBT project scaffolded | Everything | `dbt init dbt_apac_crm` |
| `dbt-fabric` adapter installed | Everything | `pip install dbt-fabric` |

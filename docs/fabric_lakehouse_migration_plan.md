# Fabric Lakehouse Migration Plan: CRM & Sales Data

**Last updated:** 2026-04-22
**Detail:** Full staged breakdown → [`dbt_migration_staged_plan.md`](dbt_migration_staged_plan.md)

---

## 1. Executive Summary

Migrate APAC CRM pipeline from a denormalised notebook/Dataflow architecture to a
Fabric-native star schema, transformation managed entirely by **dbt-fabric**.

**Benefits:**

- Bronze pipeline extracts raw data only — no transformation in ingestion
- DBT handles all Silver (cleanse/merge) and Gold (star schema) logic with full lineage
- Power BI connects via Direct Lake to Gold Delta tables — no import, no Dataflows
- Unmapped reference keys surfaced as DBT test warnings, not silent MERGE write-backs
- 9 CRB country split tables eliminated — replaced by `dim_territory` + Power BI filter context

---

## 2. Architecture

```text
D365 CRM (SQL Server)
    │
    ▼
[Fabric Data Pipeline]                ← Bronze: raw extraction only
    │
    ▼
APAC_CRM_Analytics_LH (Bronze)        ← Delta tables: src_crm_*, ref_crm_*
    │
    ▼
[dbt-fabric]                          ← All transformation
    ├── staging/   (views)             ← 1:1 from Bronze, type casts only
    ├── intermediate/  (tables)        ← Silver: merge, dedup, stable keys
    └── marts/  (tables/incremental)   ← Gold: star schema dims + facts
    │
    ▼
The_Global_Loom (Gold)                ← fact_crm_*, dim_*, bridge_*
    │
    ▼
Power BI (Direct Lake)
```

---

## 3. Workspace Inventory

| Lakehouse | Role | Lakehouse ID |
| :--- | :--- | :--- |
| `APAC_CRM_Analytics_LH` | Bronze — raw D365 ingestion + reference tables | `1c0d3357-c170-4ddd-9738-e1c90bbe99f2` |
| `APAC_Reporting_LH` | Silver — DBT staging + intermediate (internal) | `34b6eb71-e1ed-4b06-832f-38346b869a1c` |
| `The_Global_Loom` | Gold — star schema, Power BI Direct Lake target | `2d1524ac-d471-4885-aedf-cd7ee45ba05e` |

Workspace ID (all three): `76ec20c3-c400-415a-99c6-708f8207d5f9`

---

## 4. What We're Replacing

| Old | Replaced by | Retire when |
| :--- | :--- | :--- |
| `APAC Sales Model.ipynb` | DBT intermediate + fact models | Stage 4 validated |
| `02_silver_notebook_crm_crb.ipynb` | DBT `fact_crm_opportunity` + `dim_territory` | Stage 4 validated |
| `02_silver_notebook_crm_account.ipynb` | DBT `int_crm_account` + `dim_account` | Stage 3 validated |
| 9 CRB split tables (Singapore, HK, India…) | `dim_territory` — Power BI filter context | Stage 3 validated |
| Dataflow-managed mapping tables | DBT seeds (small) + renamed Lakehouse tables (large) | Stage 0 complete |
| STEP 3B MERGE write-back (CRB notebook) | `dbt test --severity warn` unmapped key report | Stage 5 |

---

## 5. Star Schema — Target Model

**Facts (Gold — `The_Global_Loom`):**

| Table | Grain | Source |
| :--- | :--- | :--- |
| `fact_crm_sales` | `MainKey` — one row per transaction line | `src_crm_sales` + dim FK resolution |
| `fact_crm_opportunity` | `MainKey` — one row per opportunity service line | `int_crm_opportunity_unified` + enrichment joins |

**Dimensions (Gold — `The_Global_Loom`):**

| Table | Key | Source |
| :--- | :--- | :--- |
| `dim_account` | `AccountKey` | `int_crm_account` (Bronze + Legacy CIS merge) |
| `dim_user` | `UserKey` | `int_crm_users` (Bronze + Legacy CIS merge) |
| `dim_product` | `ProductClassKey` | `int_crm_product` + `ref_crb_glob_subproduct` |
| `dim_profitcenter` | `ProfitcenterKey` | `int_crm_profitcenter` + `ref_apac_pc_business` |
| `dim_territory` | `Country` | Finance Level logic from opportunity unified |
| `dim_pipeline_phase` | `D365PipelinePhase` | DBT seed |
| `dim_frequency` | `CRMFrequency` | DBT seed |
| `bridge_account_tags` | `AccountID + TagID` | `src_crm_bridge_account_tags` passthrough |

---

## 6. Staged Implementation Plan

### Stage 0: Pre-conditions ❌ Not started

Everything downstream is blocked until Stage 0 is complete.
**Detail:** [`dbt_migration_staged_plan.md — Stage 0`](dbt_migration_staged_plan.md)

#### 0.1 — Add missing Bronze tables to pipeline

**File:** [`01_bronze_pipeline_crm.json`](../Transformers/Alteryx-Migration/Fabric-Bronze/CRM/01_bronze_pipeline_crm.json)

Two copy activities missing:

| Activity | Source | Target table | Status |
| :--- | :--- | :--- | :--- |
| Copy Legacy CIS | SharePoint / static Excel | `src_crm_legacy_cis` | **MISSING** |
| Copy Workers (raw) | `rs_workers` (D365) | `src_crm_workers` | **MISSING** |

`src_crm_legacy_cis` expected columns:
`OpptyID, OpptyName, OpptyOwner, ColleagueInvolved, LobProductClass, Service,
ReportingOffice, ReportingOfficeCountry, ReportingOfficeRegion, ProfitCenter,
CreatedOn, FirstIncomeDate, LikelihoodOfWin, Frequency, EstRevenueUSD,
WtRevenueUSD, Tiers, GCID, Account, Industry_Account_Name_Account_`

#### 0.2 — Rename reference tables in Lakehouse

All mapping tables currently managed by Dataflow need renaming before DBT can source them.

| Current name (Dataflow) | New name | Rows | Disposition |
| :--- | :--- | :--- | :--- |
| `CRB_Sub Product Class to GLOB Mapping` | `ref_crb_glob_subproduct` | 824 | OneLake shortcut |
| `CRB_Profit Center to GLOB Mapping` | `ref_crb_glob_profitcenter` | 850 | OneLake shortcut |
| `Profit Center to Business Mapping` | `ref_apac_pc_business` | ? | OneLake shortcut |
| `Product to Business Mapping` | `ref_apac_product_business` | ? | OneLake shortcut |
| `Service Owner Office Mapping` | `ref_apac_office_country` | ? | OneLake shortcut |
| `CRB_Pipeline Phase Mapping` | `ref_crb_pipeline_phase` | 19 | DBT seed (CSV) |
| `Frequency Mapping` | `ref_apac_frequency` | ? | DBT seed (CSV) |
| `CRB_Exchange Rate` | `ref_crb_fx_rates` | 180 | DBT seed (CSV) |
| `CRB_Assumed Pipeline` | `ref_crb_assumed_pipeline` | 12 | DBT seed (CSV) |

Action: create OneLake shortcuts in `APAC_CRM_Analytics_LH` with the new names above.
Export the 4 seed tables to CSV files committed to the DBT repo.
Drop Dataflow dependencies after shortcuts confirmed.

#### 0.3 — Scaffold DBT project

```text
dbt_apac_crm/
├── dbt_project.yml
├── profiles.yml                   ← dbt-fabric Spark endpoint
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

Install: `pip install dbt-fabric`

---

### Stage 1: Staging Models ❌ Not started

**Materialization:** `view` — no compute until downstream runs.
**Blocked by:** Stage 0.2 (mapping table renames), Stage 0.1 (Legacy CIS for `stg_crm_legacy_cis`).

| DBT model | Source table | Existing SQL | Status |
| :--- | :--- | :--- | :--- |
| `stg_crm_opportunity` | `src_crm_opportunity` | `02_silver_clean_crm_opportunity_unified.sql` | Ready to write |
| `stg_crm_sales` | `src_crm_sales` | None — new table | Ready to write |
| `stg_crm_account` | `src_crm_account` | `02_silver_clean_crm_account.sql` (Bronze half) | Ready to write |
| `stg_crm_users` | `src_crm_users` | `02_silver_clean_crm_users.sql` (Bronze half) | Ready to write |
| `stg_crm_product` | `src_crm_product` | `02_silver_clean_crm_product.sql` (Bronze half) | Ready to write |
| `stg_crm_profitcenter` | `src_crm_profitcenter` | `02_silver_clean_crm_profitcenter.sql` (Bronze half) | Ready to write |
| `stg_crm_legacy_cis` | `src_crm_legacy_cis` | All SQL views reference it | **Blocked — 0.1** |
| `stg_crm_tags` | `src_crm_tags` | None | Ready to write |
| `stg_crm_bridge_account_tags` | `src_crm_bridge_account_tags` | None | Ready to write |
| `stg_ref_glob_subproduct` | `ref_crb_glob_subproduct` | None | **Blocked — 0.2** |
| `stg_ref_glob_profitcenter` | `ref_crb_glob_profitcenter` | None | **Blocked — 0.2** |
| `stg_ref_pc_business` | `ref_apac_pc_business` | None | **Blocked — 0.2** |
| `stg_ref_product_business` | `ref_apac_product_business` | None | **Blocked — 0.2** |
| `stg_ref_office_country` | `ref_apac_office_country` | None | **Blocked — 0.2** |

---

### Stage 2: Intermediate Models ❌ Not started

**Materialization:** `table` — physical Delta tables in `APAC_Reporting_LH`.
**Blocked by:** Stage 0.1 (Legacy CIS — every model below depends on it).

All 5 intermediates follow the same pattern from the existing SQL views:
Bronze rows pass through with native keys → Legacy CIS rows appended only where
not already matched by GCID or name → stable surrogate key via `SHA2` replaces
non-deterministic `ROW_NUMBER()`.

| DBT model | Was (SQL view) | Source file | Status |
| :--- | :--- | :--- | :--- |
| `int_crm_account` | `clean_crm_account` | `02_silver_clean_crm_account.sql` | **Blocked — 0.1** |
| `int_crm_users` | `clean_crm_users` | `02_silver_clean_crm_users.sql` | **Blocked — 0.1** |
| `int_crm_product` | `clean_crm_product` | `02_silver_clean_crm_product.sql` | **Blocked — 0.1** |
| `int_crm_profitcenter` | `clean_crm_profitcenter` | `02_silver_clean_crm_profitcenter.sql` | **Blocked — 0.1** |
| `int_crm_opportunity_unified` | `clean_crm_opportunity_unified` | `02_silver_clean_crm_opportunity_unified.sql` | **Blocked — 0.1** |

**Key SQL → DBT changes:**

| SQL view pattern | DBT fix |
| :--- | :--- |
| `ROW_NUMBER()` legacy surrogate keys | `SHA2(CONCAT(natural_key_cols), 256)` — deterministic |
| `NOT EXISTS` subquery | `LEFT ANTI JOIN` |
| Hard-coded Asia Specialty profit center list | `LEFT JOIN stg_ref_pc_business` |
| Hard-coded expiry date `'2025-10-13'` | `{{ var('expiry_date') }}` — DBT variable |
| Hard-coded country exclusion list | Seed table `ref_crm_excluded_countries` |

---

### Stage 3: Dimension Mart Models ❌ Not started

**Materialization:** `table`.
**Target:** `The_Global_Loom`.
**Blocked by:** Stage 2.

| DBT model | Key | Depends on | Status |
| :--- | :--- | :--- | :--- |
| `dim_account` | `AccountKey` | `int_crm_account` | **Blocked — Stage 2** |
| `dim_user` | `UserKey` | `int_crm_users` | **Blocked — Stage 2** |
| `dim_product` | `ProductClassKey` | `int_crm_product`, `stg_ref_glob_subproduct` | **Blocked — Stage 2** |
| `dim_profitcenter` | `ProfitcenterKey` | `int_crm_profitcenter`, `stg_ref_pc_business` | **Blocked — Stage 2** |
| `dim_territory` | `Country` | `int_crm_opportunity_unified` | **Blocked — Stage 2** |
| `dim_pipeline_phase` | `D365PipelinePhase` | `ref_crb_pipeline_phase` (seed) | Ready once seed exported |
| `dim_frequency` | `CRMFrequency` | `ref_apac_frequency` (seed) | Ready once seed exported |
| `bridge_account_tags` | `AccountID + TagID` | `stg_crm_bridge_account_tags` | Ready — no Legacy CIS dep |

`dim_territory` replaces the 9 CRB country split tables. It holds `Country`,
`ServiceRegion`, `FinanceLevel`, `AsiaSpecialtyFlag`. Power BI slices on this
dimension instead of loading separate per-country tables.

---

### Stage 4: Fact Mart Models ❌ Not started

**Materialization:** `incremental` on `MainKey` for `fact_crm_sales`; `table` for `fact_crm_opportunity`.
**Target:** `The_Global_Loom`.
**Blocked by:** Stages 2 + 3.

| DBT model | Grain | Replaces | Status |
| :--- | :--- | :--- | :--- |
| `fact_crm_sales` | `MainKey` (transaction line) | `src_crm_sales` + FK resolution | **Blocked — Stages 2+3** |
| `fact_crm_opportunity` | `MainKey` (opportunity service line) | `APAC Sales Model.ipynb` + CRB notebook | **Blocked — Stages 2+3** |

`fact_crm_opportunity` joins:

- `int_crm_opportunity_unified` — base rows + Legacy CIS merged
- `dim_user` — on `ColleagueInvolvedKey` → Business, LOB, Segment
- `dim_profitcenter` — on `ProfitCenterKey` → FinanceLevel, AsiaSpecialtyFlag
- `stg_ref_glob_subproduct` + `stg_ref_glob_profitcenter` → GLOB mapping
- `ref_crb_assumed_pipeline` (seed) + `ref_crb_fx_rates` (seed) → assumed pipeline rows unioned in
- `ref_crb_pipeline_phase` (seed) + `ref_apac_frequency` (seed) → standardised phase/frequency labels

---

### Stage 5: DBT Tests — Unmapped Key Detection ❌ Not started

**Replaces:** STEP 3B MERGE write-back in `02_silver_notebook_crm_crb.ipynb`.
**Blocked by:** Stage 4.

Run after every `dbt run`:

```bash
dbt test --select fact_crm_opportunity --severity warn
```

Any new unmapped `ProductSubClass`, `ProfitCenter`, or `PipelinePhase` values print
to the run log with exact values. Update the seed CSV or Lakehouse ref table,
re-run `dbt seed && dbt run`, done.

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
      - name: ProfitCenter
        tests:
          - relationships:
              to: ref('stg_ref_glob_profitcenter')
              field: D365ProfitCenter
              severity: warn
      - name: PipelinePhase
        tests:
          - relationships:
              to: ref('ref_crb_pipeline_phase')
              field: D365PipelinePhase
              severity: warn
```

---

### Stage 6: Orchestration ❌ Not started

**Goal:** Bronze pipeline → DBT run in dependency order on a daily schedule.

1. Fabric Data Pipeline triggers Bronze copy activities (existing `01_bronze_pipeline_crm.json`).
2. On success, trigger `dbt run --target prod` via Fabric notebook activity or REST API.
3. `dbt test` runs after `dbt run` — failures alert via email activity in pipeline.
4. Schedule: daily, aligned to D365 sync window.

---

### Stage 7: Power BI & Dataflow Retirement ❌ Not started

**Blocked by:** Stage 4 validated, parity confirmed.

1. Update Power BI Semantic Models to connect via **Direct Lake** to `The_Global_Loom`.
2. Parity validation: compare row counts + key KPIs between old Dataflow model and new
   Direct Lake model across at least 2 reporting periods.
3. Get sign-off from report owners.
4. Delete legacy Dataflows: `Account_Goals_GoalsActivity`, `Activity`, `ANZ_Leads`, `APAC Leads_`, `Opportunity`.
5. Delete retired notebooks: `APAC Sales Model.ipynb`, `02_silver_notebook_crm_crb.ipynb`.

---

## 7. Open Questions

| # | Question | Owner | Blocks |
| :--- | :--- | :--- | :--- |
| 1 | Where is Legacy CIS sourced from — SharePoint Excel or SQL? What connection? | Source system owner | Stage 0.1 |
| 2 | Should `src_crm_workers` be raw `rs_workers` or can `src_crm_users` cover dim_user? | Prisco | Stage 0.1 |
| 3 | Which Dataflow outputs does the current Power BI report rely on — full list? | Report owner | Stage 7 |
| 4 | What is the intended daily refresh schedule / D365 sync window? | Stakeholder | Stage 6 |

---

## 8. Progress Tracker

| Stage | Deliverable | Status |
| :--- | :--- | :--- |
| **0.1** | Add `src_crm_legacy_cis` + `src_crm_workers` to Bronze pipeline | Not started |
| **0.2** | Rename 9 mapping tables in Lakehouse | Not started |
| **0.3** | Scaffold DBT project + export 4 seeds to CSV | Not started |
| **1** | 14 staging models + `sources.yml` | Not started |
| **2** | 5 intermediate models | Not started |
| **3** | 8 dimension mart models | Not started |
| **4** | 2 fact mart models | Not started |
| **5** | DBT relationship tests for unmapped keys | Not started |
| **6** | Orchestration pipeline (Bronze → DBT → alert) | Not started |
| **7** | Power BI Direct Lake + Dataflow retirement | Not started |

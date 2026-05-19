# Bronze CRM Pipeline — Design Record

**Pipeline:** `01_bronze_pipeline_crm`  
**Sink:** `APAC_CRM_Analytics_bronze_LH`  
**Source:** Dataverse SQL endpoint — `wtwcrb` database  
**Connection:** `1cc13e34-2473-4d65-99ac-f6bc684cbf7a`

---

## What Changed

The original `Bronze_ETL` pipeline mixed Bronze, Silver, and Gold logic in a single pipeline:
- `Copy Opportunity` — 3-part UNION with GROUP BY + SUM aggregations
- `Copy Main Transaction` — 5-part UNION with probability-weighted revenue
- `Copy Account` — INNER JOIN to opportunity + regional WHERE filter
- `Copy Activity` — 6-table JOIN with CASE logic and user filters
- `ANZ_Leads` / `APAC Leads_` — two separate Dataflow Gen2 regional variants

**These were removed.** All Silver logic is now dbt's responsibility (Phase 2).  
**Dataflow Gen2 activities replaced** with Copy Data activities to reduce Fabric capacity spend.

---

## Bronze Tables — Current State

| Activity | Target Table | Source Entity | Key | Mode |
|---|---|---|---|---|
| Copy SystemUser | `src_crm_systemuser` | `systemuser` | `systemuserid` | Upsert |
| Copy Account | `src_crm_account` | `account` | `accountid` | Upsert |
| Copy Office | `src_crm_office` | `rs_office` | `rs_officeid` | Upsert |
| Copy ProfitCenter | `src_crm_profitcenter` | `rs_profitcenter` | `rs_profitcenterid` | Upsert |
| Copy Currency | `src_crm_currency` | `transactioncurrency` | `transactioncurrencyid` | Upsert |
| Copy ProductClass | `src_crm_product` | `rs_productclass` | `ProductClassKey` | Upsert |
| Copy Tags | `src_crm_tags` | `rs_rs_tagslist_opportunity` | `opportunityid` + `rs_tagslistid` | Upsert |
| Copy Tags_Accounts | `src_crm_bridge_account_tags` | `account` + `rs_account_rs_tagslist` | — | Overwrite |
| Copy KeyAccounts | `src_crm_key_accounts` | `account` + `rs_account_rs_tagslist` | — | Overwrite |
| Copy Opportunity | `src_crm_opportunity` | `opportunity` | `opportunityid` | Upsert |
| Copy OpportunityService | `src_crm_opportunity_service` | `rs_opportunityservice` | `rs_opportunityserviceid` | Upsert |
| Copy IncomeAssignment | `src_crm_income_assignment` | `rs_incomeassignment` | `rs_incomeassignmentid` | Upsert |
| Copy Activity | `src_crm_activity` | `activitypointer` | `activityid` | Upsert |
| Copy Lead | `src_crm_lead` | `lead` | `leadid` | Upsert |

### Bronze Contract Rules
- No JOINs except simple name lookups (e.g. `src_crm_tags` joins `rs_tagslist` for `rs_name`)
- No aggregation, no CASE business logic
- No regional filters — APAC scoping is Silver responsibility
- `statecode = 0` or `statecode IN (0, 1)` are the only permitted filters
- SQL reference files: `01_bronze_ingest_crm_*.sql` in this folder

---

## Silver dbt — Phase 2 Backlog

Target: `wh_sales_pipeline_gold` Warehouse, schema `apac_crm`

### 1. Staging Models (1:1 with Bronze, light cleaning only)

| dbt Model | Source Bronze Table | Key Tasks |
|---|---|---|
| `stg_crm__opportunity` | `src_crm_opportunity` | Cast types, rename to snake_case, null handling |
| `stg_crm__opportunity_service` | `src_crm_opportunity_service` | Cast types |
| `stg_crm__income_assignment` | `src_crm_income_assignment` | Cast types |
| `stg_crm__account` | `src_crm_account` | Cast types |
| `stg_crm__systemuser` | `src_crm_systemuser` | Cast types |
| `stg_crm__office` | `src_crm_office` | Cast types |
| `stg_crm__profitcenter` | `src_crm_profitcenter` | Cast types |
| `stg_crm__currency` | `src_crm_currency` | Cast types |
| `stg_crm__activity` | `src_crm_activity` | Cast types; `regardingobjecttypecodename` replaces old CASE JOIN |
| `stg_crm__lead` | `src_crm_lead` | Cast types |

### 2. Intermediate Models (joins + APAC scoping)

| dbt Model | Sources | Logic |
|---|---|---|
| `int_crm__opportunity_apac` | `stg_crm__opportunity` + `stg_crm__systemuser` + `stg_crm__office` | APAC filter: `COALESCE(rs_regionname, office.rs_subregionname, user.territoryidname) IN ('Asia', 'Australasia', ...)` |
| `int_crm__opportunity_service_enriched` | `stg_crm__opportunity_service` + `stg_crm__income_assignment` | Join service lines to income assignments on `rs_opportunityserviceid` |
| `int_crm__activity_apac` | `stg_crm__activity` + `stg_crm__systemuser` + `stg_crm__office` | Resolve owner region; filter to APAC; filter to Appointment/Email/Phone Call/Task |
| `int_crm__lead_apac` | `stg_crm__lead` + `stg_crm__systemuser` + `stg_crm__office` | APAC filter via owner territory; exclude SYSTEM-created |

### 3. Unified / Master Models (replacing old Silver SQL files)

| dbt Model | Replaces | Logic |
|---|---|---|
| `int_crm__opportunity_no_service` | `02_silver_clean_crm_opportunity_no_service.sql` | Non-OS path: opportunity + account + user + office joins |
| `int_crm__opportunity_with_service` | `02_silver_clean_crm_opportunity_service.sql` | OS path: opportunity + service + income assignment |
| `int_crm__opportunity_unified` | `02_silver_clean_crm_opportunity_unified.sql` | UNION of Non-OS + OS paths; add `DataVersion` flag |
| `clean_crm_opportunity` | `02_silver_clean_crm_opportunity.sql` | Add `isExpired`, tag string aggregation (STRING_AGG), Asia Specialty profit center logic, country exclusions — **move all hard-coded lists to ref tables** |
| `master_crm_sales` | `02_silver_master_crm_sales.sql` | Final UNION with Legacy CIS; join to dim lookups |

### 4. Silver Logic Removed from Bronze — Coverage Needed

| Logic Removed | Where to Rebuild |
|---|---|
| `RegardingType` CASE JOIN (activity) | `int_crm__activity_apac` — use `regardingobjecttypecodename` directly |
| `ProfitCenter`, `Office`, `Email` on activity | `int_crm__activity_apac` — join `stg_crm__systemuser` |
| APAC filter via COALESCE on opportunity | `int_crm__opportunity_apac` |
| Probability-weighted revenue on service lines | `int_crm__opportunity_with_service` |
| STRING_AGG tags to `tag1 / tag2` string | `clean_crm_opportunity` |
| `isExpired` date flag (hard-coded `2025-10-13`) | `clean_crm_opportunity` — replace with dbt variable |
| Asia Specialty profit center list (~50 rows) | Create `ref_crm_asia_specialty_profit_centers` seed |
| Country exclusion list | Create `ref_crm_excluded_countries` seed |
| ANZ vs APAC lead split | `int_crm__lead_apac` via owner territory — no longer two separate tables |

### 5. Retire After dbt Models Are Live

- `02_silver_clean_crm_opportunity.sql` (Fabric SQL view)
- `02_silver_clean_crm_opportunity_unified.sql`
- `02_silver_clean_crm_opportunity_no_service.sql`
- `02_silver_clean_crm_opportunity_service.sql`
- `02_silver_master_crm_sales.sql`
- `ANZ_Leads.Dataflow` + `APAC Leads_.Dataflow`
- `Activity.Dataflow`
- `Account_Goals_GoalsActivity.Dataflow`

---

## Fabric CLI Reference

Auth: `Prisco.Liu@willistowerswatson.com` — run commands from **cmd.exe** (not PowerShell subprocess).

```cmd
# List all items in workspace (verify what exists before retiring anything)
fab dir "APAC Sales Operations.Workspace"

# Deploy the Bronze pipeline
cd "C:\Users\LiuPr\OneDrive - Willis Towers Watson\Documents\WTW-Data-Solutions\fabric-workspace\Fabric-Bronze\CRM"
fab import "APAC Sales Operations.Workspace/01_bronze_pipeline_crm.DataPipeline" -i "01_bronze_pipeline_crm.DataPipeline" -f

# Export any Dataflow definition to inspect its SQL before retiring
fab export "APAC Sales Operations.Workspace/Activity.Dataflow" -o ./exports
```

> `fab export` / `fab import` require an interactive Windows console. Use cmd.exe or Windows Terminal, not PowerShell ISE or VS Code terminal.

---

## Artifacts to Retire After First Successful Pipeline Run

| Old Artifact | Replaced By |
|---|---|
| `01_bronze_new_ingest_crm.DataPipeline` | `01_bronze_pipeline_crm` |
| `01_bronze_OS&O_crm.DataPipeline` | `01_bronze_pipeline_crm` |
| `Activity.Dataflow` | Copy Activity |
| `Account_Goals_GoalsActivity.Dataflow` | Copy KeyAccounts |
| `ANZ_Leads.Dataflow` | Copy Lead |
| `APAC Leads_.Dataflow` | Copy Lead |

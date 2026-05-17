# Setup — dbt_apac_crm

## 1. Install

```bash
pip install dbt-fabric
```

## 2. Configure connection

1. Open Fabric portal → `APAC Sales Operations` workspace → `APAC_Reporting_WH`
2. Click **Settings** → copy the **SQL connection string** (server name)
3. Paste into `profiles.yml` replacing `<your-workspace>.datawarehouse.fabric.microsoft.com`

## 3. Verify connection

Run from this directory:

```bash
cd fabric-workspace/dbt_apac_crm
dbt debug --profiles-dir .
```

## 4. First build (staging views only)

```bash
dbt build --select staging --profiles-dir .
```

This creates 6 views in `APAC_Reporting_WH.staging`:
- `stg_crm_opportunity`
- `stg_crm_account`
- `stg_crm_product`
- `stg_crm_profitcenter`
- `stg_crm_users`
- `stg_crm_legacy_cis`

## 5. Next steps (WS2)

- Load ref_* seeds: `dbt seed --profiles-dir .`
- Enable APAC filter in `stg_crm_opportunity.sql` (uncomment the TODO block)
- Build intermediate models (opportunity union + enrichment)
- Build mart models (fact_crm_opportunity + dims)

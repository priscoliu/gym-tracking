-- Mart: fct_billing_baseline
-- Output: apac_billing_gold.fct_billing_baseline (table)
-- Unified baseline fact table -- one row per billing/revenue record across all 8 sources,
-- conformed to the 18-column standard schema that Power BI consumes.
--
-- POC state (2026-05-26): Arias only. Add UNION ALL of remaining sources as their
-- int_billing__*_enriched models come online.

with arias as (
    select * from {{ ref('int_billing__arias_enriched') }}
)

select
    SystemClientName,
    SystemProductClass,
    TX_ID,
    IncomeInceptionDate,
    Revenue,
    Premium,
    SystemID,
    RevenueCountry,
    ClientID,
    DataSource,
    Segment,
    BusinessType,
    RecurringRevenue,
    RevenueCities,
    DUNSNO,
    Currency,
    GCID,
    [Source]
from arias

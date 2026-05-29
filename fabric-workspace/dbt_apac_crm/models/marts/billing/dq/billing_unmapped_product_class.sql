{{ config(materialized='table') }}

-- DQ: SystemProductClass values from fct_billing_baseline that are NOT in the product mapping
-- (or where their Product/Service / SubProduct/Service comes through as NULL).
-- Output: apac_billing_gold.billing_unmapped_product_class (table)
-- Use: exported as CSV by downstream dataflow so the mapping owners can add the missing entries.
--
-- NOTE: Once Phase 2 wires baseline_ProductMapping into fct_billing_baseline, the
-- [Product/Service] / [SubProduct/Service] fields will be populated for matched classes.
-- Until then, this view will list everything; the result narrows as the mart catches up.

with unmapped as (
    select distinct
        SystemProductClass,
        Segment
    from {{ ref('fct_billing_baseline') }}
    where ([Product/Service] is null or [SubProduct/Service] is null)
      and SystemProductClass is not null
)

select * from unmapped

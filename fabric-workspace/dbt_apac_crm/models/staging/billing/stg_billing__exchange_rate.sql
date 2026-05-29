-- Staging: Exchange Rate reference
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_billing_exchange_rate
-- Output:  apac_billing_silver.stg_billing__exchange_rate (view)
-- Wide table from Bronze (one row per CURRENCY, one column per month-end date).
-- Light cleanup only -- the wide->long unpivot for FX conversion happens in int/mart.
-- All rate columns kept as strings here; downstream casts to decimal during the unpivot.

with source as (
    select * from {{ source('bronze_billing', 'src_billing_exchange_rate') }}
),

renamed as (
    select *
    from source
    where CURRENCY is not null
)

select * from renamed

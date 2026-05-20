-- Staging: CRM Currency
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_crm_currency
-- Output:  apac_crm_silver.stg_crm_currency (view)
-- Currency reference table. Joins on TransactionCurrencyId for USD conversion.

with source as (
    select * from {{ source('bronze', 'src_crm_currency') }}
),

renamed as (
    select
        cast(transactioncurrencyid as nvarchar(50))   as CurrencyId,
        cast(currencyname          as nvarchar(255))  as CurrencyName,
        cast(exchangerate          as decimal(18,6))  as ExchangeRate,
        cast(currencysymbol        as nvarchar(10))   as CurrencySymbol,
        cast(isocurrencycode       as nvarchar(10))   as IsoCurrencyCode,
        cast(statecode             as int)            as StateCode
    from source
    where transactioncurrencyid is not null
)

select * from renamed

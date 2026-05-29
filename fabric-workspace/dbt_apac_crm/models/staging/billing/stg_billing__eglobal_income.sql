-- Staging: eGlobal Income billing
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_eglobal_income_report
-- Output:  apac_billing_silver.stg_billing__eglobal_income (view)
-- One row per eGlobal income line. Type cast only -- no filters, no joins.
-- Trailing spaces in column names (Company , Inv Date , Industry Code ) are stripped at Bronze now,
-- so we can reference clean names here.

with source as (
    select * from {{ source('bronze_billing', 'src_eglobal_income_report') }}
),

renamed as (
    select
        cast([Client No]        as nvarchar(50))    as ClientNo,
        cast([Client Name]      as nvarchar(500))   as ClientName,
        cast(Department         as nvarchar(50))    as Department,          -- drives departmental filter in int
        try_cast(PREMIUM        as decimal(18,2))   as Premium,
        try_cast([TOTAL INCOME] as decimal(18,2))   as TotalIncome,
        cast(Company            as nvarchar(100))   as Company,
        cast(Branch             as nvarchar(100))   as Branch,
        cast(Risk               as nvarchar(255))   as Risk,
        cast([Inv No]           as nvarchar(100))   as InvNo,
        try_cast([EFFECTIVE DATE] as datetime)      as EffectiveDate,
        cast([INCOME CLASS]     as nvarchar(50))    as IncomeClass,         -- drives BusinessType / RecurringRevenue
        cast([PARTY ID]         as nvarchar(50))    as PartyId,             -- GCID source
        cast([DUNS NUMBER]      as nvarchar(50))    as DunsNo,
        cast(Source_Name        as nvarchar(255))   as SourceName           -- drives country/currency lookup
    from source
)

select * from renamed

-- Staging: Arias billing
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_arias_crb
-- Output:  apac_billing_silver.stg_billing__arias (view)
-- One row per Arias revenue record. Type cast + English column names only -- no filters, no joins.
-- Original Japanese column names from source preserved as comments.

with source as (
    select * from {{ source('bronze_billing', 'src_arias_crb') }}
),

renamed as (
    select
        cast([保険種類]      as nvarchar(255))   as InsuranceType,        -- SystemProductClass
        cast([契約者名]      as nvarchar(500))   as ClientName,           -- SystemClientName
        try_cast([保険始期]  as date)            as InceptionDate,
        cast([請求書番号]    as nvarchar(100))   as InvoiceNumber,        -- TX_ID source
        cast(Recurring       as nvarchar(10))    as RecurringFlag,        -- R / N
        try_cast([保険料]    as decimal(18,2))   as Premium,
        try_cast([手数料（税抜)] as decimal(18,2)) as Revenue,             -- Brokerage net of tax
        cast(GCID            as nvarchar(50))    as Gcid,
        cast([Policy No]     as nvarchar(100))   as PolicyNo,
        cast([チーム名]      as nvarchar(50))    as TeamName              -- needed for HB exclusion in int layer
    from source
)

select * from renamed

-- Staging: WR SPM billing
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_wr_spm
-- Output:  apac_billing_silver.stg_billing__wr_spm (view)
-- One row per WR SPM revenue record. Type cast only -- no filters, no joins.
-- GCID join with OracleID Mapping happens in the int layer.

with source as (
    select * from {{ source('bronze_billing', 'src_wr_spm') }}
),

renamed as (
    select
        cast(Reference                  as nvarchar(100))   as Reference,
        cast([Operating Unit]           as nvarchar(255))   as OperatingUnit,         -- filter + country/city mapping in int
        cast([Bill To Customer]         as nvarchar(500))   as BillToCustomer,
        try_cast([Invoice Amount]       as decimal(18,2))   as InvoiceAmount,
        cast(Currency                   as nvarchar(10))    as Currency,
        try_cast([Date]                 as datetime)        as TxnDate,
        cast([Bill To Customer Number]  as nvarchar(50))    as BillToCustomerNumber  -- join key to OracleID Mapping
    from source
)

select * from renamed

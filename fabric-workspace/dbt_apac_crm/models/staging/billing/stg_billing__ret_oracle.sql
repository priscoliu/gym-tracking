-- Staging: Oracle RET billing
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_ret_oracle
-- Output:  apac_billing_silver.stg_billing__ret_oracle (view)
-- One row per Oracle retirement project revenue record. Type cast only -- no filters, no joins.
-- GCID join with OracleID Mapping happens in the int layer.
-- SourceName needed to identify YYYYMM-as-integer files for the FiscalPeriod fix.

with source as (
    select * from {{ source('bronze_billing', 'src_ret_oracle') }}
),

renamed as (
    select
        cast([Customer Name]                       as nvarchar(500))   as CustomerName,
        cast([CLIENT GROUP Global DUNS Number]     as nvarchar(50))    as DunsNo,
        try_cast([Fiscal Period]                   as datetime)        as FiscalPeriod,
        cast([Fiscal Period Number]                as nvarchar(20))    as FiscalPeriodNumber,   -- YYYYMM string used for date reconstruction
        cast([Project Number]                      as nvarchar(100))   as ProjectNumber,
        cast(TW_Service_Offering                   as nvarchar(50))    as TwServiceOffering,    -- filters "RET" rows in int
        cast([Project Office Code]                 as nvarchar(50))    as ProjectOfficeCode,    -- city mapping in int
        cast([Project Market Cluster Name]         as nvarchar(100))   as ProjectMarketCluster,
        cast([Employee Market Cluster]             as nvarchar(100))   as EmployeeMarketCluster,
        try_cast([Revenue Amount]                  as decimal(18,2))   as RevenueAmount,
        cast([Primary Customer Account Number]     as nvarchar(50))    as PrimaryCustomerAcctNo, -- join key to OracleID Mapping
        cast(Source_Name                           as nvarchar(255))   as SourceName             -- triggers FiscalPeriod fix for older files
    from source
)

select * from renamed

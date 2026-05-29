-- Staging: Saiba billing
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_saiba_crb
-- Output:  apac_billing_silver.stg_billing__saiba (view)
-- One row per Saiba revenue record. Type cast only -- no filters, no joins.
-- Selecting only the columns the int layer uses (matches saiba_crb_baseline.m Base Columns).

with source as (
    select * from {{ source('bronze_billing', 'src_saiba_crb') }}
),

renamed as (
    select
        cast(CNo                 as nvarchar(50))    as Cno,
        cast(InstNo              as nvarchar(50))    as InstNo,
        cast(CustName            as nvarchar(500))   as CustName,
        cast(CustCode            as nvarchar(50))    as CustCode,
        cast(GCID                as nvarchar(50))    as Gcid,
        cast([Policy Type]       as nvarchar(255))   as PolicyType,
        cast(BizType             as nvarchar(50))    as BizType,
        try_cast(StartDate       as datetime)        as StartDate,
        try_cast([Brok Prem_]    as decimal(18,2))   as BrokPrem,
        try_cast(Brokerage       as decimal(18,2))   as Brokerage,
        cast(Department          as nvarchar(50))    as Department         -- needed for EB/HB/H&B exclusion in int layer
    from source
)

select * from renamed

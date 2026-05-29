-- Staging: Eclipse CRB billing
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_eclipse_crb
-- Output:  apac_billing_silver.stg_billing__eclipse_crb (view)
-- One row per Eclipse transaction. Type cast only -- no filters, no joins.
-- Selecting only the columns the int layer uses (matches eclipse_crb_baseline.m Base Columns).

with source as (
    select * from {{ source('bronze_billing', 'src_eclipse_crb') }}
),

renamed as (
    select
        cast(LegalEntity                as nvarchar(255))   as LegalEntity,
        cast(BusinessUnit               as nvarchar(100))   as BusinessUnit,
        cast(Team                       as nvarchar(255))   as Team,
        cast(PolicyRef                  as nvarchar(100))   as PolicyRef,
        try_cast(InceptionDate          as datetime)        as InceptionDate,
        try_cast(ExpiryDate             as datetime)        as ExpiryDate,
        cast(Insured                    as nvarchar(500))   as Insured,
        try_cast(NetBkgeUSDPlan         as decimal(18,2))   as NetBkgeUsdPlan,
        try_cast(GrossPremNonTtyUSDPlan as decimal(18,2))   as GrossPremNonTtyUsdPlan,
        cast(ClassOfBusiness            as nvarchar(255))   as ClassOfBusiness,
        cast([Willis Party ID]          as nvarchar(50))    as WillisPartyId,         -- GCID source
        cast([Dun and Bradstreet No]    as nvarchar(50))    as DunsNo,
        cast([Revenue Type]             as nvarchar(100))   as RevenueType,           -- drives BusinessType
        cast(InsuredID                  as nvarchar(50))    as InsuredId,             -- SystemID source
        cast(BUSegment                  as nvarchar(50))    as BuSegment              -- Segment after rename
    from source
)

select * from renamed

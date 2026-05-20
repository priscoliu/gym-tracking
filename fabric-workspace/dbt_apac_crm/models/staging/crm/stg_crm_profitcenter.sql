-- Staging: CRM Profit Center
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_crm_profitcenter
-- Output:  apac_crm_silver.stg_crm_profitcenter (view)
-- Reference table used in intermediate layer to resolve Finance Level 1.

with source as (
    select * from {{ source('bronze', 'src_crm_profitcenter') }}
),

renamed as (
    select
        cast(rs_profitcenterid    as nvarchar(50))   as ProfitCenterId,
        cast(rs_name              as nvarchar(500))  as ProfitCenterName,
        cast(rs_financelevel1name as nvarchar(255))  as FinanceLevel1Name,
        cast(rs_businessname      as nvarchar(255))  as BusinessName,
        cast(rs_lobname           as nvarchar(255))  as LobName,
        cast(rs_segmentname       as nvarchar(255))  as SegmentName,
        cast(statecode            as int)            as StateCode
    from source
    where rs_profitcenterid is not null
)

select * from renamed

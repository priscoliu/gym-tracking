-- Staging: CRM Profit Center
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_crm_profitcenter
-- Output:  APAC_Reporting_WH.staging.stg_crm_profitcenter

with source as (
    select * from {{ source('bronze', 'src_crm_profitcenter') }}
),

renamed as (
    select
        cast(ProfitcenterKey     as nvarchar(255))  as ProfitCenterKey,
        -- normalise for join with ref_profitcenter
        upper(ltrim(rtrim(cast(ProfitCenter as nvarchar(500))))) as ProfitCenter,
        cast(Financelevel        as nvarchar(255))  as FinanceLevel,
        cast(OwningBusinessName  as nvarchar(255))  as OwningBusinessName,
        cast(BusinessName        as nvarchar(255))  as BusinessName,
        cast(LobName             as nvarchar(255))  as LobName,
        cast(Segment             as nvarchar(255))  as Segment,
        cast(Statename           as nvarchar(255))  as StateName,
        cast(Createdon           as datetime2)      as CreatedOn,
        cast(Modifiedon          as datetime2)      as ModifiedOn
    from source
    where ProfitcenterKey is not null
)

select * from renamed

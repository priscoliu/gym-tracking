-- Staging: CRM Income Assignment
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_crm_income_assignment
-- Output:  apac_crm_silver.stg_crm_income_assignment (view)
-- Colleague split records. Joins to stg_crm_opportunity_service on OpportunityServiceId.

with source as (
    select * from {{ source('bronze', 'src_crm_income_assignment') }}
),

renamed as (
    select
        cast(rs_incomeassignmentid as nvarchar(50))   as IncomeAssignmentId,
        cast(rs_serviceline        as nvarchar(50))   as ServiceLineId,
        cast(rs_colleague          as nvarchar(50))   as ColleagueId,
        cast(rs_colleaguename      as nvarchar(500))  as ColleagueName,
        cast(rs_profitcenter       as nvarchar(50))   as ProfitCenterId,
        cast(rs_profitcentername   as nvarchar(500))  as ProfitCenterName,
        cast(rs_share              as decimal(10,4))  as ShareAmount,
        cast(rs_share_base         as decimal(10,4))  as ShareAmountBase,
        cast(statecode             as int)            as StateCode,
        cast(createdon             as datetime2)      as CreatedOn,
        cast(modifiedon            as datetime2)      as ModifiedOn
    from source
    where rs_incomeassignmentid is not null
)

select * from renamed

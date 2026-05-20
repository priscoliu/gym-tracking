-- Staging: CRM Opportunity Service Line
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_crm_opportunity_service
-- Output:  apac_crm_silver.stg_crm_opportunity_service (view)
-- One row per service line. Joins to stg_crm_opportunity on OpportunityId in intermediate layer.

with source as (
    select * from {{ source('bronze', 'src_crm_opportunity_service') }}
),

renamed as (
    select
        cast(rs_opportunityserviceid as nvarchar(50))   as OpportunityServiceId,
        cast(rs_opportunity          as nvarchar(50))   as OpportunityId,
        cast(rs_opportunityname      as nvarchar(500))  as OpportunityName,
        cast(rs_lobname              as nvarchar(255))  as LobName,
        cast(rs_servicename          as nvarchar(255))  as ServiceName,
        cast(rs_frequencyname        as nvarchar(100))  as FrequencyName,
        cast(rs_linevalue            as decimal(18,2))  as LineValue,
        cast(rs_linevalue_base       as decimal(18,2))  as LineValueBase,
        cast(transactioncurrencyid   as nvarchar(50))   as TransactionCurrencyId,
        cast(rs_officename           as nvarchar(255))  as OfficeName,
        cast(rs_office               as nvarchar(50))   as OfficeId,
        cast(statecode               as int)            as StateCode,
        cast(createdon               as datetime2)      as CreatedOn,
        cast(modifiedon              as datetime2)      as ModifiedOn
    from source
    where rs_opportunityserviceid is not null
)

select * from renamed

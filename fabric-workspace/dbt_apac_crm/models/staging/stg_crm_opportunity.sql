-- Staging: CRM Opportunity
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_crm_opportunity
-- Output:  apac_crm_silver.stg_crm_opportunity (view)
-- One row per D365 opportunity. Light type casting only — no joins, no filters beyond Bronze.

with source as (
    select * from {{ source('bronze', 'src_crm_opportunity') }}
),

renamed as (
    select
        cast(opportunityid                        as nvarchar(50))   as OpportunityId,
        cast(rs_opportunitynumber                 as nvarchar(50))   as OpportunityNumber,
        cast([name]                               as nvarchar(500))  as OpportunityName,
        cast(stepname                             as nvarchar(255))  as PipelinePhase,
        cast([description]                        as nvarchar(max))  as Description,
        cast(rs_formname                          as nvarchar(255))  as FormName,
        cast(rs_productclassname                  as nvarchar(255))  as ProductClassName,
        cast(rs_productsubclassname               as nvarchar(255))  as ProductSubClassName,
        cast(rs_frequencyname                     as nvarchar(100))  as FrequencyName,
        cast(statuscodename                       as nvarchar(100))  as StatusCodeName,
        cast(statecodename                        as nvarchar(100))  as StateCodeName,
        cast(statecode                            as int)            as StateCode,
        cast(rs_opportunitytypename               as nvarchar(100))  as OpportunityTypeName,
        cast(rs_opportunitysubtypename            as nvarchar(100))  as OpportunitySubTypeName,
        cast(estimatedvalue                       as decimal(18,2))  as EstimatedValue,
        cast(estimatedvalue_base                  as decimal(18,2))  as EstimatedValueBase,
        cast(rs_weightedincome                    as decimal(18,2))  as WeightedIncome,
        cast(rs_weightedincome_base               as decimal(18,2))  as WeightedIncomeBase,
        cast(transactioncurrencyid                as nvarchar(50))   as TransactionCurrencyId,
        cast(rs_probabilityname                   as nvarchar(50))   as ProbabilityName,
        cast(rs_premium_base                      as decimal(18,2))  as PremiumBase,
        cast(rs_projectstartdate                  as date)           as ProjectStartDate,
        cast(rs_latestmodifieddate                as date)           as LatestModifiedDate,
        cast(createdon                            as datetime2)      as CreatedOn,
        cast(actualclosedate                      as date)           as ActualCloseDate,
        cast(campaignidname                       as nvarchar(255))  as CampaignName,
        cast(parentaccountid                      as nvarchar(50))   as ParentAccountId,
        cast(parentaccountidname                  as nvarchar(500))  as ParentAccountName,
        cast(ownerid                              as nvarchar(50))   as OwnerId,
        cast(owneridname                          as nvarchar(500))  as OwnerName,
        cast(rs_regionname                        as nvarchar(255))  as RegionName,
        cast(rs_officename                        as nvarchar(255))  as OfficeName,
        cast(rs_office                            as nvarchar(50))   as OfficeId,
        cast(rs_incomeassignmentprofitcenter1name as nvarchar(500))  as ProfitCenterName,
        cast(rs_incomeassignmentfinancelevel11name as nvarchar(255)) as FinanceLevel1Name,
        cast(rs_inceptiondate                     as date)           as InceptionDate,
        cast(originatingleadid                    as nvarchar(50))   as OriginatingLeadId
    from source
    where opportunityid is not null
)

select * from renamed

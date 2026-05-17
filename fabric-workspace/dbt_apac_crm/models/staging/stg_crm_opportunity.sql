-- Staging: CRM Opportunity
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_crm_opportunity
-- Output:  APAC_Reporting_WH.staging.stg_crm_opportunity
--
-- APAC filter applied via ref_territory.IsAPACInScope (added once seeds are loaded in WS2).
-- Join keys normalised with UPPER + TRIM on both sides.

with source as (
    select * from {{ source('bronze', 'src_crm_opportunity') }}
),

renamed as (
    select
        cast(MainKey              as nvarchar(255))  as MainKey,
        cast(OpptyID              as nvarchar(255))  as OpptyID,
        cast(OpptyName            as nvarchar(500))  as OpptyName,
        cast(OpptyOwner           as nvarchar(500))  as OpptyOwner,
        cast(ColleagueInvolved    as nvarchar(500))  as ColleagueInvolved,
        cast(LobProductClass      as nvarchar(255))  as LobProductClass,
        cast(Service              as nvarchar(255))  as Service,
        cast(PipelinePhase        as nvarchar(255))  as PipelinePhase,
        cast(Description          as nvarchar(max))  as Description,
        cast(FormName             as nvarchar(255))  as FormName,
        cast(OpptyStatus          as nvarchar(100))  as OpptyStatus,
        cast(OpptyState           as nvarchar(100))  as OpptyState,
        cast(OpptyType            as nvarchar(100))  as OpptyType,
        cast(OpptySubType         as nvarchar(100))  as OpptySubType,
        cast(LikelihoodOfWin      as nvarchar(50))   as LikelihoodOfWin,
        cast(Frequency            as nvarchar(100))  as Frequency,
        cast(ProjectStartDate     as date)           as ProjectStartDate,
        cast(OriginatingLeadID    as nvarchar(255))  as OriginatingLeadID,
        cast(ReportingOffice      as nvarchar(255))  as ReportingOffice,

        -- normalise join key for ref_territory join downstream
        upper(ltrim(rtrim(cast(ReportingOfficeCountry  as nvarchar(255))))) as ReportingOfficeCountry,
        upper(ltrim(rtrim(cast(ReportingOfficeRegion   as nvarchar(255))))) as ReportingOfficeRegion,
        upper(ltrim(rtrim(cast(ProfitCenter            as nvarchar(500))))) as ProfitCenter,

        cast(CreatedOn            as datetime2)      as CreatedOn,
        cast(ModifiedOn           as datetime2)      as ModifiedOn,
        cast(FirstIncomeDate      as date)           as FirstIncomeDate,
        cast(DataSource           as nvarchar(100))  as DataSource

    from source
    where MainKey is not null
)

-- TODO (WS2): add APAC filter once ref_territory seed is loaded:
-- inner join {{ ref('ref_territory') }} t
--     on renamed.ReportingOfficeCountry = upper(ltrim(rtrim(t.Country)))
-- where t.IsAPACInScope = 1

select * from renamed

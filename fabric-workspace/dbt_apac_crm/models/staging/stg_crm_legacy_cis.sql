-- Staging: Legacy CIS
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_crm_legacy_cis  (shortcut)
-- Output:  APAC_Reporting_WH.staging.stg_crm_legacy_cis
--
-- Provides historical opportunities pre-D365. Unioned with stg_crm_opportunity
-- in the intermediate layer to produce the full opportunity set.
-- Excludes any OpptyID already present in src_crm_opportunity (dedup at intermediate layer).

with source as (
    select * from {{ source('bronze', 'src_crm_legacy_cis') }}
),

renamed as (
    select
        cast(OpptyID              as nvarchar(255))  as OpptyID,
        cast(OpptyName            as nvarchar(500))  as OpptyName,
        cast(OpptyOwner           as nvarchar(500))  as OpptyOwner,
        cast(ColleagueInvolved    as nvarchar(500))  as ColleagueInvolved,
        cast(LobProductClass      as nvarchar(255))  as LobProductClass,
        cast(Service              as nvarchar(255))  as Service,
        cast(OpptyStatus          as nvarchar(100))  as OpptyStatus,
        cast(OpptyState           as nvarchar(100))  as OpptyState,
        cast([Likelihood of Win]  as nvarchar(50))   as LikelihoodOfWin,
        cast(Frequency            as nvarchar(100))  as Frequency,
        cast(ReportingOffice      as nvarchar(255))  as ReportingOffice,
        upper(ltrim(rtrim(cast(ReportingOfficeCountry as nvarchar(255))))) as ReportingOfficeCountry,
        upper(ltrim(rtrim(cast(ReportingOfficeRegion  as nvarchar(255))))) as ReportingOfficeRegion,
        upper(ltrim(rtrim(cast(ProfitCenter           as nvarchar(500))))) as ProfitCenter,
        upper(ltrim(rtrim(cast(UserName               as nvarchar(500))))) as UserName,
        cast(CreatedOn            as datetime2)      as CreatedOn,
        cast([First Income Date]  as date)           as FirstIncomeDate,
        cast('Legacy CIS'         as nvarchar(100))  as DataSource
    from source
    where OpptyID is not null
)

select * from renamed

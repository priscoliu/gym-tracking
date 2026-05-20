-- Staging: CRM Lead
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_crm_lead
-- Output:  apac_crm_silver.stg_crm_lead (view)
-- Open and converted leads. ANZ vs APAC scope filter is intermediate layer responsibility.

with source as (
    select * from {{ source('bronze', 'src_crm_lead') }}
),

renamed as (
    select
        cast(leadid             as nvarchar(50))   as LeadId,
        cast(fullname           as nvarchar(500))  as FullName,
        cast(firstname          as nvarchar(255))  as FirstName,
        cast(lastname           as nvarchar(255))  as LastName,
        cast(companyname        as nvarchar(500))  as CompanyName,
        cast(emailaddress1      as nvarchar(255))  as EmailAddress,
        cast(telephone1         as nvarchar(100))  as Phone,
        cast(mobilephone        as nvarchar(100))  as MobilePhone,
        cast(subject            as nvarchar(500))  as Subject,
        cast([description]      as nvarchar(max))  as Description,
        cast(leadsourcecodename as nvarchar(255))  as LeadSourceName,
        cast(industrycodename   as nvarchar(255))  as IndustryName,
        cast(sic                as nvarchar(50))   as SicCode,
        cast(budgetamount       as decimal(18,2))  as BudgetAmount,
        cast(budgetamount_base  as decimal(18,2))  as BudgetAmountBase,
        cast(numberofemployees  as int)            as NumberOfEmployees,
        cast(estimatedvalue     as decimal(18,2))  as EstimatedValue,
        cast(estimatedclosedate as date)           as EstimatedCloseDate,
        cast(ownerid            as nvarchar(50))   as OwnerId,
        cast(owneridname        as nvarchar(500))  as OwnerName,
        cast(statecode          as int)            as StateCode,
        cast(statecodename      as nvarchar(100))  as StateCodeName,
        cast(statuscodename     as nvarchar(100))  as StatusCodeName,
        cast(createdon          as datetime2)      as CreatedOn,
        cast(modifiedon         as datetime2)      as ModifiedOn
    from source
    where leadid is not null
)

select * from renamed

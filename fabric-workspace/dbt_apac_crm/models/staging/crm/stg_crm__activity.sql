-- Staging: CRM Activity
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_crm_activity
-- Output:  apac_crm_silver.stg_crm_activity (view)
-- Open and completed activities. Office/region resolution via SystemUserId join at intermediate layer.

with source as (
    select * from {{ source('bronze_crm', 'src_crm_activity') }}
),

renamed as (
    select
        cast(activityid             as nvarchar(50))   as ActivityId,
        cast(activitytypecodename   as nvarchar(100))  as ActivityTypeName,
        cast(subject                as nvarchar(500))  as Subject,
        cast(regardingobjectid      as nvarchar(50))   as RegardingObjectId,
        cast(regardingobjectidname  as nvarchar(500))  as RegardingObjectName,
        cast(ownerid                as nvarchar(50))   as OwnerId,
        cast(owneridname            as nvarchar(500))  as OwnerName,
        cast(owninguser             as nvarchar(50))   as OwningUser,
        cast(createdon              as datetime2)      as CreatedOn,
        cast(createdbyname          as nvarchar(500))  as CreatedByName,
        cast(modifiedon             as datetime2)      as ModifiedOn,
        cast(modifiedbyname         as nvarchar(500))  as ModifiedByName,
        cast(scheduledstart         as datetime2)      as ScheduledStart,
        cast(scheduledend           as datetime2)      as ScheduledEnd,
        cast(actualstart            as datetime2)      as ActualStart,
        cast(actualend              as datetime2)      as ActualEnd,
        cast(statecode              as int)            as StateCode,
        cast(statecodename          as nvarchar(100))  as StateCodeName,
        cast(prioritycodename       as nvarchar(100))  as PriorityCodeName
    from source
    where activityid is not null
)

select * from renamed

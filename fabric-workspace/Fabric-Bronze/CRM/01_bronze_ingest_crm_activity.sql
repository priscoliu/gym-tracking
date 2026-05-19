-- =============================================================================
-- 01_bronze_ingest_crm_activity
-- Output: src_crm_activity  → APAC_CRM_Analytics_bronze_LH
-- Source: Dataverse — activitypointer entity
-- Layer:  Bronze
--
-- Bronze contract: raw D365 columns only. No joins, no aggregation.
-- regardingobjectidname carries the linked entity name. The entity type code
-- column does not exist on this CRM instance — Silver resolves type via joins.
-- Region and office resolution (via systemuser join) is Silver responsibility.
-- Replaces: Activity.Dataflow (two regional variants → one unfiltered pull).
--
-- dbt Phase 2: source for stg_crm__activity.
-- =============================================================================

SELECT
    activityid,
    activitytypecodename,
    subject,
    regardingobjectid,
    regardingobjectidname,
    ownerid,
    owneridname,
    owninguser,
    createdon,
    createdbyname,
    modifiedon,
    modifiedbyname,
    scheduledstart,
    scheduledend,
    actualstart,
    actualend,
    statecode,
    statecodename,
    prioritycodename
FROM
    activitypointer
WHERE
    statecode IN (0, 1)

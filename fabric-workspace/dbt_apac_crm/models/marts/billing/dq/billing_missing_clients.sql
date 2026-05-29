{{ config(materialized='table') }}

-- DQ: Clients in fct_billing_baseline that are NOT in the client masterlist.
-- Output: apac_billing_gold.billing_missing_clients (table)
-- Use: exported as CSV by downstream dataflow for analysts to recheck and add to the masterlist.
-- Source masterlist:  bronze_billing.src_billing_client_list (ClientID column)
-- Match logic: case-insensitive, trimmed.

with tx as (
    select
        SystemClientName as Account,
        DUNSNO,
        GCID,
        DataSource as [Data Source],
        ClientID,
        RevenueCountry,
        SystemID
    from {{ ref('fct_billing_baseline') }}
),

masterlist as (
    select
        lower(ltrim(rtrim(cast(ClientID as nvarchar(50)))))   as ClientIDKey
    from {{ source('bronze_billing', 'src_billing_client_list') }}
    where ClientID is not null
),

missing as (
    select distinct
        tx.Account,
        tx.DUNSNO,
        tx.GCID,
        tx.[Data Source],
        tx.ClientID,
        tx.RevenueCountry,
        tx.SystemID
    from tx
    left join masterlist m
        on lower(ltrim(rtrim(tx.ClientID))) = m.ClientIDKey
    where m.ClientIDKey is null
)

select * from missing

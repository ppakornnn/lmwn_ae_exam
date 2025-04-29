{{ config(
    materialized='view'
) }}

SELECT
        interaction_id
    ,   campaign_id
    ,   customer_id
    ,   session_id
    ,   order_id
    ,   CAST(interaction_datetime AS DATE)      AS interaction_date
    ,   interaction_datetime
    ,   event_type
    ,   platform
    ,   device_type
    ,   ad_cost                         AS ad_cost_thb
    ,   revenue                         AS revenue_thb
    ,   is_new_customer

FROM    {{source('raw_duckdb_data','campaign_interactions')}}
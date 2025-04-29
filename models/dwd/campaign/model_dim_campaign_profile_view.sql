{{ config(
    materialized='view'
) }}

SELECT
        campaign_id
    ,   campaign_name
    ,   start_date
    ,   end_date
    ,   DATE_DIFF('day', start_date, end_date)      AS campaign_duration_day
    ,   campaign_type
    ,   objective
    ,   channel
    ,   budget
    ,   cost_model
    ,   targeting_strategy
    ,   is_active
    
FROM    {{source('raw_duckdb_data','campaign_master')}}
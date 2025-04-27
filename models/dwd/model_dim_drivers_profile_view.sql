{{ config(
    materialized='view'
) }}

SELECT
        driver_id
    ,   join_date
    ,   vehicle_type
    ,   region
    ,   CASE
            WHEN active_status = 'active'   THEN 1
            WHEN active_status = 'inactive' THEN 0
        ELSE NULL
        END AS is_active
    ,   driver_rating
    ,   bonus_tier

FROM    {{source('raw_duckdb_data','drivers_master')}}
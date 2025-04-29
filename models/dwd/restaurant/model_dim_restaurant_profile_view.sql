{{ config(
    materialized='view'
) }}

SELECT
        restaurant_id
    ,   name                            AS restaurant_name
    ,   category
    ,   city
    ,   average_rating
    ,   CASE LOWER(active_status)
            WHEN 'active' THEN true
            WHEN 'inactive' THEN false
            ELSE NULL
        END AS is_active
    ,   prep_time_min

FROM     {{source('raw_duckdb_data','restaurants_master')}}

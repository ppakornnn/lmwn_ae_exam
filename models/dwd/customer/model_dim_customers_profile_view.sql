{{ config(
    materialized='view'
) }}

SELECT
        customer_id
    ,   signup_date
    ,   customer_segment
    ,   CASE 
            WHEN LOWER(status) = 'active'   THEN true
            WHEN LOWER(status) = 'inactive' THEN false
            ELSE NULL
        END AS is_active
    ,   referral_source
    ,   birth_year
    ,   CASE 
            WHEN LOWER(gender) ='male'     THEN 0
            WHEN LOWER(gender) ='female'   THEN 1
            WHEN LOWER(gender) ='other'    THEN 2
            ELSE NULL
        END AS gender
    ,   preferred_device

FROM    {{source('raw_duckdb_data','customers_master')}}
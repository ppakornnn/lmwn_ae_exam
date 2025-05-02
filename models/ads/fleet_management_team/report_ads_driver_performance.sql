{{ config(
    materialized='table'
) }}

SELECT
            driver_id
        ,   join_date
        ,   vehicle_type
        ,   region
        ,   is_active
        ,   driver_rating
        ,   bonus_tier
        ,   cnt_assigned_order
        ,   cnt_completed_order
        ,   avg_resp_accepted_order_sec
        ,   avg_duration_create_complete_sec
        ,   cnt_late_delivery
        ,   feedback_driver

FROM    {{ ref('model_dws_driver_profile') }}
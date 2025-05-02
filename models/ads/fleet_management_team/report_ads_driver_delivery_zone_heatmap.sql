{{ config(
    materialized='table'
) }}

SELECT
        delivery_zone
    ,   city
    ,   cnt_delivery_request
    ,   cnt_complete_order
    ,   completion_ratio
    ,   avg_delivery_time_sec
    ,   cnt_delivery_cancel_unavailable_driver
    ,   avg_delivery_speed_kmh
    ,   cnt_late_delivery
    ,   cnt_driver_active
    ,   delivery_request_driver_active_ratio

FROM    {{ref('model_dws_driver_delivery_heatmap')}}

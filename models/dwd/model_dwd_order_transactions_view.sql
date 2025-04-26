{{ config(
    materialized='view'
) }}

SELECT
        order_id
    ,   customer_id
    ,   restaurant_id
    ,   driver_id
    ,   order_datetime
    ,   pickup_datetime
    ,   delivery_datetime
    ,   order_status
    ,   CASE
            WHEN order_status = 'completed' THEN true
            ELSE false
        END AS is_net_order
    ,   delivery_zone
    ,   total_amount            AS total_amount_thb
    ,   payment_method
    ,   is_late_delivery
    ,   delivery_distance_km

FROM     {{source('raw_duckdb_data','order_transactions')}}

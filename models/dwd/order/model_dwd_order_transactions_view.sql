{{ config(
    materialized='view'
) }}

WITH order_transactions AS (
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

FROM    {{ source('raw_duckdb_data','order_transactions') }}
)
,   campaign_order AS (
    SELECT
            campaign_id
        ,   order_id

    FROM    {{ ref('model_dwd_campaign_interactions_view') }}
    WHERE
        TRUE
        AND event_type = 'conversion' -- Select only conversion since this is event which make order happen
)

SELECT
            t1.order_id
        ,   t1.customer_id
        ,   t1.restaurant_id
        ,   t1.driver_id
        ,   t2.campaign_id
        ,   t1.order_datetime
        ,   t1.pickup_datetime
        ,   t1.delivery_datetime
        ,   t1.order_status
        ,   t1.is_net_order
        ,   t1.delivery_zone
        ,   t1.total_amount_thb
        ,   t1.payment_method
        ,   t1.is_late_delivery
        ,   t1.delivery_distance_km

FROM    order_transactions t1
        LEFT JOIN campaign_order t2 ON t1.order_id = t2.order_id
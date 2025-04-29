{{ config(
    materialized='table'
) }}

WITH driver_profile AS (
    SELECT
            driver_id
        ,   region
        ,   is_active
    
    FROM    {{ref('model_dim_drivers_profile_view')}}
)


,   order_transactions AS (
    SELECT
            order_id
        ,   driver_id
        ,   restaurant_id
        ,   customer_id
        ,   delivery_zone
        ,   is_net_order
        ,   is_late_delivery
        ,   delivery_distance_km
    
    FROM    {{ref('model_dwd_order_transactions_view')}}
)
,   order_delivery AS (
    SELECT
            order_id
        ,   order_created_datetime
        ,   order_accepted_datetime
        ,   order_picked_up_datetime
        ,   order_completed_datetime
        ,   order_failed_datetime
        ,   order_canceled_datetime
        ,   DATE_DIFF('sec', order_created_datetime, order_completed_datetime)      AS duration_delivery_sec

    FROM    {{ref('model_dwd_order_delivery_view')}}
)
,   restaurant_profile AS (
    SELECT
            restaurant_id
        ,   city
    
    FROM    {{ref('model_dim_restaurant_profile_view')}}
)
,   support_ticket_late_delivery AS (
    SELECT
            ticket_id
        ,   order_id
    
    FROM    {{ref('model_dwd_support_ticket_view')}}
    WHERE
        TRUE
        AND issue_type = 'delivery'
        AND issue_sub_type = 'late'
)
/* Aggregation */
,   order_transaction_delivery AS (
    SELECT
            t1.order_id
        ,   t1.driver_id
        ,   t1.delivery_zone
        ,   t3.city
        ,   t1.is_late_delivery
        ,   t1.is_net_order
        ,   t1.delivery_distance_km
        ,   t2.order_created_datetime
        ,   t2.order_accepted_datetime
        ,   t2.order_picked_up_datetime
        ,   t2.order_completed_datetime
        ,   t2.order_failed_datetime
        ,   t2.order_canceled_datetime
        ,   t2.duration_delivery_sec

    FROM    order_transactions t1
            LEFT JOIN order_delivery t2 ON t1.order_id = t2.order_id
            LEFT JOIN restaurant_profile t3 ON t1.restaurant_id = t3.restaurant_id
)
,   order_volume_by_zone AS (
    SELECT
            delivery_zone
        ,   city
        ,   COUNT(DISTINCT order_id)                                                                            AS cnt_delivery_request
        ,   COUNT(DISTINCT CASE WHEN is_net_order = true THEN order_id END)                                     AS cnt_complete_order
        ,   AVG(duration_delivery_sec)                                                                          AS avg_delivery_time
        ,   SUM(CASE WHEN is_net_order = true THEN duration_delivery_sec END)                                   AS sum_duration_delivery_sec
        ,   SUM(CASE WHEN is_net_order = true THEN delivery_distance_km END)                                    AS sum_delivery_distance_km                            
        ,   COUNT(DISTINCT CASE WHEN order_accepted_datetime IS NULL THEN order_id END)                         AS cnt_delivery_cancel_unavailable_driver -- Assume that order which doesn't has accepted time = Unavailable driver can be found

    FROM    order_transaction_delivery
    GROUP BY 1,2
)
,   support_ticket_late_delivery_detail AS (
    SELECT
            t1.ticket_id
        ,   t2.delivery_zone
        ,   t3.city
    FROM    support_ticket_late_delivery t1
            LEFT JOIN order_transactions t2 ON t1.order_id = t2.order_id
            LEFT JOIN restaurant_profile t3 ON t2.restaurant_id = t3.restaurant_id
)
,   customer_late_complain_agg AS (
    SELECT
            delivery_zone
        ,   city
        ,   COUNT(DISTINCT ticket_id)   AS cnt_late_delivery

    FROM    support_ticket_late_delivery_detail
    GROUP BY 1,2
)
,   driver_supply_agg AS (
    SELECT
            region                                                          AS delivery_zone
        ,   COUNT(DISTINCT CASE WHEN is_active = true THEN driver_id END)   AS cnt_driver_active

    FROM    driver_profile
    GROUP BY 1
)
,   delivery_zone_profile AS (
    SELECT
            t1.delivery_zone
        ,   t1.city
        ,   t1.cnt_delivery_request
        ,   t1.cnt_complete_order
        ,   t1.avg_delivery_time
        ,   t1.sum_duration_delivery_sec
        ,   t1.sum_delivery_distance_km
        ,   t1.cnt_delivery_cancel_unavailable_driver
        ,   t2.cnt_late_delivery

    FROM    order_volume_by_zone t1
    LEFT JOIN customer_late_complain_agg t2 ON t1.delivery_zone = t2.delivery_zone AND t1.city = t2.city
)
,   delivery_zone_agg AS (
    SELECT
            delivery_zone
        ,   COALESCE(city, 'all')                                                    AS city
        ,   SUM(cnt_delivery_request)                                                   AS cnt_delivery_request
        ,   SUM(cnt_complete_order)                                                     AS cnt_complete_order
        ,   (1.00 * SUM(cnt_complete_order)) / SUM(cnt_delivery_request)                AS completion_ratio
        ,   SUM(sum_duration_delivery_sec) / SUM(cnt_complete_order)                    AS avg_delivery_time_sec
        ,   SUM(cnt_delivery_cancel_unavailable_driver)                                 AS cnt_delivery_cancel_unavailable_driver
        ,   (1.00 * SUM(sum_delivery_distance_km)) / SUM(cnt_complete_order * 3600)     AS avg_delivery_speed_kmh
        ,   SUM(cnt_late_delivery)                                                      AS cnt_late_delivery
    
    FROM    delivery_zone_profile
    GROUP BY GROUPING SETS (
        (delivery_zone)
    ,   (delivery_zone, city)
    )
)
SELECT
        t1.delivery_zone
    ,   t1.city
    ,   t1.cnt_delivery_request
    ,   t1.cnt_complete_order
    ,   t1.completion_ratio
    ,   t1.avg_delivery_time_sec
    ,   t1.cnt_delivery_cancel_unavailable_driver
    ,   t1.avg_delivery_speed_kmh
    ,   t1.cnt_late_delivery
    ,   t2.cnt_driver_active

FROM    delivery_zone_agg t1
        LEFT JOIN driver_supply_agg t2 ON t1.delivery_zone = t2.delivery_zone AND t1.city = 'all'
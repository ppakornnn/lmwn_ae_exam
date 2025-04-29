{{ config(
    materialized='table'
) }}

WITH driver_profile AS (
    SELECT
            driver_id
        ,   join_date
        ,   vehicle_type
        ,   region
        ,   is_active
        ,   driver_rating
        ,   bonus_tier
    
    FROM    {{ ref('model_dim_drivers_profile_view') }}
)
,   order_transactions AS (
    SELECT
            order_id
        ,   driver_id
        ,   delivery_zone
        ,   is_late_delivery
    
    FROM    {{ ref( 'model_dwd_order_transactions_view') }}
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
    
    FROM    {{ ref('model_dwd_order_delivery_view') }}
)
,   support_tickets AS (
    SELECT
            ticket_id
        ,   driver_id
        ,   issue_type
        ,   issue_sub_type
    
    FROM    {{ ref('model_dwd_support_ticket_view') }}
    WHERE
        TRUE
        AND status = 'resolved'
)

/* Aggregation */
,   order_transaction_delivery AS (
    SELECT
            t1.order_id
        ,   t1.driver_id
        ,   t1.delivery_zone
        ,   t1.is_late_delivery
        ,   t1.is_net_order
        ,   t2.order_created_datetime
        ,   t2.order_accepted_datetime
        ,   t2.order_picked_up_datetime
        ,   t2.order_completed_datetime
        ,   t2.order_failed_datetime
        ,   t2.order_canceled_datetime

    FROM    order_transactions t1
            LEFT JOIN order_delivery t2 ON t1.order_id = t2.order_id
)
,   order_details AS (
    SELECT
            order_id
        ,   driver_id
        ,   delivery_zone
        ,   is_late_delivery
        ,   is_net_order
        ,   DATE_DIFF('sec', order_created_datetime, order_accepted_datetime)       AS resp_accepted_order_sec
        ,   DATE_DIFF('sec', order_created_datetime, order_completed_datetime)      AS duration_create_complete_sec

    FROM    order_transaction_delivery
)
,   order_aggregation AS (
    SELECT
            driver_id
        ,   COUNT(DISTINCT order_id)                                                                            AS cnt_assigned_order
        ,   COUNT(DISTINCT CASE WHEN is_net_order = 1 THEN order_id END)                                                  AS cnt_completed_order
        ,   AVG(resp_accepted_order_sec)                                                                        AS avg_resp_accepted_order_sec
        ,   AVG(CASE WHEN duration_create_complete_sec IS NOT NULL THEN duration_create_complete_sec END)       AS avg_duration_create_complete_sec
        ,   COUNT(DISTINCT CASE WHEN is_late_delivery = 1 THEN order_id END)                                    AS cnt_late_delivery
    
    FROM    order_details
    GROUP BY 1
)
,   support_ticket_sub_type_agg AS (
    SELECT
            driver_id
        ,   issue_sub_type
        ,   COUNT(DISTINCT ticket_id)   AS cnt_issue_sub_type
    
    FROM    support_tickets
    GROUP BY 1,2,3
)
,   support_ticket_sub_type_map AS (
    SELECT
            driver_id
        ,   ARRAY_AGG(STRUCT_INSERT({issue_sub_type : cnt_issue_sub_type}))        AS feedback_driver

    FROM    support_ticket_sub_type_agg
    GROUP BY 1
)

SELECT
            t1.driver_id
        ,   t1.join_date
        ,   t1.vehicle_type
        ,   t1.region
        ,   t1.is_active
        ,   t1.driver_rating
        ,   t1.bonus_tier
        ,   t2.cnt_assigned_order
        ,   t2.cnt_completed_order
        ,   t2.avg_resp_accepted_order_sec
        ,   t2.avg_duration_create_complete_sec
        ,   t2.cnt_late_delivery
        ,   t3.feedback_driver

FROM    driver_profile t1
        LEFT JOIN order_aggregation t2 ON t1.driver_id = t2.driver_id
        LEFT JOIN support_ticket_sub_type_map t3 ON t1.driver_id = t3.driver_id
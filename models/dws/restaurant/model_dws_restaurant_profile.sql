{{ config(
    materialized='table'
) }}

WITH restaurant_profile AS (
    SELECT
            restaurant_id
        ,   restaurant_name
        ,   category
        ,   city
        ,   average_rating
        ,   is_active
        ,   prep_time_min

    FROM    {{ ref('model_dim_restaurant_profile_view') }}
)
,   order_transactions AS (
    SELECT
            order_id
        ,   restaurant_id
        ,   is_net_order
    
    FROM    {{ ref( 'model_dwd_order_transactions_view') }}
)
,   support_tickets AS (
    SELECT
            ticket_id
        ,   restaurant_id
        ,   issue_type
        ,   issue_sub_type
    
    FROM    {{ ref('model_dwd_support_ticket_view') }}
    WHERE
        TRUE
        AND status = 'resolved'
        AND issue_type = 'food'
)
/* Aggregation Zone */

,   order_aggregation AS (
    SELECT
            restaurant_id
        ,   COUNT(DISTINCT order_id)                                            AS cnt_assigned_order
        ,   COUNT(DISTINCT CASE WHEN is_net_order = 1 THEN order_id END)        AS cnt_completed_order
    
    FROM    order_transactions
    GROUP BY 1
)
,   support_ticket_sub_type_agg AS (
    SELECT
            restaurant_id
        ,   issue_sub_type
        ,   COUNT(DISTINCT ticket_id)   AS cnt_issue_sub_type
    
    FROM    support_tickets
    GROUP BY 1,2
)
,   support_ticket_sub_type_map AS (
    SELECT
            restaurant_id
        ,   ARRAY_AGG(
            STRUCT_PACK(issue_sub_type := issue_sub_type, cnt_issue_sub_type := cnt_issue_sub_type)
        )   AS feedback_restaurant

    FROM    support_ticket_sub_type_agg
    GROUP BY 1
)

SELECT
            t1.restaurant_id
        ,   t1.restaurant_name
        ,   t1.category
        ,   t1.city
        ,   t1.average_rating
        ,   t1.is_active
        ,   t1.prep_time_min
        ,   t2.cnt_assigned_order
        ,   t2.cnt_completed_order
        ,   t3.feedback_restaurant

FROM    restaurant_profile t1
        LEFT JOIN order_aggregation t2 ON t1.restaurant_id = t2.restaurant_id
        LEFT JOIN support_ticket_sub_type_map t3 ON t1.restaurant_id = t3.restaurant_id
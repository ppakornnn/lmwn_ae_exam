{{ config(
    materialized='table'
) }}

WITH incentive_order_cost AS (
    SELECT
            order_id
        ,   driver_id
        ,   COALESCE(incentive_program, 'No Incentive')                 AS incentive_program
        ,   order_datetime
        ,   is_net_order
        ,   is_incentive_order
        ,   revenue_thb
        ,   incentive_cost_thb
    
    FROM    {{ ref('model_dws_order_transactions_ue') }}
)
,   order_delivery AS (
    SELECT
            order_id
        ,   CASE
                WHEN pickup_datetime IS NULL THEN true
                ELSE false
            END                                                         AS is_accepted_order
        ,   DATE_DIFF('min', order_datetime, delivery_datetime)         AS duration_delivery_min

    FROM    {{ ref('model_dwd_order_transactions_view')}}
)

,   order_details AS (
    SELECT
            t1.order_id
        ,   t1.driver_id
        ,   t1.incentive_program
        ,   t1.order_datetime
        ,   t1.is_net_order
        ,   t2.is_accepted_order
        ,   t2.duration_delivery_min
        ,   t1.is_incentive_order
        ,   t1.revenue_thb
        ,   t1.incentive_cost_thb

    FROM    incentive_order_cost t1
            LEFT JOIN order_delivery t2 ON t1.order_id = t2.order_id
)

SELECT
        incentive_program
    ,   COUNT(DISTINCT CASE WHEN is_net_order = true AND is_incentive_order = true THEN order_id END)                   AS cnt_completed_order
    ,   AVG(CASE WHEN is_net_order = true AND is_incentive_order = true THEN duration_delivery_min END)                 AS avg_delivery_time_min
    ,   (1.00 * COUNT(DISTINCT CASE WHEN is_accepted_order = true THEN order_id END)) / COUNT(DISTINCT order_id)        AS acceptance_ratio
    ,   SUM(incentive_cost_thb)                                                                                         AS bonus_amount_paid_thb
    ,   SUM(revenue_thb)                                                                                                AS revenue_thb

FROM    order_details
GROUP BY 1
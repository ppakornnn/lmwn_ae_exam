{{ config(
    materialized='table'
) }}

WITH order_transactions AS (
    SELECT
            order_id
        ,   customer_id
        ,   campaign_id
        ,   order_datetime
        ,   is_net_order
        ,   total_amount_thb

    FROM    {{ ref('model_dwd_order_transactions_view')}}
    WHERE
        TRUE
        AND is_net_order = true
)
,   campaign_profile AS (
    SELECT
            campaign_id
        ,   campaign_name
        ,   start_date          AS campaign_start_date
        ,   end_date            AS campaign_end_date
        ,   campaign_type
        ,   targeting_strategy

    FROM    {{ ref('model_dim_campaign_profile_view') }}
    WHERE
        TRUE
        AND campaign_type = 'retargeting'
)
,   first_order_retargeting AS (
    SELECT
            t1.campaign_id
        ,   t1.customer_id
        ,   t2.campaign_start_date
        ,   t2.campaign_end_date
        ,   MIN(t1.order_datetime)      AS first_campaign_order_datetime

    FROM    order_transactions          t1
            INNER JOIN campaign_profile  t2 ON t1.campaign_id = t2.campaign_id
    GROUP BY 1,2,3,4
)
,   customer_order_after_retargeting AS (
        SELECT
            t1.customer_id
        ,   t1.campaign_id
        ,   t1.first_campaign_order_datetime
        ,   CASE
                WHEN COUNT(DISTINCT t2.order_id) >= 1 THEN true
                ELSE false
                END AS is_returned
        ,   MIN(t2.order_datetime)      AS returned_order_datetime
        ,   CASE
                WHEN COUNT(DISTINCT CASE WHEN DATE_DIFF('day',t1.first_campaign_order_datetime, t2.order_datetime) <= 30 THEN t2.order_id END) >= 1 THEN true
                ELSE false
                END AS is_retain
        ,   SUM(total_amount_thb)       AS total_spend_after_retarget_thb
        ,   DATE_DIFF('day', CAST(t1.first_campaign_order_datetime AS DATE), CAST(t2.order_datetime AS DATE))   AS time_gap_original_return_order_day
    FROM    first_order_retargeting t1
            LEFT JOIN order_transactions t2 ON t1.customer_id = t2.customer_id AND t1.first_campaign_order_datetime < t2.order_datetime
    GROUP BY 1,2,3
)

SELECT
            COALESCE(t1.campaign_id, 0)                                                                     AS campaign_id
        ,   COALESCE(t1.campaign_name, 0)                                                                   AS campaign_name 
        ,   COALESCE(t1.targeting_strategy, 0)                                                              AS targeting_strategy
        ,   COUNT(DISTINCT t2.customer_id)                                                                  AS cnt_customers_targeted
        ,   (1.00 * COUNT(DISTINCT CASE WHEN t2.is_returned = true END)) / COUNT(DISTINCT t2.customer_id)   AS ratio_returned_customer
        ,   SUM(total_spend_after_retarget_thb)                                                             AS total_spend_after_retarget_thb    
        ,   AVG(time_gap_original_return_order_day)                                                         AS avg_time_gap_original_return_order_day
        ,   (1.00 * COUNT(DISTINCT CASE WHEN t2.is_retain = true END)) / COUNT(DISTINCT t2.customer_id)     AS ratio_retained_customer

FROM    campaign_profile t1
        LEFT JOIN customer_order_after_retargeting t2 ON t1.campaign_id = t2.campaign_id
GROUP BY CUBE (t1.campaign_id, t1.campaign_name, t1.targeting_strategy)
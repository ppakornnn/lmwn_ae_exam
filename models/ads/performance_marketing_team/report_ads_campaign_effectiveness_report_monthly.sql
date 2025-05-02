{{ config(
    materialized='table'
) }}

WITH dim_date AS (
    SELECT
            date_day        AS report_date

    FROM    {{ ref('model_dim_date') }}
    WHERE
        TRUE
        AND date_day BETWEEN CAST('2023-12-31' AS DATE) AND CAST('2024-12-30' AS DATE)
)
-- Raw Data Zone --
,   campaign_interaction AS (
    SELECT
            interaction_id
        ,   campaign_id
        ,   customer_id
        ,   order_id
        ,   interaction_date
        ,   event_type
        ,   ad_cost_thb
        ,   revenue_thb
        ,   is_new_customer
    
    FROM    {{ ref('model_dwd_campaign_interactions_view') }}
)
,   order_transactions AS (
    SELECT
            order_id
        ,   is_net_order
    
    FROM    {{ ref('model_dwd_order_transactions_view') }}
)
,   campaign_across_date AS (
SELECT
            t1.report_date
        ,   t2.campaign_id
        ,   t2.campaign_name
        ,   t2.start_date
        ,   t2.end_date
        ,   t2.campaign_type
        ,   t2.objective
        ,   t2.channel
        ,   t2.budget
        ,   t2.cost_model
        ,   t2.targeting_strategy

FROM        dim_date         t1
LEFT JOIN   campaign_profile t2 ON t1.report_date BETWEEN t2.start_date AND t2.end_date
)
SELECT
        t1.campaign_id
    ,   DATE_TRUNC('month', t1.interaction_date)                                                                        AS report_month
    ,   COUNT(DISTINCT CASE WHEN t1.event_type = 'impression' THEN t1.interaction_id END)                               AS monthly_cnt_exposure
    ,   COUNT(DISTINCT CASE WHEN t1.event_type = 'click' THEN t1.interaction_id END)                                    AS monthly_cnt_interaction
    ,   COUNT(DISTINCT CASE WHEN t1.event_type = 'conversion' THEN t1.interaction_id END)                               AS monthly_cnt_conversion
    ,   COUNT(DISTINCT CASE WHEN t1.event_type = 'conversion' AND t2.is_net_order = true THEN t1.customer_id END)       AS monthly_cnt_customer_conversion_completed
    ,   SUM(t1.ad_cost_thb)                                                                                             AS monthly_ad_cost_thb
    ,   SUM(CASE WHEN t2.is_net_order = true THEN t1.revenue_thb END)                                                   AS monthly_revenue_thb

FROM    campaign_interaction t1
        LEFT JOIN order_transactions t2 ON t1.order_id = t2.order_id
GROUP BY 1,2
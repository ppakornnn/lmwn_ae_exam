{{ config(
    materialized='table'
) }}

WITH dim_date AS (
    SELECT
            date_day        AS report_date

    FROM    {{ ref('dim_date') }}
    WHERE
        TRUE
        AND date_day BETWEEN CAST('2023-12-31' AS DATE) AND CAST('2024-12-30' AS DATE)
)
-- Raw Data Zone --
,   campaign_profile AS (
    SELECT
            campaign_id
        ,   campaign_name
        ,   start_date
        ,   end_date
        ,   campaign_type
        ,   objective
        ,   channel
        ,   budget
        ,   cost_model
        ,   targeting_strategy
        
    FROM    {{ ref('model_dim_campaign_profile_view') }}
)
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
-- Aggregation Zone --
,   campaign_interaction_detail AS (
    SELECT
            t1.campaign_id
        ,   t1.interaction_date
        ,   COUNT(DISTINCT CASE WHEN t1.event_type = 'impression' THEN t1.interaction_id END)                               AS cnt_exposure
        ,   COUNT(DISTINCT CASE WHEN t1.event_type = 'click' THEN t1.interaction_id END)                                    AS cnt_interaction
        ,   COUNT(DISTINCT CASE WHEN t1.event_type = 'conversion' THEN t1.interaction_id END)                               AS cnt_conversion
        ,   COUNT(DISTINCT CASE WHEN t1.event_type = 'conversion' AND t2.is_net_order = true THEN t1.customer_id END)       AS cnt_customer_conversion_completed
        ,   SUM(t1.ad_cost_thb)                                                                                             AS ad_cost_thb
        ,   SUM(CASE WHEN t2.is_net_order = true THEN t1.revenue_thb END)                                                   AS revenue_thb

    FROM    campaign_interaction t1
            LEFT JOIN order_transactions t2 ON t1.order_id = t2.order_id
    GROUP BY 1,2
)

SELECT
            t1.report_date
        ,   t1.campaign_id
        ,   t1.campaign_name
        ,   t1.start_date
        ,   t1.end_date
        ,   t1.campaign_type
        ,   t1.objective
        ,   t1.channel
        ,   t1.budget
        ,   t1.cost_model
        ,   t1.targeting_strategy
        ,   t2.cnt_exposure
        ,   t2.cnt_interaction
        ,   t2.cnt_customer_conversion_completed
        ,   t2.ad_cost_thb
        ,   t2.revenue_thb

FROM    campaign_across_date t1
        LEFT JOIN campaign_interaction_detail t2 ON t1.campaign_id = t2.campaign_id AND t1.report_date = t2.interaction_date
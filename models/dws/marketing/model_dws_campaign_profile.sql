{{ config(
    materialized='table'
) }}
/*
Definition
- Customer Acquistion = New customer who had net order and interaction is converted
*/
WITH campaign_profile AS (
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

/* Aggregation Zone */
,   campaign_interaction_detail AS (
    SELECT
            t1.campaign_id
        ,   COUNT(DISTINCT CASE WHEN t1.event_type = 'impression' THEN t1.interaction_id END)                                                               AS cnt_exposure
        ,   COUNT(DISTINCT CASE WHEN t1.event_type = 'click' THEN t1.interaction_id END)                                                                    AS cnt_interaction
        ,   COUNT(DISTINCT CASE WHEN t1.event_type = 'conversion' THEN t1.interaction_id END)                                                               AS cnt_conversion
        ,   COUNT(DISTINCT CASE WHEN t1.event_type = 'conversion' AND t2.is_net_order = true THEN t1.customer_id END)                                       AS cnt_customer_conversion_completed
        ,   COUNT(DISTINCT CASE WHEN t1.event_type = 'conversion' AND t2.is_net_order = true AND t1.is_new_customer = true THEN t1.customer_id END)         AS cnt_customer_acquistion_completed
        ,   SUM(t1.ad_cost_thb)                                                                                                                             AS ad_cost_thb
        ,   SUM(CASE WHEN t1.event_type = 'conversion' AND t2.is_net_order = true AND t1.is_new_customer = true THEN t1.ad_cost_thb END)                    AS ad_cost_acquistion_thb
        ,   SUM(CASE WHEN t2.is_net_order = true THEN t1.revenue_thb END)                                                                                   AS revenue_thb

    FROM    campaign_interaction t1
            LEFT JOIN order_transactions t2 ON t1.order_id = t2.order_id
    GROUP BY 1
)

SELECT
            t1.campaign_id
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
        ,   t2.cnt_conversion
        ,   t2.cnt_customer_conversion_completed
        ,   t2.cnt_customer_acquistion_completed
        ,   t2.ad_cost_acquistion_thb
        ,   t2.ad_cost_thb
        ,   t2.revenue_thb
        ,   (1.00 * t2.ad_cost_acquistion_thb) / t2.cnt_customer_acquistion_completed           AS cost_per_acquired_customer
        ,   (t2.revenue_thb - t2.ad_cost_thb)                                                   AS return_on_ad_spend_thb

FROM    campaign_profile t1
        LEFT JOIN campaign_interaction_detail t2 ON t1.campaign_id = t2.campaign_id
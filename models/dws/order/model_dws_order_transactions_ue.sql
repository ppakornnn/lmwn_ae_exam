{{ config(
    materialized='table'
) }}

WITH order_transactions AS (
    SELECT
            order_id
        ,   campaign_id
        ,   driver_id
        ,   order_datetime
        ,   order_status
        ,   is_net_order
        ,   delivery_zone
        ,   total_amount_thb
        ,   payment_method

    FROM    {{ ref('model_dwd_order_transactions_view') }}
)
,   campaign_interactions AS (
    SELECT
            campaign_id
        ,   order_id
        ,   ad_cost_thb

    FROM    {{ ref('model_dwd_campaign_interactions_view') }}
)
,   driver_incentive_bonus AS (
    SELECT
            driver_id
        ,   incentive_program
        ,   applied_date
        ,   region
        ,   bonus_amount_per_order_thb
    
    FROM    {{ ref('model_dwd_drivers_incentive_view')}}
)
,   cs_compensation AS (
    SELECT
            order_id
        ,   compensation_amount_thb

    FROM    {{ ref('model_dwd_support_ticket_view')}}
)
,   order_ue_detail AS (
    SELECT
            t1.order_id
        ,   t1.campaign_id
        ,   t1.driver_id
        ,   t3.incentive_program
        ,   t1.order_datetime
        ,   t1.order_status
        ,   t1.is_net_order
        ,   CASE
                WHEN t3.bonus_amount_per_order_thb IS NOT NULL THEN true
                ELSE false
            END                                                                                     AS is_incentive_order
        ,   CASE
                WHEN t4.compensation_amount_thb IS NOT NULL THEN true
                ELSE false
            END                                                                                     AS is_compensation_order
        ,   t1.delivery_zone
        ,   t1.payment_method
        /* Revenue */
        ,   t1.total_amount_thb
        ,   (t1.total_amount_thb)                                                                   AS revenue_thb
        /* Cost */
        ,   COALESCE(t2.ad_cost_thb , 0)                                                            AS ad_cost_thb
        ,   COALESCE(t3.bonus_amount_per_order_thb , 0)                                             AS incentive_cost_thb
        ,   COALESCE(t4.compensation_amount_thb , 0)                                                AS compensation_cost_thb
    FROM    order_transactions                      t1
            LEFT JOIN campaign_interactions         t2 ON t1.order_id = t2.order_id
            LEFT JOIN driver_incentive_bonus        t3 ON t1.driver_id = t3.driver_id AND CAST(t1.order_datetime AS DATE) = t3.applied_date AND t1.delivery_zone = t3.region
            LEFT JOIN cs_compensation               t4 ON t1.order_id = t4.order_id
)

SELECT
            order_id
        ,   campaign_id
        ,   driver_id
        ,   incentive_program
        ,   order_datetime
        ,   order_status
        ,   is_net_order
        ,   is_incentive_order
        ,   is_compensation_order
        ,   delivery_zone
        ,   payment_method
        /* Revenue */
        ,   total_amount_thb
        ,   (total_amount_thb)                                                                      AS revenue_thb
        /* Cost */
        ,   ad_cost_thb
        ,   incentive_cost_thb
        ,   compensation_cost_thb
        ,   (ad_cost_thb + incentive_cost_thb + compensation_cost_thb)                              AS cost_thb

FROM    order_ue_detail


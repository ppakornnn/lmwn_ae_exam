{{ config(
    materialized='table'
) }}

SELECT
        campaign_type
    ,   objective
    ,   channel
    ,   platform
    ,   campaign_id
    ,   cnt_first_time_campaign_customer
    ,   avg_purchase_value_thb
    ,   avg_repeated_order_after_acquistion
    ,   avg_customer_retention_day
    ,   avg_interaction_order_sec
    ,   total_ad_cost_thb

FROM    {{ ref('model_dws_customer_acquisition') }}
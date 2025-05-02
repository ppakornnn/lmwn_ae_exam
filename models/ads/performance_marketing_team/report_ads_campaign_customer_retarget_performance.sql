{{ config(
    materialized='table'
) }}

SELECT
        campaign_id
    ,   targeting_strategy
    ,   cnt_customers_targeted
    ,   ratio_returned_customer
    ,   total_spend_after_retarget_thb    
    ,   avg_time_gap_original_return_order_day
    ,   ratio_retained_customer

FROM    {{ ref('model_dws_customer_retarget')}}
{{ config(
    materialized='incremental'
) }}

WITH customers_master AS (
    SELECT
        customer_id
    ,   signup_date
    ,   referral_source
    ,   customer_segment
    ,   is_active
    ,   birth_year
    ,   gender
    ,   preferred_device
    FROM {{ ref('model_dim_customers_profile_view') }}
),

customer_activeness AS (
    SELECT
        customer_id
    ,   MIN(session_start) AS first_active_datetime
    ,   MIN(session_end) AS latest_active_datetime

    FROM {{ source('raw_duckdb_data','order_log_incentive_sessions_customer_app_sessions') }}
    GROUP BY customer_id
),

customer_order AS (
    SELECT
            customer_id
        ,   COUNT(DISTINCT CASE WHEN is_net_order = 1 THEN order_id END) AS total_net_orders
        ,   COUNT(DISTINCT order_id) AS total_gross_orders
        ,   SUM(CASE WHEN is_net_order = 1 THEN total_amount_thb END) AS total_spent_thb
        ,   AVG(CASE WHEN is_net_order = 1 THEN total_amount_thb END) AS avg_order_value_thb
        ,   MIN(order_datetime) AS first_order_datetime
        ,   MAX(order_datetime) AS latest_order_datetime
        ,   MIN_BY(campaign_id, CASE WHEN campaign_id IS NOT NULL AND is_net_order = 1 THEN order_datetime END) AS first_campaign_id_converted
        ,   MIN(CASE WHEN campaign_id IS NOT NULL AND is_net_order = 1 THEN order_datetime END)                 AS first_campaign_datetime_converted

    FROM {{ ref('model_dwd_order_transactions_view') }}
    GROUP BY 1
),

customer_campaign AS (
    SELECT
        customer_id,
        COUNT(DISTINCT interaction_id) AS total_campaigns_engaged,
        COUNT(DISTINCT CASE WHEN event_type = 'click' THEN interaction_id END) AS total_campaigns_clicked,
        COUNT(DISTINCT CASE WHEN event_type = 'conversion' THEN interaction_id END) AS total_campaigns_converted,
        MIN_BY(campaign_id, interaction_datetime) AS first_campaign_id_engagement,
        MIN(interaction_datetime) AS first_campaign_datetime_engagement,
        SUM(ad_cost) AS total_campaign_cost_thb,
        SUM(revenue) AS total_campaign_revenue_thb
    FROM {{ source('raw_duckdb_data','campaign_interactions') }}
    GROUP BY 1
)

SELECT
        t1.customer_id
    ,   t1.signup_date
    ,   t1.referral_source
    ,   t1.customer_segment
    ,   t1.is_active
    ,   t1.birth_year
    ,   t1.gender
    ,   t1.preferred_device
    ,   t2.first_active_datetime
    ,   t2.latest_active_datetime
    ,   t3.total_net_orders
    ,   t3.total_gross_orders
    ,   t3.total_spent_thb
    ,   t3.avg_order_value_thb
    ,   t3.first_order_datetime
    ,   t3.latest_order_datetime
    ,   t4.total_campaigns_engaged
    ,   t4.total_campaigns_clicked
    ,   t4.total_campaigns_converted
    ,   t4.first_campaign_id_engagement
    ,   t4.first_campaign_datetime_engagement
    ,   t3.first_campaign_id_converted
    ,   t3.first_campaign_datetime_converted
    ,   COALESCE(t4.total_campaign_cost_thb, 0) AS total_campaign_cost_thb
    ,   COALESCE(t4.total_campaign_revenue_thb, 0) AS total_campaign_revenue_thb

FROM customers_master t1
LEFT JOIN customer_activeness t2 ON t1.customer_id = t2.customer_id
LEFT JOIN customer_order t3 ON t1.customer_id = t3.customer_id
LEFT JOIN customer_campaign t4 ON t1.customer_id = t4.customer_id

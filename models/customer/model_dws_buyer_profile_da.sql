{{ config(
    materialized='table'
) }}

WITH customers_master AS (
    SELECT
        customer_id,
        signup_date,
        referral_source,
        customer_segment,
        status,
        birth_year,
        gender,
        preferred_device
    FROM {{ source('raw_duckdb_data','customers_master') }}
),

customer_activeness AS (
    SELECT
        customer_id,
        MIN(session_start) AS first_active_timestamp,
        MIN(session_end) AS latest_active_timestamp
    FROM {{ source('raw_duckdb_data','order_log_incentive_sessions_customer_app_sessions') }}
    GROUP BY customer_id
),

customer_order AS (
    SELECT
        customer_id,
        COUNT(DISTINCT CASE WHEN order_status = 'completed' THEN order_id END) AS total_net_orders,
        COUNT(DISTINCT order_id) AS total_gross_orders,
        SUM(CASE WHEN order_status = 'completed' THEN total_amount END) AS total_spent,
        AVG(CASE WHEN order_status = 'completed' THEN total_amount END) AS avg_order_value,
        MIN(order_datetime) AS first_order_date,
        MAX(order_datetime) AS latest_order_date
    FROM {{ source('raw_duckdb_data','order_transactions') }}
    GROUP BY customer_id
),

customer_campaign AS (
    SELECT
        customer_id,
        COUNT(DISTINCT interaction_id) AS total_campaigns_engaged,
        COUNT(DISTINCT CASE WHEN event_type = 'click' THEN interaction_id END) AS total_campaigns_clicked,
        COUNT(DISTINCT CASE WHEN event_type = 'converted' THEN interaction_id END) AS total_campaigns_converted,
        MIN_BY(campaign_id, interaction_datetime) AS first_campaign_id_engagement,
        MIN(interaction_datetime) AS first_campaign_date_engagement,
        MIN_BY(campaign_id, CASE WHEN event_type = 'converted' THEN interaction_datetime END) AS first_campaign_id_converted,
        MIN(CASE WHEN event_type = 'converted' THEN interaction_datetime END) AS first_campaign_date_converted,
        SUM(ad_cost) AS total_campaign_cost,
        SUM(revenue) AS total_campaign_revenue
    FROM {{ source('raw_duckdb_data','campaign_interactions') }}
    GROUP BY customer_id
)

SELECT
    t1.customer_id,
    t1.signup_date,
    t1.referral_source,
    t1.customer_segment,
    t1.status,
    t1.birth_year,
    t1.gender,
    t1.preferred_device,
    t2.first_active_timestamp,
    t2.latest_active_timestamp,
    t3.total_net_orders,
    t3.total_gross_orders,
    t3.total_spent,
    t3.avg_order_value,
    t3.first_order_date,
    t3.latest_order_date,
    t4.total_campaigns_engaged,
    t4.total_campaigns_clicked,
    t4.total_campaigns_converted,
    t4.first_campaign_id_engagement,
    t4.first_campaign_date_engagement,
    t4.first_campaign_id_converted,
    t4.first_campaign_date_converted,
    COALESCE(t4.total_campaign_cost, 0) AS total_campaign_cost,
    COALESCE(t4.total_campaign_revenue, 0) AS total_campaign_revenue

FROM customers_master t1
LEFT JOIN customer_activeness t2 ON t1.customer_id = t2.customer_id
LEFT JOIN customer_order t3 ON t1.customer_id = t3.customer_id
LEFT JOIN customer_campaign t4 ON t1.customer_id = t4.customer_id

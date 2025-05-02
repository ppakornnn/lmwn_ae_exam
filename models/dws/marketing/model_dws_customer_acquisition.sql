{{ config(
    materialized='table'
) }}

WITH campaign_acquisition_profile AS (
    SELECT
            campaign_id
        ,   campaign_name
        ,   start_date
        ,   end_date
        ,   campaign_duration_day
        ,   campaign_type
        ,   objective
        ,   channel

    FROM    {{ ref('model_dim_campaign_profile_view') }}
    WHERE
        TRUE
)

,   customer_campaign_interaction AS (
    SELECT
            interaction_id
        ,   interaction_datetime
        ,   campaign_id
        ,   customer_id
        ,   order_id
        ,   event_type
        ,   device_type
        ,   platform
        ,   ad_cost_thb
        ,   ROW_NUMBER() OVER (PARTITION BY campaign_id, customer_id ORDER BY interaction_datetime ASC) AS rnk

    FROM    {{ ref('model_dwd_campaign_interactions_view')}}
    WHERE
        TRUE
)
,   first_customer_campaign_interaction AS (
    SELECT
            campaign_id
        ,   customer_id
        ,   order_id                AS first_order_id
        ,   event_type              AS first_event_type
        ,   platform                AS first_platform
        ,   interaction_datetime    AS first_interaction_datetime
        ,   ad_cost_thb
    FROM    customer_campaign_interaction
    WHERE
        TRUE
        AND rnk = 1    
)

,   order_transactions AS (
    SELECT
            order_id
        ,   CAST(order_datetime AS DATE)        AS order_date
        ,   order_datetime
        ,   is_net_order
        ,   campaign_id
    FROM    {{ ref('model_dwd_order_transactions_view') }}
)

,   customer_campaign_acquistion_profile AS (
    SELECT
            customer_id
        ,   COALESCE(latest_active_datetime, latest_order_datetime)     AS latest_active_datetime -- In case of we can't find latest session ID using order datetime instead
        ,   total_net_orders
        ,   avg_order_value_thb
        ,   total_campaigns_converted
        ,   first_campaign_id_converted
        ,   first_campaign_datetime_converted
        ,   first_campaign_datetime_engagement
        ,   first_order_datetime

    FROM    {{ ref('model_dws_customers_profile_da')}}
    WHERE
        TRUE
        AND first_order_datetime = first_campaign_datetime_converted -- Assume that Order and converted is the same event
)

,   new_customer_campaign_interaction AS (
    SELECT
            t1.customer_id
        ,   t1.first_campaign_id_converted          AS campaign_id
        ,   t2.campaign_type
        ,   t2.objective
        ,   t2.channel
        ,   t3.first_platform                       AS platform
        -- Customer behavior --
        ,   t1.total_net_orders
        ,   t1.avg_order_value_thb
        ,   t1.total_campaigns_converted
        ,   DATE_DIFF('day', CAST(t1.first_order_datetime AS DATE), CAST(t1.latest_active_datetime AS DATE))    AS duration_customer_retention_after_trx_day
        ,   DATE_DIFF('second', t1.first_campaign_datetime_engagement, t1.first_order_datetime)                 AS duration_interaction_order_sec
        ,   ad_cost_thb
    FROM    customer_campaign_acquistion_profile        t1
    LEFT JOIN campaign_acquisition_profile              t2 ON t1.first_campaign_id_converted = t2.campaign_id
    LEFT JOIN first_customer_campaign_interaction       t3 ON t1.customer_id = t3.customer_id AND t1.first_campaign_id_converted = t3.campaign_id
)

SELECT
        COALESCE(campaign_type, 'all')                      AS campaign_type
    ,   COALESCE(objective, 'all')                          AS objective
    ,   COALESCE(channel, 'all')                            AS channel
    ,   COALESCE(platform, 'all')                           AS platform
    ,   COALESCE(campaign_id, 'all')                        AS campaign_id
    ,   COUNT(DISTINCT customer_id)                         AS cnt_first_time_campaign_customer
    ,   AVG(avg_order_value_thb)                            AS avg_purchase_value_thb
    ,   AVG(total_net_orders)                               AS avg_repeated_order_after_acquistion
    ,   AVG(duration_customer_retention_after_trx_day)      AS avg_customer_retention_day
    ,   AVG(duration_interaction_order_sec)                 AS avg_interaction_order_sec
    ,   SUM(ad_cost_thb)                                    AS total_ad_cost_thb

FROM    new_customer_campaign_interaction
GROUP BY GROUPING SETS (
        (campaign_type, objective, channel, platform, campaign_id)
    ,   (campaign_type)
    ,   (objective)
    ,   (channel)
    ,   (platform)
    ,   (campaign_type, objective)
    ,   (campaign_type, channel)
    ,   (campaign_type, platform)
    ,   (objective, channel)
    ,   (objective, platform)
    ,   (channel, platform)
    ,   (campaign_type, objective, channel)
    ,   (campaign_type, objective, platform)
    ,   (objective, channel, platform)
    ,   (campaign_type, objective, channel, platform)
)
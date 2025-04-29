{{ config(
    materialized='view'
) }}

WITH order_delivery AS (
    SELECT
            order_id
        ,   MAX(CASE WHEN status = 'created' THEN status_datetime END)      AS order_created_datetime
        ,   MAX(CASE WHEN status = 'accepted' THEN status_datetime END)     AS order_accepted_datetime
        ,   MAX(CASE WHEN status = 'picked_up' THEN status_datetime END)    AS order_picked_up_datetime
        ,   MAX(CASE WHEN status = 'completed' THEN status_datetime END)    AS order_completed_datetime
        ,   MAX(CASE WHEN status = 'failed' THEN status_datetime END)       AS order_failed_datetime
        ,   MAX(CASE WHEN status = 'canceled' THEN status_datetime END)     AS order_canceled_datetime

FROM     {{source('raw_duckdb_data','order_log_incentive_sessions_order_status_logs')}}
GROUP BY 1
)
SELECT
        order_id
    ,   CASE
            WHEN order_completed_datetime IS NOT NULL THEN 1
            ELSE 0
        END AS is_net_order
    ,   order_created_datetime
    ,   order_accepted_datetime
    ,   order_picked_up_datetime
    ,   order_completed_datetime
    ,   order_failed_datetime
    ,   order_canceled_datetime

FROM    order_delivery
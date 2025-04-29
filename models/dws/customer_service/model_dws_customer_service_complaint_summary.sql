{{ config(
        materialized='table'
) }}

WITH support_ticket AS (
    SELECT
            ticket_id
        ,   issue_type
        ,   issue_sub_type
        ,   channel
        ,   status
        ,   opened_datetime
        ,   resolved_datetime
        ,   CAST(opened_datetime AS DATE)                               AS opened_date
        ,   CAST(resolved_datetime AS DATE)                             AS resolved_date
        ,   DATE_DIFF('min',opened_datetime, resolved_datetime)         AS duration_resolve_min
        ,   compensation_amount_thb

    FROM    {{ ref('model_dwd_support_ticket_view') }}
)

SELECT
        opened_date                                                                         AS ticket_open_date
    ,   COALESCE(issue_type, 'all')                                                         AS issue_type
    ,   COALESCE(issue_sub_type, 'all')                                                     AS issue_sub_type
    ,   COUNT(DISTINCT ticket_id)                                                           AS cnt_opened_ticket
    ,   COUNT(DISTINCT CASE WHEN status = 'resolved' THEN ticket_id END)                    AS cnt_resolved_ticket
    ,   COUNT(DISTINCT CASE WHEN status IN ('unresolved', 'escalated') THEN ticket_id END)  AS cnt_unresolved_ticket
    ,   SUM(duration_resolve_min)                                                           AS total_duration_resolve_min
    ,   SUM(duration_resolve_min) / COUNT(DISTINCT ticket_id)                               AS avg_duration_resolve_min
    ,   SUM(compensation_amount_thb)                                                        AS total_compensation_amount_thb

FROM    support_ticket
GROUP BY GROUPING SETS(
        (opened_date)
    ,   (opened_date, issue_type, issue_sub_type)
)


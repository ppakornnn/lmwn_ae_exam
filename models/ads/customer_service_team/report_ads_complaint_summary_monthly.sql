{{ config(
    materialized='table'
) }}

WITH ticket_support AS (
    SELECT
            DATE_TRUNC('month', ticket_open_date)                                               AS report_month
        ,   issue_type
        ,   issue_sub_type
        ,   cnt_opened_ticket
        ,   cnt_resolved_ticket
        ,   cnt_unresolved_ticket
        ,   total_duration_resolve_min
        ,   avg_duration_resolve_min
        ,   total_compensation_amount_thb

    FROM    {{ ref('model_dws_customer_service_complaint_summary') }}
)

SELECT
        report_month
    ,   issue_type
    ,   issue_sub_type
    ,   SUM(cnt_opened_ticket)                                                              AS total_opened_ticket
    ,   SUM(total_duration_resolve_min) / SUM(cnt_resolved_ticket)                          AS avg_time_taken_to_resolve_min
    ,   SUM(cnt_unresolved_ticket)                                                          AS total_unresolved_ticket
    ,   SUM(total_compensation_amount_thb)                                                  AS total_compensation_amount_thb

FROM    ticket_support
GROUP BY 1,2,3
{{ config(
    materialized='table'
) }}

WITH   support_driver_tickets AS (
    SELECT
            ticket_id
        ,   issue_type
        ,   issue_sub_type
        ,   DATE_DIFF('min', opened_datetime, resolved_datetime)        AS duration_resolve_min
        ,   csat_score
    FROM    {{ ref('model_dwd_support_ticket_view') }}
    WHERE
        TRUE
        AND status = 'resolved'
)
SELECT
        issue_type
    ,   issue_sub_type
    ,   AVG(duration_resolve_min)           AS avg_duration_resolve_min
    ,   AVG(csat_score)                     AS avg_csat_score

FROM    support_driver_tickets
GROUP BY 1,2
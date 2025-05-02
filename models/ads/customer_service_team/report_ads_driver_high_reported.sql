{{ config(
    materialized='table'
) }}


WITH driver_profile_complaint_type AS (
    SELECT
            driver_id
        ,   cnt_assigned_order
        ,   UNNEST(feedback_driver) AS feedback_driver_sub_type

    FROM    {{ ref('model_dws_driver_profile') }}
)

SELECT
        driver_id
    ,   cnt_assigned_order
    ,   SUM(feedback_driver_sub_type.cnt_issue_sub_type)                                                    AS total_complainted
    ,   (1.00 * cnt_assigned_order) / SUM(feedback_driver_sub_type.cnt_issue_sub_type)                      AS ratio_complaint_total_assign_order
    ,   MAX_BY(feedback_driver_sub_type.issue_sub_type, feedback_driver_sub_type.cnt_issue_sub_type)        AS most_complated_sub_type

FROM    driver_profile_complaint_type
GROUP BY 1,2
ORDER BY total_complainted DESC

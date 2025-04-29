{{ config(
    materialized='table'
) }}


WITH restaurant_profile_complaint_type AS (
    SELECT
            restaurant_id
        ,   cnt_assigned_order
        ,   UNNEST(feedback_restaurant) AS feedback_restaurant_sub_type

    FROM    {{ ref('model_dws_restaurant_profile') }}
    
)

SELECT
        restaurant_id
    ,   cnt_assigned_order
    ,   SUM(feedback_restaurant_sub_type.cnt_issue_sub_type)                                                    AS total_complainted
    ,   (1.00 * cnt_assigned_order) / SUM(feedback_restaurant_sub_type.cnt_issue_sub_type)                      AS ratio_complaint_total_assign_order
    ,   MAX_BY(feedback_restaurant_sub_type.issue_sub_type, feedback_restaurant_sub_type.cnt_issue_sub_type)    AS most_complained_sub_type

FROM    restaurant_profile_complaint_type
GROUP BY 1,2
ORDER BY total_complainted DESC

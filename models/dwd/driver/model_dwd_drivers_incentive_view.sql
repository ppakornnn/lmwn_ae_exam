{{ config(
    materialized='view'
) }}

/* Since we don't have Driver incentive master table. I'll using assumption as following to create Driver incentive master
1.) MIN applied_date is incentive program start and MAX applied_date is MAX applied_date start
2.) Bonus Amount from incentive will dividend by actual_deliveries to add driver cost for each Order during incentive program
*/
SELECT
        log_id
    ,   driver_id
    ,   incentive_program
    ,   bonus_amount                                                                            AS bonus_amount_thb
    ,   applied_date
    ,   delivery_target
    ,   actual_deliveries
    ,   bonus_qualified
    ,   (CASE WHEN bonus_qualified = true THEN bonus_amount ELSE 0 END) / actual_deliveries     AS bonus_amount_per_order_thb
    ,   region

FROM    {{source('raw_duckdb_data', 'order_log_incentive_sessions_driver_incentive_logs')}}

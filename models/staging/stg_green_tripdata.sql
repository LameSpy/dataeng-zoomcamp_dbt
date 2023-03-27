with tripdata as 
(
  select *,
    row_number() over(partition by vendorid, lpep_pickup_datetime) as rn
  from {{ source('staging','green_tripdata') }}
  where vendorid is not null 
)

select
    -- identifiers
    {{dbt_utils.generate_surrogate_key(['vendorid', 'lpep_pickup_datetime'])}} as tripid,
    cast(replace(vendorid, 'nan', '0') as numeric) as vendorid,
    cast(replace(ratecodeid, 'nan', '0') as numeric) as ratecodeid,
    cast(replace(pulocationid, 'nan', '0') as numeric) as  pickup_locationid,
    cast(replace(dolocationid, 'nan', '0') as numeric) as dropoff_locationid,
    
    -- timestamps
    cast(replace(lpep_pickup_datetime, 'nan', '') as timestamp) as pickup_datetime,
    cast(replace(lpep_dropoff_datetime, 'nan', '') as timestamp) as dropoff_datetime,
    
    -- trip info
    replace(store_and_fwd_flag, 'nan', '') as store_and_fwd_flag,
    cast(replace(passenger_count, 'nan', '0') as numeric) as passenger_count,
    cast(replace(trip_distance, 'nan', '0') as numeric) as trip_distance,
    cast(replace(trip_type, 'nan', '0') as numeric) as trip_type,
    
    -- payment info
    cast(replace(fare_amount, 'nan', '0') as numeric) as fare_amount,
    cast(replace(extra, 'nan', '0') as numeric) as extra,
    cast(replace(mta_tax, 'nan', '0') as numeric) as mta_tax,
    cast(replace(tip_amount, 'nan', '0') as numeric) as tip_amount,
    cast(replace(tolls_amount, 'nan', '0') as numeric) as tolls_amount,
    cast(replace(ehail_fee, 'nan', '0') as numeric) as ehail_fee,
    cast(replace(improvement_surcharge, 'nan', '0') as numeric) as improvement_surcharge,
    cast(replace(total_amount, 'nan', '0') as numeric) as total_amount,
    cast(replace(payment_type, 'nan', '0') as numeric) as payment_type,
    {{get_payment_type_description('cast(replace(payment_type, \'nan\', \'0\') as numeric)')}} as payment_type_description,
    cast(replace(congestion_surcharge, 'nan', '0') as numeric) as congestion_surcharge
from tripdata
where rn = 1
{%- if var('is_test_run', default=True) %}
{# we can changa var in cli. Use this dbt run --select stg_green_tripdata --var 'is_test_run: false' #}
    limit 100
{% endif -%}
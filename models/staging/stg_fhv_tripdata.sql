with tripdata as 
(
  select *,
    row_number() over(partition by dispatching_base_num, pickup_datetime, dropOff_datetime) as rn
  from {{ source('staging','fhv_tripdata') }}
)

select
    -- identifiers
    {{dbt_utils.generate_surrogate_key(['dispatching_base_num', 'pickup_datetime', 'dropOff_datetime'])}} as tripid,
    replace(dispatching_base_num, 'nan', '') as dispatching_base_num,
    replace(Affiliated_base_number, 'nan', '') as Affiliated_base_number,
    cast(replace(PUlocationID, 'nan', '0') as numeric) as  PUlocationID,
    cast(replace(DOlocationID, 'nan', '0') as numeric) as DOlocationID,
    
    -- timestamps
    cast(replace(pickup_datetime, 'nan', '') as timestamp) as pickup_datetime,
    cast(replace(dropOff_datetime, 'nan', '') as timestamp) as dropOff_datetime,
    
    -- Other
    cast(replace(SR_Flag, 'nan', '0') as numeric) as SR_Flag
   
from tripdata
where rn = 1
{%- if var('is_test_run', default=True) %}
{# we can changa var in cli. Use this dbt run --select stg_green_tripdata --var 'is_test_run: false' #}
    limit 100
{% endif -%}
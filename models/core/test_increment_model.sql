{{
    config(
        materialized='incremental',
        unique_key = 'tripid'
    )
}}

with t1 as (
select 
    {{dbt_utils.generate_surrogate_key(['LocationID'])}} as tripid,
    LocationID,
    Borough,
    Zone,
    replace(service_zone, "Boro", "Green") as service_zone
from {{ref('taxi_zone_lookup')}}
)

select * 
from t1
{% if is_incremental() %}

  -- this filter will only be applied on an incremental run
  where LocationID > (select max(LocationID) from {{ this }})

{% endif %}
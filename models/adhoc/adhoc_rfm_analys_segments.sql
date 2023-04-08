with t1 as (
select user_id,
first_value(segment_date) over (partition by user_id order by segment_date desc) as segment_date,
first_value(RFM_SEGMENT) over (partition by user_id order by segment_date desc) as RFM_SEGMENT,
first_value(RFM_SEGMENT_CHANGING) over (partition by user_id order by segment_date desc) as RFM_SEGMENT_CHANGING
from {{ref('adhoc_prf_analys')}}
)

select *
from t1
group by user_id, segment_date, RFM_SEGMENT, RFM_SEGMENT_CHANGING
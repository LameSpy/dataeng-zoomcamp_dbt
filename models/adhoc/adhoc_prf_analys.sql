with stage as (
SELECT 
DATE_TRUNC(DATE(sales_date), MONTH) AS segment_date,
DATE_TRUNC(DATE(sales_date), MONTH) + interval 1 month - interval 1 day AS last_day_of_month,
sales_date,
user_id,
order_id,
revenue,
from {{ref('SQL_test_data')}}
where sales_date >= '2021-01-01'
),

group_table as (
select
segment_date,
user_id,
min(date_diff(last_day_of_month, sales_date, DAY)) as recency,
count(user_id) as frequency,
sum(revenue) as monetary
from stage
group by segment_date, user_id
),

add_percentil as (
select *,
PERCENT_RANK () over(partition by segment_date order by recency desc, frequency asc, monetary asc) as recency_percent,
PERCENT_RANK () over(partition by segment_date order by frequency asc, monetary asc, recency desc) as frequency_percent,
PERCENT_RANK () over(partition by segment_date order by monetary asc, frequency asc, recency desc) as monetary_percent
from group_table
),

make_segment as (
select 
segment_date,
user_id,
recency,
frequency,
monetary,
case 
	when recency_percent <= 0.2 then 1
	when recency_percent <= 0.4 then 2
	when recency_percent <= 0.6 then 3
	when recency_percent <= 0.8 then 4
	else 5
end recency_score, 
case 
	when frequency_percent <= 0.2 then 1
	when frequency_percent <= 0.4 then 2
	when frequency_percent <= 0.6 then 3
	when frequency_percent <= 0.8 then 4
	else 5
end frequency_score, 
case 
	when monetary_percent <= 0.2 then 1
	when monetary_percent <= 0.4 then 2
	when monetary_percent <= 0.6 then 3
	when monetary_percent <= 0.8 then 4
	else 5
end monetary_score
from add_percentil
),

add_rfm_segment as (
select 
*,
case 
	when recency_score = 5 and (frequency_score+monetary_score)/2 = 5 then 'Champions'
	when recency_score >= 3 and (frequency_score+monetary_score)/2 > 3 then 'Loyal Customers'
	when recency_score >= 4 and (frequency_score+monetary_score)/2 > 1 and (frequency_score+monetary_score)/2 <= 3 then 'Potential Loyalist'
	when recency_score >= 5 and (frequency_score+monetary_score)/2 = 1  then 'New Customers'
	when recency_score = 4 and (frequency_score+monetary_score)/2 = 1  then 'Promising'
	when recency_score = 3 and (frequency_score+monetary_score)/2 > 2 and (frequency_score+monetary_score)/2 <= 3  then 'Need Attention'
	when recency_score = 3 and (frequency_score+monetary_score)/2 >= 1 and (frequency_score+monetary_score)/2 <= 2  then 'About to Sleep'
	when recency_score = 2 and (frequency_score+monetary_score)/2 >= 2  then 'Hibernating'
	when recency_score <= 2 and (frequency_score+monetary_score)/2 <= 2  then 'Lost'
	when recency_score = 1 and (frequency_score+monetary_score)/2 <= 5  then 'Cant Lose Them'
	when recency_score <=2 and (frequency_score+monetary_score)/2 > 2  then 'At Risk'
else 'Other'
end RFM_SEGMENT 
from make_segment
),
 
add_RFM_SEGMENT_CHANGING as (
select *,
lag(RFM_SEGMENT) over(partition by user_id order by segment_date asc) as RFM_SEGMENT_CHANGING 
from add_rfm_segment
)


select *
from add_RFM_SEGMENT_CHANGING




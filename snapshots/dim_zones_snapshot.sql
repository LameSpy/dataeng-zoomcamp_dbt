{% snapshot orders_snapshot %}

{{
    config(
      target_database='datacamp-378414',
      target_schema='dbt_snapshots',
      unique_key='LocationID',

      strategy='check',
      check_cols = ['Borough','Zone','service_zone']
    )
}}

select * from {{ref('taxi_zone_lookup')}}

{% endsnapshot %}
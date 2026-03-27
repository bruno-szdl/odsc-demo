with source as (

    select * from {{ ref('raw_orders') }}

),

renamed as (

    select
        order_id,
        customer_id,
        order_date::date as order_date,
        status,
        amount
    from source

)

select * from renamed

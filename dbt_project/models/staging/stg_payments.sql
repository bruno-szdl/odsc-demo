with source as (

    select * from {{ ref('raw_payments') }}

),

renamed as (

    select
        id as payment_id,
        order_id,
        payment_method,
        amount as amount_cents,
        amount / 100.0 as amount
    from source

)

select * from renamed

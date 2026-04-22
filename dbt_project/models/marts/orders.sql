with orders as (

    select * from {{ ref('stg_orders') }}

),

payments as (

    select * from {{ ref('stg_payments') }}

),

final as (

    select
        orders.order_id,
        orders.customer_id,
        orders.order_date,
        orders.order_status,
        payments.payment_method,
        payments.amount_cents,
        payments.amount
    from orders
    left join payments on orders.order_id = payments.order_id

)

select * from final

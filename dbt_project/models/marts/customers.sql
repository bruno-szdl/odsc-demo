with customers as (

    select * from {{ ref('stg_customers') }}

),

orders as (

    select * from {{ ref('stg_orders') }}

),

customer_orders as (

    select
        customer_id,
        count(*)                         as total_orders,
        min(order_date)                  as first_order_date,
        max(order_date)                  as most_recent_order_date
    from orders
    group by customer_id

),

final as (

    select
        c.customer_id,
        c.full_name,
        c.email,
        coalesce(o.total_orders, 0)      as total_orders,
        o.first_order_date,
        o.most_recent_order_date
    from customers c
    left join customer_orders o on c.customer_id = o.customer_id

)

select * from final

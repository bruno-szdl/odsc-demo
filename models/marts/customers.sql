with customers as (

    select * from {{ ref('stg_customers') }}

),

orders as (

    select * from {{ ref('stg_orders') }}

),

customer_orders as (

    -- NOTE (debugging exercise): this aggregation includes returned orders.
    -- Is that the right behavior for total_orders and total_amount?
    select
        customer_id,
        count(*)                         as total_orders,
        sum(amount)                      as total_amount,
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
        c.created_date,
        coalesce(o.total_orders, 0)      as total_orders,
        coalesce(o.total_amount, 0.0)    as total_amount,
        o.first_order_date,
        o.most_recent_order_date
    from customers c
    left join customer_orders o on c.customer_id = o.customer_id

)

select * from final

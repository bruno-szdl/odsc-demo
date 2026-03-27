with source as (

    select * from {{ ref('raw_customers') }}

),

renamed as (

    select
        customer_id,
        first_name,
        last_name,
        first_name || ' ' || last_name as full_name,
        email,
        created_at::date as created_date
    from source

)

select * from renamed


    
    

with all_values as (

    select
        genero as value_field,
        count(*) as n_records

    from "dw_cecomsap"."staging"."stg_cartera"
    group by genero

)

select *
from all_values
where value_field not in (
    'M','F','E'
)



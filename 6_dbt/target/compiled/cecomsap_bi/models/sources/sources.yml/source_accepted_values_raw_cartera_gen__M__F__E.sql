
    
    

with all_values as (

    select
        gen as value_field,
        count(*) as n_records

    from "dw_cecomsap"."raw"."cartera"
    group by gen

)

select *
from all_values
where value_field not in (
    'M','F','E'
)



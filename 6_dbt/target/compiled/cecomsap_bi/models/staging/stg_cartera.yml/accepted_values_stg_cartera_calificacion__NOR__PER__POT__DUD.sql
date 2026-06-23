
    
    

with all_values as (

    select
        calificacion as value_field,
        count(*) as n_records

    from "dw_cecomsap"."staging"."stg_cartera"
    group by calificacion

)

select *
from all_values
where value_field not in (
    'NOR','PER','POT','DUD'
)



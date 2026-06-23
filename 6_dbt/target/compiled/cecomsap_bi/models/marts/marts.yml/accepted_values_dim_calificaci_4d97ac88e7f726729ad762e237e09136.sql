
    
    

with all_values as (

    select
        calificacion as value_field,
        count(*) as n_records

    from "dw_cecomsap"."marts"."dim_calificacion"
    group by calificacion

)

select *
from all_values
where value_field not in (
    'NOR','POT','DEF','DUD','PER'
)



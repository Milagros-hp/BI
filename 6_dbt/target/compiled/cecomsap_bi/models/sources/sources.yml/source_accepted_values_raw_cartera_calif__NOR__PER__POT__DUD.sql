
    
    

with all_values as (

    select
        calif as value_field,
        count(*) as n_records

    from "dw_cecomsap"."raw"."cartera"
    group by calif

)

select *
from all_values
where value_field not in (
    'NOR','PER','POT','DUD'
)



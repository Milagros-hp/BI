
    
    

with child as (
    select gestor_id as from_field
    from "dw_cecomsap"."marts"."fact_cartera"
    where gestor_id is not null
),

parent as (
    select gestor_id as to_field
    from "dw_cecomsap"."marts"."dim_gestor"
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null



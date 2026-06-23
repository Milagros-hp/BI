
    
    

select
    gestor_id as unique_field,
    count(*) as n_records

from "dw_cecomsap"."marts"."dim_gestor"
where gestor_id is not null
group by gestor_id
having count(*) > 1




    
    

select
    calif_id as unique_field,
    count(*) as n_records

from "dw_cecomsap"."marts"."dim_calificacion"
where calif_id is not null
group by calif_id
having count(*) > 1



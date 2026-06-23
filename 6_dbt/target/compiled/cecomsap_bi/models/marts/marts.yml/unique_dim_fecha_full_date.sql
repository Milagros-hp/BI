
    
    

select
    full_date as unique_field,
    count(*) as n_records

from "dw_cecomsap"."marts"."dim_fecha"
where full_date is not null
group by full_date
having count(*) > 1



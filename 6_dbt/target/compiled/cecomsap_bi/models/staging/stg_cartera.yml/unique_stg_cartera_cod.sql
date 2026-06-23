
    
    

select
    cod as unique_field,
    count(*) as n_records

from "dw_cecomsap"."staging"."stg_cartera"
where cod is not null
group by cod
having count(*) > 1



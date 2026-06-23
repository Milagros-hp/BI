
    
    

select
    cod as unique_field,
    count(*) as n_records

from "dw_cecomsap"."raw"."cartera"
where cod is not null
group by cod
having count(*) > 1



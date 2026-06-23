
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    calif_id as unique_field,
    count(*) as n_records

from "dw_cecomsap"."marts"."dim_calificacion"
where calif_id is not null
group by calif_id
having count(*) > 1



  
  
      
    ) dbt_internal_test
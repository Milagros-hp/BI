
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select calif_id
from "dw_cecomsap"."marts"."dim_calificacion"
where calif_id is null



  
  
      
    ) dbt_internal_test
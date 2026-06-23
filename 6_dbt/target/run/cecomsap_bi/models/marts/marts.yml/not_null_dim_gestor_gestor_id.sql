
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select gestor_id
from "dw_cecomsap"."marts"."dim_gestor"
where gestor_id is null



  
  
      
    ) dbt_internal_test
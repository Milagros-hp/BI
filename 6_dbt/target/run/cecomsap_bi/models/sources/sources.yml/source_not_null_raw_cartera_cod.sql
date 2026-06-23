
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select cod
from "dw_cecomsap"."raw"."cartera"
where cod is null



  
  
      
    ) dbt_internal_test
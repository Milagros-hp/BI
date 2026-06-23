
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select titular
from "dw_cecomsap"."raw"."cartera"
where titular is null



  
  
      
    ) dbt_internal_test
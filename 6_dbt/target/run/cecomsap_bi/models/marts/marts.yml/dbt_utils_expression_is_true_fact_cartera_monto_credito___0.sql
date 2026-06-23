
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  



select
    1
from "dw_cecomsap"."marts"."fact_cartera"

where not(monto_credito > 0)


  
  
      
    ) dbt_internal_test
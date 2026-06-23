
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select monto_credito
from "dw_cecomsap"."staging"."stg_cartera"
where monto_credito is null



  
  
      
    ) dbt_internal_test
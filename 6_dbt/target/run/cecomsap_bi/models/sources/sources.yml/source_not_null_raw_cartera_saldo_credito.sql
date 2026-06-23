
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select saldo_credito
from "dw_cecomsap"."raw"."cartera"
where saldo_credito is null



  
  
      
    ) dbt_internal_test
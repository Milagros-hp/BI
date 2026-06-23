
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    cod as unique_field,
    count(*) as n_records

from "dw_cecomsap"."staging"."stg_cartera"
where cod is not null
group by cod
having count(*) > 1



  
  
      
    ) dbt_internal_test
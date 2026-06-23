
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        tipo_credito as value_field,
        count(*) as n_records

    from "dw_cecomsap"."staging"."stg_cartera"
    group by tipo_credito

)

select *
from all_values
where value_field not in (
    'MIE','CON','PEE','MEE'
)



  
  
      
    ) dbt_internal_test
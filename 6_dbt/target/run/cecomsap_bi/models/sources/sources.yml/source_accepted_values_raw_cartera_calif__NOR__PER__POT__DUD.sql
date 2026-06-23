
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        calif as value_field,
        count(*) as n_records

    from "dw_cecomsap"."raw"."cartera"
    group by calif

)

select *
from all_values
where value_field not in (
    'NOR','PER','POT','DUD'
)



  
  
      
    ) dbt_internal_test
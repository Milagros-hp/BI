
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    gestor_id as unique_field,
    count(*) as n_records

from "dw_cecomsap"."marts"."dim_gestor"
where gestor_id is not null
group by gestor_id
having count(*) > 1



  
  
      
    ) dbt_internal_test
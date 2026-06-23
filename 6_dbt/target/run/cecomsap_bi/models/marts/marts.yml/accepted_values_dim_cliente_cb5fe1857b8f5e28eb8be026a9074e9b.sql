
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        genero as value_field,
        count(*) as n_records

    from "dw_cecomsap"."marts"."dim_cliente"
    group by genero

)

select *
from all_values
where value_field not in (
    'Masculino','Femenino','Empresa/Jurídico','No especificado'
)



  
  
      
    ) dbt_internal_test
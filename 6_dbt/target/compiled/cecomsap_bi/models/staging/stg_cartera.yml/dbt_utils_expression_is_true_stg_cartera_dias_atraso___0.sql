



select
    1
from "dw_cecomsap"."staging"."stg_cartera"

where not(dias_atraso >= 0)


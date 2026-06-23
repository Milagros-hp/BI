



select
    1
from "dw_cecomsap"."staging"."stg_cartera"

where not(monto_credito > 0)


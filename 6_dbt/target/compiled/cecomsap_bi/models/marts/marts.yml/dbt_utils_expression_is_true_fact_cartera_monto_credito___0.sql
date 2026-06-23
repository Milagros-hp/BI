



select
    1
from "dw_cecomsap"."marts"."fact_cartera"

where not(monto_credito > 0)


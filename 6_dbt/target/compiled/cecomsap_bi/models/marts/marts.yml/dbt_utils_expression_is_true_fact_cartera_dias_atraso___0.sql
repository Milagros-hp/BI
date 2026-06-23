



select
    1
from "dw_cecomsap"."marts"."fact_cartera"

where not(dias_atraso >= 0)






select
    1
from "dw_cecomsap"."marts"."fact_cartera"

where not(tasa_morosidad_pct >= 0)


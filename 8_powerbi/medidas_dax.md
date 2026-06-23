# Medidas DAX — Power BI · CECOMSAP Cartera de Créditos

Conexión: PostgreSQL · schema `marts` · modo Import

## Tablas importadas
- `fact_cartera`
- `dim_fecha`
- `dim_producto`
- `dim_cliente`
- `dim_gestor`
- `dim_calificacion`

## Relaciones del modelo semántico

| Dimensión | Campo dim | Tabla hecho | Campo fact | Cardinalidad |
|-----------|-----------|-------------|------------|-------------|
| dim_fecha | date_id | fact_cartera | date_id_desembolso | 1:* |
| dim_producto | product_id | fact_cartera | product_id | 1:* |
| dim_cliente | customer_id | fact_cartera | customer_id | 1:* |
| dim_gestor | gestor_id | fact_cartera | gestor_id | 1:* |
| dim_calificacion | calif_id | fact_cartera | calif_id | 1:* |

---

## Medidas DAX

### Cartera total y saldos

```dax
Total Créditos =
COUNTROWS(fact_cartera)

Cartera Desembolsada =
SUM(fact_cartera[monto_credito])

Saldo Vigente Total =
SUM(fact_cartera[saldo_credito])

Saldo Promedio =
AVERAGE(fact_cartera[saldo_credito])
```

### Mora y atraso

```dax
Capital en Mora =
SUM(fact_cartera[capital_atraso])

Mora Total =
SUM(fact_cartera[mora])

Interés Vencido =
SUM(fact_cartera[interes_vencido])

Índice de Morosidad % =
DIVIDE(
    SUM(fact_cartera[capital_atraso]),
    SUM(fact_cartera[saldo_credito]),
    0
) * 100

Créditos Morosos =
CALCULATE(
    COUNTROWS(fact_cartera),
    fact_cartera[dias_atraso] > 0
)

% Créditos Morosos =
DIVIDE([Créditos Morosos], [Total Créditos], 0) * 100

Días Atraso Promedio =
AVERAGE(fact_cartera[dias_atraso])
```

### Provisión y riesgo

```dax
Provisión Total =
SUM(fact_cartera[provision_cartera])

Cobertura Provisión % =
DIVIDE(
    SUM(fact_cartera[provision_cartera]),
    SUM(fact_cartera[capital_atraso]),
    0
) * 100
```

### Tasa y rentabilidad

```dax
Tasa Promedio Ponderada =
DIVIDE(
    SUMX(fact_cartera, fact_cartera[monto_credito] * fact_cartera[tasa_interes]),
    SUM(fact_cartera[monto_credito]),
    0
)
```

### Cartera por calificación NOR

```dax
Cartera Normal (NOR) =
CALCULATE(
    SUM(fact_cartera[saldo_credito]),
    dim_calificacion[calificacion] = "NOR"
)

Cartera Pérdida (PER) =
CALCULATE(
    SUM(fact_cartera[saldo_credito]),
    dim_calificacion[calificacion] = "PER"
)

% Cartera en Riesgo =
DIVIDE(
    CALCULATE(
        SUM(fact_cartera[saldo_credito]),
        dim_calificacion[calificacion] IN {"PER","DUD","DEF","POT"}
    ),
    SUM(fact_cartera[saldo_credito]),
    0
) * 100
```

### Comparación período anterior (Time Intelligence)

```dax
Saldo Año Anterior =
CALCULATE(
    [Saldo Vigente Total],
    SAMEPERIODLASTYEAR(dim_fecha[full_date])
)

Variación Saldo % =
DIVIDE(
    [Saldo Vigente Total] - [Saldo Año Anterior],
    [Saldo Año Anterior],
    0
) * 100
```

---

## Visualizaciones sugeridas

| Visual | Eje / Leyenda | Medida |
|--------|--------------|--------|
| Tarjeta | — | Total Créditos, Saldo Vigente Total, Índice de Morosidad % |
| Barras apiladas | Calificación | Saldo Vigente Total |
| Líneas | Año (dim_fecha) | Cartera Desembolsada |
| Treemap | Producto, Tipo | Saldo Vigente Total |
| Tabla | Gestor | Capital en Mora, Índice de Morosidad % |
| Mapa | Región (dim_cliente) | Saldo Vigente Total |
| Gráfico donut | Género | Total Créditos |
| Barra horizontal | Bucket Atraso | Créditos Morosos |

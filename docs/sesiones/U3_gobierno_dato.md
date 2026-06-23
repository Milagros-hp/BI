# Gobierno del Dato

## Fuente oficial
`marts.fact_cartera` — única fuente de verdad para todos los KPIs.

## Definiciones oficiales

| KPI | Definición | Fórmula oficial |
|-----|-----------|-----------------|
| Saldo Vigente Total | Monto pendiente de pago al corte | SUM(saldo_credito) |
| Capital en Mora | Capital vencido no pagado | SUM(capital_atraso) |
| Índice de Morosidad % | Mora / Saldo × 100 | capital_atraso / saldo_credito * 100 |
| Provisión Total | Reserva contable SBS | SUM(provision_cartera) |
| Cobertura Provisión % | Provisión / Mora × 100 | provision_cartera / capital_atraso * 100 |
| % Cartera en Riesgo | Saldo PER+DUD+POT / Total | SUM saldo riesgo / SUM saldo total |

## Criterios de calidad
| Control | Regla | Estado |
|---------|-------|--------|
| Completitud | Sin nulos en cod, saldo, monto | PASS ✅ |
| Unicidad | cod sin duplicados | PASS ✅ |
| Valores válidos | calificacion IN (NOR,POT,DEF,DUD,PER) | PASS ✅ |
| Rango válido | monto_credito > 0 | PASS ✅ |

## Corte de análisis
**31 de marzo de 2026** — campo `fecha_corte` en `fact_cartera`.

## Frecuencia de actualización
Debezium CDC en tiempo real + dbt run bajo demanda.

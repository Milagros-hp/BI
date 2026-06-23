FROM python:3.12-slim

WORKDIR /usr/app/dbt

RUN pip install --no-cache-dir "dbt-postgres>=1.8,<1.10"

# El proyecto dbt se monta como volumen, así que no se copia aquí.
# DBT_PROFILES_DIR apunta al mismo working dir donde está profiles.yml
ENV DBT_PROFILES_DIR=/usr/app/dbt

ENTRYPOINT ["dbt"]
CMD ["--version"]

FROM python:3.12-slim

WORKDIR /app

# Dependencias del sistema para confluent-kafka y psycopg2-binary
RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc \
        librdkafka-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY consumer.py .

CMD ["python", "-u", "consumer.py"]

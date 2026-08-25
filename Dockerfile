FROM python:3.11-slim

FROM python:3.11-slim

# Parcheo del Sistema Operativo
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

# Creación del usuario sin privilegios
RUN useradd -m -r appuser && mkdir -p /app && chown -R appuser /app

WORKDIR /app

COPY requirements.txt .

# Forzar un salto de línea previo para evitar concatenación con el último paquete
RUN echo "" >> requirements.txt && \
    echo "msgpack>=1.2.1" >> requirements.txt && \
    echo "setuptools>=78.1.1" >> requirements.txt

# hadolint ignore=DL3013
RUN pip install --no-cache-dir --upgrade pip wheel && \
    pip install --no-cache-dir -r requirements.txt

COPY app/ ./app/

USER appuser

EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
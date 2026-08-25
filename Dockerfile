FROM python:3.11-slim

# Parcheo del Sistema Operativo
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

# Creación del usuario sin privilegios
RUN useradd -m -r appuser && mkdir -p /app && chown -R appuser /app

WORKDIR /app

COPY requirements.txt .

# 1. Actualizamos pip
# 2. Instalamos tu app normal
# 3. FORZAMOS el parcheo de seguridad sobrescribiendo cualquier versión vieja
# hadolint ignore=DL3013
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir --upgrade "setuptools>=78.1.1" "wheel>=0.46.2" "msgpack>=1.2.1" "jaraco.context>=6.1.0"

COPY app/ ./app/

USER appuser

EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
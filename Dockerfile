FROM python:3.11-slim

# Parcheo del Sistema Operativo
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

# Creación del usuario sin privilegios
RUN useradd -m -r appuser && mkdir -p /app && chown -R appuser /app

WORKDIR /app

COPY requirements.txt .

# 1. Actualizamos pip
# 2. Instalamos las versiones seguras de Trivy PRIMERO
# 3. Forzamos PyTorch a usar CPU para evitar la descarga de 9GB de CUDA
# 4. Instalamos las dependencias de la aplicación
# hadolint ignore=DL3013
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir "setuptools>=78.1.1" "msgpack>=1.2.1" "wheel>=0.46.2" "jaraco.context>=6.1.0" && \
    pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir -r requirements.txt

COPY app/ ./app/

USER appuser

EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
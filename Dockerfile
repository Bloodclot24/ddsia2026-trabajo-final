FROM python:3.11-slim

# 1. Parcheo del Sistema Operativo: Actualiza los paquetes de Debian para mitigar los CVEs de util-linux
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

# 2. Creación del usuario sin privilegios (Hardening)
# Mantenemos todo en una sola línea para evitar el error CRLF de Hadolint
RUN useradd -m -r appuser && mkdir -p /app && chown -R appuser /app

WORKDIR /app

COPY requirements.txt .

# 3. Parcheo de Python: Actualizamos las herramientas base antes de instalar las dependencias
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt

COPY app/ ./app/

USER appuser

EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
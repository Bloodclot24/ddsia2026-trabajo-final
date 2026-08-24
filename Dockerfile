FROM python:3.11-slim

# Ejecutamos todo en una sola línea para evitar errores de CRLF (Windows) en Hadolint
RUN useradd -m -r appuser && mkdir -p /app && chown -R appuser /app

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ./app/

USER appuser

EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
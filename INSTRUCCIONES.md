# Instructivo de Despliegue y Uso: Asistente de Ciberseguridad OT

Este documento detalla los pasos exactos para configurar, ejecutar y probar la API del Asistente de Ciberseguridad OT de principio a fin. Al desplegar esta solución en entornos cercanos a la línea de producción de manufactura, es vital seguir estos pasos para asegurar que los modelos locales y la base documental se inicialicen correctamente sin depender de internet en tiempo de ejecución.

## 1. Requisitos Previos

Asegúrate de contar con las siguientes herramientas en tu entorno local. Esta arquitectura basada en contenedores está diseñada para ejecutarse fácilmente mediante Docker Compose, o integrarse más adelante en un clúster local como k3s utilizando herramientas de orquestación.

*   **Git** instalado.
*   **Docker** y **Docker Compose** instalados y funcionando.
*   (Opcional pero recomendado) Entorno virtual de Python (`venv` o `conda`) para correr los tests unitarios localmente.

## 2. Estructura y Preparación de Documentos

El sistema RAG necesita una base de conocimiento para funcionar.

1.  Crea la carpeta de documentos si no existe:
    ```bash
    mkdir -p app/docs
    ```
2.  Coloca tus archivos PDF de la norma **ISA/IEC 62443** (u otros documentos técnicos OT) dentro de la carpeta `app/docs/`.
    *   *Nota:* El sistema procesará automáticamente cualquier archivo `.pdf` en este directorio al inicializar la API.

## 3. Construcción e Inicialización del Entorno

Levantaremos la infraestructura utilizando Docker Compose. Esto creará el contenedor de la API y el contenedor de Ollama para el modelo local.

1.  Posiciónate en la raíz de tu repositorio y ejecuta:
    ```bash
    docker-compose up --build -d
    ```
    *Esto construirá la imagen de la API, instalará las dependencias de `requirements.txt` y levantará ambos servicios en segundo plano.*

## 4. Descarga de Dependencias y Modelos Locales

Dado que operamos con un enfoque de "cero datos hacia afuera" (zero data exfiltration), debemos descargar el modelo de lenguaje (Mistral) dentro del contenedor de Ollama.

1.  Una vez que los contenedores estén corriendo, ejecuta el siguiente comando para descargar e instanciar el modelo:
    ```bash
    docker exec -it <nombre_del_contenedor_ollama> ollama run mistral
    ```
    *(Puedes obtener el nombre exacto del contenedor ejecutando `docker ps`)*
2.  La descarga puede tardar unos minutos dependiendo de la conexión. Una vez que veas el prompt interactivo de Ollama (`>>>`), puedes presionar `Ctrl+D` para salir. El modelo ya está cacheado en el volumen local.
3.  **Embeddings:** El modelo de embeddings de HuggingFace (`all-MiniLM-L6-v2`) se descargará automáticamente la primera vez que la API reciba una petición y procese los PDFs.

## 5. Uso de la API

Con la infraestructura operativa, puedes consultar la API. Asegúrate de incluir el API Key en los headers.

**Validar que la API está viva:**
```bash
curl -X GET http://localhost:8000/
```

**Hacer una consulta sobre Ciberseguridad OT al sistema RAG:**
```bash
curl -X POST http://localhost:8000/ask \
     -H "Content-Type: application/json" \
     -H "X-API-Key: ddsia-ot-cyber-2026" \
     -d '{"question": "¿Cuáles son los niveles del modelo Purdue mencionados en la IEC 62443?"}'
```

## 6. Ejecución de Tests Unitarios y de Integración

Los tests están diseñados para validar la resiliencia de la API (Autenticación, Rate Limiting y Prevención de Prompt Injection).

1.  Asegúrate de instalar las dependencias de testing en tu entorno local (o dentro del contenedor de la API):
    ```bash
    pip install pytest httpx
    ```
2.  Ejecuta la suite de pruebas con `pytest`:
    ```bash
    pytest test_main.py -v
    ```
    *Deberías ver que todos los tests de seguridad y validación de Pydantic pasan exitosamente.*

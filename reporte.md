# Reporte de Cumplimiento de Alcance - Trabajo Final Integrador

Este documento detalla cómo se ha dado cumplimiento a cada uno de los elementos obligatorios del alcance del proyecto, indicando las herramientas y estrategias implementadas.

## 1. API HTTP funcional que utilice un LLM
Se desarrolló una API web utilizando el framework **FastAPI** (Python). El endpoint principal (`POST /ask`) recibe una consulta en formato JSON, la procesa a través del sistema y retorna la respuesta generada por el LLM en formato HTTP estructurado.

## 2. RAG Básico (Ingestión, Embeddings, Recuperación y Generación)
Se implementó un pipeline completo utilizando **LangChain**:
*   **Ingestión:** `PyPDFDirectoryLoader` lee la norma ISA/IEC 62443 desde la carpeta local `/docs`.
*   **Embeddings:** Se utilizan modelos locales de HuggingFace (`all-MiniLM-L6-v2`).
*   **Recuperación:** La vectorización se almacena y consulta en una base de datos **ChromaDB**.
*   **Generación:** Se utiliza la cadena `RetrievalQA` de LangChain.

## 3. Uso de LLM (API externa o modelo local)
Para garantizar la confidencialidad de los datos técnicos y cumplir con las mejores prácticas de seguridad OT (Zero Data Exfiltration), se optó por un **modelo local**. Se utiliza el motor **Ollama** ejecutando el modelo *Mistral*, eliminando la dependencia de servicios en la nube y costos por tokens.

## 4. Empaquetado en Contenedor
El sistema entero (API + Base Vectorial) está contenido mediante un `Dockerfile` optimizado. La orquestación junto al motor de Ollama se realiza mediante `docker-compose.yml`, facilitando un despliegue unificado y reproducible.

## 5. Pipeline de CI/CD mínimo (Build, Test y Calidad)
Se implementó un pipeline en **GitHub Actions** (`.github/workflows/ci.yml`) con un enfoque DevSecOps que incluye:
*   Instalación de dependencias y ejecución de **Tests Unitarios** automatizados (con `pytest` y mocks).
*   Escaneo de secretos con **Gitleaks**.
*   Análisis estático de código Python (SAST) con **Bandit**.
*   Validación de mejores prácticas de empaquetado con **Hadolint**.
*   Validación de Build del contenedor y escaneo de vulnerabilidades (SCA) con **Trivy**, bloqueando PRs con vulnerabilidades críticas.

## 6. Autenticación y Control de Acceso en la API
El acceso al endpoint está restringido. Se implementó una verificación mediante **API Key** utilizando el esquema de seguridad nativo de FastAPI (`APIKeyHeader`). Las peticiones sin credenciales válidas reciben un error HTTP 401/403.

## 7. Rate Limiting
Para mitigar el agotamiento de recursos del hardware local (Denial of Wallet / DoS), se integró la librería **Slowapi**. El endpoint `/ask` está estrictamente limitado a **5 peticiones por minuto por IP** cliente.

## 8. Observabilidad Básica (Logs estructurados)
Se utiliza el módulo `logging` de Python configurado para emitir **logs estructurados**. El sistema registra eventos clave con marcas de tiempo, como las direcciones IP de origen, el procesamiento de consultas legítimas (nivel INFO) y la detección de intentos de inyección de código o fallas de autenticación (nivel WARNING/ERROR).

## 9. Modelo de Amenazas Documentado
Se elaboró y adjuntó en el repositorio el archivo **`THREAT_MODEL.md`**. En él se analizan los componentes del sistema bajo la metodología **STRIDE** (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege) detallando las mitigaciones aplicadas en código para cada vector.

## 10. Mitigaciones de Seguridad para IA (Guardrails)
*   **Validación de Entradas/Salidas:** A través de esquemas de **Pydantic**, se aplican límites estrictos de longitud y formato en la consulta (mitigando ataques de buffer o estrés en el LLM).
*   **Guardrails:** Se implementó un filtro programático básico en el endpoint (lista de palabras prohibidas) que intercepta y bloquea comandos clásicos de *Prompt Injection* ("ignora instrucciones", "system prompt", etc.) antes de que lleguen al modelo.

## 11. Hardening del Contenedor (Sin root e imagen mínima)
*   **Imagen Mínima:** Se utiliza `python:3.11-slim` como imagen base, reduciendo drásticamente la superficie de ataque.
*   **Ejecución sin privilegios:** El `Dockerfile` crea un usuario específico (`appuser`) y cambia el contexto de ejecución (`USER appuser`) para garantizar que la aplicación y el LLM nunca corran con privilegios de administrador (*root*).
*   **Parcheo Dinámico:** El contenedor actualiza sus paquetes base (`apt-get upgrade`) y fuerza las versiones seguras de librerías Python (`msgpack`, `setuptools`) en tiempo de compilación.

## 12. README de Ejecución y Arquitectura
El repositorio cuenta con un archivo `README.md` que detalla el alcance y la justificación de la arquitectura, complementado por un `INSTRUCCIONES.md` que contiene los pasos comandos exactos para el despliegue de los contenedores y la carga de los documentos.
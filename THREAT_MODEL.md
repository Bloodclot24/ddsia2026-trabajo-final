# Modelo de Amenazas (STRIDE) - Asistente de Ciberseguridad OT

## 1. Introducción
Este documento detalla el modelo de amenazas para la API del Asistente de Ciberseguridad OT, utilizando la metodología **STRIDE**. El análisis se realiza asumiendo una arquitectura de contenedores aislados y un despliegue de infraestructura local (on-premise/edge) para garantizar la confidencialidad de los datos técnicos. Se detallan las mitigaciones implementadas en el código y los riesgos residuales identificados.

---

## 2. Análisis STRIDE y Mitigaciones Implementadas

### 2.1. Spoofing (Suplantación de Identidad)
**Amenaza:** Un atacante intenta hacerse pasar por un cliente legítimo para consumir la API o acceder al modelo.
**Mitigación:** Se implementó un control de acceso estricto mediante la exigencia de un `API Key` en los headers de cada petición HTTP.
**Implementación en Código:**
Se utiliza el esquema de seguridad de FastAPI (`APIKeyHeader`) para interceptar y validar el token antes de procesar el endpoint.
```python
# app/main.py
 Autenticación Segura (Variable de Entorno)
API_KEY = os.getenv("API_KEY")
if not API_KEY:
    logger.critical("API_KEY no detectada en el entorno. Abortando inicio por seguridad.")
    raise RuntimeError("La variable de entorno API_KEY es obligatoria.")

api_key_header = APIKeyHeader(name="X-API-Key")

def get_api_key(api_key: str = Security(api_key_header)):
    if api_key != API_KEY:
        raise HTTPException(status_code=403, detail="Credenciales inválidas")
    return api_key
```

### 2.2. Tampering (Manipulación de Datos)
**Amenaza:** Modificación maliciosa del código, los documentos fuente (norma IEC 62443) o los pesos del modelo en tiempo de ejecución.
**Mitigación:** La infraestructura se despliega en contenedores Docker inmutables. Además, el pipeline RAG solo tiene permisos de lectura sobre el directorio de documentos.
**Implementación en Código:**
Los permisos dentro del contenedor están restringidos al usuario no privilegiado creado durante el *build*.
```dockerfile
# Dockerfile
RUN useradd -m -r appuser && \
    mkdir /app && \
    chown -R appuser /app
...
USER appuser
```

### 2.3. Repudiation (Repudio)
**Amenaza:** Un usuario o atacante realiza una acción maliciosa (ej. un intento de *Prompt Injection*) y niega haberlo hecho, por falta de rastros.
**Mitigación:** Implementación de observabilidad mediante **logs estructurados**. Se registra la IP del cliente y la naturaleza del evento (informativo, advertencia o error).
**Implementación en Código:**
```python
# app/main.py
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)
...
logger.info(f"Consulta recibida desde {request.client.host}")
logger.warning("Intento de inyección de prompt detectado.")
```

### 2.4. Information Disclosure (Fuga de Información)
**Amenaza:** Exposición de información sensible, ya sea contenido de los documentos vectorizados o fuga de datos hacia proveedores externos.
**Mitigación Principal:** Uso de un LLM local (`Ollama` con *Mistral/Llama3*) y embeddings locales (`HuggingFace`). **Cero datos abandonan la infraestructura local.**
**Implementación en Código:**
```python
# app/rag.py
OLLAMA_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
...
embeddings = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")
llm = Ollama(model="mistral", base_url=OLLAMA_URL)
```

### 2.5. Denial of Service (Denegación de Servicio)
**Amenaza:** Un atacante inunda la API con peticiones complejas para agotar los recursos de cómputo locales (CPU/RAM) destinados a la inferencia del LLM.
**Mitigación:** Implementación de un `Rate Limiting` a nivel de aplicación utilizando la librería `slowapi`, restringiendo la cantidad de peticiones por IP.
**Implementación en Código:**
```python
# app/main.py
limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
...
@app.post("/ask")
@limiter.limit("5/minute") # Límite estricto para proteger la inferencia local
def ask_question(request: Request, query: QueryRequest, key: str = Security(get_api_key)):
```

### 2.6. Elevation of Privilege (Elevación de Privilegios)
**Amenaza:** Un atacante logra ejecutar código arbitrario a través del LLM e intenta tomar control del host.
**Mitigación:** *Hardening* del contenedor. El proceso de la API corre sin privilegios de `root`.
**Implementación en Código:**
```dockerfile
# Dockerfile
FROM python:3.11-slim
# Se ejecuta como 'appuser', limitando la superficie de ataque si el proceso es vulnerado.
USER appuser 
```

---

## 3. Riesgos Específicos de IA y Sus Mitigaciones

Además del modelo STRIDE tradicional, se abordaron riesgos inherentes a los sistemas con Modelos de Lenguaje:

*   **Prompt Injection:** Mitigado mediante guardrails básicos basados en listas negras y validación estricta del tamaño y tipo de caracteres permitidos (Pydantic).
    ```python
    # app/main.py
    class QueryRequest(BaseModel):
        question: str = Field(..., min_length=5, max_length=300)
    
    # ... dentro del endpoint ...
    forbidden_words = ["ignora", "instrucciones previas", "system prompt", "bypass"]
    if any(word in query.question.lower() for word in forbidden_words):
        raise HTTPException(status_code=400, detail="Entrada no permitida por políticas de seguridad.")
    ```

---

## 4. Riesgos Residuales Aceptados (Posibles Riesgos Actuales)

A pesar de las mitigaciones, la arquitectura actual aún presenta los siguientes riesgos residuales:

1.  **Ataques Avanzados de Prompt Injection (Jailbreaks Complejos):** La validación por lista negra (keywords prohibidas) es efectiva contra ataques básicos, pero no detendrá a un atacante sofisticado que utilice técnicas de ofuscación, codificación o *role-playing* avanzado para alterar el comportamiento del LLM.
2.  **Alucinaciones y Envenenamiento de Contexto (Context Poisoning):** Si la base de documentos (PDFs de IEC 62443) contiene inconsistencias, o si el mecanismo de recuperación (RAG) trae fragmentos irrelevantes, el modelo generará respuestas incorrectas (*alucinaciones*). Actualmente no hay un evaluador externo que verifique la veracidad técnica de la salida contra la norma.
3.  **Falta de Cifrado en Tránsito (Carencia de TLS/HTTPS):** Actualmente, la comunicación entre el cliente y la API se realiza en texto plano (HTTP). Aunque esté contenido en una red local, la información es vulnerable a intercepciones (*Man-in-the-Middle*). Para un entorno productivo, se requeriría un proxy reverso (como Nginx o Traefik) gestionando certificados TLS.
4.  **Agotamiento de Recursos (Denial of Wallet / Resource Exhaustion):** Aunque hay *Rate Limiting* a nivel de API, los procesos de inferencia del LLM local consumen mucha memoria y CPU. Varias peticiones legítimas simultáneas (dentro del límite de 5 por minuto) podrían congelar el hardware local si este no cuenta con los recursos suficientes o si no se limitan los recursos a nivel de Docker (`deploy.resources` en `docker-compose.yml`).

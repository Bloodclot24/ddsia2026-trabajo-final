import logging
from fastapi import FastAPI, HTTPException, Security, Request
from fastapi.security import APIKeyHeader
from pydantic import BaseModel, Field
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from app.rag import qa_system

# Observabilidad: Logs estructurados
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Rate Limiting
limiter = Limiter(key_func=get_remote_address)
app = FastAPI(title="OT Cybersecurity Assistant API")
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Autenticación
API_KEY = "ddsia-ot-cyber-2026"
api_key_header = APIKeyHeader(name="X-API-Key")

def get_api_key(api_key: str = Security(api_key_header)):
    if api_key != API_KEY:
        raise HTTPException(status_code=403, detail="Credenciales inválidas")
    return api_key

# Mitigaciones de IA: Validación de inputs
class QueryRequest(BaseModel):
    question: str = Field(..., min_length=5, max_length=300)

@app.get("/")
def read_root():
    return {"status": "ok", "message": "API Operativa"}

@app.post("/ask")
@limiter.limit("5/minute") # Prevención de abuso / DoS
def ask_question(request: Request, query: QueryRequest, key: str = Security(get_api_key)):
    logger.info(f"Consulta recibida desde {request.client.host}")
    
    # Guardrails: Mitigación de Prompt Injection básica
    forbidden_words = ["ignora", "instrucciones previas", "system prompt", "bypass"]
    if any(word in query.question.lower() for word in forbidden_words):
        logger.warning("Intento de inyección de prompt detectado.")
        raise HTTPException(status_code=400, detail="Entrada no permitida por políticas de seguridad.")
        
    try:
        response = qa_system.invoke(query.question)
        logger.info("Respuesta generada exitosamente.")
        return {"answer": response["result"]}
    except Exception as e:
        logger.error(f"Error procesando RAG: {str(e)}")
        raise HTTPException(status_code=500, detail="Error interno procesando la solicitud.")
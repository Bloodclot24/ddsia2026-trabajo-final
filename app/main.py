from fastapi import FastAPI

app = FastAPI(title="OT Cybersecurity Assistant API")

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Hello World - API Segura Inicializada"}
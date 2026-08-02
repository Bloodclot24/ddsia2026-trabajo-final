from pydantic import BaseModel
from app.rag import qa_system

class QueryRequest(BaseModel):
    question: str

@app.post("/ask")
def ask_question(request: QueryRequest):
    response = qa_system.invoke(request.question)
    return {"answer": response["result"]}
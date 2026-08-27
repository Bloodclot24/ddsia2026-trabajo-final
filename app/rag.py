import os
from langchain_community.document_loaders import PyPDFDirectoryLoader
from langchain_text_splitter import RecursiveCharacterTextSplitter
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import Chroma
from langchain_community.llms import Ollama
from langchain.chains import RetrievalQA

OLLAMA_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")

def init_rag_pipeline():
    # 1. Ingestión
    loader = PyPDFDirectoryLoader("./app/docs/")
    docs = loader.load()
    
    # 2. Text Splitting
    text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=100)
    splits = text_splitter.split_documents(docs)
    
    # 3. Embeddings Locales (Se ejecutan en CPU sin costo)
    embeddings = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")
    vectorstore = Chroma.from_documents(documents=splits, embedding=embeddings)
    
    # 4. LLM Local vía Ollama
    llm = Ollama(model="mistral", base_url=OLLAMA_URL)
    
    # 5. Pipeline RAG
    qa_chain = RetrievalQA.from_chain_type(
        llm, 
        retriever=vectorstore.as_retriever(),
        return_source_documents=False
    )
    return qa_chain

qa_system = init_rag_pipeline()
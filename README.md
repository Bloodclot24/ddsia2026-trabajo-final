# Propuesta de Proyecto: Asistente de IA para Ciberseguridad OT

## Descripción del Proyecto
Este proyecto implementa un servicio web basado en Inteligencia Artificial diseñado para actuar como un asistente técnico especializado en estándares de Ciberseguridad para Tecnologías de la Operación (OT), específicamente sobre la norma ISA/IEC 62443. 

## Dominio Elegido
El dominio está estrictamente acotado a la documentación pública, guías de implementación y resúmenes de la serie de estándares **ISA/IEC 62443** aplicados a entornos industriales.

## Alcance del Sistema
En cumplimiento con los requerimientos obligatorios, el sistema contempla:
* **API HTTP:** Desarrollada en FastAPI con un endpoint principal para consultas.
* **RAG Local (Cero Costo):** Ingestión de PDFs, generación de embeddings locales (HuggingFace) y base de datos vectorial (ChromaDB).
* **LLM Local:** Uso de Ollama (modelo Mistral/Llama3) ejecutado en contenedor, eliminando la dependencia de APIs externas y tokens.
* **Infraestructura:** Empaquetado completo mediante Docker y Docker Compose con hardening (ejecución sin privilegios root).
* **Pipeline CI/CD:** GitHub Actions para validación de build, linters y tests unitarios básicos.
* **Seguridad y Observabilidad:** Autenticación por API Key, Rate Limiting, validación de inputs (prevención de Prompt Injection), mitigaciones STRIDE y logs estructurados.

## Fuera de Alcance
No se desarrollará una interfaz gráfica (frontend), fine-tuning del modelo base, despliegue en infraestructura cloud real (AWS/GCP), ni arquitecturas de alta disponibilidad o multi-tenancy.
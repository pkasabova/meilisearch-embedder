from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer
import numpy as np
import os
from typing import List

app = FastAPI(title="MeiliSearch Multilingual Embedder",
             description="REST API for generating embeddings using paraphrase-multilingual-MiniLM-L12-v2",
             version="1.0.0")

model = None

def get_model():
    global model
    if model is None:
        model = SentenceTransformer('sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2')
    return model

class TextRequest(BaseModel):
    texts: List[str]

@app.on_event("startup")
async def startup_event():
    # Do not load the model here to avoid long cold starts on Render free tier
    return

@app.get("/")
async def root():
    return {"message": "MeiliSearch Multilingual Embedder is running!"}

@app.post("/embed")
async def embed_texts(request: TextRequest):
    if not request.texts:
        raise HTTPException(status_code=400, detail="No texts provided")
    
    try:
        # Reduce parallelism to lower memory footprint on small instances
        os.environ.setdefault("TOKENIZERS_PARALLELISM", "false")
        os.environ.setdefault("OMP_NUM_THREADS", "1")
        os.environ.setdefault("MKL_NUM_THREADS", "1")
        os.environ.setdefault("NUMEXPR_MAX_THREADS", "1")
        # Generate embeddings
        m = get_model()
        embeddings = m.encode(
            request.texts,
            convert_to_numpy=True,
            batch_size=8,
            show_progress_bar=False,
        ).tolist()
        return {"embeddings": embeddings}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("app.main:app", host="0.0.0.0", port=port, reload=True)

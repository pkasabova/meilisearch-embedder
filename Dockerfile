FROM python:3.9-slim

WORKDIR /app

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu \
       torch==1.13.1+cpu

# Pre-download the SentenceTransformer model to avoid long cold starts
RUN python - <<'PY'
from sentence_transformers import SentenceTransformer
SentenceTransformer('sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2')
print('Model cached')
PY

# Copy application code
COPY app/ ./app

# Create a non-root user and switch to it
RUN adduser --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

# Expose the port the app runs on
EXPOSE 8000

# Command to run the application (bind to Render's PORT) with higher timeouts
CMD ["sh", "-c", "gunicorn app.main:app --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:${PORT:-8000} --timeout ${GUNICORN_TIMEOUT:-300} --graceful-timeout ${GUNICORN_GRACEFUL_TIMEOUT:-60} -w ${WEB_CONCURRENCY:-1} --threads ${GUNICORN_THREADS:-1}"]

#!/bin/bash
set -ex

# Install Python dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Download the model during build to include it in the image
python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2')"

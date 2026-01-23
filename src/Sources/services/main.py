import os
import json
import numpy as np
from flask import Flask, request, jsonify
from werkzeug.exceptions import BadRequest
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity

# Khởi tạo Flask app
app = Flask(__name__)

# Đường dẫn model local
MODEL_NAME = 'all-MiniLM-L6-v2'
MODEL_DIR = os.path.join(os.path.dirname(__file__), 'models', MODEL_NAME)
MODEL_HUGGINGFACE = f'sentence-transformers/{MODEL_NAME}'

# Load model khi app khởi động
print(f"Loading model {MODEL_NAME}...")
try:
    # Kiểm tra xem model có tồn tại local không
    # Kiểm tra cả thư mục và file config.json (file quan trọng của SentenceTransformer)
    config_path = os.path.join(MODEL_DIR, 'config.json')
    if os.path.exists(MODEL_DIR) and os.path.exists(config_path):
        print(f"Loading model from local path: {MODEL_DIR}")
        model = SentenceTransformer(MODEL_DIR)
        print("Model loaded from local successfully!")
    else:
        print(f"Model not found locally at: {MODEL_DIR}")
        print(f"Please run 'python download_model.py' first to download the model.")
        print(f"Or downloading from HuggingFace now: {MODEL_HUGGINGFACE}")
        model = SentenceTransformer(MODEL_HUGGINGFACE)
        # Tạo thư mục models nếu chưa có
        os.makedirs(os.path.dirname(MODEL_DIR), exist_ok=True)
        # Lưu model về local
        print(f"Saving model to local path: {MODEL_DIR}")
        model.save(MODEL_DIR)
        print("Model downloaded and saved successfully!")
except Exception as e:
    print(f"Error loading model: {str(e)}")
    raise


@app.route('/calculate-distances', methods=['POST'])
def calculate_distances():
    """
    Endpoint nhận spec và candidates, tính cosine distance giữa spec và từng candidate.
    
    Request body:
    {
        "spec": "string",
        "candidates": ["string1", "string2", ...]
    }
    
    Response:
    {
        "distances": [0.123, 0.456, ...]
    }
    """
    try:
        # Validate request
        if not request.is_json:
            return jsonify({"error": "Content-Type must be application/json"}), 400
        
        try:
            data = request.get_json(force=True)
        except BadRequest as e:
            return jsonify({
                "error": "Invalid JSON format",
                "details": str(e)
            }), 400
        except Exception as e:
            return jsonify({
                "error": "Failed to parse JSON",
                "details": str(e)
            }), 400
        
        if data is None:
            return jsonify({"error": "Request body is empty or invalid JSON"}), 400
        
        # Validate input fields
        if 'spec' not in data:
            return jsonify({"error": "Missing 'spec' field"}), 400
        if 'candidates' not in data:
            return jsonify({"error": "Missing 'candidates' field"}), 400
        
        spec = data['spec']
        candidates = data['candidates']
        
        # Validate types
        if not isinstance(spec, str):
            return jsonify({"error": "'spec' must be a string"}), 400
        if not isinstance(candidates, list):
            return jsonify({"error": "'candidates' must be a list"}), 400
        if len(candidates) == 0:
            return jsonify({"error": "'candidates' list cannot be empty"}), 400
        
        # Validate all candidates are strings
        if not all(isinstance(c, str) for c in candidates):
            return jsonify({"error": "All items in 'candidates' must be strings"}), 400
        
        # Encode spec và candidates thành embeddings
        spec_embedding = model.encode([spec], convert_to_numpy=True)
        candidate_embeddings = model.encode(candidates, convert_to_numpy=True)
        
        # Tính cosine similarity giữa spec và từng candidate
        # cosine_similarity expects 2D arrays, spec_embedding is already 2D (1, embedding_dim)
        similarities = cosine_similarity(spec_embedding, candidate_embeddings)[0]
        
        # Chuyển cosine similarity thành cosine distance
        # Cosine distance = 1 - cosine similarity
        distances = 1 - similarities
        
        # Convert numpy array to list of floats
        distances_list = distances.tolist()
        
        return jsonify({"distances": distances_list}), 200
        
    except Exception as e:
        return jsonify({"error": f"Internal server error: {str(e)}"}), 500


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "model": "all-MiniLM-L6-v2"}), 200


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=6868, debug=True)

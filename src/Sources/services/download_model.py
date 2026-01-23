"""
Script để download model embedding all-MiniLM-L6-v2 vào thư mục models/
"""
import os
from sentence_transformers import SentenceTransformer

MODEL_NAME = 'all-MiniLM-L6-v2'
MODEL_HUGGINGFACE = f'sentence-transformers/{MODEL_NAME}'
MODEL_DIR = os.path.join(os.path.dirname(__file__), 'models', MODEL_NAME)

def download_model():
    """Download model từ HuggingFace và lưu vào thư mục models/"""
    print(f"Downloading model: {MODEL_HUGGINGFACE}")
    print(f"Target directory: {MODEL_DIR}")
    
    # Tạo thư mục models nếu chưa có
    os.makedirs(os.path.dirname(MODEL_DIR), exist_ok=True)
    
    # Kiểm tra nếu model đã tồn tại
    if os.path.exists(MODEL_DIR):
        print(f"Model already exists at: {MODEL_DIR}")
        response = input("Do you want to re-download? (y/n): ")
        if response.lower() != 'y':
            print("Skipping download.")
            return
    
    # Download model từ HuggingFace
    print("Loading model from HuggingFace...")
    model = SentenceTransformer(MODEL_HUGGINGFACE)
    
    # Lưu model về local
    print(f"Saving model to: {MODEL_DIR}")
    model.save(MODEL_DIR)
    
    print("Model downloaded and saved successfully!")
    print(f"Model location: {MODEL_DIR}")

if __name__ == '__main__':
    download_model()

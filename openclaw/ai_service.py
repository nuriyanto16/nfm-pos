import os
import requests
import socket
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

import time

MODEL_ID = "gemini-flash-latest"
FALLBACK_MODELS = ["gemini-2.5-flash-lite", "gemini-3-flash-preview", "gemini-flash-lite-latest"]
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")

if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

def get_live_menu_data(query=""):
    try:
        limit = 20
        # 1. Get URL from environment variable
        # In VM, this should be set to http://host.docker.internal:8080/api/menus
        base_url = os.getenv("BACKEND_URL", "http://localhost:8080/api/menus")
        
        # 2. Add search query if provided
        search_query = ""
        if query:
            words = [w for w in query.split() if len(w) > 2]
            search_query = "+".join(words[:3])

        backend_url = f"{base_url}?limit={limit}"
        if search_query:
            backend_url += f"&search={search_query}"
        
        print(f"DEBUG: Fetching menu from {backend_url}")
        response = requests.get(backend_url, timeout=5)
        if response.status_code == 200:
            data = response.json()
            menus = data.get("rows") if isinstance(data, dict) else data
            if not menus or not isinstance(menus, list):
                menus = data.get("data", []) if isinstance(data, dict) else []
            
            if not menus:
                return ""
            
            menu_text = "\n=== MENU DATA ===\n"
            for m in menus:
                name = m.get('name', '-')
                price = m.get('price', 0)
                menu_text += f"{name}:Rp{price:,} "
            return menu_text + "\n"
    except Exception as e:
        print(f"DEBUG: API Error: {e}")
    return ""

def get_knowledge_context(user_message=""):
    context = ""
    knowledge_dir = "knowledge"
    if os.path.exists(knowledge_dir):
        for filename in os.listdir(knowledge_dir):
            if filename.endswith(".txt"):
                try:
                    with open(os.path.join(knowledge_dir, filename), "r", encoding="utf-8") as f:
                        context += f"\n--- {filename} ---\n{f.read()}\n"
                except Exception:
                    pass
    
    # Only fetch live menu data if user asks about menu, price, or specific items
    keywords = ["menu", "harga", "makan", "minum", "list", "daftar", "berapa", "ada"]
    if any(k in user_message.lower() for k in keywords) or len(user_message.split()) < 4:
        context += get_live_menu_data(user_message)
        
    return context

def generate_ai_response(user_message):
    context = get_knowledge_context(user_message)
    system_instruction = (
        "Anda adalah NFM Assistant dari POS Resto.\n"
        "Gaya bicara: SINGKAT, TO THE POINT, dan PROFESIONAL.\n\n"
        "ATURAN UTAMA:\n"
        "1. Jawab langsung ke inti pertanyaan (To the point).\n"
        "2. Hindari basa-basi yang panjang. Gunakan kalimat yang padat dan informatif.\n"
        "3. Jika butuh penjelasan langkah, gunakan bullet points singkat.\n"
        "4. Tetap ramah namun sangat efisien dalam kata-kata.\n"
    )
    
    prompt = f"{system_instruction}\n\nKNOWLEDGE BASE:\n{context}\n\nPertanyaan: {user_message}\nJawaban:"
    
    if not GEMINI_API_KEY:
        return {"text": "API Key Gemini belum dikonfigurasi.", "model": "None", "input_tokens": 0, "output_tokens": 0}

    # Try Primary Model then Fallback Models
    all_models = [MODEL_ID] + FALLBACK_MODELS
    for current_model_id in all_models:
        try:
            model = genai.GenerativeModel(current_model_id)
            response = model.generate_content(prompt)
            
            input_tokens = 0
            output_tokens = 0
            if hasattr(response, 'usage_metadata'):
                input_tokens = getattr(response.usage_metadata, 'prompt_token_count', 0)
                output_tokens = getattr(response.usage_metadata, 'candidates_token_count', 0)
            
            return {
                "text": response.text,
                "model": current_model_id,
                "input_tokens": input_tokens,
                "output_tokens": output_tokens
            }
        except Exception as e:
            print(f"DEBUG: Error with model {current_model_id}: {e}")
            time.sleep(1) # Wait a bit before next model
            continue 
    
    # If all models fail
    return {
        "text": "Maaf, sistem AI kami sedang sibuk atau mengalami kendala kuota. Silakan coba beberapa saat lagi atau hubungi support.",
        "model": "All Failed",
        "input_tokens": 0,
        "output_tokens": 0
    }

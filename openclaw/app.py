import os
import threading
import logging
import hmac
import hashlib
import time
import random
from flask import Flask, render_template, request, jsonify
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import telebot
from dotenv import load_dotenv

# Import our custom modules
from database import init_db, save_log, get_logs, get_token_stats
from ai_service import generate_ai_response

load_dotenv()

import logging
from logging.handlers import TimedRotatingFileHandler

# Setup Logging with Daily Rotation
LOG_DIR = "logs"
if not os.path.exists(LOG_DIR):
    os.makedirs(LOG_DIR)

log_filename = os.path.join(LOG_DIR, "openclaw.log")
handler = TimedRotatingFileHandler(
    log_filename, 
    when="midnight", 
    interval=1, 
    backupCount=30, # Simpan log selama 30 hari
    encoding="utf-8"
)
handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))

logging.basicConfig(
    level=logging.INFO,
    handlers=[handler, logging.StreamHandler()]
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})

# ── Rate Limiter (in-memory, per IP) ──────────────────────────────────────────
limiter = Limiter(
    key_func=get_remote_address,
    app=app,
    default_limits=[],   # hanya terapkan per-route
    storage_uri="memory://",
)

# ── Challenge Token Secret ────────────────────────────────────────────────────
# Token HMAC berumur pendek untuk validasi setiap sesi chat
CHAT_SECRET = os.environ.get("CHAT_SECRET", "nfm-chat-secret-2026")
TOKEN_TTL = 3600  # detik (1 jam)

TELEGRAM_TOKEN = os.environ.get("TELEGRAM_TOKEN", "")
bot = telebot.TeleBot(TELEGRAM_TOKEN) if TELEGRAM_TOKEN else None

# Initialize Database
init_db()

# --- WEB ROUTES ---

@app.route("/")
def index():
    return render_template("index.html")

# ── Challenge Token Endpoints ─────────────────────────────────────────────────

@app.route("/api/chat-token", methods=["GET"])
@limiter.limit("10 per minute")
def get_chat_token():
    """Buat HMAC token berumur TTL untuk memvalidasi sesi chat."""
    ts = str(int(time.time()))
    sig = hmac.new(CHAT_SECRET.encode(), ts.encode(), hashlib.sha256).hexdigest()
    return jsonify({"token": f"{ts}.{sig}", "ttl": TOKEN_TTL})


def _verify_token(token: str) -> bool:
    """Verifikasi HMAC token dan pastikan belum expired."""
    try:
        ts_str, sig = token.rsplit(".", 1)
        ts = int(ts_str)
        # Cek TTL
        if time.time() - ts > TOKEN_TTL:
            return False
        # Cek signature
        expected = hmac.new(CHAT_SECRET.encode(), ts_str.encode(), hashlib.sha256).hexdigest()
        return hmac.compare_digest(sig, expected)
    except Exception:
        return False


# ── Chat Endpoint ─────────────────────────────────────────────────────────────

@app.route("/chat", methods=["POST"])
@limiter.limit("5 per minute")        # maks 5 pesan/menit per IP
@limiter.limit("20 per hour")         # maks 20 pesan/jam per IP
def chat():
    data = request.json or {}
    user_message = data.get("message", "").strip()
    user_name = data.get("user_name", "Web User")
    chat_token = data.get("chat_token", "")

    # ── Validasi input ────────────────────────────────────────────────────
    if not user_message:
        return jsonify({"error": "Pesan tidak boleh kosong."}), 400
    if len(user_message) > 500:
        return jsonify({"error": "Pesan terlalu panjang (maks 500 karakter)."}), 400

    # ── Validasi token sesi ───────────────────────────────────────────────
    if not _verify_token(chat_token):
        return jsonify({"error": "Sesi tidak valid atau sudah kedaluwarsa. Muat ulang halaman."}), 403

    # ── Generate AI response ──────────────────────────────────────────────
    ai_data = generate_ai_response(user_message)

    # ── Save log ──────────────────────────────────────────────────────────
    save_log(
        user_id="WEB",
        user_name=user_name,
        platform="WEB",
        message=user_message,
        reply=ai_data['text'],
        model_name=ai_data['model'],
        input_tokens=ai_data['input_tokens'],
        output_tokens=ai_data['output_tokens']
    )

    return jsonify({"reply": ai_data['text']})


@app.errorhandler(429)
def ratelimit_error(e):
    """Custom response saat rate limit tercapai."""
    logger.warning(f"Rate limit hit from IP: {get_remote_address()}")
    return jsonify({
        "error": "Terlalu banyak pesan. Harap tunggu beberapa saat sebelum bertanya lagi."
    }), 429

@app.route("/api/logs", methods=["GET"])
def api_get_logs():
    limit = request.args.get('limit', default=20, type=int)
    offset = request.args.get('offset', default=0, type=int)
    logs, total = get_logs(limit, offset)
    return jsonify({"logs": logs, "total": total})

@app.route("/api/token-stats", methods=["GET"])
def api_get_token_stats():
    stats = get_token_stats()
    return jsonify(stats)

# --- KNOWLEDGE MANAGEMENT API ---

KNOWLEDGE_DIR = "knowledge"
if not os.path.exists(KNOWLEDGE_DIR):
    os.makedirs(KNOWLEDGE_DIR)

@app.route("/api/knowledge", methods=["GET"])
def list_knowledge():
    files = [f for f in os.listdir(KNOWLEDGE_DIR) if f.endswith(".txt")]
    return jsonify(files)

@app.route("/api/knowledge", methods=["POST"])
def add_knowledge():
    data = request.json
    filename = data.get("filename")
    content = data.get("content")
    if not filename.endswith(".txt"):
        filename += ".txt"
    
    with open(os.path.join(KNOWLEDGE_DIR, filename), "w", encoding="utf-8") as f:
        f.write(content)
    return jsonify({"message": "File saved"})

@app.route("/api/knowledge/<filename>", methods=["GET"])
def get_knowledge_content(filename):
    path = os.path.join(KNOWLEDGE_DIR, filename)
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
        return jsonify({"filename": filename, "content": content})
    return jsonify({"error": "File not found"}), 404

@app.route("/api/knowledge/<filename>", methods=["DELETE"])
def delete_knowledge(filename):
    path = os.path.join(KNOWLEDGE_DIR, filename)
    if os.path.exists(path):
        os.remove(path)
        return jsonify({"message": "File deleted"})
    return jsonify({"error": "File not found"}), 404

# --- NOTIFICATION API ---

@app.route("/api/notify", methods=["POST"])
def send_notification():
    data = request.json
    message = data.get("message")
    chat_id = data.get("chat_id")
    
    if not bot:
        logger.error("Notification failed: Telegram Bot not initialized (TOKEN missing)")
        return jsonify({"error": "Bot not initialized"}), 500
    
    try:
        # Format chat_id properly
        str_chat_id = str(chat_id)
        if not str_chat_id.startswith("@") and not str_chat_id.replace("-", "").isdigit():
             str_chat_id = "@" + str_chat_id
             
        bot.send_message(str_chat_id, message, parse_mode="Markdown")
        logger.info(f"Notification sent successfully to {str_chat_id}")
        return jsonify({"status": "success"})
    except Exception as e:
        logger.error(f"Error sending notification via OpenClaw: {e}")
        return jsonify({"error": str(e)}), 500

# --- TELEGRAM BOT LOGIC ---

if bot:
    @bot.message_handler(commands=['start', 'help'])
    def send_welcome(message):
        bot.reply_to(message, "Halo! Saya NFM Assistant. Ada yang bisa saya bantu terkait POS Resto?")

    @bot.message_handler(func=lambda message: True)
    def handle_telegram_message(message):
        user_text = message.text
        user_name = message.from_user.first_name
        
        ai_data = generate_ai_response(user_text)
        
        # Save log
        save_log(
            user_id=message.from_user.id,
            user_name=user_name,
            platform="TELEGRAM",
            message=user_text,
            reply=ai_data['text'],
            model_name=ai_data['model'],
            input_tokens=ai_data['input_tokens'],
            output_tokens=ai_data['output_tokens']
        )
        
        bot.reply_to(message, ai_data['text'])

    def run_bot():
        logger.info("Telegram Bot started...")
        bot.polling(none_stop=True)

    # Run bot in background thread
    threading.Thread(target=run_bot, daemon=True).start()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

import sqlite3
import os

DB_PATH = "chat_history.db"

def init_db():
    with sqlite3.connect(DB_PATH) as conn:
        conn.execute('PRAGMA journal_mode=WAL')
        conn.execute('PRAGMA synchronous=NORMAL')
        
        conn.execute('''
            CREATE TABLE IF NOT EXISTS chat_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id TEXT,
                user_name TEXT,
                platform TEXT,
                message TEXT,
                reply TEXT,
                model_name TEXT,
                input_tokens INTEGER,
                output_tokens INTEGER,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        conn.execute('CREATE INDEX IF NOT EXISTS idx_logs_timestamp ON chat_logs(timestamp)')
        conn.execute('CREATE INDEX IF NOT EXISTS idx_logs_user_id ON chat_logs(user_id)')
        
        # Migrasi kolom jika belum ada
        cursor = conn.execute("PRAGMA table_info(chat_logs)")
        columns = [row[1] for row in cursor.fetchall()]
        if 'input_tokens' not in columns:
            conn.execute("ALTER TABLE chat_logs ADD COLUMN input_tokens INTEGER DEFAULT 0")
        if 'output_tokens' not in columns:
            conn.execute("ALTER TABLE chat_logs ADD COLUMN output_tokens INTEGER DEFAULT 0")

def save_log(user_id, user_name, platform, message, reply, model_name, input_tokens=0, output_tokens=0):
    try:
        with sqlite3.connect(DB_PATH) as conn:
            conn.execute(
                "INSERT INTO chat_logs (user_id, user_name, platform, message, reply, model_name, input_tokens, output_tokens) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                (str(user_id), user_name, platform, message, reply, model_name, input_tokens, output_tokens)
            )
    except Exception as e:
        print(f"Database error: {e}")

def get_logs(limit=20, offset=0):
    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        cursor = conn.execute(
            "SELECT * FROM chat_logs ORDER BY timestamp DESC LIMIT ? OFFSET ?", 
            (limit, offset)
        )
        logs = [dict(row) for row in cursor.fetchall()]
        
        count_cursor = conn.execute("SELECT COUNT(*) as total FROM chat_logs")
        total = count_cursor.fetchone()['total']
        return logs, total

def get_token_stats():
    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        cursor = conn.execute(
            "SELECT model_name, SUM(input_tokens) as total_input, SUM(output_tokens) as total_output FROM chat_logs GROUP BY model_name"
        )
        return [dict(row) for row in cursor.fetchall()]

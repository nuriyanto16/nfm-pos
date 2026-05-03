import React, { useState, useRef, useEffect, useCallback } from 'react';

// Reads from .env (dev) or .env.production (build) automatically
const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080/api';

// Per-session limits (client-side guard layer)
const MAX_MESSAGES_PER_SESSION = 20;
const COOLDOWN_MS = 5000; // 5 detik antar pesan

const ChatbotWidget = () => {
  const [isOpen, setIsOpen] = useState(false);
  const [messages, setMessages] = useState([
    { from: 'bot', text: 'Halo! 👋 Saya NFM Assistant. Ada yang bisa saya bantu seputar NFM POS?' }
  ]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [chatToken, setChatToken] = useState(null);
  const [msgCount, setMsgCount] = useState(0);
  const [cooldownUntil, setCooldownUntil] = useState(0);
  const [cooldownLeft, setCooldownLeft] = useState(0);
  const [sessionBlocked, setSessionBlocked] = useState(false);
  const messagesEndRef = useRef(null);
  const inputRef = useRef(null);
  const cooldownRef = useRef(null);

  // ── Fetch session token on mount ──────────────────────────────────────────
  const fetchToken = useCallback(async () => {
    try {
      const res = await fetch(`${API_URL}/chatbot/token`);
      if (res.ok) {
        const data = await res.json();
        setChatToken(data.token);
      }
    } catch {
      // Token fetch silently fails; server will reject the empty token
    }
  }, []);

  useEffect(() => {
    fetchToken();
    // Refresh token every 55 minutes (TTL is 60 min)
    const interval = setInterval(fetchToken, 55 * 60 * 1000);
    return () => clearInterval(interval);
  }, [fetchToken]);

  // ── Cooldown ticker ───────────────────────────────────────────────────────
  useEffect(() => {
    if (cooldownUntil > Date.now()) {
      cooldownRef.current = setInterval(() => {
        const left = Math.ceil((cooldownUntil - Date.now()) / 1000);
        if (left <= 0) {
          setCooldownLeft(0);
          clearInterval(cooldownRef.current);
        } else {
          setCooldownLeft(left);
        }
      }, 500);
    }
    return () => clearInterval(cooldownRef.current);
  }, [cooldownUntil]);

  // ── Auto-scroll ───────────────────────────────────────────────────────────
  const scrollToBottom = () => messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  useEffect(() => {
    scrollToBottom();
    if (isOpen && inputRef.current) setTimeout(() => inputRef.current?.focus(), 300);
  }, [messages, isOpen]);

  // ── Send message ──────────────────────────────────────────────────────────
  const sendMessage = async (overrideText) => {
    const text = (overrideText ?? input).trim();
    if (!text || isLoading) return;

    // Client-side guards
    if (Date.now() < cooldownUntil) return;
    if (sessionBlocked) return;
    if (msgCount >= MAX_MESSAGES_PER_SESSION) {
      setSessionBlocked(true);
      setMessages(prev => [...prev, {
        from: 'bot',
        text: '⚠️ Batas sesi tercapai (20 pesan). Muat ulang halaman untuk sesi baru.'
      }]);
      return;
    }
    if (text.length > 500) {
      setMessages(prev => [...prev, { from: 'bot', text: '⚠️ Pesan terlalu panjang (maks 500 karakter).' }]);
      return;
    }

    setMessages(prev => [...prev, { from: 'user', text }]);
    setInput('');
    setIsLoading(true);
    setCooldownUntil(Date.now() + COOLDOWN_MS);
    setMsgCount(c => c + 1);

    try {
      const res = await fetch(`${API_URL}/chatbot/chat`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          message: text,
          user_name: 'Web Visitor',
          chat_token: chatToken || '',
        }),
      });

      const data = await res.json();

      if (!res.ok) {
        // 429 rate-limit or 403 token invalid
        const errMsg = data.error || 'Terjadi kesalahan. Coba lagi nanti.';
        if (res.status === 403) {
          // Token invalid – refresh silently
          fetchToken();
        }
        setMessages(prev => [...prev, { from: 'bot', text: `⚠️ ${errMsg}` }]);
      } else {
        setMessages(prev => [...prev, { from: 'bot', text: data.reply }]);
      }
    } catch {
      setMessages(prev => [...prev, {
        from: 'bot',
        text: '⚠️ Gagal terhubung ke server. Pastikan koneksi internet Anda aktif.'
      }]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(); }
  };

  const quickReplies = ['Fitur unggulan', 'Harga paket', 'Cara trial gratis', 'Cocok untuk franchise?'];
  const isThrottled = Date.now() < cooldownUntil && cooldownLeft > 0;
  const canSend = !isLoading && !isThrottled && !sessionBlocked && input.trim().length > 0;

  return (
    <>
      {/* ── Chat Window ──────────────────────────────────────────────────── */}
      <div className={`chatbot-window ${isOpen ? 'open' : ''}`}>
        {/* Header */}
        <div className="chatbot-header">
          <div className="chatbot-avatar">🤖</div>
          <div className="chatbot-header-info">
            <div className="chatbot-name">NFM Assistant</div>
            <div className="chatbot-status">● Online</div>
          </div>
          <div className="chatbot-header-actions">
            {/* Session usage indicator */}
            <div className="session-counter" title="Pesan tersisa sesi ini">
              {MAX_MESSAGES_PER_SESSION - msgCount}
            </div>
            <button className="chatbot-close" onClick={() => setIsOpen(false)}>✕</button>
          </div>
        </div>

        {/* Messages */}
        <div className="chatbot-messages">
          {messages.map((msg, i) => (
            <div key={i} className={`chatbot-msg ${msg.from}`}>
              {msg.from === 'bot' && <div className="chatbot-msg-avatar">🤖</div>}
              <div className="chatbot-bubble">{msg.text}</div>
            </div>
          ))}
          {isLoading && (
            <div className="chatbot-msg bot">
              <div className="chatbot-msg-avatar">🤖</div>
              <div className="chatbot-bubble typing">
                <span></span><span></span><span></span>
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>

        {/* Quick Replies */}
        {messages.length <= 1 && !sessionBlocked && (
          <div className="chatbot-quick">
            {quickReplies.map((q) => (
              <button key={q} className="chatbot-quick-btn"
                onClick={() => sendMessage(q)}>{q}</button>
            ))}
          </div>
        )}

        {/* Input */}
        <div className="chatbot-input-row">
          <input
            ref={inputRef}
            type="text"
            placeholder={
              sessionBlocked ? 'Sesi berakhir — muat ulang halaman'
              : isThrottled ? `Tunggu ${cooldownLeft}d...`
              : 'Ketik pertanyaan Anda...'
            }
            value={input}
            onChange={(e) => setInput(e.target.value.slice(0, 500))}
            onKeyDown={handleKeyDown}
            className="chatbot-input"
            disabled={sessionBlocked}
            maxLength={500}
          />
          <button
            className="chatbot-send"
            onClick={() => sendMessage()}
            disabled={!canSend}
            title={isThrottled ? `Tunggu ${cooldownLeft} detik` : 'Kirim pesan'}
          >
            {isThrottled ? cooldownLeft : '➤'}
          </button>
        </div>

        {/* Rate limit hint */}
        <div className="chatbot-hint">
          🔒 Maks 5 pesan/menit · {MAX_MESSAGES_PER_SESSION} pesan/sesi
        </div>
      </div>

      {/* ── FAB ─────────────────────────────────────────────────────────── */}
      <button
        className={`chatbot-fab ${isOpen ? 'open' : ''}`}
        onClick={() => setIsOpen(prev => !prev)}
        title="Tanya NFM Assistant"
      >
        <span className="chatbot-fab-icon">{isOpen ? '✕' : '💬'}</span>
        {!isOpen && <span className="chatbot-fab-badge">1</span>}
      </button>

      <style>{`
        /* ─── FAB ─────────────────────────────────────────────── */
        .chatbot-fab {
          position: fixed;
          bottom: 2rem;
          right: 2rem;
          width: 60px;
          height: 60px;
          border-radius: 50%;
          background: var(--primary);
          color: white;
          border: none;
          cursor: pointer;
          box-shadow: 0 8px 24px rgba(37,99,235,0.4);
          z-index: 9999;
          transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
          display: flex;
          align-items: center;
          justify-content: center;
        }
        .chatbot-fab:hover { transform: scale(1.12); box-shadow: 0 12px 32px rgba(37,99,235,0.5); }
        .chatbot-fab.open { background: #374151; }
        .chatbot-fab-icon { font-size: 1.4rem; line-height: 1; }
        .chatbot-fab-badge {
          position: absolute;
          top: -4px;
          right: -4px;
          background: #ef4444;
          color: white;
          border-radius: 50%;
          width: 20px;
          height: 20px;
          font-size: 11px;
          font-weight: 700;
          display: flex;
          align-items: center;
          justify-content: center;
          border: 2px solid var(--background);
          animation: badgePulse 2s ease-in-out infinite;
        }
        @keyframes badgePulse {
          0%, 100% { transform: scale(1); }
          50% { transform: scale(1.2); }
        }

        /* ─── Window ──────────────────────────────────────────── */
        .chatbot-window {
          position: fixed;
          bottom: 6rem;
          right: 2rem;
          width: 380px;
          height: 580px;
          border-radius: 20px;
          overflow: hidden;
          display: flex;
          flex-direction: column;
          box-shadow: 0 24px 60px rgba(0,0,0,0.25);
          border: 1px solid rgba(255,255,255,0.1);
          background: #0f172a;
          z-index: 9998;
          transform: scale(0.8) translateY(40px);
          opacity: 0;
          pointer-events: none;
          transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
          transform-origin: bottom right;
        }
        .chatbot-window.open {
          transform: scale(1) translateY(0);
          opacity: 1;
          pointer-events: all;
        }

        /* ─── Header ──────────────────────────────────────────── */
        .chatbot-header {
          display: flex;
          align-items: center;
          gap: 12px;
          padding: 14px 16px;
          background: linear-gradient(135deg, var(--primary), #3b82f6);
          flex-shrink: 0;
        }
        .chatbot-avatar { font-size: 1.8rem; }
        .chatbot-header-info { flex: 1; }
        .chatbot-name { font-weight: 700; color: white; font-size: 0.95rem; }
        .chatbot-status { font-size: 0.75rem; color: #86efac; }
        .chatbot-header-actions { display: flex; align-items: center; gap: 8px; }
        .session-counter {
          background: rgba(255,255,255,0.2);
          color: white;
          border-radius: 50px;
          padding: 2px 8px;
          font-size: 0.75rem;
          font-weight: 700;
          font-family: monospace;
          title: "Pesan tersisa";
        }
        .chatbot-close {
          background: rgba(255,255,255,0.15);
          border: none;
          color: white;
          width: 28px;
          height: 28px;
          border-radius: 50%;
          cursor: pointer;
          font-size: 0.85rem;
          transition: background 0.2s;
        }
        .chatbot-close:hover { background: rgba(255,255,255,0.3); }

        /* ─── Messages ────────────────────────────────────────── */
        .chatbot-messages {
          flex: 1;
          overflow-y: auto;
          padding: 16px;
          display: flex;
          flex-direction: column;
          gap: 12px;
          background: #0f172a;
          scrollbar-width: thin;
          scrollbar-color: rgba(255,255,255,0.1) transparent;
        }
        .chatbot-msg { display: flex; align-items: flex-end; gap: 8px; }
        .chatbot-msg.user { flex-direction: row-reverse; }
        .chatbot-msg-avatar { font-size: 1.2rem; flex-shrink: 0; }
        .chatbot-bubble {
          max-width: 80%;
          padding: 10px 14px;
          border-radius: 16px;
          font-size: 0.875rem;
          line-height: 1.5;
          white-space: pre-wrap;
          word-break: break-word;
        }
        .chatbot-msg.bot .chatbot-bubble {
          background: #1e293b;
          color: #e2e8f0;
          border-bottom-left-radius: 4px;
        }
        .chatbot-msg.user .chatbot-bubble {
          background: var(--primary);
          color: white;
          border-bottom-right-radius: 4px;
        }

        /* ─── Typing ──────────────────────────────────────────── */
        .typing { display: flex; gap: 5px; padding: 14px 18px; align-items: center; }
        .typing span {
          width: 7px; height: 7px; border-radius: 50%;
          background: #60a5fa;
          animation: typingBounce 1.2s ease-in-out infinite;
        }
        .typing span:nth-child(2) { animation-delay: 0.2s; }
        .typing span:nth-child(3) { animation-delay: 0.4s; }
        @keyframes typingBounce {
          0%, 100% { transform: translateY(0); opacity: 0.4; }
          50% { transform: translateY(-6px); opacity: 1; }
        }

        /* ─── Quick Replies ───────────────────────────────────── */
        .chatbot-quick { padding: 0 16px 12px; display: flex; flex-wrap: wrap; gap: 8px; background: #0f172a; }
        .chatbot-quick-btn {
          background: rgba(37,99,235,0.15);
          color: #60a5fa;
          border: 1px solid rgba(37,99,235,0.3);
          border-radius: 50px;
          padding: 6px 14px;
          font-size: 0.78rem;
          cursor: pointer;
          transition: all 0.2s;
          font-family: inherit;
        }
        .chatbot-quick-btn:hover { background: rgba(37,99,235,0.3); transform: translateY(-1px); }

        /* ─── Input ───────────────────────────────────────────── */
        .chatbot-input-row {
          display: flex;
          gap: 8px;
          padding: 12px 16px 8px;
          background: #1e293b;
          border-top: 1px solid rgba(255,255,255,0.08);
          flex-shrink: 0;
        }
        .chatbot-input {
          flex: 1;
          background: #0f172a;
          border: 1px solid rgba(255,255,255,0.1);
          border-radius: 12px;
          padding: 10px 14px;
          color: #e2e8f0;
          font-family: inherit;
          font-size: 0.875rem;
          outline: none;
          transition: border-color 0.2s;
        }
        .chatbot-input:focus { border-color: var(--primary); }
        .chatbot-input::placeholder { color: #475569; }
        .chatbot-input:disabled { opacity: 0.5; cursor: not-allowed; }
        .chatbot-send {
          background: var(--primary);
          color: white;
          border: none;
          border-radius: 12px;
          width: 44px;
          cursor: pointer;
          font-size: 1rem;
          font-weight: 700;
          transition: all 0.2s;
          flex-shrink: 0;
        }
        .chatbot-send:hover:not(:disabled) { background: var(--primary-hover); transform: scale(1.05); }
        .chatbot-send:disabled { opacity: 0.4; cursor: not-allowed; }

        /* ─── Hint bar ────────────────────────────────────────── */
        .chatbot-hint {
          padding: 6px 16px;
          font-size: 0.7rem;
          color: #475569;
          background: #1e293b;
          text-align: center;
          flex-shrink: 0;
        }

        @media (max-width: 480px) {
          .chatbot-window { width: calc(100vw - 2rem); right: 1rem; bottom: 5rem; height: 70vh; }
          .chatbot-fab { bottom: 1rem; right: 1rem; }
        }
      `}</style>
    </>
  );
};

export default ChatbotWidget;

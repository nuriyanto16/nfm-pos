import React from 'react';

const Hero = () => {
  return (
    <section className="hero gradient-bg">
      <div className="container hero-content animate-fade-in">
        <div className="hero-text">
          <span className="badge">✨ Solusi Bisnis No. 1</span>
          <h1>Kelola Bisnis Lebih Mudah dengan <span className="gradient-text">NFM POS</span></h1>
          <p>Solusi kasir pintar yang fleksibel untuk skala apa pun. Mulai dari satu gerai UMKM hingga ratusan cabang jaringan Franchise, kami siap mendukung operasional Anda.</p>
          <div className="hero-actions">
            <a href="/#trial" className="btn-hero-primary">Mulai Trial Gratis</a>
            <a href="/#features" className="btn-hero-secondary">Lihat Demo</a>
          </div>
          <div className="hero-stats">
            <div className="stat-divider"></div>
            <div className="stat-item">
              <strong>99.9%</strong>
              <span>Uptime Server</span>
            </div>
          </div>
        </div>
        <div className="hero-image">
          <div className="image-frame">
            <div className="browser-chrome">
              <span className="chrome-dot"></span>
              <span className="chrome-dot"></span>
              <span className="chrome-dot"></span>
            </div>
            <img
              src="/pos-preview.png"
              alt="NFM POS Dashboard - Tampilan Sistem Kasir"
              className="pos-screenshot"
            />
          </div>
          <div className="image-glow"></div>
          <div className="floating-badge badge-orders">
            <span>🛒</span> 24 Pesanan Aktif
          </div>
          <div className="floating-badge badge-revenue">
            <span>📈</span> Rp 3.2jt Hari Ini
          </div>
        </div>
      </div>
      <style>{`
        .hero { padding: 10rem 0 6rem; min-height: 90vh; display: flex; align-items: center; }
        .hero-content {
          display: grid;
          grid-template-columns: 1.2fr 1fr;
          gap: 4rem;
          align-items: center;
        }
        .badge {
          display: inline-block;
          padding: 0.5rem 1rem;
          background: rgba(37, 99, 235, 0.1);
          color: var(--primary);
          border-radius: 50px;
          font-size: 0.875rem;
          font-weight: 600;
          margin-bottom: 1.5rem;
        }
        .hero-text h1 { font-size: 4rem; margin-bottom: 1.5rem; line-height: 1.1; }
        .hero-text p { font-size: 1.25rem; color: var(--muted-foreground); margin-bottom: 2.5rem; max-width: 600px; }
        .hero-actions { display: flex; gap: 1rem; margin-bottom: 3rem; }
        .btn-hero-primary {
          background: var(--primary); color: white;
          padding: 1rem 2rem; border-radius: 12px;
          font-weight: 700; font-size: 1.1rem;
          box-shadow: 0 10px 20px rgba(37, 99, 235, 0.2);
          transition: all 0.3s ease;
        }
        .btn-hero-primary:hover { transform: translateY(-3px); box-shadow: 0 15px 30px rgba(37, 99, 235, 0.3); }
        .btn-hero-secondary {
          background: var(--muted); color: var(--foreground);
          padding: 1rem 2rem; border-radius: 12px;
          font-weight: 700; font-size: 1.1rem;
          transition: all 0.3s ease;
        }
        .btn-hero-secondary:hover { background: var(--border); }
        .hero-stats { display: flex; align-items: center; gap: 2rem; }
        .stat-item { display: flex; flex-direction: column; }
        .stat-item strong { font-size: 1.5rem; color: var(--foreground); }
        .stat-item span { font-size: 0.875rem; color: var(--muted-foreground); }
        .stat-divider { width: 1px; height: 30px; background: var(--border); }

        /* ─── Hero Image ─────────────────────────────── */
        .hero-image {
          position: relative;
          animation: floatUp 6s ease-in-out infinite;
        }
        @keyframes floatUp {
          0%, 100% { transform: translateY(0px); }
          50% { transform: translateY(-12px); }
        }
        .image-frame {
          border-radius: 16px;
          overflow: hidden;
          box-shadow: 0 30px 80px rgba(0,0,0,0.35), 0 0 0 1px rgba(255,255,255,0.07);
          background: #1a1a2e;
          transform: perspective(1000px) rotateY(-4deg) rotateX(2deg);
          transition: transform 0.5s ease;
        }
        .image-frame:hover {
          transform: perspective(1000px) rotateY(0deg) rotateX(0deg);
        }
        .browser-chrome {
          display: flex;
          align-items: center;
          gap: 6px;
          padding: 10px 14px;
          background: #111827;
          border-bottom: 1px solid rgba(255,255,255,0.08);
        }
        .chrome-dot {
          width: 10px; height: 10px;
          border-radius: 50%;
          background: rgba(255,255,255,0.15);
        }
        .chrome-dot:nth-child(1) { background: #ff5f57; }
        .chrome-dot:nth-child(2) { background: #febc2e; }
        .chrome-dot:nth-child(3) { background: #28c840; }
        .pos-screenshot {
          width: 100%;
          display: block;
          object-fit: cover;
        }
        .image-glow {
          position: absolute;
          inset: -20px;
          background: radial-gradient(ellipse at center, rgba(37,99,235,0.15) 0%, transparent 70%);
          border-radius: 40px;
          z-index: -1;
          pointer-events: none;
        }

        /* ─── Floating Badges ────────────────────────── */
        .floating-badge {
          position: absolute;
          background: rgba(255,255,255,0.08);
          backdrop-filter: blur(12px);
          border: 1px solid rgba(255,255,255,0.15);
          border-radius: 50px;
          padding: 0.5rem 1rem;
          font-size: 0.8rem;
          font-weight: 700;
          color: white;
          white-space: nowrap;
          box-shadow: 0 8px 24px rgba(0,0,0,0.2);
          animation: badgePop 0.6s ease forwards;
        }
        .badge-orders { bottom: -16px; left: -12px; animation-delay: 0.5s; opacity: 0; }
        .badge-revenue { top: -16px; right: -12px; animation-delay: 0.8s; opacity: 0; }
        @keyframes badgePop {
          to { opacity: 1; transform: scale(1); }
          from { transform: scale(0.8); opacity: 0; }
        }

        @media (max-width: 1024px) {
          .hero-content { grid-template-columns: 1fr; text-align: center; }
          .hero-text h1 { font-size: 3rem; }
          .hero-text p { margin-inline: auto; }
          .hero-actions { justify-content: center; }
          .hero-stats { justify-content: center; }
          .image-frame { transform: none; }
          .badge-orders { bottom: -12px; left: 8px; }
          .badge-revenue { top: -12px; right: 8px; }
        }
      `}</style>
    </section>
  );
};

export default Hero;

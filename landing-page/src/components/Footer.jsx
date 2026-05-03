import React from 'react';

const Footer = () => {
  return (
    <footer className="footer">
      <div className="container">
        <div className="footer-grid">
          <div className="footer-brand">
            <div className="logo">
              <span className="logo-icon">🚀</span>
              <span className="logo-text">NFM<span className="gradient-text">POS</span></span>
            </div>
            <p>Solusi manajemen bisnis terpercaya dari UMKM hingga jaringan Franchise di seluruh Indonesia.</p>
          </div>
          <div className="footer-links">
            <h4>Produk</h4>
            <a href="#features">Fitur</a>
            <a href="#pricing">Harga</a>
            <a href="#trial">Trial</a>
          </div>
          <div className="footer-links">
            <h4>Perusahaan</h4>
            <a href="/tentang-kami">Tentang Kami</a>
            <a href="/blog">Blog</a>
          </div>
          <div className="footer-links">
            <h4>Dukungan</h4>
            <a href="/pusat-bantuan">Pusat Bantuan</a>
            <a href="/kontak">Kontak</a>
            <a href="/kebijakan-privasi">Kebijakan Privasi</a>
          </div>
        </div>
        <div className="footer-bottom">
          <p>&copy; 2026 NFM POS. All rights reserved.</p>
        </div>
      </div>
      <style>{`
        .footer {
          background: var(--muted);
          padding: 6rem 0 3rem;
          margin-top: 4rem;
        }
        .footer-grid {
          display: grid;
          grid-template-columns: 2fr repeat(3, 1fr);
          gap: 4rem;
          margin-bottom: 4rem;
        }
        .footer-brand p {
          margin-top: 1.5rem;
          color: var(--muted-foreground);
          max-width: 300px;
        }
        .footer-links {
          display: flex;
          flex-direction: column;
          gap: 1rem;
        }
        .footer-links h4 {
          margin-bottom: 0.5rem;
          font-size: 1.1rem;
        }
        .footer-links a {
          color: var(--muted-foreground);
          transition: color 0.3s ease;
        }
        .footer-links a:hover {
          color: var(--primary);
        }
        .footer-bottom {
          padding-top: 2rem;
          border-top: 1px solid var(--border);
          text-align: center;
          color: var(--muted-foreground);
          font-size: 0.875rem;
        }

        @media (max-width: 768px) {
          .footer-grid {
            grid-template-columns: 1fr 1fr;
            gap: 2rem;
          }
          .footer-brand {
            grid-column: span 2;
          }
        }
      `}</style>
    </footer>
  );
};

export default Footer;

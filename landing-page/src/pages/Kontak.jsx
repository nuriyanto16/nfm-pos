import React, { useState } from 'react';
import PageLayout from './PageLayout';

const Kontak = () => {
  const [sent, setSent] = useState(false);

  return (
    <PageLayout
      title="Hubungi Kami"
      subtitle="Ada pertanyaan atau ingin berdiskusi? Kami siap mendengar Anda."
    >
      <div className="kontak-grid">
        <div className="kontak-info">
          <h2>Cara Menghubungi</h2>
          <div className="kontak-channels">
            {[
              { icon: '💬', title: 'WhatsApp', desc: '+62 812-3456-7890', sub: 'Respon dalam < 5 menit (jam kerja)', href: 'https://wa.me/628123456789' },
              { icon: '📧', title: 'Email', desc: 'hello@nfmpos.id', sub: 'Balasan dalam 1×24 jam', href: 'mailto:hello@nfmpos.id' },
              { icon: '📍', title: 'Kantor', desc: 'Jakarta, Indonesia', sub: 'Senin – Jumat, 09.00 – 17.00 WIB', href: null },
            ].map((c) => (
              <div key={c.title} className="channel-card glass">
                <span className="channel-icon">{c.icon}</span>
                <div>
                  <h4>{c.title}</h4>
                  {c.href ? (
                    <a href={c.href} target="_blank" rel="noreferrer">{c.desc}</a>
                  ) : (
                    <p className="channel-desc">{c.desc}</p>
                  )}
                  <small>{c.sub}</small>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="kontak-form-wrapper glass">
          {sent ? (
            <div className="form-success">
              <div style={{ fontSize: '3rem' }}>✅</div>
              <h3>Pesan Terkirim!</h3>
              <p>Terima kasih telah menghubungi kami. Tim kami akan segera membalas pesan Anda.</p>
              <button onClick={() => setSent(false)} className="btn-send">Kirim Pesan Lain</button>
            </div>
          ) : (
            <form className="kontak-form" onSubmit={(e) => { e.preventDefault(); setSent(true); }}>
              <h2>Kirim Pesan</h2>
              <div className="form-row">
                <div className="form-group">
                  <label>Nama Lengkap</label>
                  <input type="text" placeholder="Nama Anda" required />
                </div>
                <div className="form-group">
                  <label>Email</label>
                  <input type="email" placeholder="email@bisnis.com" required />
                </div>
              </div>
              <div className="form-group">
                <label>Subjek</label>
                <select required>
                  <option value="">Pilih topik...</option>
                  <option>Informasi Paket & Harga</option>
                  <option>Pertanyaan Teknis</option>
                  <option>Kerjasama Bisnis</option>
                  <option>Lainnya</option>
                </select>
              </div>
              <div className="form-group">
                <label>Pesan</label>
                <textarea placeholder="Tulis pesan Anda di sini..." rows={5} required />
              </div>
              <button type="submit" className="btn-send">Kirim Pesan 🚀</button>
            </form>
          )}
        </div>
      </div>
      <style>{`
        .kontak-grid { display: grid; grid-template-columns: 1fr 1.5fr; gap: 4rem; align-items: start; }
        .kontak-info h2 { font-size: 1.8rem; font-weight: 800; margin-bottom: 2rem; }
        .kontak-channels { display: flex; flex-direction: column; gap: 1.5rem; }
        .channel-card {
          display: flex;
          align-items: flex-start;
          gap: 1.25rem;
          padding: 1.5rem;
          border-radius: 16px;
          border: 1px solid var(--border);
        }
        .channel-icon { font-size: 2rem; flex-shrink: 0; }
        .channel-card h4 { font-size: 1rem; font-weight: 700; margin-bottom: 0.25rem; }
        .channel-card a { color: var(--primary); font-weight: 600; text-decoration: none; }
        .channel-card a:hover { text-decoration: underline; }
        .channel-desc { font-weight: 600; margin-bottom: 0.1rem; }
        .channel-card small { color: var(--muted-foreground); font-size: 0.8rem; }
        .kontak-form-wrapper {
          padding: 2.5rem;
          border-radius: 24px;
          border: 1px solid var(--border);
        }
        .kontak-form h2 { font-size: 1.6rem; font-weight: 800; margin-bottom: 1.5rem; }
        .form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
        .form-group { display: flex; flex-direction: column; gap: 0.5rem; margin-bottom: 1.25rem; }
        .form-group label { font-size: 0.875rem; font-weight: 600; color: var(--muted-foreground); }
        .form-group input,
        .form-group select,
        .form-group textarea {
          padding: 0.875rem;
          border-radius: 12px;
          border: 1px solid var(--border);
          background: var(--background);
          color: var(--foreground);
          font-family: inherit;
          font-size: 1rem;
          transition: border-color 0.3s;
        }
        .form-group input:focus,
        .form-group select:focus,
        .form-group textarea:focus {
          outline: none;
          border-color: var(--primary);
        }
        .btn-send {
          width: 100%;
          background: var(--primary);
          color: white;
          padding: 1rem;
          border-radius: 12px;
          font-weight: 700;
          font-size: 1.05rem;
          transition: all 0.3s;
        }
        .btn-send:hover { transform: translateY(-2px); box-shadow: 0 10px 20px rgba(37,99,235,0.2); }
        .form-success {
          text-align: center;
          padding: 3rem 2rem;
          display: flex;
          flex-direction: column;
          align-items: center;
          gap: 1rem;
        }
        .form-success h3 { font-size: 1.75rem; font-weight: 800; }
        .form-success p { color: var(--muted-foreground); max-width: 320px; }
        @media (max-width: 900px) {
          .kontak-grid { grid-template-columns: 1fr; }
          .form-row { grid-template-columns: 1fr; }
        }
      `}</style>
    </PageLayout>
  );
};

export default Kontak;

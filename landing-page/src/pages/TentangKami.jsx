import React from 'react';
import PageLayout from './PageLayout';

const TentangKami = () => (
  <PageLayout
    title="Tentang NFM POS"
    subtitle="Kami hadir untuk memudahkan setiap pelaku bisnis Indonesia dalam mengelola operasional mereka."
  >
    <div className="about-content">
      <section className="about-section">
        <div className="about-grid">
          <div className="about-text">
            <h2>Siapa Kami?</h2>
            <p>
              NFM POS adalah platform manajemen bisnis berbasis cloud yang dirancang khusus untuk memenuhi
              kebutuhan pelaku usaha Indonesia — mulai dari warung sederhana, kafe, restoran, hingga jaringan
              franchise dengan ratusan cabang.
            </p>
            <p>
              Kami percaya bahwa setiap bisnis, besar maupun kecil, berhak mendapatkan sistem yang andal,
              mudah digunakan, dan terjangkau.
            </p>
          </div>
          <div className="about-stats-grid">
            {[
              { number: '500+', label: 'Bisnis Aktif' },
              { number: '50+', label: 'Kota di Indonesia' },
              { number: '99.9%', label: 'Uptime Server' },
              { number: '24/7', label: 'Dukungan Tim' },
            ].map((s) => (
              <div key={s.label} className="stat-box">
                <strong>{s.number}</strong>
                <span>{s.label}</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="about-section">
        <h2>Visi & Misi</h2>
        <div className="vision-grid">
          <div className="vision-card glass">
            <div className="vision-icon">🎯</div>
            <h3>Visi</h3>
            <p>Menjadi platform manajemen bisnis terpercaya nomor 1 di Indonesia yang mendukung pertumbuhan UMKM dan Franchise secara berkelanjutan.</p>
          </div>
          <div className="vision-card glass">
            <div className="vision-icon">🚀</div>
            <h3>Misi</h3>
            <ul>
              <li>Menyediakan teknologi POS yang mudah diakses dan digunakan oleh semua kalangan.</li>
              <li>Terus berinovasi menghadirkan fitur yang relevan dengan kebutuhan pasar Indonesia.</li>
              <li>Memberikan layanan pelanggan terbaik dan responsif 24 jam sehari.</li>
            </ul>
          </div>
        </div>
      </section>

      <section className="about-section">
        <h2>Nilai Kami</h2>
        <div className="values-grid">
          {[
            { icon: '💡', title: 'Inovasi', desc: 'Kami selalu mencari cara baru untuk memberikan solusi terbaik.' },
            { icon: '🤝', title: 'Kepercayaan', desc: 'Transparansi dan integritas adalah fondasi hubungan kami dengan pelanggan.' },
            { icon: '⚡', title: 'Kecepatan', desc: 'Sistem kami dirancang untuk performa tinggi tanpa kompromi.' },
            { icon: '🌱', title: 'Pertumbuhan', desc: 'Kami tumbuh bersama bisnis Anda, dari kecil hingga berskala nasional.' },
          ].map((v) => (
            <div key={v.title} className="value-card glass">
              <div className="value-icon">{v.icon}</div>
              <h4>{v.title}</h4>
              <p>{v.desc}</p>
            </div>
          ))}
        </div>
      </section>
    </div>
    <style>{`
      .about-section { margin-bottom: 5rem; }
      .about-section h2 { font-size: 2rem; font-weight: 800; margin-bottom: 2rem; }
      .about-grid { display: grid; grid-template-columns: 1.2fr 1fr; gap: 4rem; align-items: center; }
      .about-text p { color: var(--muted-foreground); line-height: 1.8; margin-bottom: 1.2rem; font-size: 1.05rem; }
      .about-stats-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; }
      .stat-box {
        background: var(--muted);
        border-radius: 16px;
        padding: 2rem;
        text-align: center;
        border: 1px solid var(--border);
      }
      .stat-box strong { display: block; font-size: 2rem; font-weight: 900; color: var(--primary); }
      .stat-box span { font-size: 0.9rem; color: var(--muted-foreground); }
      .vision-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 2rem; }
      .vision-card { padding: 2.5rem; border-radius: 20px; }
      .vision-icon { font-size: 2.5rem; margin-bottom: 1rem; }
      .vision-card h3 { font-size: 1.4rem; margin-bottom: 1rem; }
      .vision-card p, .vision-card li { color: var(--muted-foreground); line-height: 1.7; }
      .vision-card ul { padding-left: 1.2rem; display: flex; flex-direction: column; gap: 0.5rem; }
      .values-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 1.5rem; }
      .value-card { padding: 2rem; border-radius: 16px; text-align: center; }
      .value-icon { font-size: 2rem; margin-bottom: 1rem; }
      .value-card h4 { font-size: 1.1rem; margin-bottom: 0.5rem; }
      .value-card p { color: var(--muted-foreground); font-size: 0.9rem; line-height: 1.6; }
      @media (max-width: 768px) {
        .about-grid, .vision-grid { grid-template-columns: 1fr; }
        .values-grid { grid-template-columns: 1fr 1fr; }
        .about-stats-grid { grid-template-columns: 1fr 1fr; }
      }
    `}</style>
  </PageLayout>
);

export default TentangKami;

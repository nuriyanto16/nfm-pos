import React from 'react';
import PageLayout from './PageLayout';

const faqs = [
  { q: 'Bagaimana cara memulai trial gratis?', a: 'Klik tombol "Daftar Trial Gratis" di halaman utama, isi formulir pendaftaran, dan tim kami akan menghubungi Anda dalam 1×24 jam untuk proses aktivasi.' },
  { q: 'Apakah data saya aman?', a: 'Ya. Seluruh data disimpan dengan enkripsi AES-256 di server ber-sertifikat ISO 27001. Kami tidak pernah menjual atau membagikan data Anda ke pihak ketiga.' },
  { q: 'Berapa banyak perangkat yang bisa digunakan?', a: 'Tergantung paket yang dipilih. Paket UMKM mendukung 1 perangkat, Bisnis 3 perangkat, dan Franchise tidak terbatas.' },
  { q: 'Apakah bisa digunakan secara offline?', a: 'NFM POS memiliki mode offline. Transaksi tetap berjalan dan data akan disinkronkan otomatis saat koneksi internet kembali.' },
  { q: 'Bagaimana jika saya memiliki lebih dari satu cabang?', a: 'Paket Bisnis mendukung 2 cabang dan Franchise mendukung cabang tidak terbatas, lengkap dengan dashboard monitoring terpusat.' },
  { q: 'Apakah ada biaya instalasi atau setup?', a: 'Tidak ada biaya instalasi. Proses onboarding dilakukan oleh tim kami secara gratis, termasuk pelatihan penggunaan sistem untuk karyawan Anda.' },
];

const PusatBantuan = () => (
  <PageLayout
    title="Pusat Bantuan"
    subtitle="Temukan jawaban atas pertanyaan Anda. Kami siap membantu."
  >
    <div className="help-content">
      <div className="help-search-box glass">
        <span>🔍</span>
        <input type="text" placeholder="Cari topik bantuan..." readOnly />
      </div>

      <div className="help-categories">
        {[
          { icon: '🚀', title: 'Memulai', desc: 'Panduan setup awal dan onboarding' },
          { icon: '💳', title: 'Pembayaran', desc: 'Metode pembayaran dan tagihan' },
          { icon: '📊', title: 'Laporan', desc: 'Cara membaca dan mengekspor laporan' },
          { icon: '🔧', title: 'Teknis', desc: 'Troubleshooting dan pengaturan' },
        ].map((c) => (
          <div key={c.title} className="help-cat glass">
            <div className="help-cat-icon">{c.icon}</div>
            <h4>{c.title}</h4>
            <p>{c.desc}</p>
          </div>
        ))}
      </div>

      <div className="faq-section">
        <h2>Pertanyaan yang Sering Diajukan</h2>
        <div className="faq-list">
          {faqs.map((faq, i) => (
            <details key={i} className="faq-item glass">
              <summary>{faq.q}</summary>
              <p>{faq.a}</p>
            </details>
          ))}
        </div>
      </div>

      <div className="help-contact glass">
        <div className="help-contact-icon">💬</div>
        <h3>Masih Ada Pertanyaan?</h3>
        <p>Tim support kami siap membantu Anda 24/7</p>
        <div className="help-contact-actions">
          <a href="/kontak" className="btn-contact-primary">Hubungi Kami</a>
          <a href="https://wa.me/628123456789" target="_blank" rel="noreferrer" className="btn-contact-wa">
            💬 WhatsApp
          </a>
        </div>
      </div>
    </div>
    <style>{`
      .help-content { display: flex; flex-direction: column; gap: 4rem; }
      .help-search-box {
        display: flex;
        align-items: center;
        gap: 1rem;
        padding: 1.25rem 2rem;
        border-radius: 16px;
        font-size: 1.2rem;
        border: 1px solid var(--border);
      }
      .help-search-box input {
        flex: 1;
        background: none;
        border: none;
        outline: none;
        font-size: 1rem;
        color: var(--foreground);
        font-family: inherit;
      }
      .help-categories { display: grid; grid-template-columns: repeat(4, 1fr); gap: 1.5rem; }
      .help-cat {
        padding: 2rem;
        border-radius: 16px;
        text-align: center;
        cursor: pointer;
        border: 1px solid var(--border);
        transition: transform 0.3s, box-shadow 0.3s;
      }
      .help-cat:hover { transform: translateY(-4px); box-shadow: 0 12px 30px rgba(0,0,0,0.1); }
      .help-cat-icon { font-size: 2.5rem; margin-bottom: 1rem; }
      .help-cat h4 { font-size: 1rem; margin-bottom: 0.5rem; }
      .help-cat p { color: var(--muted-foreground); font-size: 0.85rem; }
      .faq-section h2 { font-size: 2rem; font-weight: 800; margin-bottom: 2rem; }
      .faq-list { display: flex; flex-direction: column; gap: 1rem; }
      .faq-item {
        padding: 1.5rem 2rem;
        border-radius: 14px;
        border: 1px solid var(--border);
        cursor: pointer;
      }
      .faq-item summary {
        font-weight: 700;
        font-size: 1rem;
        cursor: pointer;
        list-style: none;
        display: flex;
        justify-content: space-between;
        align-items: center;
      }
      .faq-item summary::after { content: '+'; font-size: 1.5rem; color: var(--primary); }
      .faq-item[open] summary::after { content: '−'; }
      .faq-item p { color: var(--muted-foreground); margin-top: 1rem; line-height: 1.7; }
      .help-contact {
        text-align: center;
        padding: 3rem;
        border-radius: 24px;
        border: 1px solid var(--border);
      }
      .help-contact-icon { font-size: 3rem; margin-bottom: 1rem; }
      .help-contact h3 { font-size: 1.75rem; font-weight: 800; margin-bottom: 0.5rem; }
      .help-contact p { color: var(--muted-foreground); margin-bottom: 2rem; }
      .help-contact-actions { display: flex; gap: 1rem; justify-content: center; }
      .btn-contact-primary {
        background: var(--primary); color: white;
        padding: 0.875rem 2rem; border-radius: 12px;
        font-weight: 700; text-decoration: none;
        transition: all 0.3s;
      }
      .btn-contact-primary:hover { transform: translateY(-2px); }
      .btn-contact-wa {
        background: #25d366; color: white;
        padding: 0.875rem 2rem; border-radius: 12px;
        font-weight: 700; text-decoration: none;
        transition: all 0.3s;
      }
      .btn-contact-wa:hover { background: #1da851; transform: translateY(-2px); }
      @media (max-width: 768px) { .help-categories { grid-template-columns: 1fr 1fr; } }
    `}</style>
  </PageLayout>
);

export default PusatBantuan;

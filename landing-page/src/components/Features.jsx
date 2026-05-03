import React from 'react';

const Features = () => {
  const features = [
    {
      title: 'Kitchen Display (KDS)',
      description: 'Antrean dapur digital dengan timer aktivitas untuk memastikan pesanan disajikan tepat waktu.',
      icon: '🍳'
    },
    {
      title: 'Manajemen Inventori',
      description: 'Pencatatan barang masuk/keluar otomatis dengan notifikasi stok rendah untuk kelancaran bisnis.',
      icon: '📦'
    },
    {
      title: 'Laporan Keuangan',
      description: 'Jurnal Umum, Buku Besar, dan Laporan Laba Rugi otomatis yang terintegrasi langsung.',
      icon: '📑'
    },
    {
      title: 'Skala Franchise',
      description: 'Monitoring terpusat untuk banyak cabang. Sinkronisasi menu, harga, dan promo di seluruh outlet.',
      icon: '🏢'
    }
  ];

  return (
    <section id="features" className="features">
      <div className="container">
        <div className="section-header">
          <h2>Fitur Pendukung Pertumbuhan Bisnis</h2>
          <p>Satu platform untuk semua skala bisnis. Memudahkan UMKM untuk go-digital dan membantu Franchise menjaga standar operasional.</p>
        </div>
        <div className="features-grid">
          {features.map((f, i) => (
            <div key={i} className="feature-card glass">
              <div className="feature-icon">{f.icon}</div>
              <h3>{f.title}</h3>
              <p>{f.description}</p>
            </div>
          ))}
        </div>
      </div>
      <style>{`
        .features {
          padding: 6rem 0;
        }
        .section-header {
          text-align: center;
          margin-bottom: 4rem;
        }
        .section-header h2 {
          font-size: 2.5rem;
          margin-bottom: 1rem;
        }
        .section-header p {
          color: var(--muted-foreground);
          font-size: 1.1rem;
          max-width: 600px;
          margin: 0 auto;
        }
        .features-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
          gap: 2rem;
        }
        .feature-card {
          padding: 2.5rem;
          border-radius: 20px;
          transition: all 0.3s ease;
        }
        .feature-card:hover {
          transform: translateY(-10px);
          border-color: var(--primary);
          box-shadow: 0 20px 40px rgba(37, 99, 235, 0.1);
        }
        .feature-icon {
          font-size: 2.5rem;
          margin-bottom: 1.5rem;
        }
        .feature-card h3 {
          margin-bottom: 1rem;
          font-size: 1.25rem;
        }
        .feature-card p {
          color: var(--muted-foreground);
          line-height: 1.6;
        }
      `}</style>
    </section>
  );
};

export default Features;

import React from 'react';

const Ecosystem = () => {
  return (
    <section className="ecosystem gradient-bg-reverse">
      <div className="container ecosystem-content">
        <div className="ecosystem-image">
          <img
            src="/smart_restaurant_ecosystem.png"
            alt="NFM POS Integrated Ecosystem"
            className="ecosystem-img"
          />
        </div>
        <div className="ecosystem-text">
          <span className="badge">🌐 Ekosistem Masa Depan</span>
          <h2>Satu Sistem, Hubungkan Seluruh Operasional</h2>
          <p>
            NFM POS dirancang sebagai platform terintegrasi. Mulai dari pemesanan mandiri oleh pelanggan (QR Menu & Self-Service Terminal), transaksi kasir (POS Kasir), manajemen persediaan (Gudang Pusat), pemantauan dapur (KDS & Printer Dapur), hingga pelaporan keuangan (Finance) — semuanya terhubung secara real-time.
          </p>
          <ul className="ecosystem-list">
            <li>
              <strong>✓ Pemesanan Mandiri & Cepat:</strong> Self-Service Terminal (SST) & QR Menu meminimalkan antrean.
            </li>
            <li>
              <strong>✓ Sinkronisasi Dapur Instan:</strong> Printer Dapur & Kitchen Display mempercepat penyajian.
            </li>
            <li>
              <strong>✓ Kontrol Stok Akurat:</strong> Gudang Pusat memantau pergerakan bahan secara otomatis.
            </li>
            <li>
              <strong>✓ Keuangan Terintegrasi:</strong> Pembukuan otomatis langsung dari transaksi kasir.
            </li>
          </ul>
        </div>
      </div>
      <style>{`
        .ecosystem {
          padding: 8rem 0;
          border-top: 1px solid var(--border);
          border-bottom: 1px solid var(--border);
        }
        .ecosystem-content {
          display: grid;
          grid-template-columns: 1.1fr 1fr;
          gap: 5rem;
          align-items: center;
        }
        .ecosystem-image {
          display: flex;
          justify-content: center;
          align-items: center;
        }
        .ecosystem-img {
          max-width: 100%;
          border-radius: 24px;
          box-shadow: 0 20px 50px rgba(0,0,0,0.15);
          border: 1px solid rgba(255,255,255,0.08);
          transition: transform 0.3s ease;
        }
        .ecosystem-img:hover {
          transform: scale(1.02);
        }
        .ecosystem-text h2 {
          font-size: 2.5rem;
          line-height: 1.2;
          margin-bottom: 1.5rem;
        }
        .ecosystem-text p {
          font-size: 1.1rem;
          color: var(--muted-foreground);
          line-height: 1.6;
          margin-bottom: 2rem;
        }
        .ecosystem-list {
          list-style: none;
          padding: 0;
          margin: 0;
        }
        .ecosystem-list li {
          font-size: 1rem;
          margin-bottom: 1rem;
          color: var(--foreground);
        }
        .ecosystem-list strong {
          color: var(--primary);
        }

        @media (max-width: 1024px) {
          .ecosystem-content {
            grid-template-columns: 1fr;
            text-align: center;
            gap: 3rem;
          }
          .ecosystem-image {
            order: 2;
          }
          .ecosystem-text {
            order: 1;
          }
          .ecosystem-list {
            text-align: left;
            max-width: 500px;
            margin: 0 auto;
          }
        }
      `}</style>
    </section>
  );
};

export default Ecosystem;

import React from 'react';

const Pricing = () => {
  const plans = [
    {
      name: 'UMKM',
      price: 'Free',
      period: '14 Hari',
      features: ['Hingga 100 Transaksi', 'Manajemen Stok Dasar', '1 Akun Admin', 'Laporan Harian'],
      recommended: false,
      cta: 'Coba Gratis'
    },
    {
      name: 'Bisnis',
      price: 'Rp 199rb',
      period: 'per bulan',
      features: ['Transaksi Unlimited', 'Manajemen Stok Lanjut', '2 Akun Admin', 'Multi Cabang (2)', 'Support 24/7'],
      recommended: true,
      cta: 'Pilih Paket'
    },
    {
      name: 'Franchise',
      price: 'Custom',
      period: 'per bulan',
      features: ['Semua Fitur Bisnis', 'API Integration', 'Custom Dashboard', 'Cabang Unlimited', 'Dedicated Account Manager'],
      recommended: false,
      cta: 'Hubungi Sales'
    }
  ];

  return (
    <section id="pricing" className="pricing gradient-bg">
      <div className="container">
        <div className="section-header">
          <h2>Paket Harga yang Fleksibel</h2>
          <p>Pilih paket yang sesuai dengan skala bisnis Anda saat ini.</p>
        </div>
        <div className="pricing-grid">
          {plans.map((plan, i) => (
            <div key={i} className={`pricing-card ${plan.recommended ? 'recommended' : 'glass'}`}>
              {plan.recommended && <div className="recommended-badge">Paling Populer</div>}
              <h3>{plan.name}</h3>
              <div className="price">
                <span className="amount">{plan.price}</span>
                <span className="period">/{plan.period}</span>
              </div>
              <ul className="plan-features">
                {plan.features.map((f, j) => (
                  <li key={j}><span className="check">✓</span> {f}</li>
                ))}
              </ul>
              <a href="#trial" className={`btn-plan ${plan.recommended ? 'btn-plan-primary' : 'btn-plan-secondary'}`}>
                {plan.cta}
              </a>
            </div>
          ))}
        </div>
      </div>
      <style>{`
        .pricing {
          padding: 6rem 0;
        }
        .pricing-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
          gap: 2rem;
          margin-top: 3rem;
        }
        .pricing-card {
          padding: 3rem 2.5rem;
          border-radius: 24px;
          text-align: center;
          position: relative;
          transition: transform 0.3s ease;
        }
        .pricing-card:hover {
          transform: scale(1.02);
        }
        .pricing-card.recommended {
          background: var(--primary);
          color: white;
          box-shadow: 0 20px 40px rgba(37, 99, 235, 0.3);
          transform: scale(1.05);
          z-index: 10;
        }
        .recommended-badge {
          position: absolute;
          top: -15px;
          left: 50%;
          transform: translateX(-50%);
          background: var(--accent);
          color: white;
          padding: 0.5rem 1.5rem;
          border-radius: 50px;
          font-size: 0.875rem;
          font-weight: 700;
        }
        .pricing-card h3 {
          font-size: 1.5rem;
          margin-bottom: 1.5rem;
        }
        .price {
          margin-bottom: 2.5rem;
        }
        .price .amount {
          font-size: 3rem;
          font-weight: 800;
        }
        .price .period {
          font-size: 1rem;
          opacity: 0.7;
        }
        .plan-features {
          list-style: none;
          text-align: left;
          margin-bottom: 2.5rem;
        }
        .plan-features li {
          margin-bottom: 1rem;
          font-size: 1rem;
          display: flex;
          gap: 0.75rem;
        }
        .check {
          color: var(--primary);
          font-weight: bold;
        }
        .btn-plan {
          display: block;
          padding: 1rem;
          border-radius: 12px;
          font-weight: 700;
          transition: all 0.3s ease;
        }
        .btn-plan-primary {
          background: var(--primary);
          color: white;
        }
        .btn-plan-primary:hover {
          background: var(--primary-hover);
        }
        .btn-plan-secondary {
          background: var(--muted);
          color: var(--foreground);
        }
        .btn-plan-secondary:hover {
          background: var(--border);
        }
        .pricing-card.recommended .check {
          color: white;
        }
        .pricing-card.recommended .btn-plan-primary {
          background: white;
          color: var(--primary);
        }
        .pricing-card.recommended .btn-plan-primary:hover {
          background: var(--muted);
        }
      `}</style>
    </section>
  );
};

export default Pricing;

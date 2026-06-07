import React, { useState, useEffect, useCallback } from 'react';

// Reads from .env (dev) or .env.production (build) automatically
const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:8080/api';

const validate = (formData) => {
  const errors = {};
  if (!formData.fullName.trim() || formData.fullName.trim().length < 3) {
    errors.fullName = 'Nama lengkap minimal 3 karakter';
  }
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(formData.email)) {
    errors.email = 'Format email tidak valid';
  }
  const digitsOnly = formData.phone.replace(/\D/g, '');
  if (digitsOnly.length < 9 || digitsOnly.length > 15) {
    errors.phone = 'Nomor WhatsApp harus 9-15 digit angka';
  }
  if (!formData.businessName.trim() || formData.businessName.trim().length < 2) {
    errors.businessName = 'Nama bisnis minimal 2 karakter';
  }
  if (!formData.businessCategory) {
    errors.businessCategory = 'Pilih kategori bisnis Anda';
  }
  if (!formData.captcha_value.trim()) {
    errors.captcha_value = 'Kode captcha wajib diisi';
  }
  return errors;
};

const TrialForm = ({ selectedPlan, onSelectPlan }) => {
  const [formData, setFormData] = useState({
    fullName: '',
    email: '',
    phone: '',
    businessName: '',
    businessAddress: '',
    businessCategory: '',
    pos_type: 'resto',
    captcha_id: '',
    captcha_value: '',
  });
  const [fieldErrors, setFieldErrors] = useState({});
  const [captchaImage, setCaptchaImage] = useState('');
  const [submitted, setSubmitted] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isError, setIsError] = useState('');
  const [invoiceId, setInvoiceId] = useState('');

  const planPrices = {
    UMKM: { name: 'UMKM (Free Trial)', priceStr: 'Gratis', numericPrice: 0 },
    Bisnis: { name: 'Bisnis (Berlangganan)', priceStr: 'Rp 149.000', numericPrice: 149000 },
    Franchise: { name: 'Franchise (Enterprise)', priceStr: 'Rp 499.000', numericPrice: 499000 }
  };
  const activePlanDetails = planPrices[selectedPlan] || planPrices.UMKM;

  const loadCaptcha = useCallback(async () => {
    try {
      const res = await fetch(`${API_BASE}/captcha`);
      const data = await res.json();
      setCaptchaImage(data.captcha_image);
      setFormData(prev => ({ ...prev, captcha_id: data.captcha_id, captcha_value: '' }));
    } catch {
      setCaptchaImage('');
    }
  }, []);

  useEffect(() => {
    loadCaptcha();
  }, [loadCaptcha]);

  const handleChange = (field, value) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    if (fieldErrors[field]) {
      setFieldErrors(prev => ({ ...prev, [field]: '' }));
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsError('');
    const errors = validate(formData);
    if (Object.keys(errors).length > 0) {
      setFieldErrors(errors);
      return;
    }

    setIsSubmitting(true);
    try {
      const response = await fetch(`${API_BASE}/registrations`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...formData, plan: selectedPlan }),
      });

      const data = await response.json();
      if (response.ok) {
        setInvoiceId(`INV/${new Date().getFullYear()}${(new Date().getMonth() + 1).toString().padStart(2, '0')}${new Date().getDate().toString().padStart(2, '0')}/NFM/${Math.floor(1000 + Math.random() * 9000)}`);
        setSubmitted(true);
      } else {
        setIsError(data.error || 'Terjadi kesalahan saat mendaftar.');
        loadCaptcha();
      }
    } catch {
      setIsError('Gagal terhubung ke server. Pastikan backend berjalan.');
      loadCaptcha();
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <section id="trial" className="trial">
      <div className="container">
        <div className="trial-wrapper glass">
          {submitted ? (
            selectedPlan !== 'UMKM' ? (
              // PAID PLAN PAYMENT QRIS VIEW
              <div className="payment-message">
                <div className="invoice-header">
                  <div className="success-badge">🎉 PENDAFTARAN BERHASIL!</div>
                  <h2>Invoice Pembayaran Layanan</h2>
                  <p className="invoice-id">No. Invoice: {invoiceId}</p>
                </div>

                <div className="invoice-card">
                  <div className="invoice-row">
                    <span>Nama Bisnis / Toko</span>
                    <strong>{formData.businessName}</strong>
                  </div>
                  <div className="invoice-row">
                    <span>Nama Pelanggan</span>
                    <strong>{formData.fullName}</strong>
                  </div>
                  <div className="invoice-row">
                    <span>Paket NFM POS</span>
                    <strong>{activePlanDetails.name}</strong>
                  </div>
                  <div className="invoice-divider"></div>
                  <div className="invoice-row total-row">
                    <span>Total Tagihan</span>
                    <span className="total-amount">{activePlanDetails.priceStr}</span>
                  </div>
                </div>

                <div className="qris-payment-container glass">
                  <h3>Metode Pembayaran: QRIS</h3>
                  <div className="qris-image-wrapper">
                    <img src="/qris_payment.png" alt="QRIS NFM TECH" className="qris-img-pay" />
                  </div>
                  <div className="qris-instructions">
                    <p><strong>Panduan Scan QRIS:</strong></p>
                    <ol>
                      <li>Buka aplikasi m-banking atau e-wallet (GoPay, OVO, Dana, LinkAja).</li>
                      <li>Pilih tombol <strong>Scan / Bayar</strong>.</li>
                      <li>Pindai barcode QRIS NFM Tech di atas.</li>
                      <li>Masukkan nominal transfer sesuai tagihan secara tepat: <strong>{activePlanDetails.priceStr}</strong>.</li>
                      <li>Setelah transaksi berhasil, simpan bukti bayar Anda.</li>
                    </ol>
                  </div>
                </div>

                <a
                  href={`https://wa.me/62895385996105?text=${encodeURIComponent(
                    `Halo Admin NFM POS, saya sudah melakukan pendaftaran untuk:\n\n` +
                    `- Nama Bisnis: ${formData.businessName}\n` +
                    `- Nama Pelanggan: ${formData.fullName}\n` +
                    `- Paket Pilihan: ${selectedPlan}\n` +
                    `- No Invoice: ${invoiceId}\n` +
                    `- Total Tagihan: ${activePlanDetails.priceStr}\n\n` +
                    `Berikut saya lampirkan bukti pembayaran via QRIS. Mohon bantuannya untuk melakukan aktivasi akun kami 🙏`
                  )}`}
                  target="_blank"
                  rel="noreferrer"
                  className="btn-whatsapp"
                >
                  💬 Konfirmasi Pembayaran via WhatsApp
                </a>
                <button onClick={() => { setSubmitted(false); loadCaptcha(); }} className="btn-back">Kembali ke Beranda</button>
              </div>
            ) : (
              // FREE PLAN TRIAL VIEW
              <div className="success-message">
                <div className="success-icon">🎉</div>
                <h2>Pendaftaran Berhasil!</h2>
                <p>Terima kasih <strong>{formData.fullName}</strong>. Akun trial NFM POS Anda sedang kami siapkan.</p>
                <div className="success-steps">
                  <div className="step">
                    <span className="step-num">1</span>
                    <p>Tim admin kami akan melakukan verifikasi data bisnis Anda.</p>
                  </div>
                  <div className="step">
                    <span className="step-num">2</span>
                    <p>Kredensial login akan dikirimkan melalui WhatsApp/Email.</p>
                  </div>
                </div>
                <a
                  href={`https://wa.me/62895385996105?text=${encodeURIComponent('Halo NFM POS, saya baru saja mendaftar trial untuk ' + formData.businessName + '. Mohon bantuannya untuk aktivasi akun UMKM Free saya 🙏')}`}
                  target="_blank"
                  rel="noreferrer"
                  className="btn-whatsapp"
                >
                  💬 Konfirmasi Cepat via WhatsApp
                </a>
                <button onClick={() => { setSubmitted(false); loadCaptcha(); }} className="btn-back">Kembali ke Beranda</button>
              </div>
            )
          ) : (
            <div className="trial-grid">
              <div className="trial-info">
                <span className="badge">{selectedPlan === 'UMKM' ? 'UMKM Free Version' : `Paket ${selectedPlan}`}</span>
                <h2>Mulai Kelola Bisnis Lebih Profesional</h2>
                <p>Daftarkan bisnis Anda sekarang dan dapatkan akses penuh 14 hari atau pilih paket <strong>Gratis Selamanya</strong> untuk UMKM.</p>
                
                <div className="info-cards">
                  <div className="info-card">
                    <div className="info-icon">🏪</div>
                    <div>
                      <h4>Multi-Outlet Ready</h4>
                      <p>Kelola banyak cabang dalam satu dashboard admin.</p>
                    </div>
                  </div>
                  <div className="info-card">
                    <div className="info-icon">📊</div>
                    <div>
                      <h4>Laporan Real-time</h4>
                      <p>Pantau penjualan dan stok kapan saja di mana saja.</p>
                    </div>
                  </div>
                </div>

                <div className="trust-badges">
                  <span>🔒 Secure Data</span>
                  <span>⚡ Cloud Integration</span>
                  <span>🛠️ 24/7 Support</span>
                </div>
              </div>

              <form className="trial-form" onSubmit={handleSubmit} noValidate>
                <h3>Lengkapi Data Bisnis</h3>
                
                <div className="plan-selection-indicator">
                  <span>Paket Pilihan:</span>
                  <select 
                    value={selectedPlan} 
                    onChange={(e) => onSelectPlan && onSelectPlan(e.target.value)}
                    className="plan-select-dropdown"
                  >
                    <option value="UMKM">UMKM (Free Trial 14 Hari)</option>
                    <option value="Bisnis">Bisnis (Rp 149.000 / Bulan)</option>
                    <option value="Franchise">Franchise (Rp 499.000 / Bulan)</option>
                  </select>
                </div>

                <div className="form-row">
                  <div className="form-group">
                    <label>Nama Lengkap *</label>
                    <input
                      type="text"
                      placeholder="Nama Anda"
                      value={formData.fullName}
                      onChange={(e) => handleChange('fullName', e.target.value)}
                      className={fieldErrors.fullName ? 'input-error' : ''}
                    />
                    {fieldErrors.fullName && <span className="field-error">{fieldErrors.fullName}</span>}
                  </div>
                  <div className="form-group">
                    <label>Nomor WhatsApp *</label>
                    <input
                      type="tel"
                      placeholder="0812345678"
                      value={formData.phone}
                      onChange={(e) => handleChange('phone', e.target.value.replace(/[^0-9+\-\s]/g, ''))}
                      className={fieldErrors.phone ? 'input-error' : ''}
                      maxLength={16}
                    />
                    {fieldErrors.phone && <span className="field-error">{fieldErrors.phone}</span>}
                  </div>
                </div>

                <div className="form-group">
                  <label>Email Bisnis *</label>
                  <input
                    type="email"
                    placeholder="email@bisnis.com"
                    value={formData.email}
                    onChange={(e) => handleChange('email', e.target.value)}
                    className={fieldErrors.email ? 'input-error' : ''}
                  />
                  {fieldErrors.email && <span className="field-error">{fieldErrors.email}</span>}
                </div>

                <div className="form-row">
                  <div className="form-group">
                    <label>Nama Bisnis / Toko *</label>
                    <input
                      type="text"
                      placeholder="Nama Bisnis"
                      value={formData.businessName}
                      onChange={(e) => handleChange('businessName', e.target.value)}
                      className={fieldErrors.businessName ? 'input-error' : ''}
                    />
                    {fieldErrors.businessName && <span className="field-error">{fieldErrors.businessName}</span>}
                  </div>
                  <div className="form-group">
                    <label>Kategori Bisnis *</label>
                    <select
                      value={formData.businessCategory}
                      onChange={(e) => handleChange('businessCategory', e.target.value)}
                      className={fieldErrors.businessCategory ? 'input-error' : ''}
                    >
                      <option value="">Pilih Kategori</option>
                      <option value="F&B (Resto/Cafe)">F&B (Resto/Cafe)</option>
                      <option value="Retail / Toko">Retail / Toko</option>
                      <option value="Jasa (Laundry/Salon)">Jasa (Laundry/Salon)</option>
                      <option value="Lainnya">Lainnya</option>
                    </select>
                    {fieldErrors.businessCategory && <span className="field-error">{fieldErrors.businessCategory}</span>}
                  </div>
                </div>

                <div className="form-row">
                  <div className="form-group">
                    <label>Jenis Aplikasi POS *</label>
                    <select
                      value={formData.pos_type}
                      onChange={(e) => handleChange('pos_type', e.target.value)}
                    >
                      <option value="resto">POS Resto / F&B</option>
                      <option value="retail">POS Retail / Toko Kelontong</option>
                      <option value="jasa">POS Jasa (Laundry/Salon/Cuci)</option>
                      <option value="fashion">POS Fashion / Toko Baju</option>
                    </select>
                  </div>
                  <div className="form-group">
                    <label>Alamat Bisnis (Opsional)</label>
                    <input
                      type="text"
                      placeholder="Alamat lengkap bisnis Anda"
                      value={formData.businessAddress}
                      onChange={(e) => handleChange('businessAddress', e.target.value)}
                      style={{ height: '100%', boxSizing: 'border-box' }}
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label>Kode Keamanan *</label>
                  <div className="captcha-row">
                    <div className="captcha-container">
                      {captchaImage ? (
                        <img src={captchaImage} alt="captcha" className="captcha-img" />
                      ) : (
                        <div className="captcha-placeholder">Memuat...</div>
                      )}
                      <button type="button" className="btn-refresh-captcha" onClick={loadCaptcha} title="Refresh">
                        🔄
                      </button>
                    </div>
                    <input
                      type="text"
                      placeholder="5 digit kode"
                      value={formData.captcha_value}
                      onChange={(e) => handleChange('captcha_value', e.target.value)}
                      className={fieldErrors.captcha_value ? 'input-error' : ''}
                      maxLength={6}
                      autoComplete="off"
                    />
                  </div>
                  {fieldErrors.captcha_value && <span className="field-error">{fieldErrors.captcha_value}</span>}
                </div>

                {isError && <div className="error-alert">⚠️ {isError}</div>}

                <button type="submit" className="btn-submit" disabled={isSubmitting}>
                  {isSubmitting ? '⏳ Memproses...' : selectedPlan === 'UMKM' ? '🚀 Daftar Sekarang (Gratis)' : `🚀 Daftar & Bayar ${activePlanDetails.priceStr}`}
                </button>
                <p className="form-note">Dengan mendaftar, Anda menyetujui Syarat & Ketentuan kami.</p>
              </form>
            </div>
          )}
        </div>
      </div>
      <style>{`
        .trial { padding: 6rem 0; background: var(--muted); }
        .trial-wrapper {
          padding: 4rem;
          border-radius: 40px;
          max-width: 1100px;
          margin: 0 auto;
          box-shadow: 0 20px 50px rgba(0,0,0,0.1);
        }
        .trial-grid {
          display: grid;
          grid-template-columns: 0.9fr 1.1fr;
          gap: 5rem;
          align-items: start;
        }
        .badge {
          background: var(--primary);
          color: white;
          padding: 0.5rem 1rem;
          border-radius: 50px;
          font-size: 0.75rem;
          font-weight: 800;
          text-transform: uppercase;
          letter-spacing: 1px;
          display: inline-block;
          margin-bottom: 1.5rem;
        }
        .trial-info h2 { font-size: 2.8rem; margin-bottom: 1.5rem; line-height: 1.1; }
        .trial-info p { color: var(--muted-foreground); font-size: 1.15rem; margin-bottom: 2.5rem; }
        .info-cards { display: flex; flex-direction: column; gap: 1.5rem; margin-bottom: 3rem; }
        .info-card {
          display: flex;
          gap: 1.25rem;
          align-items: center;
          padding: 1.25rem;
          background: rgba(255,255,255,0.05);
          border-radius: 16px;
          border: 1px solid var(--border);
        }
        .info-icon { font-size: 2rem; }
        .info-card h4 { margin-bottom: 0.25rem; }
        .info-card p { font-size: 0.9rem; margin-bottom: 0; color: var(--muted-foreground); }
        .trust-badges { display: flex; gap: 1.5rem; font-size: 0.8rem; font-weight: 700; color: var(--muted-foreground); }
        
        .trial-form { 
          display: flex; 
          flex-direction: column; 
          gap: 1.25rem; 
          background: var(--background);
          padding: 2.5rem;
          border-radius: 24px;
          border: 1px solid var(--border);
          box-shadow: 0 10px 30px rgba(0,0,0,0.05);
        }
        .trial-form h3 { margin-bottom: 0.5rem; font-size: 1.5rem; }
        .form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
        .form-group { display: flex; flex-direction: column; gap: 0.5rem; }
        .form-group label { font-size: 0.85rem; font-weight: 700; color: var(--foreground); }
        .form-group input, .form-group select, .form-group textarea {
          padding: 0.85rem;
          border-radius: 12px;
          border: 2px solid var(--border);
          background: var(--background);
          color: var(--foreground);
          font-family: inherit;
          transition: all 0.3s ease;
        }
        .form-group input:focus, .form-group select:focus, .form-group textarea:focus { 
          outline: none; 
          border-color: var(--primary); 
          box-shadow: 0 0 0 4px rgba(37, 99, 235, 0.1);
        }
        .form-group input.input-error, .form-group select.input-error { border-color: #f43f5e; }
        .field-error { font-size: 0.75rem; color: #f43f5e; font-weight: 600; }
        
        .captcha-row {
          display: flex;
          align-items: center;
          gap: 1rem;
        }
        .captcha-container {
          display: flex;
          align-items: center;
          gap: 0.5rem;
          background: var(--muted);
          padding: 4px;
          border-radius: 12px;
        }
        .captcha-img { height: 48px; border-radius: 8px; background: white; }
        .btn-refresh-captcha { padding: 0.5rem; font-size: 1.2rem; cursor: pointer; }
        
        .btn-submit {
          background: var(--primary);
          color: white;
          padding: 1.1rem;
          border-radius: 14px;
          font-weight: 800;
          font-size: 1.1rem;
          margin-top: 0.5rem;
          transition: all 0.3s ease;
          box-shadow: 0 8px 20px rgba(37, 99, 235, 0.3);
        }
        .btn-submit:hover:not(:disabled) {
          transform: translateY(-3px);
          box-shadow: 0 12px 25px rgba(37, 99, 235, 0.4);
          background: var(--primary-hover);
        }
        .form-note { font-size: 0.75rem; color: var(--muted-foreground); text-align: center; }
        
        .success-message { text-align: center; padding: 1rem 0; }
        .success-icon { font-size: 5rem; margin-bottom: 1.5rem; }
        .success-steps { 
          text-align: left; 
          background: rgba(0,0,0,0.02); 
          padding: 1.5rem; 
          border-radius: 16px; 
          margin: 2rem 0;
          display: flex;
          flex-direction: column;
          gap: 1rem;
        }
        .step { display: flex; gap: 1rem; align-items: center; }
        .step-num { 
          background: var(--primary); 
          color: white; 
          width: 24px; 
          height: 24px; 
          border-radius: 50%; 
          display: flex; 
          align-items: center; 
          justify-content: center; 
          font-size: 0.8rem;
          font-weight: 800;
        }
        .step p { margin: 0; font-size: 0.95rem; font-weight: 600; }
        .btn-whatsapp {
          display: block;
          background: #25d366;
          color: white;
          padding: 1.1rem;
          border-radius: 14px;
          font-weight: 800;
          text-decoration: none;
          margin-bottom: 1rem;
          transition: all 0.3s ease;
          cursor: pointer;
          border: none;
          text-align: center;
        }
        .btn-whatsapp:hover { transform: scale(1.02); background: #1da851; }
        .btn-back { color: var(--muted-foreground); font-weight: 600; font-size: 0.9rem; text-decoration: underline; background: none; border: none; cursor: pointer; }

        .plan-selection-indicator {
          background: rgba(0, 0, 0, 0.02);
          padding: 0.75rem 1rem;
          border-radius: 12px;
          border: 1px dashed var(--border);
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 1rem;
          margin-bottom: 0.5rem;
        }
        .plan-selection-indicator span {
          font-weight: 700;
          font-size: 0.85rem;
          color: var(--foreground);
        }
        .plan-select-dropdown {
          padding: 0.4rem 0.8rem;
          border-radius: 8px;
          border: 1.5px solid var(--border);
          background: var(--background);
          color: var(--foreground);
          font-weight: 700;
          font-size: 0.85rem;
          outline: none;
          cursor: pointer;
        }
        .plan-select-dropdown:focus {
          border-color: var(--primary);
        }

        /* Payment / Invoice Page Styles */
        .payment-message {
          max-width: 600px;
          margin: 0 auto;
          text-align: center;
        }
        .success-badge {
          display: inline-block;
          background: #10b981;
          color: white;
          padding: 0.4rem 1rem;
          border-radius: 50px;
          font-size: 0.75rem;
          font-weight: 800;
          margin-bottom: 1rem;
          letter-spacing: 0.5px;
        }
        .invoice-header h2 {
          font-size: 2rem;
          margin-bottom: 0.5rem;
          color: var(--foreground);
        }
        .invoice-id {
          color: var(--muted-foreground);
          font-size: 0.85rem;
          font-weight: 600;
          margin-bottom: 1.5rem;
        }
        .invoice-card {
          background: var(--background);
          border: 1px solid var(--border);
          border-radius: 16px;
          padding: 1.5rem;
          text-align: left;
          box-shadow: 0 8px 25px rgba(0,0,0,0.02);
          margin-bottom: 2rem;
        }
        .invoice-row {
          display: flex;
          justify-content: space-between;
          margin-bottom: 0.75rem;
          font-size: 0.9rem;
        }
        .invoice-row span {
          color: var(--muted-foreground);
        }
        .invoice-row strong {
          color: var(--foreground);
        }
        .invoice-divider {
          height: 1px;
          background: var(--border);
          margin: 1rem 0;
        }
        .total-row {
          font-size: 1.05rem;
          margin-bottom: 0;
        }
        .total-row span {
          font-weight: 700;
          color: var(--foreground);
        }
        .total-amount {
          color: var(--primary) !important;
          font-size: 1.35rem;
          font-weight: 900;
        }
        .qris-payment-container {
          background: var(--background);
          border: 1px solid var(--border);
          border-radius: 20px;
          padding: 2rem;
          margin-bottom: 2rem;
          box-shadow: 0 8px 25px rgba(0,0,0,0.02);
        }
        .qris-payment-container h3 {
          font-size: 1.15rem;
          margin-bottom: 1.25rem;
          color: var(--foreground);
        }
        .qris-image-wrapper {
          background: white;
          padding: 1rem;
          border-radius: 16px;
          display: inline-block;
          border: 1.5px solid var(--border);
          margin-bottom: 1.5rem;
        }
        .qris-img-pay {
          max-width: 380px;
          height: auto;
          display: block;
        }
        .qris-instructions {
          text-align: left;
          font-size: 0.85rem;
        }
        .qris-instructions p {
          margin-bottom: 0.5rem;
          color: var(--foreground);
        }
        .qris-instructions ol {
          padding-left: 1.1rem;
          color: var(--muted-foreground);
          line-height: 1.5;
        }
        .qris-instructions li {
          margin-bottom: 0.4rem;
        }
        .qris-instructions strong {
          color: var(--foreground);
        }

        .error-alert {
          background: rgba(244, 63, 94, 0.1);
          color: #f43f5e;
          padding: 0.85rem;
          border-radius: 12px;
          border: 1px solid rgba(244, 63, 94, 0.2);
          font-size: 0.9rem;
          font-weight: 600;
          text-align: center;
        }

        @media (max-width: 992px) {
          .trial-grid { grid-template-columns: 1fr; gap: 3rem; }
          .trial-wrapper { padding: 2.5rem; }
        }
        @media (max-width: 600px) {
          .form-row { grid-template-columns: 1fr; }
          .trial-info h2 { font-size: 2rem; }
          .invoice-card, .qris-payment-container { padding: 1.25rem; }
          .qris-img-pay { max-width: 280px; }
        }
      `}</style>
    </section>
  );
};

export default TrialForm;

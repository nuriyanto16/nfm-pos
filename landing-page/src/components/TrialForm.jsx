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
  if (!formData.captcha_value.trim()) {
    errors.captcha_value = 'Kode captcha wajib diisi';
  }
  return errors;
};

const TrialForm = () => {
  const [formData, setFormData] = useState({
    fullName: '',
    email: '',
    phone: '',
    businessName: '',
    captcha_id: '',
    captcha_value: '',
  });
  const [fieldErrors, setFieldErrors] = useState({});
  const [captchaImage, setCaptchaImage] = useState('');
  const [submitted, setSubmitted] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isError, setIsError] = useState('');

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
        body: JSON.stringify(formData),
      });

      const data = await response.json();
      if (response.ok) {
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
            <div className="success-message">
              <div className="success-icon">✅</div>
              <h2>Terima Kasih, {formData.fullName}!</h2>
              <p>Tim kami akan menghubungi Anda dalam waktu 1×24 jam untuk aktivasi akun trial Anda.</p>
              <a
                href={`https://wa.me/62${formData.phone.replace(/^0/, '').replace(/\D/g, '')}?text=${encodeURIComponent('Halo NFM POS, saya baru saja mendaftar trial. Mohon bantuan aktivasinya 🙏')}`}
                target="_blank"
                rel="noreferrer"
                className="btn-whatsapp"
              >
                💬 Konfirmasi via WhatsApp
              </a>
              <button onClick={() => { setSubmitted(false); loadCaptcha(); }} className="btn-back">Daftar Lagi</button>
            </div>
          ) : (
            <div className="trial-grid">
              <div className="trial-info">
                <h2>Mulai Trial Gratis 14 Hari</h2>
                <p>Rasakan kemudahan mengelola bisnis dengan fitur lengkap tanpa komitmen apapun.</p>
                <ul className="trial-benefits">
                  <li>✨ Full access ke semua fitur</li>
                  <li>✨ Setup dibantu tim ahli</li>
                  <li>✨ Tanpa kartu kredit</li>
                  <li>🔒 Data Anda aman & terenkripsi</li>
                </ul>
              </div>
              <form className="trial-form" onSubmit={handleSubmit} noValidate>

                <div className="form-group">
                  <label>Nama Lengkap *</label>
                  <input
                    type="text"
                    placeholder="Contoh: Budi Santoso"
                    value={formData.fullName}
                    onChange={(e) => handleChange('fullName', e.target.value)}
                    className={fieldErrors.fullName ? 'input-error' : ''}
                  />
                  {fieldErrors.fullName && <span className="field-error">{fieldErrors.fullName}</span>}
                </div>

                <div className="form-group">
                  <label>Email Bisnis *</label>
                  <input
                    type="email"
                    placeholder="budi@bisnis.id"
                    value={formData.email}
                    onChange={(e) => handleChange('email', e.target.value)}
                    className={fieldErrors.email ? 'input-error' : ''}
                  />
                  {fieldErrors.email && <span className="field-error">{fieldErrors.email}</span>}
                </div>

                <div className="form-group">
                  <label>Nomor WhatsApp *</label>
                  <input
                    type="tel"
                    placeholder="08123456789"
                    value={formData.phone}
                    onChange={(e) => handleChange('phone', e.target.value.replace(/[^0-9+\-\s]/g, ''))}
                    className={fieldErrors.phone ? 'input-error' : ''}
                    maxLength={16}
                  />
                  {fieldErrors.phone && <span className="field-error">{fieldErrors.phone}</span>}
                </div>

                <div className="form-group">
                  <label>Nama Bisnis *</label>
                  <input
                    type="text"
                    placeholder="Contoh: Kedai Kopi Maju"
                    value={formData.businessName}
                    onChange={(e) => handleChange('businessName', e.target.value)}
                    className={fieldErrors.businessName ? 'input-error' : ''}
                  />
                  {fieldErrors.businessName && <span className="field-error">{fieldErrors.businessName}</span>}
                </div>

                <div className="form-group">
                  <label>Kode Keamanan (Captcha) *</label>
                  <div className="captcha-row">
                    {captchaImage ? (
                      <img src={captchaImage} alt="captcha" className="captcha-img" />
                    ) : (
                      <div className="captcha-placeholder">Memuat...</div>
                    )}
                    <button type="button" className="btn-refresh-captcha" onClick={loadCaptcha} title="Refresh captcha">
                      🔄
                    </button>
                  </div>
                  <input
                    type="text"
                    placeholder="Masukkan 5 digit kode di atas"
                    value={formData.captcha_value}
                    onChange={(e) => handleChange('captcha_value', e.target.value)}
                    className={fieldErrors.captcha_value ? 'input-error' : ''}
                    maxLength={6}
                    autoComplete="off"
                  />
                  {fieldErrors.captcha_value && <span className="field-error">{fieldErrors.captcha_value}</span>}
                </div>

                {isError && <div className="error-alert">⚠️ {isError}</div>}

                <button type="submit" className="btn-submit" disabled={isSubmitting}>
                  {isSubmitting ? '⏳ Mendaftar...' : '🚀 Daftar Trial Sekarang'}
                </button>
              </form>
            </div>
          )}
        </div>
      </div>
      <style>{`
        .trial { padding: 6rem 0; }
        .trial-wrapper {
          padding: 4rem;
          border-radius: 32px;
          max-width: 1000px;
          margin: 0 auto;
        }
        .trial-grid {
          display: grid;
          grid-template-columns: 1fr 1.2fr;
          gap: 4rem;
          align-items: start;
        }
        .trial-info h2 { font-size: 2.5rem; margin-bottom: 1.5rem; }
        .trial-info p { color: var(--muted-foreground); font-size: 1.1rem; margin-bottom: 2rem; }
        .trial-benefits { list-style: none; }
        .trial-benefits li { margin-bottom: 0.75rem; font-weight: 600; }
        .trial-form { display: flex; flex-direction: column; gap: 1.1rem; }
        .form-group { display: flex; flex-direction: column; gap: 0.4rem; }
        .form-group label { font-size: 0.875rem; font-weight: 600; color: var(--muted-foreground); }
        .form-group input {
          padding: 0.875rem;
          border-radius: 12px;
          border: 1px solid var(--border);
          background: var(--background);
          color: var(--foreground);
          font-family: inherit;
          transition: border-color 0.3s ease;
        }
        .form-group input:focus { outline: none; border-color: var(--primary); }
        .form-group input.input-error { border-color: #f43f5e; }
        .field-error { font-size: 0.78rem; color: #f43f5e; font-weight: 500; }
        .captcha-row {
          display: flex;
          align-items: center;
          gap: 0.75rem;
          margin-bottom: 0.5rem;
        }
        .captcha-img {
          border-radius: 8px;
          border: 1px solid var(--border);
          height: 56px;
          background: #fff;
        }
        .captcha-placeholder {
          height: 56px;
          width: 160px;
          border-radius: 8px;
          border: 1px solid var(--border);
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 0.85rem;
          color: var(--muted-foreground);
        }
        .btn-refresh-captcha {
          background: var(--glass-bg, rgba(255,255,255,0.1));
          border: 1px solid var(--border);
          border-radius: 8px;
          padding: 0.5rem 0.75rem;
          cursor: pointer;
          font-size: 1.1rem;
          transition: transform 0.2s ease;
        }
        .btn-refresh-captcha:hover { transform: rotate(180deg); }
        .btn-submit {
          background: var(--primary);
          color: white;
          padding: 1rem;
          border-radius: 12px;
          font-weight: 700;
          font-size: 1.05rem;
          margin-top: 0.5rem;
          transition: all 0.3s ease;
        }
        .btn-submit:hover:not(:disabled) {
          background: var(--primary-hover);
          transform: translateY(-2px);
        }
        .btn-submit:disabled { opacity: 0.65; cursor: not-allowed; }
        .error-alert {
          background: rgba(244, 63, 94, 0.1);
          color: #f43f5e;
          padding: 0.75rem;
          border-radius: 8px;
          font-size: 0.875rem;
          font-weight: 600;
          text-align: center;
          border: 1px solid rgba(244,63,94,0.3);
        }
        .success-message { text-align: center; padding: 2rem 0; }
        .success-icon { font-size: 4rem; margin-bottom: 1rem; }
        .btn-whatsapp {
          display: inline-block;
          margin-top: 1.5rem;
          background: #25d366;
          color: white;
          padding: 0.875rem 2rem;
          border-radius: 12px;
          font-weight: 700;
          font-size: 1rem;
          text-decoration: none;
          transition: all 0.3s ease;
        }
        .btn-whatsapp:hover { background: #1da851; transform: translateY(-2px); }
        .btn-back {
          display: block;
          margin-top: 1rem;
          color: var(--primary);
          font-weight: 600;
          text-decoration: underline;
          cursor: pointer;
          background: none;
          border: none;
        }
        @media (max-width: 768px) {
          .trial-wrapper { padding: 2rem; }
          .trial-grid { grid-template-columns: 1fr; gap: 2rem; }
          .trial-info h2 { font-size: 2rem; }
        }
      `}</style>
    </section>
  );
};

export default TrialForm;

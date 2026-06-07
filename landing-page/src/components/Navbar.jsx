import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';

const Navbar = () => {
  const [isScrolled, setIsScrolled] = useState(false);
  const [theme, setTheme] = useState(localStorage.getItem('theme') || 'light');

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('theme', theme);
  }, [theme]);

  const toggleTheme = () => {
    setTheme(prev => prev === 'light' ? 'dark' : 'light');
  };

  return (
    <nav className={`navbar ${isScrolled ? 'scrolled glass' : ''}`}>
      <div className="container nav-content">
        <Link to="/" className="logo">
          <span className="logo-icon">🚀</span>
          <div className="logo-brand">
            <span className="logo-text">NFM<span className="gradient-text">POS</span></span>
            <span className="logo-subtitle">Next Future Machine</span>
          </div>
        </Link>
        <div className="nav-links">
          <a href="/#features">Fitur</a>
          <a href="/#pricing">Harga</a>
          <Link to="/blog">Blog</Link>
          <Link to="/kontak">Kontak</Link>
          <button onClick={toggleTheme} className="btn-theme" title="Ubah Tema">
            {theme === 'light' ? (
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="theme-icon">
                <path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"/>
              </svg>
            ) : (
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="theme-icon">
                <circle cx="12" cy="12" r="4"/>
                <path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41"/>
              </svg>
            )}
          </button>
          <a href="/#trial" className="btn-primary">Coba Gratis</a>
        </div>
      </div>
      <style>{`
        .navbar {
          position: fixed;
          top: 0;
          left: 0;
          right: 0;
          z-index: 1000;
          padding: 1.5rem 0;
          transition: all 0.3s ease;
        }
        .navbar.scrolled {
          padding: 0.75rem 0;
          box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05);
        }
        .nav-content {
          display: flex;
          justify-content: space-between;
          align-items: center;
        }
        .logo {
          display: flex;
          align-items: center;
          gap: 0.5rem;
          text-decoration: none;
          color: inherit;
        }
        .logo-brand {
          display: flex;
          flex-direction: column;
          align-items: flex-start;
          line-height: 1.1;
        }
        .logo-text {
          font-size: 1.5rem;
          font-weight: 800;
        }
        .logo-subtitle {
          font-size: 0.6rem;
          font-weight: 600;
          color: var(--muted-foreground);
          letter-spacing: 0.5px;
          text-transform: uppercase;
        }
        .nav-links {
          display: flex;
          align-items: center;
          gap: 2rem;
        }
        .nav-links a {
          font-weight: 500;
          color: var(--muted-foreground);
          transition: color 0.3s ease;
        }
        .nav-links a:hover {
          color: var(--primary);
        }
        .btn-theme {
          display: flex;
          align-items: center;
          justify-content: center;
          width: 38px;
          height: 38px;
          border-radius: 50%;
          background: var(--muted);
          color: var(--foreground);
          transition: all 0.3s ease;
          border: 1px solid var(--border);
        }
        .btn-theme:hover {
          background: var(--border);
          transform: scale(1.05);
        }
        .theme-icon {
          width: 18px;
          height: 18px;
        }
        .btn-primary {
          background: var(--primary);
          color: white !important;
          padding: 0.6rem 1.5rem;
          border-radius: 50px;
          font-weight: 600 !important;
          transition: transform 0.3s ease, background 0.3s ease;
        }
        .btn-primary:hover {
          background: var(--primary-hover);
          transform: translateY(-2px);
        }
      `}</style>
    </nav>
  );
};

export default Navbar;

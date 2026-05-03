import React, { useState, useEffect } from 'react';

const Navbar = () => {
  const [isScrolled, setIsScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  return (
    <nav className={`navbar ${isScrolled ? 'scrolled glass' : ''}`}>
      <div className="container nav-content">
        <div className="logo">
          <span className="logo-icon">🚀</span>
          <span className="logo-text">NFM<span className="gradient-text">POS</span></span>
        </div>
        <div className="nav-links">
          <a href="#features">Fitur</a>
          <a href="#pricing">Harga</a>
          <a href="#trial" className="btn-primary">Coba Gratis</a>
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
          font-size: 1.5rem;
          font-weight: 800;
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

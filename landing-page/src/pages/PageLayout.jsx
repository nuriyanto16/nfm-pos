import React from 'react';
import Navbar from '../components/Navbar';
import Footer from '../components/Footer';

const PageLayout = ({ title, subtitle, children }) => (
  <div className="page-wrapper">
    <Navbar />
    <div className="page-hero">
      <div className="container">
        <h1>{title}</h1>
        {subtitle && <p>{subtitle}</p>}
      </div>
    </div>
    <main className="page-content">
      <div className="container">
        {children}
      </div>
    </main>
    <Footer />
    <style>{`
      .page-wrapper { overflow-x: hidden; }
      .page-hero {
        padding: 9rem 0 4rem;
        background: var(--muted);
        border-bottom: 1px solid var(--border);
        text-align: center;
      }
      .page-hero h1 {
        font-size: 3rem;
        font-weight: 800;
        margin-bottom: 1rem;
      }
      .page-hero p {
        font-size: 1.2rem;
        color: var(--muted-foreground);
        max-width: 600px;
        margin: 0 auto;
      }
      .page-content {
        padding: 5rem 0;
        min-height: 50vh;
      }
    `}</style>
  </div>
);

export default PageLayout;

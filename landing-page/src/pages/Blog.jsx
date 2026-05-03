import React from 'react';
import PageLayout from './PageLayout';

const posts = [
  {
    tag: 'Tips Bisnis',
    title: '5 Cara Meningkatkan Omzet Restoran dengan Sistem POS Modern',
    excerpt: 'Ketahui bagaimana penggunaan POS yang tepat dapat membantu restoran Anda meningkatkan efisiensi operasional dan mendongkrak pendapatan hingga 30%.',
    date: '28 April 2026',
    readTime: '5 menit',
    emoji: '📈',
  },
  {
    tag: 'Fitur Baru',
    title: 'Mengenal Kitchen Display System (KDS): Dapur Digital Era Modern',
    excerpt: 'KDS hadir menggantikan slip kertas di dapur. Pelajari cara kerja, keunggulan, dan bagaimana KDS NFM POS membantu tim dapur Anda bekerja lebih cepat.',
    date: '22 April 2026',
    readTime: '4 menit',
    emoji: '🍳',
  },
  {
    tag: 'Panduan',
    title: 'Panduan Lengkap Manajemen Stok untuk UMKM Kuliner',
    excerpt: 'Stok habis di jam sibuk? Pelajari strategi manajemen inventaris yang terbukti efektif untuk bisnis kuliner skala kecil hingga menengah.',
    date: '15 April 2026',
    readTime: '7 menit',
    emoji: '📦',
  },
  {
    tag: 'Franchise',
    title: 'Strategi Membuka Franchise Kuliner yang Sukses di 2026',
    excerpt: 'Dari standarisasi menu hingga kontrol kualitas multi-cabang — temukan rahasia brand franchise kuliner yang berhasil mengembangkan bisnis mereka.',
    date: '10 April 2026',
    readTime: '6 menit',
    emoji: '🏢',
  },
  {
    tag: 'Teknologi',
    title: 'QRIS vs Kartu Debit: Mana yang Lebih Menguntungkan untuk Merchant?',
    excerpt: 'Analisis mendalam tentang biaya transaksi, kecepatan settlement, dan pengalaman pelanggan dari dua metode pembayaran populer saat ini.',
    date: '5 April 2026',
    readTime: '5 menit',
    emoji: '💳',
  },
  {
    tag: 'Tips Bisnis',
    title: 'Cara Membaca Laporan Keuangan Restoran untuk Pemula',
    excerpt: 'Tidak perlu menjadi akuntan — pahami laporan laba rugi, arus kas, dan neraca bisnis kuliner Anda dengan panduan sederhana ini.',
    date: '1 April 2026',
    readTime: '8 menit',
    emoji: '📑',
  },
];

const Blog = () => (
  <PageLayout
    title="Blog NFM POS"
    subtitle="Tips, panduan, dan wawasan terkini seputar manajemen bisnis dan teknologi POS."
  >
    <div className="blog-grid">
      {posts.map((post) => (
        <article key={post.title} className="blog-card glass">
          <div className="blog-emoji">{post.emoji}</div>
          <div className="blog-tag">{post.tag}</div>
          <h3>{post.title}</h3>
          <p>{post.excerpt}</p>
          <div className="blog-meta">
            <span>📅 {post.date}</span>
            <span>⏱ {post.readTime}</span>
          </div>
          <button className="btn-read">Baca Selengkapnya →</button>
        </article>
      ))}
    </div>
    <style>{`
      .blog-grid {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 2rem;
      }
      .blog-card {
        border-radius: 20px;
        padding: 2rem;
        display: flex;
        flex-direction: column;
        gap: 1rem;
        transition: transform 0.3s ease, box-shadow 0.3s ease;
        border: 1px solid var(--border);
      }
      .blog-card:hover {
        transform: translateY(-6px);
        box-shadow: 0 20px 40px rgba(0,0,0,0.1);
      }
      .blog-emoji { font-size: 2.5rem; }
      .blog-tag {
        display: inline-block;
        background: rgba(37,99,235,0.1);
        color: var(--primary);
        padding: 0.25rem 0.75rem;
        border-radius: 50px;
        font-size: 0.78rem;
        font-weight: 700;
        width: fit-content;
      }
      .blog-card h3 {
        font-size: 1.1rem;
        font-weight: 700;
        line-height: 1.4;
      }
      .blog-card p {
        color: var(--muted-foreground);
        font-size: 0.9rem;
        line-height: 1.7;
        flex: 1;
      }
      .blog-meta {
        display: flex;
        gap: 1rem;
        font-size: 0.8rem;
        color: var(--muted-foreground);
      }
      .btn-read {
        color: var(--primary);
        font-weight: 700;
        font-size: 0.9rem;
        background: none;
        border: none;
        cursor: pointer;
        text-align: left;
        padding: 0;
        transition: gap 0.2s;
      }
      .btn-read:hover { text-decoration: underline; }
      @media (max-width: 1024px) { .blog-grid { grid-template-columns: 1fr 1fr; } }
      @media (max-width: 640px) { .blog-grid { grid-template-columns: 1fr; } }
    `}</style>
  </PageLayout>
);

export default Blog;

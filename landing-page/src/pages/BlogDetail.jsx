import React from 'react';
import { useParams, Link } from 'react-router-dom';
import PageLayout from './PageLayout';

const posts = [
  {
    slug: '5-cara-meningkatkan-omzet-restoran',
    tag: 'Tips Bisnis',
    title: '5 Cara Meningkatkan Omzet Restoran dengan Sistem POS Modern',
    content: `
      <p>Di era digital saat ini, persaingan bisnis kuliner semakin ketat. Mengandalkan rasa makanan saja tidak cukup. Anda perlu sistem yang efisien untuk mengelola operasional harian. Salah satu solusi terbaik adalah dengan mengimplementasikan sistem Point of Sale (POS) yang modern.</p>
      
      <h4>1. Optimalkan Alur Pemesanan</h4>
      <p>Dengan POS modern, pelayan dapat langsung memasukkan pesanan melalui tablet atau smartphone yang terhubung langsung ke dapur. Ini mengurangi risiko kesalahan pesanan dan mempercepat waktu penyajian.</p>
      
      <h4>2. Analisis Data Penjualan</h4>
      <p>Sistem POS mencatat setiap transaksi. Anda dapat melihat menu mana yang paling laris dan mana yang kurang diminati. Gunakan data ini untuk mengoptimalkan menu dan stok bahan baku.</p>
      
      <h4>3. Manajemen Inventaris yang Ketat</h4>
      <p>Kehilangan bahan baku (waste) adalah salah satu penyebab utama kebocoran omzet. POS modern dapat melacak penggunaan bahan baku secara real-time berdasarkan pesanan yang masuk.</p>
      
      <h4>4. Program Loyalitas Pelanggan</h4>
      <p>Simpan data pelanggan dan berikan reward khusus untuk pelanggan setia. CRM yang terintegrasi di POS memudahkan Anda menjalankan campaign pemasaran yang personal.</p>
      
      <h4>5. Integrasi Pembayaran Digital</h4>
      <p>Mudahkan pelanggan bertransaksi dengan berbagai metode pembayaran digital seperti QRIS, E-wallet, hingga kartu debit/kredit tanpa perlu banyak perangkat tambahan.</p>
    `,
    date: '28 April 2026',
    readTime: '5 menit',
    emoji: '📈',
  },
  {
    slug: 'mengenal-kitchen-display-system',
    tag: 'Fitur Baru',
    title: 'Mengenal Kitchen Display System (KDS): Dapur Digital Era Modern',
    content: `
      <p>Kitchen Display System (KDS) adalah evolusi dari printer pesanan tradisional. Alih-alih mencetak kertas, pesanan ditampilkan pada layar digital di area dapur.</p>
      
      <h4>Mengapa Beralih ke KDS?</h4>
      <ul>
        <li><strong>Tanpa Kertas:</strong> Mengurangi biaya operasional dan lebih ramah lingkungan.</li>
        <li><strong>Kejelasan Pesanan:</strong> Tidak ada lagi tulisan tangan yang sulit dibaca atau kertas yang hilang.</li>
        <li><strong>Waktu Produksi:</strong> Admin dapat melacak berapa lama setiap menu disiapkan untuk evaluasi performa tim dapur.</li>
        <li><strong>Prioritas Otomatis:</strong> KDS dapat mengurutkan pesanan berdasarkan waktu masuk atau tingkat kerumitan.</li>
      </ul>
      
      <p>NFM POS kini hadir dengan modul KDS yang terintegrasi penuh, memudahkan koordinasi antara front-of-house dan tim dapur Anda.</p>
    `,
    date: '22 April 2026',
    readTime: '4 menit',
    emoji: '🍳',
  },
  {
    slug: 'panduan-manajemen-stok-umkm',
    tag: 'Panduan',
    title: 'Panduan Lengkap Manajemen Stok untuk UMKM Kuliner',
    content: `
      <p>Manajemen stok yang buruk bisa membunuh bisnis kuliner. Terlalu banyak stok berarti modal mati, terlalu sedikit stok berarti kehilangan potensi penjualan.</p>
      
      <h4>Langkah Dasar Manajemen Stok:</h4>
      <ol>
        <li><strong>First In First Out (FIFO):</strong> Gunakan bahan yang paling lama disimpan terlebih dahulu.</li>
        <li><strong>Stock Opname Berkala:</strong> Lakukan pencocokan stok fisik dengan data sistem secara rutin (harian atau mingguan).</li>
        <li><strong>Set Minimum Stock:</strong> Atur alarm di sistem POS Anda ketika stok bahan tertentu mencapai batas minimum.</li>
        <li><strong>Pilih Supplier Terpercaya:</strong> Pastikan pasokan bahan baku stabil untuk menghindari kekosongan stok mendadak.</li>
      </ol>
    `,
    date: '15 April 2026',
    readTime: '7 menit',
    emoji: '📦',
  },
  {
    slug: 'strategi-membuka-franchise-kuliner',
    tag: 'Franchise',
    title: 'Strategi Membuka Franchise Kuliner yang Sukses di 2026',
    content: `
      <p>Membuka franchise adalah cara tercepat untuk melakukan skala bisnis. Namun, tanpa strategi yang tepat, Anda bisa terjebak dalam masalah operasional di banyak cabang.</p>
      <h4>Rahasia Sukses Franchise:</h4>
      <ul>
        <li>Standard Operating Procedure (SOP) yang sangat detail.</li>
        <li>Sistem kontrol kualitas (QC) berkala.</li>
        <li>Sistem POS yang terpusat untuk memantau semua outlet secara real-time.</li>
      </ul>
    `,
    date: '10 April 2026',
    readTime: '6 menit',
    emoji: '🏢',
  },
  {
    slug: 'qris-vs-kartu-debit',
    tag: 'Teknologi',
    title: 'QRIS vs Kartu Debit: Mana yang Lebih Menguntungkan untuk Merchant?',
    content: `
      <p>Dilema merchant saat ini adalah memilih metode pembayaran yang paling efisien. QRIS sangat populer, namun kartu debit masih memiliki tempat di hati pelanggan.</p>
      <p>QRIS unggul dalam biaya perangkat (cukup cetak stiker), sementara kartu debit unggul dalam kecepatan transaksi untuk nominal besar.</p>
    `,
    date: '5 April 2026',
    readTime: '5 menit',
    emoji: '💳',
  },
  {
    slug: 'cara-membaca-laporan-keuangan-restoran',
    tag: 'Tips Bisnis',
    title: 'Cara Membaca Laporan Keuangan Restoran untuk Pemula',
    content: `
      <p>Jangan takut dengan angka. Laporan keuangan adalah cermin kesehatan bisnis Anda. Fokuslah pada tiga hal: Gross Profit, Net Profit, dan Cash Flow.</p>
    `,
    date: '1 April 2026',
    readTime: '8 menit',
    emoji: '📑',
  },
];

const BlogDetail = () => {
  const { slug } = useParams();
  const post = posts.find((p) => p.slug === slug) || posts[0];

  return (
    <PageLayout title={post.title} subtitle={`${post.tag} • ${post.date}`}>
      <div className="blog-content glass">
        <div className="post-header">
            <Link to="/blog" className="btn-back">← Kembali ke Blog</Link>
            <div className="post-emoji">{post.emoji}</div>
        </div>
        
        <div className="post-body" dangerouslySetInnerHTML={{ __html: post.content }} />
        
        <div className="post-footer">
            <p>Butuh solusi POS untuk bisnis Anda? <Link to="/#trial">Coba Gratis Sekarang</Link></p>
        </div>
      </div>

      <style>{`
        .blog-content {
          max-width: 800px;
          margin: 0 auto;
          padding: 3rem;
          border-radius: 30px;
          border: 1px solid var(--border);
        }
        .post-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 2.5rem;
        }
        .btn-back {
            color: var(--primary);
            font-weight: 700;
            text-decoration: none;
        }
        .btn-back:hover { text-decoration: underline; }
        .post-emoji { font-size: 4rem; }
        .post-body {
          line-height: 1.8;
          color: var(--foreground);
        }
        .post-body h4 {
          margin-top: 2rem;
          margin-bottom: 0.75rem;
          font-size: 1.3rem;
        }
        .post-body p {
          margin-bottom: 1.25rem;
          color: var(--muted-foreground);
        }
        .post-body ul, .post-body ol {
            margin-bottom: 1.5rem;
            padding-left: 1.5rem;
            color: var(--muted-foreground);
        }
        .post-body li { margin-bottom: 0.5rem; }
        .post-footer {
            margin-top: 4rem;
            padding-top: 2rem;
            border-top: 1px solid var(--border);
            text-align: center;
            font-weight: 600;
        }
        .post-footer a { color: var(--primary); }
      `}</style>
    </PageLayout>
  );
};

export default BlogDetail;

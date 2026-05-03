import React from 'react';
import PageLayout from './PageLayout';

const KebijakanPrivasi = () => (
  <PageLayout
    title="Kebijakan Privasi"
    subtitle="Terakhir diperbarui: 1 April 2026"
  >
    <div className="legal-content glass">
      {[
        {
          title: '1. Informasi yang Kami Kumpulkan',
          body: `Kami mengumpulkan informasi yang Anda berikan secara langsung kepada kami ketika mendaftar atau menggunakan layanan NFM POS, termasuk:
          • Nama lengkap dan informasi kontak (email, nomor telepon)
          • Informasi bisnis (nama usaha, alamat, jenis usaha)
          • Data transaksi dan operasional yang diproses melalui sistem kami
          • Informasi perangkat dan log akses untuk keperluan keamanan`
        },
        {
          title: '2. Cara Kami Menggunakan Informasi',
          body: `Informasi yang kami kumpulkan digunakan untuk:
          • Menyediakan, mengoperasikan, dan meningkatkan layanan NFM POS
          • Mengirimkan notifikasi penting terkait akun dan layanan Anda
          • Memberikan dukungan pelanggan dan merespons permintaan Anda
          • Memenuhi kewajiban hukum dan peraturan yang berlaku di Indonesia`
        },
        {
          title: '3. Keamanan Data',
          body: `Keamanan data Anda adalah prioritas utama kami. Kami menerapkan:
          • Enkripsi AES-256 untuk semua data yang tersimpan
          • Koneksi HTTPS/TLS untuk semua transmisi data
          • Autentikasi dua faktor (2FA) untuk akses akun
          • Audit keamanan berkala oleh tim internal dan pihak ketiga independen
          • Server berlokasi di data center bersertifikat Tier III di Indonesia`
        },
        {
          title: '4. Berbagi Informasi dengan Pihak Ketiga',
          body: `Kami tidak menjual, menyewakan, atau membagikan data pribadi Anda kepada pihak ketiga untuk kepentingan komersial. Data Anda hanya dapat dibagikan dalam kondisi berikut:
          • Dengan persetujuan eksplisit dari Anda
          • Kepada penyedia layanan terpercaya yang membantu operasional kami (tunduk pada perjanjian kerahasiaan)
          • Jika diwajibkan oleh hukum atau perintah pengadilan yang sah`
        },
        {
          title: '5. Hak Anda',
          body: `Sebagai pengguna, Anda memiliki hak untuk:
          • Mengakses data pribadi yang kami simpan tentang Anda
          • Meminta koreksi atas data yang tidak akurat
          • Meminta penghapusan data Anda (hak untuk dilupakan)
          • Menarik persetujuan pemrosesan data kapan saja
          • Mengajukan keluhan kepada otoritas perlindungan data yang berwenang
          Untuk menggunakan hak-hak ini, silakan hubungi kami di privacy@nfmpos.id`
        },
        {
          title: '6. Retensi Data',
          body: `Kami menyimpan data Anda selama akun Anda aktif atau selama diperlukan untuk menyediakan layanan. Setelah penutupan akun, data operasional akan dihapus dalam 90 hari, kecuali data yang wajib disimpan sesuai ketentuan hukum perpajakan dan keuangan Indonesia.`
        },
        {
          title: '7. Perubahan Kebijakan',
          body: `Kami dapat memperbarui Kebijakan Privasi ini dari waktu ke waktu. Setiap perubahan material akan diberitahukan kepada Anda melalui email atau notifikasi dalam aplikasi minimal 30 hari sebelum perubahan berlaku. Penggunaan layanan yang berlanjut setelah perubahan dianggap sebagai persetujuan terhadap kebijakan yang diperbarui.`
        },
        {
          title: '8. Hubungi Kami',
          body: `Jika Anda memiliki pertanyaan, kekhawatiran, atau permintaan terkait Kebijakan Privasi ini, silakan hubungi:
          📧 Email: privacy@nfmpos.id
          💬 WhatsApp: +62 812-3456-7890
          📍 NFM Technology, Jakarta, Indonesia`
        },
      ].map((section) => (
        <div key={section.title} className="legal-section">
          <h3>{section.title}</h3>
          <p style={{ whiteSpace: 'pre-line' }}>{section.body}</p>
        </div>
      ))}
    </div>
    <style>{`
      .legal-content {
        padding: 3rem;
        border-radius: 24px;
        border: 1px solid var(--border);
        display: flex;
        flex-direction: column;
        gap: 2.5rem;
      }
      .legal-section h3 {
        font-size: 1.2rem;
        font-weight: 800;
        margin-bottom: 1rem;
        color: var(--primary);
      }
      .legal-section p {
        color: var(--muted-foreground);
        line-height: 1.8;
        font-size: 0.95rem;
      }
      @media (max-width: 768px) { .legal-content { padding: 1.5rem; } }
    `}</style>
  </PageLayout>
);

export default KebijakanPrivasi;

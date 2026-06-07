import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DocumentationScreen extends ConsumerStatefulWidget {
  const DocumentationScreen({super.key});

  @override
  ConsumerState<DocumentationScreen> createState() => _DocumentationScreenState();
}

class _DocumentationScreenState extends ConsumerState<DocumentationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedSection = 0;

  final List<_DocSection> _sections = [
    _DocSection(
      icon: Icons.account_tree_outlined,
      title: 'Alur Sistem',
      color: Color(0xFF6366F1),
      pages: [
        _DocPage('Alur Registrasi & Aktivasi', _registrationFlow),
        _DocPage('Alur Login & Akses', _loginFlow),
        _DocPage('Alur Transaksi POS', _transactionFlow),
        _DocPage('Alur Void / Pembatalan', _voidFlow),
      ],
    ),
    _DocSection(
      icon: Icons.manage_accounts_outlined,
      title: 'Panduan Super User',
      color: Color(0xFF8B5CF6),
      pages: [
        _DocPage('Apa itu Super User?', _superUserIntro),
        _DocPage('Manajemen Registrasi', _registrationMgmt),
        _DocPage('Aktivasi via Telegram', _telegramActivation),
        _DocPage('Manajemen Tenant', _tenantMgmt),
      ],
    ),
    _DocSection(
      icon: Icons.inventory_2_outlined,
      title: 'Manajemen Stok',
      color: Color(0xFF059669),
      pages: [
        _DocPage('Logika Stok per Jenis POS', _stockLogic),
        _DocPage('Penerimaan Barang (GR)', _goodsReceipt),
        _DocPage('Pengeluaran Barang (GI)', _goodsIssue),
        _DocPage('Transfer Cabang', _branchTransfer),
      ],
    ),
    _DocSection(
      icon: Icons.layers_outlined,
      title: 'Technology Stack',
      color: Color(0xFF0369A1),
      pages: [
        _DocPage('Backend (Go + Gin)', _backendStack),
        _DocPage('Frontend (Flutter)', _frontendStack),
        _DocPage('Bot & Integrasi', _botStack),
        _DocPage('Database & DevOps', _dbStack),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _sections.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedSection = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // ─── Header (pakai warna tema aplikasi) ───────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withRed(
                    (colorScheme.primary.red + 30).clamp(0, 255),
                  ),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dokumentasi Sistem',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'NFM POS SaaS — Panduan Lengkap',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tab Bar
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.6),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: _sections.map((s) => Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(s.icon, size: 16),
                        const SizedBox(width: 6),
                        Text(s.title),
                      ],
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),

          // ─── Body: Sidebar + Content ───────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _sections.map((section) =>
                _SectionView(section: section, accentColor: section.color)
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }
}


// ─── Section View ─────────────────────────────────────────────────────────────
class _SectionView extends StatefulWidget {
  final _DocSection section;
  final Color accentColor;
  const _SectionView({required this.section, required this.accentColor});

  @override
  State<_SectionView> createState() => _SectionViewState();
}

class _SectionViewState extends State<_SectionView> {
  int _selectedPage = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 800;

    if (isWide) {
      return Row(
        children: [
          // Left sidebar
          Container(
            width: 220,
            color: colorScheme.surfaceContainerHighest,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: widget.section.pages.length,
              itemBuilder: (context, i) {
                final isSelected = i == _selectedPage;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    dense: true,
                    leading: Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected ? widget.accentColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    title: Text(
                      widget.section.pages[i].title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? widget.accentColor : colorScheme.onSurface,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: widget.accentColor.withOpacity(0.1),
                    onTap: () => setState(() => _selectedPage = i),
                  ),
                );
              },
            ),
          ),
          const VerticalDivider(width: 1),
          // Right content
          Expanded(
            child: _DocContent(
              page: widget.section.pages[_selectedPage],
              accentColor: widget.accentColor,
            ),
          ),
        ],
      );
    }

    // Mobile: vertical list
    return Column(
      children: [
        // Page selector chips
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.section.pages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final isSelected = i == _selectedPage;
              return ChoiceChip(
                label: Text(widget.section.pages[i].title, style: const TextStyle(fontSize: 12)),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedPage = i),
                selectedColor: widget.accentColor.withOpacity(0.2),
              );
            },
          ),
        ),
        Expanded(
          child: _DocContent(
            page: widget.section.pages[_selectedPage],
            accentColor: widget.accentColor,
          ),
        ),
      ],
    );
  }
}

// ─── Doc Content ───────────────────────────────────────────────────────────────
class _DocContent extends StatelessWidget {
  final _DocPage page;
  final Color accentColor;
  const _DocContent({required this.page, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            page.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: accentColor,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 16),
          ...page.buildContent(context, accentColor),
        ],
      ),
    );
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────
class _DocSection {
  final IconData icon;
  final String title;
  final Color color;
  final List<_DocPage> pages;
  const _DocSection({required this.icon, required this.title, required this.color, required this.pages});
}

class _DocPage {
  final String title;
  final List<Widget> Function(BuildContext, Color) buildContent;
  const _DocPage(this.title, this.buildContent);
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────
Widget _docStep(Color accent, int step, String title, String desc) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: Text('$step', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 13, height: 1.5)),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _docAlert(IconData icon, Color color, String text) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: color.withBlue(50), fontSize: 13, height: 1.4))),
      ],
    ),
  );
}

Widget _docBadge(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    margin: const EdgeInsets.only(right: 6, bottom: 6),
    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
  );
}

Widget _docCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
    ),
  );
}

Widget _sectionTitle(String text) => Padding(
  padding: const EdgeInsets.only(top: 16, bottom: 8),
  child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
);

Widget _tableRow(String key, String val, {bool header = false}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 5),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(width: 180, child: Text(key, style: TextStyle(fontWeight: header ? FontWeight.w800 : FontWeight.w600, fontSize: 13))),
      Expanded(child: Text(val, style: TextStyle(fontSize: 13, fontWeight: header ? FontWeight.w800 : FontWeight.normal))),
    ],
  ),
);

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION 1: Alur Sistem
// ═══════════════════════════════════════════════════════════════════════════════

List<Widget> _registrationFlow(BuildContext ctx, Color accent) => [
  _docAlert(Icons.info_outline, accent, 'Alur ini menjelaskan proses dari calon tenant mengisi form di landing page hingga akun mereka aktif dan siap digunakan.'),
  _sectionTitle('FASE 1: Pendaftaran'),
  _docStep(accent, 1, 'Buka Landing Page', 'Calon tenant mengunjungi halaman pemasaran NFM POS dan mengklik tombol "Coba Gratis".'),
  _docStep(accent, 2, 'Isi Form Registrasi', 'Mengisi: Nama Lengkap, Email, No. WhatsApp, Nama Bisnis, Alamat, Kategori Bisnis, Jenis POS (resto/retail/jasa/fashion), Plan (UMKM/Bisnis/Franchise), dan Captcha.'),
  _docStep(accent, 3, 'Submit Form', 'Sistem memvalidasi captcha dan menyimpan data. Jika plan UMKM, is_paid otomatis true.'),
  _sectionTitle('FASE 2: Pembayaran'),
  _docStep(accent, 4, 'Plan Bisnis/Franchise', 'Sistem menampilkan QRIS barcode pembayaran. Tenant mentransfer dan mengirim bukti ke admin.'),
  _docStep(accent, 5, 'Plan UMKM (Gratis)', 'Langsung lanjut ke proses verifikasi tanpa perlu bayar.'),
  _sectionTitle('FASE 3: Notifikasi Super User'),
  _docStep(accent, 6, 'Telegram Bot', 'Sistem otomatis mengirim notifikasi ke chat Telegram admin dengan tombol [✅ Setujui] dan [❌ Tolak].'),
  _docStep(accent, 7, 'Update Status Bayar', 'Super User mengecek bukti bayar dan mengupdate is_paid → true di aplikasi admin.'),
  _sectionTitle('FASE 4: Aktivasi Otomatis'),
  _docStep(accent, 8, 'Klik Approve', 'Dari aplikasi atau Telegram, Super User menyetujui pendaftaran.'),
  _docStep(accent, 9, 'Provisioning Otomatis', 'Sistem membuat: Company → Branch HQ → User Admin → Password default (nfm12345).'),
  _docStep(accent, 10, 'Notifikasi WhatsApp', 'Kredensial login dikirim otomatis ke nomor WhatsApp tenant via Qontak API.'),
  _docStep(accent, 11, 'Seed Data', 'Sistem membuat 1 kategori dan 1 contoh produk sesuai jenis POS sebagai data awal.'),
  _docAlert(Icons.check_circle_outline, Colors.green, 'Tenant sudah bisa login ke aplikasi NFM POS dengan username dan password yang dikirim via WhatsApp.'),
];

List<Widget> _loginFlow(BuildContext ctx, Color accent) => [
  _docAlert(Icons.lock_outline, accent, 'Sistem menggunakan JWT (JSON Web Token) untuk autentikasi. Token disimpan di SharedPreferences dan dikirim via header Authorization.'),
  _sectionTitle('Langkah Login'),
  _docStep(accent, 1, 'Buka Aplikasi', 'User membuka aplikasi Flutter di browser atau desktop.'),
  _docStep(accent, 2, 'Cek Token', 'Jika token JWT masih valid di storage lokal, langsung redirect ke dashboard tanpa perlu login ulang.'),
  _docStep(accent, 3, 'Input Kredensial', 'Masukkan username dan password, lalu submit ke POST /api/login.'),
  _docStep(accent, 4, 'Deteksi Role', 'Sistem membaca role dari token JWT dan mengarahkan ke dashboard yang sesuai.'),
  _sectionTitle('Arah Berdasarkan Role'),
  _docCard(ctx, title: 'Super User', subtitle: 'Dashboard Executive + Statistik Global SaaS', icon: Icons.admin_panel_settings, color: Color(0xFF8B5CF6)),
  _docCard(ctx, title: 'Business Owner', subtitle: 'Dashboard Executive Cabang + Multi-Branch Report', icon: Icons.business_center, color: Color(0xFF0369A1)),
  _docCard(ctx, title: 'Kasir / Staff', subtitle: 'Layar POS + Cek Sesi Kasir', icon: Icons.point_of_sale, color: Color(0xFF059669)),
];

List<Widget> _transactionFlow(BuildContext ctx, Color accent) => [
  _sectionTitle('Prasyarat Transaksi'),
  _docAlert(Icons.warning_amber_outlined, Colors.orange, 'Kasir harus membuka sesi kasir terlebih dahulu sebelum dapat melakukan transaksi. Klik status sesi di sidebar.'),
  _sectionTitle('Langkah Transaksi'),
  _docStep(accent, 1, 'Buka Sesi Kasir', 'Input modal awal (kas di laci). Sesi dicatat dengan waktu mulai.'),
  _docStep(accent, 2, 'Pilih Meja (Resto)', 'Untuk tipe POS Resto, pilih meja yang statusnya "Kosong". Meja berubah status menjadi "Digunakan".'),
  _docStep(accent, 3, 'Pilih Produk', 'Cari dan tambahkan item ke keranjang. Atur quantity dan catatan per item.'),
  _docStep(accent, 4, 'Terapkan Promo', 'Opsional: pilih promo yang aktif (flat/persentase, ada min. order).'),
  _docStep(accent, 5, 'Buat Order', 'POST /api/orders — Sistem memvalidasi dan memotong stok secara atomik.'),
  _docStep(accent, 6, 'Proses Pembayaran', 'Pilih metode (Tunai/QRIS/Transfer). Input nominal, sistem hitung kembalian.'),
  _docStep(accent, 7, 'Cetak/Kirim Struk', 'Struk dikirim otomatis via WhatsApp ke customer (jika ada nomor HP).'),
  _sectionTitle('Logika Stok Saat Order'),
  _docCard(ctx, title: 'Resto & Jasa', subtitle: 'Potong stok via resep (MenuIngredient). Jika tidak ada resep, jual bebas tanpa batas.', icon: Icons.blender, color: Colors.orange),
  _docCard(ctx, title: 'Retail & Fashion', subtitle: 'Potong Menu.Stock langsung sesuai quantity order. Wajib ada stok.', icon: Icons.inventory_2, color: Colors.blue),
];

List<Widget> _voidFlow(BuildContext ctx, Color accent) => [
  _docAlert(Icons.cancel_outlined, Colors.red, 'Void hanya bisa dilakukan pada order yang BELUM dibayar. Order yang sudah dibayar harus di-refund manual.'),
  _sectionTitle('Proses Void'),
  _docStep(accent, 1, 'Pilih Order', 'Buka daftar order, pilih order yang ingin dibatalkan (status bukan Selesai).'),
  _docStep(accent, 2, 'Klik Void', 'POST /api/orders/:id/void — Input alasan pembatalan.'),
  _docStep(accent, 3, 'Pemulihan Stok Otomatis', 'Sistem membalikkan stok yang sudah dipotong saat order dibuat.'),
  _docStep(accent, 4, 'Bebaskan Meja', 'Jika ada meja yang terikat, status meja kembali menjadi "Kosong".'),
  _sectionTitle('Stok yang Dikembalikan'),
  _docCard(ctx, title: 'Retail & Fashion', subtitle: 'Menu.Stock += Qty item yang di-void', icon: Icons.inventory_2, color: Colors.blue),
  _docCard(ctx, title: 'Resto & Jasa (ada resep)', subtitle: 'Ingredient.Stock += Qty × QtyUsed per resep. StockHistory dicatat Type: VOID', icon: Icons.blender, color: Colors.orange),
  _docCard(ctx, title: 'Resto & Jasa (tanpa resep)', subtitle: 'Tidak ada stok yang dikembalikan', icon: Icons.block, color: Colors.grey),
];

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION 2: Panduan Super User
// ═══════════════════════════════════════════════════════════════════════════════

List<Widget> _superUserIntro(BuildContext ctx, Color accent) => [
  _docAlert(Icons.admin_panel_settings, accent, 'Super User adalah operator SaaS NFM Tech. Memiliki akses global ke seluruh data platform, termasuk statistik registrasi dan manajemen tenant.'),
  _sectionTitle('Kemampuan Eksklusif Super User'),
  _docCard(ctx, title: 'Statistik Global SaaS', subtitle: 'Total registrasi, registrasi lunas, distribusi jenis POS', icon: Icons.bar_chart, color: accent),
  _docCard(ctx, title: 'Approve Registrasi', subtitle: 'Buat akun tenant otomatis dengan 1 klik', icon: Icons.check_circle, color: Colors.green),
  _docCard(ctx, title: 'Update Data Pendaftar', subtitle: 'Ubah is_paid, pos_type, status kapan saja', icon: Icons.edit, color: Colors.blue),
  _docCard(ctx, title: 'Kelola Semua Tenant', subtitle: 'CRUD Company/Tenant dari seluruh platform', icon: Icons.corporate_fare, color: Colors.purple),
  _sectionTitle('Dashboard Eksklusif'),
  _tableRow('Total Registrasi', 'Semua pendaftar dari landing page'),
  const Divider(height: 12),
  _tableRow('Registrasi Lunas', 'is_paid = true atau Status = Approved'),
  const Divider(height: 12),
  _tableRow('Distribusi POS Resto', 'Jumlah tenant dengan pos_type = resto'),
  const Divider(height: 12),
  _tableRow('Distribusi POS Retail', 'Jumlah tenant dengan pos_type = retail'),
  const Divider(height: 12),
  _tableRow('Distribusi POS Jasa', 'Jumlah tenant dengan pos_type = jasa'),
  const Divider(height: 12),
  _tableRow('Distribusi POS Fashion', 'Jumlah tenant dengan pos_type = fashion'),
];

List<Widget> _registrationMgmt(BuildContext ctx, Color accent) => [
  _sectionTitle('Aksi yang Tersedia'),
  _docCard(ctx, title: 'Update Status Bayar', subtitle: 'PUT /api/registrations/:id  →  { "is_paid": true }', icon: Icons.payment, color: Colors.green),
  _docCard(ctx, title: 'Update Jenis POS', subtitle: 'PUT /api/registrations/:id  →  { "pos_type": "retail" }', icon: Icons.devices, color: Colors.blue),
  _docCard(ctx, title: 'Update Status', subtitle: 'PUT /api/registrations/:id  →  { "status": "Rejected" }', icon: Icons.toggle_on, color: Colors.orange),
  _docCard(ctx, title: 'Approve & Aktivasi', subtitle: 'POST /api/registrations/:id/approve  — Buat akun otomatis', icon: Icons.rocket_launch, color: accent),
  _docCard(ctx, title: 'Hapus Data', subtitle: 'DELETE /api/registrations/:id  — Untuk data spam/invalid', icon: Icons.delete, color: Colors.red),
  _sectionTitle('Nilai Valid Jenis POS'),
  Wrap(
    children: [
      _docBadge('resto', Colors.orange),
      _docBadge('retail', Colors.blue),
      _docBadge('jasa', Colors.green),
      _docBadge('fashion', Colors.purple),
    ],
  ),
  _sectionTitle('Nilai Valid Status'),
  Wrap(
    children: [
      _docBadge('Pending', Colors.grey),
      _docBadge('Approved', Colors.green),
      _docBadge('Rejected', Colors.red),
    ],
  ),
  _docAlert(Icons.warning_amber, Colors.orange, 'Pastikan is_paid = true sebelum approve. Approval bisa dilakukan tanpa is_paid, namun tidak disarankan untuk plan berbayar.'),
];

List<Widget> _telegramActivation(BuildContext ctx, Color accent) => [
  _docAlert(Icons.telegram, accent, 'Super User dapat menyetujui atau menolak pendaftaran langsung dari chat Telegram tanpa membuka aplikasi Flutter.'),
  _sectionTitle('Alur Notifikasi Telegram'),
  _docStep(accent, 1, 'Pendaftar Submit Form', 'Calon tenant mengisi form di landing page.'),
  _docStep(accent, 2, 'Bot Kirim Notifikasi', 'Backend otomatis mengirim pesan ke chat/grup Telegram admin dengan detail pendaftar dan 2 tombol inline keyboard.'),
  _docStep(accent, 3, 'Super User Klik Tombol', '[✅ Setujui & Buat Akun] atau [❌ Tolak]'),
  _docStep(accent, 4, 'Sistem Memproses', 'Bot mengirim request ke POST /api/registrations/:id/approve dengan header X-Bot-Token.'),
  _docStep(accent, 5, 'Akun Dibuat Otomatis', 'Company + Branch + User dibuat dalam 1 transaksi atomik.'),
  _docStep(accent, 6, 'WhatsApp ke Tenant', 'Kredensial login dikirim ke nomor HP tenant.'),
  _sectionTitle('Konfigurasi Environment (.env)'),
  Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.black87,
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Text(
      'TELEGRAM_BOT_TOKEN=your_bot_token\nTELEGRAM_CHAT_ID=your_chat_id_or_group\nCHAT_SECRET=your_secret_key',
      style: TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 13, height: 1.8),
    ),
  ),
];

List<Widget> _tenantMgmt(BuildContext ctx, Color accent) => [
  _docAlert(Icons.business, accent, 'Super User memiliki akses penuh ke manajemen Company/Tenant di menu Manajemen Perusahaan.'),
  _sectionTitle('Aksi Tersedia'),
  _docCard(ctx, title: 'Lihat Semua Tenant', subtitle: 'GET /api/companies — List semua company aktif/nonaktif', icon: Icons.list, color: accent),
  _docCard(ctx, title: 'Update Data Tenant', subtitle: 'PUT /api/companies/:id — Ubah nama, plan, pos_type, is_active', icon: Icons.edit, color: Colors.blue),
  _docCard(ctx, title: 'Upload Logo', subtitle: 'POST /api/companies/upload — Upload logo tenant', icon: Icons.image, color: Colors.green),
  _docCard(ctx, title: 'Nonaktifkan Tenant', subtitle: 'PUT /api/companies/:id  →  { "is_active": false }', icon: Icons.block, color: Colors.red),
  _sectionTitle('Field Penting Company'),
  _tableRow('pos_type', 'Menentukan fitur POS aktif (meja, resep, dll)'),
  const Divider(height: 12),
  _tableRow('subscription_plan', 'UMKM / Bisnis / Franchise'),
  const Divider(height: 12),
  _tableRow('is_active', 'true = aktif, false = tenant diblokir'),
  const Divider(height: 12),
  _tableRow('transaction_limit', 'Batas jumlah transaksi per periode'),
];

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION 3: Manajemen Stok
// ═══════════════════════════════════════════════════════════════════════════════

List<Widget> _stockLogic(BuildContext ctx, Color accent) => [
  _docAlert(Icons.info_outline, accent, 'Sistem stok berperilaku berbeda tergantung jenis POS. Perbedaan ini terjadi secara otomatis saat kasir membuat order.'),
  _sectionTitle('Retail & Fashion — Direct Stock'),
  _docCard(ctx, title: 'Menu.Stock dipotong langsung', subtitle: 'Saat order: Menu.Stock -= Qty. Saat void: Menu.Stock += Qty', icon: Icons.remove_shopping_cart, color: Colors.blue),
  _docAlert(Icons.warning_amber, Colors.blue, 'Jika Menu.Stock < Qty yang dipesan, transaksi akan GAGAL dengan pesan error stok habis.'),
  _sectionTitle('Resto & Jasa — Recipe-Based Stock'),
  _docCard(ctx, title: 'Pakai Resep (MenuIngredient)', subtitle: 'Potong Ingredient.Stock sesuai qty_used per resep. Catat di StockHistory.', icon: Icons.blender, color: Colors.orange),
  _docCard(ctx, title: 'Tanpa Resep', subtitle: 'Tidak ada stok yang dipotong. Produk bisa dijual tanpa batas (contoh: jasa konsultasi, layanan cuci tanpa bahan tercatat).', icon: Icons.all_inclusive, color: Colors.green),
  _sectionTitle('Tipe StockHistory'),
  _tableRow('IN', 'Stok masuk (Goods Receipt diapprove)'),
  const Divider(height: 12),
  _tableRow('OUT', 'Stok keluar (Goods Issue diapprove)'),
  const Divider(height: 12),
  _tableRow('ADJUST', 'Penyesuaian manual stok'),
  const Divider(height: 12),
  _tableRow('WASTE', 'Pembuangan/kerusakan barang'),
  const Divider(height: 12),
  _tableRow('VOID', 'Pembalikan stok akibat void order'),
];

List<Widget> _goodsReceipt(BuildContext ctx, Color accent) => [
  _docAlert(Icons.local_shipping, accent, 'Goods Receipt digunakan untuk mencatat penerimaan barang/bahan baku dari supplier.'),
  _sectionTitle('Alur Penerimaan Barang'),
  _docStep(accent, 1, 'Buat Draft GR', 'POST /api/inventory/receipts — Isi supplier, tanggal, dan item + qty.'),
  _docStep(accent, 2, 'Review Draft', 'Cek kesesuaian barang fisik dengan dokumen dari supplier.'),
  _docStep(accent, 3, 'Approve GR', 'PUT /api/inventory/receipts/:id/approve — Stok ingredient bertambah otomatis.'),
  _sectionTitle('Efek Approve'),
  _docCard(ctx, title: 'Ingredient.Stock bertambah', subtitle: '+= Quantity yang diterima sesuai GR', icon: Icons.add_circle, color: Colors.green),
  _docCard(ctx, title: 'StockHistory tercatat', subtitle: 'Type: IN, dicatat per ingredient dengan referensi Receipt ID', icon: Icons.history, color: Colors.blue),
];

List<Widget> _goodsIssue(BuildContext ctx, Color accent) => [
  _docAlert(Icons.output_outlined, accent, 'Goods Issue digunakan untuk mencatat pengeluaran barang di luar transaksi POS (waste, transfer, penyesuaian).'),
  _sectionTitle('Kategori Goods Issue'),
  _docCard(ctx, title: 'Waste', subtitle: 'Barang rusak, expired, atau terbuang', icon: Icons.delete_forever, color: Colors.red),
  _docCard(ctx, title: 'Transfer', subtitle: 'Pengiriman barang ke cabang lain', icon: Icons.swap_horiz, color: Colors.orange),
  _docCard(ctx, title: 'Sales Adjustment', subtitle: 'Koreksi stok akibat perbedaan perhitungan', icon: Icons.tune, color: Colors.blue),
  _sectionTitle('Alur'),
  _docStep(accent, 1, 'Buat Draft GI', 'POST /api/inventory/issues — Pilih kategori dan item.'),
  _docStep(accent, 2, 'Approve GI', 'PUT /api/inventory/issues/:id/approve — Stok berkurang otomatis.'),
];

List<Widget> _branchTransfer(BuildContext ctx, Color accent) => [
  _docAlert(Icons.swap_horiz, accent, 'Branch Order adalah mekanisme permintaan stok dari cabang ke kantor pusat.'),
  _sectionTitle('Alur Transfer Cabang'),
  _docStep(accent, 1, 'Cabang Buat Request', 'POST /api/inventory/branch-orders — Daftar item yang dibutuhkan.'),
  _docStep(accent, 2, 'Pusat Review & Approve', 'PUT /api/inventory/branch-orders/:id/status — Set qty yang disetujui.'),
  _docStep(accent, 3, 'Kirim Barang Fisik', 'Barang dikirim dari pusat ke cabang.'),
  _docStep(accent, 4, 'Cabang Terima (GR)', 'Cabang membuat Goods Receipt untuk mencatat penerimaan. Stok cabang bertambah.'),
];

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION 4: Technology Stack
// ═══════════════════════════════════════════════════════════════════════════════

List<Widget> _backendStack(BuildContext ctx, Color accent) => [
  _docCard(ctx, title: 'Bahasa: Go (Golang) 1.20+', subtitle: 'Performa tinggi, statically typed, compile ke binary tunggal', icon: Icons.code, color: accent),
  _docCard(ctx, title: 'Framework: Gin Web Framework', subtitle: 'HTTP routing cepat dengan middleware support', icon: Icons.electrical_services, color: accent),
  _docCard(ctx, title: 'ORM: GORM v2', subtitle: 'Object-Relational Mapping + AutoMigrate schema', icon: Icons.storage, color: accent),
  _docCard(ctx, title: 'Database: PostgreSQL 14+', subtitle: 'ACID-compliant, relational, production-grade', icon: Icons.dns, color: Colors.blue),
  _docCard(ctx, title: 'Auth: JWT + bcrypt', subtitle: 'Stateless JWT token, password hashed dengan bcrypt', icon: Icons.security, color: Colors.green),
  _docCard(ctx, title: 'Rate Limiter', subtitle: '5 request per 10 menit per IP untuk endpoint registrasi', icon: Icons.speed, color: Colors.orange),
];

List<Widget> _frontendStack(BuildContext ctx, Color accent) => [
  _docCard(ctx, title: 'Framework: Flutter 3.x', subtitle: 'Multi-platform: Web, Windows, Android, iOS dari 1 codebase', icon: Icons.flutter_dash, color: accent),
  _docCard(ctx, title: 'Bahasa: Dart 3.0+', subtitle: 'Typed, null-safe, compiled language', icon: Icons.code, color: accent),
  _docCard(ctx, title: 'State: Flutter Riverpod v2', subtitle: 'Reactive state management, FutureProvider, autoDispose', icon: Icons.manage_accounts, color: Colors.blue),
  _docCard(ctx, title: 'HTTP: Dio v5', subtitle: 'Advanced client dengan JWT interceptor otomatis', icon: Icons.wifi, color: Colors.green),
  _docCard(ctx, title: 'Routing: Go Router v10', subtitle: 'Declarative routing dengan auth guard', icon: Icons.route, color: Colors.orange),
  _docCard(ctx, title: 'Charts: FL Chart', subtitle: 'Grafik laporan penjualan interaktif', icon: Icons.bar_chart, color: Colors.purple),
];

List<Widget> _botStack(BuildContext ctx, Color accent) => [
  _docCard(ctx, title: 'Telegram Bot (Python)', subtitle: 'pyTelegramBotAPI — Polling & callback handler untuk approval', icon: Icons.telegram, color: accent),
  _docCard(ctx, title: 'Flask (Python)', subtitle: 'Proxy webhook & health endpoint untuk bot', icon: Icons.web, color: accent),
  _docCard(ctx, title: 'WhatsApp: Qontak API', subtitle: 'Kirim notifikasi aktivasi dan struk via Qontak Omnichannel', icon: Icons.message, color: Colors.green),
  _docCard(ctx, title: 'AI Chatbot: Gemini', subtitle: 'Asisten chatbot menu berbasis AI (via proxy backend)', icon: Icons.smart_toy, color: Colors.blue),
  _docCard(ctx, title: 'Landing Page: React + Vite', subtitle: 'Halaman pemasaran & form registrasi. Framer Motion untuk animasi.', icon: Icons.web_asset, color: Colors.orange),
];

List<Widget> _dbStack(BuildContext ctx, Color accent) => [
  _docCard(ctx, title: 'PostgreSQL 14+', subtitle: 'Database utama. GORM AutoMigrate saat startup backend.', icon: Icons.storage, color: accent),
  _docCard(ctx, title: 'Docker Compose', subtitle: 'Containerization seluruh service (backend, db, bot)', icon: Icons.inventory_2, color: Colors.blue),
  _docCard(ctx, title: 'File Storage', subtitle: 'Upload gambar disimpan di /uploads (local). Diakses via /uploads/ endpoint.', icon: Icons.folder, color: Colors.green),
  _docCard(ctx, title: 'Deployment: deploy.sh', subtitle: 'Bash script untuk deploy production otomatis', icon: Icons.terminal, color: Colors.orange),
  _sectionTitle('Environment Variables Penting'),
  Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)),
    child: const Text(
      'DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME\nJWT_SECRET\nWHATSAPP_API_KEY, WHATSAPP_CHANNEL_ID\nTELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID\nCHAT_SECRET\nPORT (default: 8080)',
      style: TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12, height: 1.8),
    ),
  ),
];

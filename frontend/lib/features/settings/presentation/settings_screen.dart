import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/theme_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _taxController = TextEditingController();
  final _serviceController = TextEditingController();
  final _waSenderController = TextEditingController();
  final _appNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  List<dynamic> _accounts = [];
  String? _accSalesId;
  String? _accCashId;
  String? _accTaxId;
  String? _accServiceId;
  String? _accHppId;
  String? _accInventoryId;
  String? _logoUrl;
  bool _isLoading = false;

  @override
  void dispose() {
    _taxController.dispose();
    _serviceController.dispose();
    _waSenderController.dispose();
    _appNameController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadAccounts(),
      _loadSettings(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadAccounts() async {
    try {
      final res = await ref.read(dioProvider).get('finance/coa');
      _accounts = res.data;
    } catch (e) {
      debugPrint('Error loading accounts: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final data = await ref.read(settingsProvider.future);
      setState(() {
        _taxController.text = (data['tax_pct'] ?? '10').toString();
        _serviceController.text = (data['service_charge_pct'] ?? '0').toString();
        _waSenderController.text = (data['wa_sender_number'] ?? '').toString();
        _accSalesId = data['acc_sales_id']?.toString();
        _accCashId = data['acc_cash_id']?.toString();
        _accTaxId = data['acc_tax_id']?.toString();
        _accServiceId = data['acc_service_id']?.toString();
        _accHppId = data['acc_hpp_id']?.toString();
        _accInventoryId = data['acc_inventory_id']?.toString();
        _logoUrl = data['logo_url']?.toString();
        _appNameController.text = data['app_name']?.toString() ?? 'NFM POS';
        _companyNameController.text = data['company_name']?.toString() ?? 'NFM Technology';
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat pengaturan: $e')));
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(dioProvider).post('settings', data: {
        'tax_pct': _taxController.text,
        'service_charge_pct': _serviceController.text,
        'wa_sender_number': _waSenderController.text,
        'acc_sales_id': _accSalesId,
        'acc_cash_id': _accCashId,
        'acc_tax_id': _accTaxId,
        'acc_service_id': _accServiceId,
        'acc_hpp_id': _accHppId,
        'acc_inventory_id': _accInventoryId,
        'logo_url': _logoUrl,
        'app_name': _appNameController.text,
        'company_name': _companyNameController.text,
      });
      if (mounted) {
        ref.invalidate(settingsProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Pengaturan berhasil disimpan')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isLoading = true);
      
      final bytes = await image.readAsBytes();
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(bytes, filename: image.name),
      });

      final res = await ref.read(dioProvider).post('settings/logo', data: formData);
      setState(() {
        _logoUrl = res.data['url'];
        _isLoading = false;
      });
      // Save it immediately or via the save button
      await _saveSettings();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal upload logo: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeSettings = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Sistem')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─── Logo \u0026 Branding ─────────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Logo \u0026 Branding', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceVariant.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(16),
                                  image: (_logoUrl != null && _logoUrl!.isNotEmpty && _logoUrl != '/')
                                      ? DecorationImage(
                                          image: NetworkImage('${ref.watch(imageBaseUrlProvider)}$_logoUrl'),
                                          fit: BoxFit.contain,
                                        )
                                      : null,
                                ),
                                child: (_logoUrl == null || _logoUrl!.isEmpty || _logoUrl == '/')
                                    ? const Icon(Icons.restaurant, size: 40, color: Colors.grey)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: IconButton.filled(
                                  onPressed: _pickLogo,
                                  icon: const Icon(Icons.edit, size: 16),
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              children: [
                                TextField(
                                  controller: _appNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nama Aplikasi (POS)',
                                    hintText: 'Contoh: NFM POS',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _companyNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nama Perusahaan Induk',
                                    hintText: 'Contoh: NFM Technology',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Logo dan identitas ini akan muncul di halaman login dan laporan.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // ─── Theme / Skin ──────────────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tema & Tampilan (Skin)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      // ─── Mode Toggle ───────────────────────────────────
                      const Text('Mode Tampilan', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 8),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(value: ThemeMode.system, label: Text('Otomatis'), icon: Icon(Icons.brightness_auto, size: 16)),
                          ButtonSegment(value: ThemeMode.light, label: Text('Terang'), icon: Icon(Icons.light_mode, size: 16)),
                          ButtonSegment(value: ThemeMode.dark, label: Text('Gelap'), icon: Icon(Icons.dark_mode, size: 16)),
                        ],
                        selected: {themeSettings.themeMode},
                        onSelectionChanged: (Set<ThemeMode> newSelection) {
                          themeNotifier.setThemeMode(newSelection.first);
                        },
                      ),
                      const SizedBox(height: 24),
                      // ─── Color Presets ─────────────────────────────────
                      Row(
                        children: [
                          const Text('Warna Tema', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          const Spacer(),
                          Container(
                            width: 20, height: 20,
                            decoration: BoxDecoration(
                              color: themeSettings.seedColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white30, width: 2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '#${themeSettings.seedColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildColorDot(const Color(0xFF2E7D32), 'Hijau Hutan', themeSettings.seedColor, themeNotifier),
                          _buildColorDot(const Color(0xFF00695C), 'Teal Gelap', themeSettings.seedColor, themeNotifier),
                          _buildColorDot(const Color(0xFF1565C0), 'Biru Gelap', themeSettings.seedColor, themeNotifier),
                          _buildColorDot(const Color(0xFF283593), 'Indigo', themeSettings.seedColor, themeNotifier),
                          _buildColorDot(const Color(0xFF6A1B9A), 'Ungu', themeSettings.seedColor, themeNotifier),
                          _buildColorDot(const Color(0xFFAD1457), 'Pink Gelap', themeSettings.seedColor, themeNotifier),
                          _buildColorDot(const Color(0xFFC62828), 'Merah', themeSettings.seedColor, themeNotifier),
                          _buildColorDot(const Color(0xFFE65100), 'Oranye', themeSettings.seedColor, themeNotifier),
                          _buildColorDot(const Color(0xFFF57F17), 'Kuning Tua', themeSettings.seedColor, themeNotifier),
                          _buildColorDot(const Color(0xFF558B2F), 'Hijau Lime', themeSettings.seedColor, themeNotifier),
                          _buildColorDot(const Color(0xFF00838F), 'Cyan', themeSettings.seedColor, themeNotifier),
                          _buildColorDot(const Color(0xFF0277BD), 'Biru Cerah', themeSettings.seedColor, themeNotifier),
                          _buildColorDot(const Color(0xFF37474F), 'Abu-Abu', themeSettings.seedColor, themeNotifier),
                          _buildColorDot(const Color(0xFF212121), 'Hitam', themeSettings.seedColor, themeNotifier),
                          _buildColorDot(const Color(0xFF4E342E), 'Coklat', themeSettings.seedColor, themeNotifier),
                          _buildColorDot(const Color(0xFF00796B), 'Hijau Mint', themeSettings.seedColor, themeNotifier),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Konfigurasi Pajak & Layanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _taxController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Pajak / PPN (%)',
                          suffixText: '%',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _serviceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Service Charge (%)',
                          suffixText: '%',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Konfigurasi WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _waSenderController,
                        decoration: const InputDecoration(
                          labelText: 'Nomor WhatsApp Pengirim',
                          hintText: 'Contoh: 081234567890',
                          prefixIcon: Icon(Icons.message),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Nomor ini akan muncul sebagai pengirim struk digital.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pemetaan Akun Jurnal (Posting)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text('Pilih akun yang akan digunakan untuk posting otomatis saat transaksi.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 16),
                      _buildAccountDropdown('Akun Kas/Bank', _accCashId, (v) => setState(() => _accCashId = v)),
                      _buildAccountDropdown('Akun Pendapatan Penjualan', _accSalesId, (v) => setState(() => _accSalesId = v)),
                      _buildAccountDropdown('Akun Hutang PPN (Pajak)', _accTaxId, (v) => setState(() => _accTaxId = v)),
                      _buildAccountDropdown('Akun Pendapatan Service Charge', _accServiceId, (v) => setState(() => _accServiceId = v)),
                      _buildAccountDropdown('Akun Biaya HPP', _accHppId, (v) => setState(() => _accHppId = v)),
                      _buildAccountDropdown('Akun Persediaan (Inventory)', _accInventoryId, (v) => setState(() => _accInventoryId = v)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: FilledButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text('Simpan Semua Pengaturan'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
    );
  }

  Widget _buildAccountDropdown(String label, String? value, ValueChanged<String?> onChanged) {
    // Ensure value exists in accounts or is null
    final items = _accounts.map((a) {
      return DropdownMenuItem<String>(
        value: a['id'].toString(),
        child: Text('${a['code']} - ${a['name']}'),
      );
    }).toList();

    // Safety: ensure the 'value' is actually one of the options
    final bool valueExists = items.any((item) => item.value == value);
    final String? effectiveValue = valueExists ? value : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        value: effectiveValue,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        isExpanded: true,
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildColorDot(Color color, String name, Color selectedColor, ThemeNotifier notifier) {
    final isSelected = color.value == selectedColor.value;
    return Tooltip(
      message: name,
      preferBelow: false,
      child: GestureDetector(
        onTap: () => notifier.setSeedColor(color),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(color: Colors.white, width: 3)
                : Border.all(color: Colors.white24, width: 2),
            boxShadow: isSelected
                ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 10, spreadRadius: 2)]
                : [],
          ),
          child: isSelected
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : null,
        ),
      ),
    );
  }
}

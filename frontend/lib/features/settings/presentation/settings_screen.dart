import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _taxController = TextEditingController();
  final _serviceController = TextEditingController();
  final _waSenderController = TextEditingController();
  List<dynamic> _accounts = [];
  String? _accSalesId;
  String? _accCashId;
  String? _accTaxId;
  String? _accServiceId;
  String? _accHppId;
  String? _accInventoryId;
  bool _isLoading = false;

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
      final res = await ref.read(dioProvider).get('settings');
      final data = res.data as Map<String, dynamic>;
      _taxController.text = data['tax_pct'] ?? '10';
      _serviceController.text = data['service_charge_pct'] ?? '0';
      _waSenderController.text = data['wa_sender_number'] ?? '';
      _accSalesId = data['acc_sales_id'];
      _accCashId = data['acc_cash_id'];
      _accTaxId = data['acc_tax_id'];
      _accServiceId = data['acc_service_id'];
      _accHppId = data['acc_hpp_id'];
      _accInventoryId = data['acc_inventory_id'];
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
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Pengaturan berhasil disimpan')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Sistem')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Konfigurasi Pajak \u0026 Layanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
}

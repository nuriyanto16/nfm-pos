import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/network/dio_client.dart';
import 'report_provider.dart';

class FinancialReportScreen extends ConsumerStatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  ConsumerState<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends ConsumerState<FinancialReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    // Stable key for family provider
    final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(_endDate);
    final paramsKey = '$startStr|$endStr';

    final reportAsync = ref.watch(financialReportProvider(paramsKey));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download CSV',
            onPressed: () => _downloadCSV(context),
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _selectDateRange(context),
          ),
        ],
      ),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Periode: ${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                style: TextStyle(color: colorScheme.outline, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Summary Cards
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _SummaryItem(
                    title: 'Total Pendapatan',
                    value: formatRupiah((data['total_revenue'] as num? ?? 0).toDouble()),
                    icon: Icons.payments_outlined,
                    color: colorScheme.primary,
                  ),
                  _SummaryItem(
                    title: 'Total Pesanan',
                    value: '${data['total_orders'] ?? 0}',
                    icon: Icons.shopping_bag_outlined,
                    color: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Payment Summary
              const Text('Ringkasan Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildPaymentSummary(data['payment_summary'] ?? [], colorScheme),
              const SizedBox(height: 24),

              // Best Sellers
              const Text('Menu Terlaris', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildBestSellers(data['best_sellers'] ?? [], colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _SummaryItem({required String title, required String value, required IconData icon, required Color color}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate width for 2 columns on mobile, more on desktop
        final width = MediaQuery.of(context).size.width;
        final cardWidth = width > 600 ? 250.0 : (width - 48) / 2;
        
        return Container(
          width: cardWidth,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color),
                  const SizedBox(height: 8),
                  Text(title, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildPaymentSummary(List<dynamic> items, ColorScheme colorScheme) {
    if (items.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No payment data')));
    
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final item = items[i];
          return ListTile(
            title: Text(item['method'] ?? 'Unknown'),
            subtitle: Text('${item['count']} transaksi'),
            trailing: Text(formatRupiah((item['total'] as num).toDouble()), style: const TextStyle(fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }

  Widget _buildBestSellers(List<dynamic> items, ColorScheme colorScheme) {
    if (items.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No sales data')));

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final item = items[i];
          return ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text(item['name']),
            subtitle: Text('${item['quantity']} terjual'),
            trailing: Text(formatRupiah((item['revenue'] as num).toDouble()), style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _downloadCSV(BuildContext context) async {
    final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(_endDate);
    
    // In a real app we'd construct the base URL dynamically or from env
    final baseUrl = ref.read(dioProvider).options.baseUrl;
    final exportUrl = '${baseUrl}reports/financial/export?start_date=$startStr&end_date=$endStr';
    
    final uri = Uri.parse(exportUrl);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka URL download')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

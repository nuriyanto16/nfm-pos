import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/currency_formatter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

class SalesReportScreen extends ConsumerStatefulWidget {
  const SalesReportScreen({super.key});

  @override
  ConsumerState<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends ConsumerState<SalesReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String? _selectedBranch;
  String? _selectedPayment;
  String? _selectedSource;
  String? _selectedDelivery;
  
  List<dynamic> _branches = [];
  List<dynamic> _data = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBranches();
    _fetchReport();
  }

  Future<void> _loadBranches() async {
    try {
      final res = await ref.read(dioProvider).get('branches');
      final data = res.data;
      setState(() {
        if (data is Map && data.containsKey('rows')) {
          _branches = data['rows'] ?? [];
        } else if (data is List) {
          _branches = data;
        } else {
          _branches = [];
        }
      });
    } catch (e) {
      debugPrint('Error loading branches: $e');
    }
  }

  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('reports/sales', queryParameters: {
        'start_date': DateFormat('yyyy-MM-dd').format(_startDate),
        'end_date': DateFormat('yyyy-MM-dd').format(_endDate),
        'branch_id': _selectedBranch,
        'payment_method': _selectedPayment,
        'order_source': _selectedSource,
        'delivery_method': _selectedDelivery,
      });
      setState(() => _data = res.data);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _exportExcel() {
    if (_data.isEmpty) return;
    
    // Create CSV content
    String csv = 'ID,Tanggal,Cabang,Pelanggan,Total,Pajak,Service,Diskon,Sumber,Metode,Metode Bayar,Status\n';
    for (var row in _data) {
      final date = DateTime.parse(row['created_at']).toLocal();
      csv += '${row['id']},'
          '${DateFormat('yyyy-MM-dd HH:mm').format(date)},'
          '"${row['branch_name']}",'
          '"${row['customer_name']}",'
          '${row['total_amount']},'
          '${row['tax_amount']},'
          '${row['service_charge']},'
          '${row['discount_amount']},'
          '"${row['order_source']}",'
          '"${row['delivery_method']}",'
          '"${row['payment_method']}",'
          '"${row['status']}"\n';
    }

    final bytes = utf8.encode(csv);
    final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'text/csv'));
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = 'Laporan_Penjualan_${DateFormat('yyyyMMdd').format(_startDate)}_${DateFormat('yyyyMMdd').format(_endDate)}.csv';
    anchor.click();
    web.URL.revokeObjectURL(url);
  }

  Future<void> _exportPDF() async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Laporan Penjualan Detail', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18))),
          pw.Text('Periode: ${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}'),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['ID', 'Tanggal', 'Cabang', 'Pelanggan', 'Total', 'Sumber', 'Metode', 'Bayar'],
            data: _data.map((row) {
              final date = DateTime.parse(row['created_at']).toLocal();
              return [
                row['id'].toString(),
                DateFormat('dd/MM/yy HH:mm').format(date),
                row['branch_name'] ?? '-',
                row['customer_name'] ?? '-',
                formatRupiah(row['total_amount']),
                row['order_source'] ?? '-',
                row['delivery_method'] ?? '-',
                row['payment_method'] ?? '-',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan Detail'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchReport),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (isMobile) ...[
                    _buildDateRangeButton(context),
                    const SizedBox(height: 12),
                    _buildBranchDropdown(),
                    const SizedBox(height: 12),
                    _buildSourceDropdown(),
                    const SizedBox(height: 12),
                    _buildDeliveryDropdown(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _fetchReport,
                        icon: const Icon(Icons.search),
                        label: const Text('Filter Laporan'),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(child: _buildDateRangeButton(context)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildBranchDropdown()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildSourceDropdown()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDeliveryDropdown()),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: _fetchReport,
                          icon: const Icon(Icons.search),
                          label: const Text('Filter'),
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Action Buttons & Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: isMobile 
              ? Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_data.length} Transaksi', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Total: ${formatRupiah(_data.fold(0.0, (sum, item) => sum + (item['total_amount'] as num).toDouble()))}', 
                          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: OutlinedButton.icon(onPressed: _exportExcel, icon: const Icon(Icons.table_view, size: 18), label: const Text('Excel'))),
                        const SizedBox(width: 8),
                        Expanded(child: OutlinedButton.icon(onPressed: _exportPDF, icon: const Icon(Icons.picture_as_pdf, size: 18), label: const Text('PDF'))),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Text('${_data.length} Transaksi Ditemukan', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    OutlinedButton.icon(onPressed: _exportExcel, icon: const Icon(Icons.table_view), label: const Text('Excel (CSV)')),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(onPressed: _exportPDF, icon: const Icon(Icons.picture_as_pdf), label: const Text('PDF')),
                  ],
                ),
          ),

          // Data Display
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _data.isEmpty 
                ? const Center(child: Text('Tidak ada data'))
                : isMobile 
                  ? _buildMobileList(colorScheme)
                  : _buildDesktopTable(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDateRangePicker(
          context: context,
          initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            _startDate = picked.start;
            _endDate = picked.end;
          });
        }
      },
      icon: const Icon(Icons.date_range),
      label: Text('${DateFormat('dd/MM/yy').format(_startDate)} - ${DateFormat('dd/MM/yy').format(_endDate)}'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 56),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  Widget _buildBranchDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBranch,
      decoration: const InputDecoration(labelText: 'Cabang', border: OutlineInputBorder()),
      items: [
        const DropdownMenuItem(value: null, child: Text('Semua Cabang')),
        ..._branches.map((b) => DropdownMenuItem(value: b['id'].toString(), child: Text(b['name']))),
      ],
      onChanged: (v) => setState(() => _selectedBranch = v),
    );
  }

  Widget _buildSourceDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSource,
      decoration: const InputDecoration(labelText: 'Sumber Order', border: OutlineInputBorder()),
      items: [
        const DropdownMenuItem(value: null, child: Text('Semua Sumber')),
        ...['Resto', 'Online', 'Shopee Food', 'Go Food', 'Grab Food'].map((s) => DropdownMenuItem(value: s, child: Text(s))),
      ],
      onChanged: (v) => setState(() => _selectedSource = v),
    );
  }

  Widget _buildDeliveryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedDelivery,
      decoration: const InputDecoration(labelText: 'Metode Pengiriman', border: OutlineInputBorder()),
      items: [
        const DropdownMenuItem(value: null, child: Text('Semua Metode')),
        ...['Makan di Tempat', 'Bawa Pulang', 'Pengiriman'].map((s) => DropdownMenuItem(value: s, child: Text(s))),
      ],
      onChanged: (v) => setState(() => _selectedDelivery = v),
    );
  }

  Widget _buildDesktopTable(ColorScheme colorScheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(colorScheme.primaryContainer.withOpacity(0.5)),
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Tanggal')),
              DataColumn(label: Text('Cabang')),
              DataColumn(label: Text('Pelanggan')),
              DataColumn(label: Text('Total')),
              DataColumn(label: Text('Sumber')),
              DataColumn(label: Text('Metode')),
              DataColumn(label: Text('Pembayaran')),
              DataColumn(label: Text('Status')),
            ],
            rows: _data.map((row) {
              final date = DateTime.parse(row['created_at']).toLocal();
              return DataRow(cells: [
                DataCell(Text('#${row['id']}')),
                DataCell(Text(DateFormat('dd/MM/yy HH:mm').format(date))),
                DataCell(Text(row['branch_name'] ?? '-')),
                DataCell(Text(row['customer_name'] ?? '-')),
                DataCell(Text(formatRupiah((row['total_amount'] as num).toDouble()))),
                DataCell(Text(row['order_source'] ?? '-')),
                DataCell(Text(row['delivery_method'] ?? '-')),
                DataCell(Text(row['payment_method'] ?? '-')),
                DataCell(_buildStatusBadge(row['status'])),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _data.length,
      itemBuilder: (context, index) {
        final row = _data[index];
        final date = DateTime.parse(row['created_at']).toLocal();
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: ExpansionTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#${row['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(formatRupiah((row['total_amount'] as num).toDouble()), 
                  style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            subtitle: Text(
              '${DateFormat('dd MMM, HH:mm').format(date)} • ${row['branch_name'] ?? "-"}',
              style: TextStyle(fontSize: 12, color: colorScheme.outline),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              _buildDetailRow('Pelanggan', row['customer_name'] ?? '-'),
              _buildDetailRow('Sumber', row['order_source'] ?? '-'),
              _buildDetailRow('Metode', row['delivery_method'] ?? '-'),
              _buildDetailRow('Pembayaran', row['payment_method'] ?? '-'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Status:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  _buildStatusBadge(row['status']),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isSuccess = status == 'Selesai';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status, 
        style: TextStyle(
          color: isSuccess ? Colors.green : Colors.orange, 
          fontSize: 11, 
          fontWeight: FontWeight.bold
        )
      ),
    );
  }
}

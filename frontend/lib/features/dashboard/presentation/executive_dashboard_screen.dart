import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/currency_formatter.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../shared/widgets/sidebar_layout.dart';
import '../../../shared/widgets/skeleton.dart';

final executiveDashboardPosTypeProvider = StateProvider<String>((ref) => '');

final executiveDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final posType = ref.watch(executiveDashboardPosTypeProvider);
  final queryParameters = posType.isNotEmpty ? {'pos_type': posType} : <String, dynamic>{};
  final res = await dio.get('dashboard/executive', queryParameters: queryParameters);
  return res.data as Map<String, dynamic>;
});

class ExecutiveDashboardScreen extends ConsumerWidget {
  const ExecutiveDashboardScreen({super.key});

  Widget _buildFilterChip(BuildContext context, WidgetRef ref, String value, String label, IconData icon) {
    final activePosType = ref.watch(executiveDashboardPosTypeProvider);
    final isSelected = activePosType == value;
    final colorScheme = Theme.of(context).colorScheme;

    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : colorScheme.onSurfaceVariant),
      label: Text(label),
      selected: isSelected,
      selectedColor: colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          ref.read(executiveDashboardPosTypeProvider.notifier).state = value;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(executiveDashboardProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 700;
    final authMeAsync = ref.watch(authMeProvider);
    final isSuperUser = authMeAsync.maybeWhen(
      data: (user) => user['role']?['name'] == 'Super User',
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Executive', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: statsAsync.when(
        loading: () => _buildDashboardSkeleton(context, isMobile),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) => RefreshIndicator(
          onRefresh: () => ref.refresh(executiveDashboardProvider.future),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSuperUser) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(context, ref, '', 'Semua POS', Icons.all_inclusive),
                        const SizedBox(width: 8),
                        _buildFilterChip(context, ref, 'resto', 'Restoran / Cafe', Icons.restaurant),
                        const SizedBox(width: 8),
                        _buildFilterChip(context, ref, 'retail', 'Retail / Toko', Icons.storefront),
                        const SizedBox(width: 8),
                        _buildFilterChip(context, ref, 'fashion', 'Fashion', Icons.checkroom),
                        const SizedBox(width: 8),
                        _buildFilterChip(context, ref, 'jasa', 'Jasa / Laundry', Icons.dry_cleaning),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (isSuperUser && stats['total_registrations'] != null) ...[
                  _buildSuperUserStatsCard(context, stats, colorScheme, isMobile),
                  const SizedBox(height: 20),
                ],
                _buildSummaryCards(stats, colorScheme, isMobile),
                const SizedBox(height: 20),
                
                if (!isMobile)
                  Row(
                    children: [
                      Expanded(child: _buildRevenueChart(stats, colorScheme, isMobile)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildMonthlyRevenueChart(stats, colorScheme, isMobile)),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildRevenueChart(stats, colorScheme, isMobile),
                      const SizedBox(height: 20),
                      _buildMonthlyRevenueChart(stats, colorScheme, isMobile),
                    ],
                  ),
                  
                const SizedBox(height: 20),
                
                if (!isMobile)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildBranchPerformance(stats, colorScheme)),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildBranchOrderTracking(stats, colorScheme),
                            const SizedBox(height: 20),
                            _buildBranchOrderList(stats, colorScheme),
                            const SizedBox(height: 20),
                            _buildRecentActivities(stats, colorScheme),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildBranchPerformance(stats, colorScheme),
                      const SizedBox(height: 20),
                      _buildBranchOrderTracking(stats, colorScheme),
                      const SizedBox(height: 20),
                      _buildBranchOrderList(stats, colorScheme),
                      const SizedBox(height: 20),
                      _buildRecentActivities(stats, colorScheme),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> stats, ColorScheme colorScheme, bool isMobile) {
    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isMobile ? 1.6 : 2.0,
      children: [
        _StatCard(
          title: 'Total Pendapatan',
          value: formatRupiah((stats['total_revenue'] as num).toDouble()),
          icon: Icons.payments,
          colors: const [Colors.green, Colors.teal],
        ),
        _StatCard(
          title: 'Total Transaksi',
          value: stats['total_orders'].toString(),
          icon: Icons.shopping_bag,
          colors: const [Colors.blue, Colors.indigo],
        ),
        _StatCard(
          title: 'Jumlah Cabang',
          value: stats['total_branches'].toString(),
          icon: Icons.store,
          colors: const [Colors.orange, Colors.deepOrange],
        ),
        _StatCard(
          title: 'Jumlah User',
          value: stats['total_users'].toString(),
          icon: Icons.people,
          colors: const [Colors.purple, Colors.deepPurple],
        ),
      ],
    );
  }

  Widget _buildBranchPerformance(Map<String, dynamic> stats, ColorScheme colorScheme) {
    final list = stats['branch_performance'] as List? ?? [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Performa Cabang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (list.isEmpty) const Text('Belum ada data')
            else Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: colorScheme.surfaceVariant.withOpacity(0.3)),
                  children: const [
                    Padding(padding: EdgeInsets.all(12), child: Text('Nama Cabang', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(12), child: Text('Transaksi', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(12), child: Text('Pendapatan', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                ...list.map((b) => TableRow(
                  children: [
                    Padding(padding: const EdgeInsets.all(12), child: Text(b['name'])),
                    Padding(padding: const EdgeInsets.all(12), child: Text(b['orders'].toString())),
                    Padding(padding: const EdgeInsets.all(12), child: Text(formatRupiah((b['revenue'] as num).toDouble()))),
                  ],
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart(Map<String, dynamic> stats, ColorScheme colorScheme, bool isMobile) {
    final chartData = stats['revenue_chart'] as List? ?? [];
    if (chartData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Belum ada data tren pendapatan')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tren Pendapatan (7 Hari)', style: TextStyle(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: isMobile ? 180 : 200,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: colorScheme.surfaceContainerHighest,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((s) {
                          return LineTooltipItem(
                            formatRupiah(s.y),
                            TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          if (val == 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(formatRupiahCompact(val), style: const TextStyle(fontSize: 9), textAlign: TextAlign.right),
                          );
                        },
                        reservedSize: 60,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          if (val.toInt() < 0 || val.toInt() >= chartData.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(chartData[val.toInt()]['label'] ?? '', style: const TextStyle(fontSize: 10)),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['value'] as num).toDouble())).toList(),
                      isCurved: true,
                      color: colorScheme.primary,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: colorScheme.primary.withOpacity(0.1)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyRevenueChart(Map<String, dynamic> stats, ColorScheme colorScheme, bool isMobile) {
    final chartData = stats['monthly_revenue_chart'] as List? ?? [];
    if (chartData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Belum ada data tren pendapatan')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tren Bulanan', style: TextStyle(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: isMobile ? 180 : 200,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: colorScheme.surfaceContainerHighest,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((s) {
                          return LineTooltipItem(
                            formatRupiah(s.y),
                            TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          if (val == 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(formatRupiahCompact(val), style: const TextStyle(fontSize: 9), textAlign: TextAlign.right),
                          );
                        },
                        reservedSize: 60,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          if (val.toInt() < 0 || val.toInt() >= chartData.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(chartData[val.toInt()]['label'] ?? '', style: const TextStyle(fontSize: 10)),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['value'] as num).toDouble())).toList(),
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: Colors.orange.withOpacity(0.1)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchOrderTracking(Map<String, dynamic> stats, ColorScheme colorScheme) {
    final orderStats = stats['branch_order_stats'] ?? {};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.blue, size: 18),
                SizedBox(width: 8),
                Text('Tracking Order', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            _buildTrackingRow('Pending Request', orderStats['pending'] ?? 0, Colors.orange),
            const Divider(),
            _buildTrackingRow('Disetujui / Proses', orderStats['approved'] ?? 0, Colors.blue),
            const Divider(),
            _buildTrackingRow('Selesai / Terkirim', orderStats['fulfilled'] ?? 0, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingRow(String label, dynamic value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(value.toString(), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchOrderList(Map<String, dynamic> stats, ColorScheme colorScheme) {
    final list = stats['recent_branch_orders'] as List? ?? [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, color: Colors.blueGrey, size: 18),
                SizedBox(width: 8),
                Text('Request Terbaru', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            if (list.isEmpty) const Text('Belum ada request'),
            ...list.map((o) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(o['order_no'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(o['branch']?['name'] ?? '-'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getBranchOrderStatusColor(o['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  o['status'] ?? 'Pending',
                  style: TextStyle(fontSize: 10, color: _getBranchOrderStatusColor(o['status']), fontWeight: FontWeight.bold),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Color _getBranchOrderStatusColor(String? status) {
    switch (status) {
      case 'Pending': return Colors.orange;
      case 'Approved': return Colors.blue;
      case 'Fulfilled': return Colors.green;
      default: return Colors.grey;
    }
  }

  Widget _buildRecentActivities(Map<String, dynamic> stats, ColorScheme colorScheme) {
    final receipts = stats['recent_receipts'] as List? ?? [];
    final issues = stats['recent_issues'] as List? ?? [];

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.input, color: Colors.green, size: 18),
                    SizedBox(width: 8),
                    Text('Barang Masuk', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ...receipts.map((r) => ListTile(
                  dense: true,
                  title: Text(r['receipt_no'], style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(r['branch']?['name'] ?? ''),
                  trailing: Text(formatRupiah((r['total_amount'] as num).toDouble()), style: const TextStyle(fontSize: 12)),
                )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.output, color: Colors.orange, size: 18),
                    SizedBox(width: 8),
                    Text('Barang Keluar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ...issues.map((i) => ListTile(
                  dense: true,
                  title: Text(i['issue_no'], style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(i['branch']?['name'] ?? ''),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardSkeleton(BuildContext context, bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips skeleton placeholder
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(4, (index) => const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Skeleton(width: 100, height: 36, borderRadius: 18),
              )),
            ),
          ),
          const SizedBox(height: 20),
          // Summary cards skeleton
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 2 : 4,
              crossAxisSpacing: isMobile ? 10 : 16,
              mainAxisSpacing: isMobile ? 10 : 16,
              childAspectRatio: isMobile ? 1.4 : 1.6,
            ),
            itemCount: 4,
            itemBuilder: (context, index) => const Skeleton(borderRadius: 16),
          ),
          const SizedBox(height: 24),
          // Chart placeholder skeleton
          const Skeleton(width: double.infinity, height: 260, borderRadius: 20),
          const SizedBox(height: 24),
          // Double card row skeleton
          Row(
            children: [
              const Expanded(child: Skeleton(height: 200, borderRadius: 20)),
              if (!isMobile) ...[
                const SizedBox(width: 16),
                const Expanded(child: Skeleton(height: 200, borderRadius: 20)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuperUserStatsCard(BuildContext context, Map<String, dynamic> stats, ColorScheme colorScheme, bool isMobile) {
    final posCounts = stats['pos_type_counts'] ?? {};
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.15), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings, color: colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Statistik Registrasi SaaS (Super User)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Metrics Row
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'Total Penggunaan Registrasi',
                    stats['total_registrations']?.toString() ?? '0',
                    Colors.indigo,
                    Icons.app_registration,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    'Registrasi Daftar + Bayar',
                    stats['total_paid_registrations']?.toString() ?? '0',
                    Colors.teal,
                    Icons.check_circle_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Distribusi Jenis POS Pengguna',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            // Row of POS type usage counts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPosCountItem('POS Resto', posCounts['resto'] ?? 0, Colors.blue, Icons.restaurant),
                _buildPosCountItem('POS Retail', posCounts['retail'] ?? 0, Colors.amber.shade800, Icons.storefront),
                _buildPosCountItem('POS Jasa', posCounts['jasa'] ?? 0, Colors.purple, Icons.dry_cleaning),
                _buildPosCountItem('POS Fashion', posCounts['fashion'] ?? 0, Colors.pink, Icons.checkroom),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosCountItem(String label, dynamic count, Color color, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          const SizedBox(height: 2),
          Text(
            count.toString(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> colors;

  const _StatCard({required this.title, required this.value, required this.icon, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [colors[0].withOpacity(0.85), colors[1]],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            bottom: -8,
            child: Icon(icon, size: 56, color: Colors.white.withOpacity(0.12)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

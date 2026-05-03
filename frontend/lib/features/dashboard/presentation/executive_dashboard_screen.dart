import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/currency_formatter.dart';
import 'package:fl_chart/fl_chart.dart';

final executiveDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('dashboard/executive');
  return res.data as Map<String, dynamic>;
});

class ExecutiveDashboardScreen extends ConsumerWidget {
  const ExecutiveDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(executiveDashboardProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Executive', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) => RefreshIndicator(
          onRefresh: () => ref.refresh(executiveDashboardProvider.future),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
          color: Colors.green,
        ),
        _StatCard(
          title: 'Total Transaksi',
          value: stats['total_orders'].toString(),
          icon: Icons.shopping_bag,
          color: Colors.blue,
        ),
        _StatCard(
          title: 'Jumlah Cabang',
          value: stats['total_branches'].toString(),
          icon: Icons.store,
          color: Colors.orange,
        ),
        _StatCard(
          title: 'Jumlah User',
          value: stats['total_users'].toString(),
          icon: Icons.people,
          color: Colors.purple,
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
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/currency_formatter.dart';

final dashboardStatsProvider = FutureProvider((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('dashboard/stats');
  return response.data as Map<String, dynamic>;
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Dashboard Overview', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: statsAsync.when(
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ringkasan Bisnis',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                        style: TextStyle(color: Theme.of(context).colorScheme.outline),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(dashboardStatsProvider),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Key Stats Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 700 ? 2 : 1);
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.2,
                    children: [
                      _ModernStatCard(
                        title: 'Pendapatan Hari Ini',
                        value: formatRupiah((stats['total_revenue_today'] as num).toDouble()),
                        icon: Icons.account_balance_wallet,
                        colors: [Colors.green, Colors.teal],
                      ),
                      _ModernStatCard(
                        title: 'Total Pesanan',
                        value: '${stats['total_orders_today']}',
                        icon: Icons.receipt_long,
                        colors: [Colors.blue, Colors.indigo],
                      ),
                      _ModernStatCard(
                        title: 'Meja Aktif',
                        value: '${stats['active_tables']}',
                        icon: Icons.table_restaurant,
                        colors: [Colors.orange, Colors.deepOrange],
                      ),
                      _ModernStatCard(
                        title: 'Meja Tersedia',
                        value: '${stats['available_tables']}',
                        icon: Icons.event_available,
                        colors: [Colors.purple, Colors.deepPurple],
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Main content grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 1000;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _SectionCard(
                              title: 'Tren Penjualan (7 Hari)',
                              child: SizedBox(
                                height: 260,
                                child: _RevenueChart(chartData: stats['revenue_chart'] as List? ?? []),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _SectionCard(
                              title: 'Pesanan Terbaru',
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: _RecentOrdersTable(orders: stats['recent_orders'] as List),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isWide) const SizedBox(width: 24),
                      if (isWide)
                        Expanded(
                          child: Column(
                            children: [
                              _SectionCard(
                                title: '🔥 Menu Terlaris',
                                child: _TopItemsList(items: stats['top_items'] as List? ?? []),
                              ),
                              const SizedBox(height: 24),
                              _SectionCard(
                                title: '⚠️ Stok Menipis',
                                child: _LowStockWarning(items: stats['low_stock'] as List? ?? []),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
              
              // Mobile only lists
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 1000) return const SizedBox.shrink();
                  return Column(
                    children: [
                      const SizedBox(height: 24),
                      _SectionCard(
                        title: '🔥 Menu Terlaris',
                        child: _TopItemsList(items: stats['top_items'] as List? ?? []),
                      ),
                      const SizedBox(height: 24),
                      _SectionCard(
                        title: '⚠️ Stok Menipis',
                        child: _LowStockWarning(items: stats['low_stock'] as List? ?? []),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

// ─── Chart Component ──────────────────────────────────────────────────────────
class _RevenueChart extends StatelessWidget {
  final List<dynamic> chartData;

  const _RevenueChart({required this.chartData});

  @override
  Widget build(BuildContext context) {
    if (chartData.isEmpty) {
      return const Center(child: Text('Belum ada data penjualan'));
    }

    final colorScheme = Theme.of(context).colorScheme;
    
    // Find max value to scale chart
    double maxVal = 0;
    for (var item in chartData) {
      final val = (item['value'] as num).toDouble();
      if (val > maxVal) maxVal = val;
    }
    if (maxVal == 0) maxVal = 100000;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                formatRupiah(rod.toY),
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < chartData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      chartData[value.toInt()]['label'],
                      style: TextStyle(fontSize: 12, color: colorScheme.outline),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // Hide Y axis text to save space
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxVal / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outline.withOpacity(0.1),
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(chartData.length, (index) {
          final val = (chartData[index]['value'] as num).toDouble();
          final isToday = index == chartData.length - 1;
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: val,
                color: isToday ? colorScheme.primary : colorScheme.primary.withOpacity(0.5),
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─── Low Stock Widget ─────────────────────────────────────────────────────────
class _LowStockWarning extends StatelessWidget {
  final List<dynamic> items;

  const _LowStockWarning({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
              SizedBox(height: 16),
              Text('Stok Aman', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final item = items[i];
        final isCritical = (item['stock'] as num) <= 5;
        
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.warning_amber_rounded, 
            color: isCritical ? Colors.red : Colors.orange
          ),
          title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isCritical ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isCritical ? Colors.red : Colors.orange),
            ),
            child: Text(
              '${item['stock']} ${item['unit']}',
              style: TextStyle(
                color: isCritical ? Colors.red : Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 12
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModernStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> colors;

  const _ModernStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [colors[0].withOpacity(0.8), colors[1]],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(icon, size: 80, color: Colors.white.withOpacity(0.15)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              FittedBox(
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopItemsList extends StatelessWidget {
  final List items;
  const _TopItemsList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('Belum ada data'));
    
    final maxQty = (items.first['qty'] as num).toDouble();

    return Column(
      children: items.map((item) {
        final qty = (item['qty'] as num).toDouble();
        final percent = qty / maxQty;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${item['qty']} porsi', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 6,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _RecentOrdersTable extends StatelessWidget {
  final List orders;

  const _RecentOrdersTable({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Belum ada pesanan terbaru'),
      ));
    }

    return DataTable(
      columnSpacing: 24,
      columns: const [
        DataColumn(label: Text('Meja')),
        DataColumn(label: Text('Customer')),
        DataColumn(label: Text('Total')),
        DataColumn(label: Text('Status')),
      ],
      rows: orders.map((order) {
        return DataRow(cells: [
          DataCell(Text(order['table'] != null ? 'Meja ${order['table']['table_number']}' : 'Take-away')),
          DataCell(Text(order['customer_name'] ?? 'Guest')),
          DataCell(Text(formatRupiah((order['total_amount'] as num).toDouble()))),
          DataCell(_StatusBadge(status: order['status'])),
        ]);
      }).toList(),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Selesai': color = Colors.green; break;
      case 'Pending': color = Colors.orange; break;
      case 'Proses': color = Colors.blue; break;
      case 'Batal': color = Colors.red; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

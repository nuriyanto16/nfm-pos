import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'table_provider.dart';
import '../../../core/network/dio_client.dart';

class TableMonitoringScreen extends ConsumerStatefulWidget {
  const TableMonitoringScreen({super.key});

  @override
  ConsumerState<TableMonitoringScreen> createState() => _TableMonitoringScreenState();
}

class _TableMonitoringScreenState extends ConsumerState<TableMonitoringScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(tableManagementProvider.notifier).fetchTables());
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      ref.read(tableManagementProvider.notifier).fetchTables();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Color _getStatusColor(String status, String? orderStatus) {
    if (status == 'Kosong') return Colors.green;
    if (status == 'Dipesan') return Colors.orange;
    
    if (orderStatus == 'Pending') return Colors.red;
    if (orderStatus == 'Proses') return Colors.blue;
    if (orderStatus == 'Siap') return Colors.amber;
    
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tableManagementProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final tablesByFloor = <String, List<dynamic>>{};
    for (var t in state.items) {
      final floor = t['floor']?.toString() ?? '1';
      if (!tablesByFloor.containsKey(floor)) tablesByFloor[floor] = [];
      tablesByFloor[floor]!.add(t);
    }

    final sortedFloors = tablesByFloor.keys.toList()..sort();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Monitoring Meja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Real-time updates aktif', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70)),
          ],
        ),
        actions: [
          if (state.isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            )),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(tableManagementProvider.notifier).fetchTables(),
          ),
        ],
      ),
      body: state.items.isEmpty && state.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: sortedFloors.length,
            itemBuilder: (context, floorIndex) {
              final floor = sortedFloors[floorIndex];
              final tables = tablesByFloor[floor]!;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.layers_outlined, size: 18, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'AREA / LANTAI $floor', 
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.w900, 
                            color: colorScheme.primary,
                            letterSpacing: 1.2,
                          )
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 160,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: tables.length,
                    itemBuilder: (context, i) {
                      final t = tables[i];
                      final status = t['status'] ?? 'Kosong';
                      final activeOrder = t['active_order'];
                      final orderStatus = activeOrder?['status'];
                      
                      final baseColor = _getStatusColor(status, orderStatus);
                      final isOccupied = status == 'Digunakan';

                      return _buildTableCard(context, t, baseColor, isOccupied, orderStatus);
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
    );
  }

  Widget _buildTableCard(BuildContext context, dynamic t, Color baseColor, bool isOccupied, String? orderStatus) {
    final theme = Theme.of(context);
    final statusText = isOccupied && orderStatus != null ? orderStatus.toUpperCase() : t['status'].toUpperCase();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: theme.cardColor,
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: baseColor.withOpacity(0.05),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: baseColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: baseColor),
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            isOccupied ? Icons.restaurant : Icons.table_bar_rounded,
                            color: baseColor,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${t['table_number']}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 12, color: theme.hintColor),
                        const SizedBox(width: 4),
                        Text(
                          '${t['capacity']} Kursi',
                          style: TextStyle(fontSize: 10, color: theme.hintColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isOccupied && orderStatus != 'Siap')
                Positioned(
                  top: 10,
                  right: 10,
                  child: _PulseIndicator(color: baseColor),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseIndicator extends StatefulWidget {
  final Color color;
  const _PulseIndicator({required this.color, super.key});

  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(1 - _controller.value),
                blurRadius: 10 * _controller.value,
                spreadRadius: 5 * _controller.value,
              )
            ],
          ),
        );
      },
    );
  }
}

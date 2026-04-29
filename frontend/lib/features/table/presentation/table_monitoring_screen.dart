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
    // Fetch immediately
    Future.microtask(() => ref.read(tableManagementProvider.notifier).fetchTables());
    // Set up auto-refresh every 5 seconds
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
    
    // If used, check order status
    if (orderStatus == 'Pending') return Colors.red;
    if (orderStatus == 'Proses') return Colors.blue;
    if (orderStatus == 'Siap') return Colors.amber;
    
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tableManagementProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Group tables by floor
    final tablesByFloor = <String, List<dynamic>>{};
    for (var t in state.items) {
      final floor = t['floor']?.toString() ?? '1';
      if (!tablesByFloor.containsKey(floor)) tablesByFloor[floor] = [];
      tablesByFloor[floor]!.add(t);
    }

    final sortedFloors = tablesByFloor.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Status Meja'),
        actions: [
          if (state.isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            )),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(tableManagementProvider.notifier).fetchTables(),
          ),
        ],
      ),
      body: state.items.isEmpty && state.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
        padding: const EdgeInsets.all(16),
        children: sortedFloors.map((floor) {
          final tables = tablesByFloor[floor]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    Icon(Icons.layers, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Area / Lantai $floor', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
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

                  return Card(
                    elevation: 4,
                    shadowColor: baseColor.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: baseColor.withOpacity(0.5), width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              baseColor.withOpacity(0.05),
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: baseColor.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isOccupied ? Icons.restaurant : Icons.table_restaurant,
                                      color: baseColor,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'MEJA ${t['table_number']}',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: baseColor),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: baseColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isOccupied && orderStatus != null ? orderStatus.toUpperCase() : status.toUpperCase(),
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${t['capacity']} Kursi',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            if (isOccupied && activeOrder != null)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle),
                                  child: const Icon(Icons.priority_high, color: Colors.white, size: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          );
        }).toList(),
      ),
    );
  }
}

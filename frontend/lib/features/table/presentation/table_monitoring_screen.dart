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
  @override
  void initState() {
    super.initState();
    // Auto refresh could be added here
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tableManagementProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
        title: const Text('Monitoring Meja'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(tableManagementProvider.notifier).fetchTables(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: sortedFloors.map((floor) {
          final tables = tablesByFloor[floor]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Lantai / Area $floor', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 150,
                  childAspectRatio: 1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: tables.length,
                itemBuilder: (context, i) {
                  final t = tables[i];
                  final status = t['status'] ?? 'Kosong';
                  
                  Color bgColor = Colors.green[100]!;
                  Color textColor = Colors.green[800]!;
                  IconData icon = Icons.check_circle_outline;

                  if (status == 'Digunakan') {
                    bgColor = Colors.red[100]!;
                    textColor = Colors.red[800]!;
                    icon = Icons.cancel_outlined;
                  } else if (status == 'Dipesan') {
                    bgColor = Colors.orange[100]!;
                    textColor = Colors.orange[800]!;
                    icon = Icons.access_time;
                  }

                  return Card(
                    color: bgColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: textColor.withOpacity(0.3))),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          t['image_url'] != null && t['image_url'].toString().isNotEmpty
                              ? Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      '${ref.read(dioProvider).options.baseUrl.replaceAll('/api/', '')}${t['image_url']}',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  ),
                                )
                              : Icon(icon, color: textColor, size: 28),
                          const SizedBox(height: 8),
                          Text('Meja ${t['table_number']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                          const SizedBox(height: 4),
                          Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                          const Spacer(),
                          Text('${t['capacity']} Orang', style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.7))),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 32),
            ],
          );
        }).toList(),
      ),
    );
  }
}

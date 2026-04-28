import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import 'table_provider.dart';

class TableLayoutScreen extends ConsumerStatefulWidget {
  const TableLayoutScreen({super.key});

  @override
  ConsumerState<TableLayoutScreen> createState() => _TableLayoutScreenState();
}

class _TableLayoutScreenState extends ConsumerState<TableLayoutScreen> {
  String selectedFloor = '1';
  bool isEditMode = false;
  bool isSaving = false;
  Map<int, Offset> modifiedPositions = {};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tableManagementProvider);
    final notifier = ref.read(tableManagementProvider.notifier);

    // Filter tables by floor
    final floorTables = state.items.where((t) => (t['floor']?.toString() ?? '1') == selectedFloor).toList();

    // Get unique floors
    final floors = state.items.map((t) => t['floor']?.toString() ?? '1').toSet().toList();
    if (!floors.contains('1')) floors.add('1');
    floors.sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Denah Meja'),
        actions: [
          if (isEditMode)
            FilledButton.icon(
              onPressed: isSaving ? null : _savePositions,
              icon: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
              label: Text(isSaving ? 'Menyimpan...' : 'Simpan Denah'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
            ),
          const SizedBox(width: 8),
          Switch(
            value: isEditMode,
            onChanged: (val) {
              setState(() {
                isEditMode = val;
                if (!val) modifiedPositions.clear();
              });
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0, left: 8.0),
            child: Center(child: Text('Mode Edit')),
          ),
        ],
      ),
      body: Column(
        children: [
          if (isSaving) const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text('Pilih Lantai/Area: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: selectedFloor,
                  items: floors.map((f) => DropdownMenuItem(value: f, child: Text('Lantai $f'))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        selectedFloor = val;
                        modifiedPositions.clear();
                      });
                    }
                  },
                ),
                const Spacer(),
                if (!isEditMode)
                  Row(
                    children: [
                      _buildLegendItem(Colors.green, 'Kosong'),
                      const SizedBox(width: 12),
                      _buildLegendItem(Colors.orange, 'Dipesan'),
                      const SizedBox(width: 12),
                      _buildLegendItem(Colors.red, 'Digunakan'),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.grey[200], // Background grid can be added here
              child: Stack(
                fit: StackFit.expand,
                children: floorTables.map((t) {
                  final id = t['id'];
                  final tableNum = t['table_number'];
                  final cap = t['capacity'];
                  final status = t['status'];
                  final imageUrl = t['image_url'];
                  
                  // Use modified position if exists, otherwise DB position
                  double px = modifiedPositions[id]?.dx ?? (t['position_x'] as dynamic ?? 0).toDouble();
                  double py = modifiedPositions[id]?.dy ?? (t['position_y'] as dynamic ?? 0).toDouble();

                  Color statusColor = Colors.green;
                  if (status == 'Digunakan') statusColor = Colors.red;
                  if (status == 'Dipesan') statusColor = Colors.orange;

                  return Positioned(
                    left: px,
                    top: py,
                    child: GestureDetector(
                      onPanUpdate: isEditMode
                          ? (details) {
                              setState(() {
                                double newX = px + details.delta.dx;
                                double newY = py + details.delta.dy;
                                // Simple boundary check
                                if (newX < 0) newX = 0;
                                if (newY < 0) newY = 0;
                                modifiedPositions[id] = Offset(newX, newY);
                              });
                            }
                          : null,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isEditMode ? Colors.blue : statusColor, width: isEditMode ? 2 : 4),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (imageUrl != null)
                              Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(8)), child: Image.network('${ref.read(dioProvider).options.baseUrl.replaceAll('/api/', '')}$imageUrl', fit: BoxFit.cover, width: double.infinity)))
                            else
                              Icon(Icons.table_restaurant, color: statusColor, size: 32),
                            const SizedBox(height: 4),
                            Text('Meja $tableNum', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('$cap Pax', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Future<void> _savePositions() async {
    final dio = ref.read(dioProvider);
    try {
      setState(() => isSaving = true);
      
      // Save all modified tables in one go
      final data = modifiedPositions.entries.map((e) => {
        'id': e.key,
        'position_x': e.value.dx,
        'position_y': e.value.dy,
      }).toList();

      if (data.isNotEmpty) {
        await dio.put('tables/bulk-positions', data: data);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Denah berhasil disimpan'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green[800],
          )
        );
        setState(() {
          isEditMode = false;
          isSaving = false;
          modifiedPositions.clear();
        });
        ref.read(tableManagementProvider.notifier).fetchTables();
      }
    } catch (e) {
      if (mounted) {
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

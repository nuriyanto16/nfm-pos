import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

// Auto-refresh kitchen orders every 5 seconds
final kitchenOrdersProvider = StreamProvider.autoDispose<List<dynamic>>((ref) async* {
  final dio = ref.read(dioProvider);

  Future<List<dynamic>> fetchOrders() async {
    // Only fetch orders from last 24 hours to avoid showing ancient unpaid orders
    final res = await dio.get('orders', queryParameters: {
      'status': 'Pending,Proses,Siap', 
      'limit': 100,
      'sort': 'created_at desc'
    });
    List<dynamic> allRows = [];
    if (res.data is Map && res.data.containsKey('rows')) {
      allRows = res.data['rows'] as List<dynamic>;
    } else {
      allRows = res.data as List<dynamic>;
    }
    
    // Filter: Show Pending, Proses, and Siap (even if paid, as long as not Selesai)
    return allRows.where((o) {
      final status = o['status'];
      return status == 'Pending' || status == 'Proses' || status == 'Siap';
    }).toList();
  }

  yield await fetchOrders();

  await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
    yield await fetchOrders();
  }
});

class KitchenDisplayScreen extends ConsumerStatefulWidget {
  const KitchenDisplayScreen({super.key});

  @override
  ConsumerState<KitchenDisplayScreen> createState() => _KitchenDisplayScreenState();
}

class _KitchenDisplayScreenState extends ConsumerState<KitchenDisplayScreen> {
  int _previousOrderCount = 0;
  final Set<int> _loadingIds = {};

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Proses':
        return Colors.blue;
      case 'Siap':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(kitchenOrdersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.kitchen, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Kitchen Display System', style: TextStyle(color: Colors.white)),
            const Spacer(),
            // Live indicator
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            const Text('LIVE', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
            // Counter badge
            ordersAsync.when(
              data: (orders) {
                final pendingCount = orders.where((o) => o['status'] == 'Pending').length;
                final prosesCount = orders.where((o) => o['status'] == 'Proses').length;

                // Detect new orders
                if (orders.length > _previousOrderCount && _previousOrderCount > 0) {
                  // New order arrived — highlight them
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.notifications_active, color: Colors.white),
                              const SizedBox(width: 8),
                              Text('🔔 ${orders.length - _previousOrderCount} pesanan baru masuk!'),
                            ],
                          ),
                          backgroundColor: Colors.orange.shade800,
                          duration: const Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  });
                }
                _previousOrderCount = orders.length;

                return Row(
                  children: [
                    _CounterBadge(label: 'Antrian', count: pendingCount, color: Colors.orange),
                    const SizedBox(width: 8),
                    _CounterBadge(label: 'Proses', count: prosesCount, color: Colors.blue),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      body: ordersAsync.when(
        loading: () => const _KdsSkeleton(),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text('Semua pesanan selesai!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Tidak ada pesanan masuk', style: TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 24),
                  const _PulsingDot(),
                  const SizedBox(height: 8),
                  const Text('Menunggu pesanan baru...', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            );
          }

          // Sort: Pending first, then by oldest created_at
          final sorted = List<dynamic>.from(orders);
          sorted.sort((a, b) {
            // Sort by priority: Pending > Proses > Siap
            final priority = {'Pending': 0, 'Proses': 1, 'Siap': 2};
            final aPrio = priority[a['status']] ?? 99;
            final bPrio = priority[b['status']] ?? 99;
            if (aPrio != bPrio) return aPrio.compareTo(bPrio);
            
            // Within same status, oldest first
            final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
            final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
            return aTime.compareTo(bTime);
          });

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 380,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final order = sorted[index];
              final status = order['status'] as String;
              final table = order['table'];
              final customerName = order['customer_name'] ?? 'Umum';
              final tableLabel = table != null && table['id'] != null
                  ? 'Meja ${table['table_number']}'
                  : 'Take Away - $customerName';

              return _KitchenOrderCard(
                order: order,
                status: status,
                tableLabel: tableLabel,
                statusColor: _statusColor(status),
                isLoading: _loadingIds.contains(order['id']),
                onUpdateStatus: (newStatus) => _updateStatus(ref, context, order['id'], newStatus),
                onUpdateItemStatus: (itemId, isReady) => _updateItemStatus(ref, context, itemId, isReady),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _updateStatus(WidgetRef ref, BuildContext context, int id, String status) async {
    setState(() => _loadingIds.add(id));
    try {
      final dio = ref.read(dioProvider);
      await dio.put('orders/$id/status', data: {'status': status});
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingIds.remove(id));
    }
  }

  Future<void> _updateItemStatus(WidgetRef ref, BuildContext context, int itemId, bool isReady) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.put('orders/items/$itemId/ready', data: {'is_ready': isReady});
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

// ─── Kitchen Order Card ───────────────────────────────────────────────────────
class _KitchenOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final String status;
  final String tableLabel;
  final Color statusColor;
  final bool isLoading;
  final Function(String) onUpdateStatus;
  final Function(int, bool) onUpdateItemStatus;

  const _KitchenOrderCard({
    required this.order,
    required this.status,
    required this.tableLabel,
    required this.statusColor,
    required this.isLoading,
    required this.onUpdateStatus,
    required this.onUpdateItemStatus,
  });

  @override
  Widget build(BuildContext context) {
    final items = order['items'] as List? ?? [];
    final table = order['table'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Card(
        color: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: statusColor, width: status == 'Pending' ? 2.5 : 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${order['id']}',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (status == 'Pending')
                          const _PulsingDot(color: Colors.orange, size: 8),
                        if (status == 'Pending') const SizedBox(width: 4),
                        Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    table != null && table['id'] != null ? Icons.table_restaurant : Icons.local_shipping,
                    color: Colors.white70,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tableLabel,
                      style: TextStyle(
                        color: table != null && table['id'] != null ? Colors.white : Colors.orange.shade300,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (table != null && table['id'] != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_outline, color: Colors.white54, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      order['customer_name'] ?? 'Umum',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              // Time elapsed
              _TimeElapsed(createdAt: order['created_at']),
              const Divider(color: Colors.white24, height: 16),
              // Items
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final itemNote = item['notes'];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${item['quantity']}x',
                                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item['menu']?['name'] ?? 'Menu',
                                  style: TextStyle(
                                    color: item['is_ready'] == true ? Colors.white38 : Colors.white, 
                                    fontSize: 14,
                                    decoration: item['is_ready'] == true ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                              if (status != 'Selesai')
                                Transform.scale(
                                  scale: 0.8,
                                  child: Checkbox(
                                    value: item['is_ready'] == true,
                                    activeColor: Colors.green,
                                    checkColor: Colors.black,
                                    side: const BorderSide(color: Colors.white38),
                                    onChanged: (val) {
                                      final isReady = val ?? false;
                                      _showItemConfirm(
                                        context, 
                                        item['menu']?['name'] ?? 'Menu', 
                                        isReady, 
                                        item['id']
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                          // Item-level note
                          if (itemNote != null && itemNote.toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 38, top: 0, bottom: 4),
                              child: Text(
                                '📝 $itemNote',
                                style: TextStyle(
                                  color: item['is_ready'] == true ? Colors.yellow.withOpacity(0.3) : Colors.yellow.shade200, 
                                  fontSize: 11, 
                                  fontStyle: FontStyle.italic
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Global notes
              if (order['notes'] != null && order['notes'].toString().isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.yellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.yellow.shade700),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.note_alt_outlined, size: 14, color: Colors.yellow),
                      const SizedBox(width: 4),
                      Expanded(child: Text(order['notes'], style: const TextStyle(color: Colors.yellow, fontSize: 12))),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              // Action buttons
              SizedBox(
                width: double.infinity,
                child: isLoading
                    ? FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white10,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: null,
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                      )
                    : status == 'Pending'
                        ? FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => _showConfirm(context, 'Mulai Proses', 'Proses', Colors.blue),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Mulai Proses', style: TextStyle(fontWeight: FontWeight.bold)),
                          )
                        : status == 'Proses'
                            ? FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () => _showConfirm(context, 'Siap Disajikan', 'Siap', Colors.green),
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Siap Disajikan', style: TextStyle(fontWeight: FontWeight.bold)),
                              )
                            : FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () => _showConfirm(context, 'Selesaikan Pesanan', 'Selesai', Colors.teal),
                                icon: const Icon(Icons.done_all),
                                label: const Text('Selesai (Hapus dari Display)', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemConfirm(BuildContext context, String menuName, bool isReady, int itemId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: Text(isReady ? 'Selesaikan Item' : 'Batal Selesai', style: const TextStyle(color: Colors.white)),
        content: Text(
          isReady ? 'Tandai "$menuName" sebagai SIAP?' : 'Batal tandai "$menuName" sebagai SIAP?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.white38)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: isReady ? Colors.green : Colors.orange),
            onPressed: () {
              Navigator.pop(ctx);
              onUpdateItemStatus(itemId, isReady);
            },
            child: const Text('Konfirmasi', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showConfirm(BuildContext context, String title, String newStatus, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text('Ubah status pesanan #${order['id']} menjadi $newStatus?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.white38)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: color),
            onPressed: () {
              Navigator.pop(ctx);
              onUpdateStatus(newStatus);
            },
            child: const Text('Konfirmasi', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─── KDS Skeleton ─────────────────────────────────────────────────────────────
class _KdsSkeleton extends StatelessWidget {
  const _KdsSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 350,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Card(
        color: const Color(0xFF161B22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 80, height: 20, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4))),
                  Container(width: 60, height: 20, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4))),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(3, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(width: 24, height: 24, decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Container(width: 150, height: 16, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              )),
              const Spacer(),
              Container(width: double.infinity, height: 44, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8))),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Counter Badge ────────────────────────────────────────────────────────────
class _CounterBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CounterBadge({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─── Pulsing Dot ──────────────────────────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  const _PulsingDot({this.color = Colors.green, this.size = 12});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(0.4 + _ctrl.value * 0.6),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.3 * _ctrl.value),
              blurRadius: 8 * _ctrl.value,
              spreadRadius: 2 * _ctrl.value,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Time Elapsed Widget ──────────────────────────────────────────────────────
class _TimeElapsed extends StatefulWidget {
  final String? createdAt;
  const _TimeElapsed({this.createdAt});

  @override
  State<_TimeElapsed> createState() => _TimeElapsedState();
}

class _TimeElapsedState extends State<_TimeElapsed> {
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calcElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calcElapsed());
  }

  void _calcElapsed() {
    if (widget.createdAt != null) {
      final created = DateTime.tryParse(widget.createdAt!);
      if (created != null && mounted) {
        // Use UTC for both to avoid timezone confusion
        final now = DateTime.now().toUtc();
        final createdUtc = created.isUtc ? created : created.toUtc();
        
        Duration diff = now.difference(createdUtc);
        
        // If server time is slightly ahead of client, don't show negative
        if (diff.isNegative) {
          diff = Duration.zero;
        }
        
        setState(() => _elapsed = diff);
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mins = _elapsed.inMinutes;
    final secs = _elapsed.inSeconds % 60;
    
    // Professional Resto Thresholds
    Color color = Colors.green;
    String label = 'Normal';
    
    if (mins >= 25) {
      color = Colors.redAccent;
      label = 'Terlambat';
    } else if (mins >= 15) {
      color = Colors.orangeAccent;
      label = 'Lambat';
    } else if (mins >= 8) {
      color = Colors.yellowAccent;
      label = 'Perhatian';
    } else {
      color = Colors.greenAccent;
      label = 'Cepat';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'monospace'),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

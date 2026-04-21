import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_client.dart';

// ─── User Info Provider ───────────────────────────────────────────────────────
final userInfoProvider = FutureProvider<Map<String, String>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return {
    'username': prefs.getString('username') ?? 'User',
    'role': prefs.getString('role') ?? '-',
  };
});


// ─── Cashier Session Provider ─────────────────────────────────────────────────
final cashierSessionProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  try {
    final dio = ref.read(dioProvider);
    final response = await dio.get('sessions/active');
    return response.data as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
});

class SidebarLayout extends ConsumerStatefulWidget {
  final Widget child;
  const SidebarLayout({super.key, required this.child});

  @override
  ConsumerState<SidebarLayout> createState() => _SidebarLayoutState();
}

class _SidebarLayoutState extends ConsumerState<SidebarLayout> {
  static const _navItems = [
    _NavItem('/dashboard', Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
    _NavItem('/pos', Icons.point_of_sale_outlined, Icons.point_of_sale, 'POS Kasir'),
    _NavItem('/kitchen', Icons.kitchen_outlined, Icons.kitchen, 'Dapur (KDS)'),
    _NavItem('/reports', Icons.bar_chart_outlined, Icons.bar_chart, 'Laporan'),
    _NavItem('/orders', Icons.receipt_long_outlined, Icons.receipt_long, 'Pesanan'),
  ];

  static const _mgmtItems = [
    _NavItem('/menus', Icons.restaurant_menu_outlined, Icons.restaurant_menu, 'Menu'),
    _NavItem('/ingredients', Icons.science_outlined, Icons.science, 'Bahan (Baku)'),
    _NavItem('/stock', Icons.inventory_2_outlined, Icons.inventory_2, 'Manajemen Stok'),
    _NavItem('/manage-tables', Icons.table_bar_outlined, Icons.table_bar, 'Meja'),
    _NavItem('/customers', Icons.people_outline, Icons.people, 'Customer'),
    _NavItem('/promos', Icons.local_offer_outlined, Icons.local_offer, 'Promo'),
    _NavItem('/branches', Icons.business_outlined, Icons.business, 'Cabang'),
    _NavItem('/users', Icons.manage_accounts_outlined, Icons.manage_accounts, 'User / Role'),
    _NavItem('/suppliers', Icons.local_shipping_outlined, Icons.local_shipping, 'Supplier'),
    
    // Keuangan Split
    _NavItem('/finance/coa', Icons.account_tree_outlined, Icons.account_tree, 'Chart of Account'),
    _NavItem('/finance/journal', Icons.description_outlined, Icons.description, 'Jurnal Umum'),
    _NavItem('/finance/ledger', Icons.menu_book_outlined, Icons.menu_book, 'Buku Besar'),
    _NavItem('/wa-logs', Icons.history_edu_outlined, Icons.history_edu, 'Log WhatsApp'),
    
    _NavItem('/settings', Icons.settings_outlined, Icons.settings, 'Pengaturan'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final isWide = MediaQuery.of(context).size.width >= 900;
    final sessionAsync = ref.watch(cashierSessionProvider);

    if (!isWide) {
      return _buildMobileLayout(context, location, sessionAsync);
    }
    return _buildDesktopLayout(context, location, sessionAsync);
  }

  Widget _buildDesktopLayout(
      BuildContext context, String location, AsyncValue<Map<String, dynamic>?> sessionAsync) {
    return Scaffold(
      body: Row(
        children: [
          _DesktopSidebar(
            location: location,
            navItems: _navItems,
            mgmtItems: _mgmtItems,
            sessionAsync: sessionAsync,
            onLogout: _logout,
            onSessionAction: _handleSessionAction,
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, String location, AsyncValue<Map<String, dynamic>?> sessionAsync) {
    // Find selected index for BottomNavigationBar
    final allItems = [..._navItems, ..._mgmtItems];
    final selectedIndex = allItems.indexWhere((item) => item.path == location);

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Resto Modern'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          sessionAsync.when(
            data: (session) => session != null
                ? IconButton(
                    icon: const Icon(Icons.point_of_sale, color: Colors.green),
                    tooltip: 'Sesi Aktif',
                    onPressed: () => _handleSessionAction(context, session),
                  )
                : IconButton(
                    icon: const Icon(Icons.point_of_sale),
                    tooltip: 'Buka Sesi',
                    onPressed: () => _handleSessionAction(context, null),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      drawer: _MobileDrawer(
        location: location,
        navItems: _navItems,
        mgmtItems: _mgmtItems,
        sessionAsync: sessionAsync,
        onLogout: _logout,
        onSessionAction: _handleSessionAction,
      ),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex >= 0 ? selectedIndex % _navItems.length : 0,
        onDestinationSelected: (i) => context.go(_navItems[i].path),
        destinations: _navItems.map((item) => NavigationDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.selectedIcon),
          label: item.label,
        )).toList(),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (context.mounted) context.go('/login');
  }

  Future<void> _handleSessionAction(BuildContext context, Map<String, dynamic>? session) async {
    if (session == null) {
      await _showOpenSessionDialog(context);
    } else {
      await _showCloseSessionDialog(context, session);
    }
  }

  Future<void> _showOpenSessionDialog(BuildContext context) async {
    final controller = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.point_of_sale, color: Colors.green),
            SizedBox(width: 8),
            Text('Buka Sesi Kasir'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Modal Awal (Rp)',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Catatan (Opsional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              try {
                final dio = ref.read(dioProvider);
                await dio.post('sessions/open', data: {
                  'initial_cash': double.tryParse(controller.text) ?? 0,
                  'notes': notesCtrl.text,
                });
                ref.invalidate(cashierSessionProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Sesi kasir dibuka!')),
                );
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Buka Sesi'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCloseSessionDialog(BuildContext context, Map<String, dynamic> session) async {
    final dio = ref.read(dioProvider);
    Map<String, dynamic>? summary;
    
    try {
      final res = await dio.get('sessions/active/summary');
      summary = res.data;
    } catch (e) {
      // Ignored
    }

    final controller = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();
    
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.orange),
            SizedBox(width: 8),
            Text('Tutup Sesi Kasir'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dibuka: ${session['open_time']?.toString().substring(0, 16) ?? '-'}'),
            if (summary != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ringkasan Laci Uang (TUNAI)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Modal Awal:', style: TextStyle(fontSize: 12)),
                      Text('Rp ${summary['initial_cash'] ?? 0}', style: const TextStyle(fontSize: 12)),
                    ]),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Pendapatan Tunai:', style: TextStyle(fontSize: 12)),
                      Text('+ Rp ${summary['total_cash_sales'] ?? 0}', style: const TextStyle(fontSize: 12)),
                    ]),
                    const Divider(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Ekspektasi Uang Fisik:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      Text('Rp ${summary['expected_cash'] ?? 0}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Text('Modal Awal: Rp ${session['initial_cash'] ?? 0}'),
              const Divider(height: 20),
            ],
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Uang di Laci Kasir Aktual (Rp)',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Catatan Penutupan',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              try {
                final dio = ref.read(dioProvider);
                await dio.put('sessions/${session['id']}/close', data: {
                  'closing_cash': double.tryParse(controller.text) ?? 0,
                  'notes': notesCtrl.text,
                });
                ref.invalidate(cashierSessionProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🔒 Sesi kasir ditutup!')),
                );
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Tutup Sesi'),
          ),
        ],
      ),
    );
  }
}

// ─── Desktop Sidebar ──────────────────────────────────────────────────────────
class _DesktopSidebar extends ConsumerWidget {
  final String location;
  final List<_NavItem> navItems;
  final List<_NavItem> mgmtItems;
  final AsyncValue<Map<String, dynamic>?> sessionAsync;
  final Function(BuildContext) onLogout;
  final Function(BuildContext, Map<String, dynamic>?) onSessionAction;

  const _DesktopSidebar({
    required this.location,
    required this.navItems,
    required this.mgmtItems,
    required this.sessionAsync,
    required this.onLogout,
    required this.onSessionAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 240,
      color: colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          // Logo header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
            ),
            child: Row(
              children: [
                Icon(Icons.restaurant_menu, color: colorScheme.primary, size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('POS Resto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.primary)),
                      Text('Modern v2.0', style: TextStyle(fontSize: 11, color: colorScheme.primary.withOpacity(0.7))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Profile Section ──────────────────────────────────────
          ref.watch(userInfoProvider).when(
            data: (info) => InkWell(
              onTap: () => context.go('/profile'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: colorScheme.primary,
                      child: Text(
                        (info['username'] ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(info['username'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(info['role'] ?? '-', style: TextStyle(fontSize: 11, color: colorScheme.outline)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: colorScheme.outline),
                  ],
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Session status band
          sessionAsync.when(
            data: (session) => InkWell(
              onTap: () => onSessionAction(context, session),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: session != null ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                child: Row(
                  children: [
                    Icon(
                      session != null ? Icons.lock_open_outlined : Icons.lock_outline,
                      size: 16,
                      color: session != null ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        session != null ? 'Sesi Aktif — Tap untuk tutup' : 'Sesi Ditutup — Tap untuk buka',
                        style: TextStyle(
                          fontSize: 11,
                          color: session != null ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Main nav
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text('MENU UTAMA',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.outline, letterSpacing: 1)),
                ),
                ...navItems.map((item) => _SidebarItem(item: item, location: location)),

                const SizedBox(height: 8),
                const Divider(indent: 16, endIndent: 16),

                // Management nav
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text('MANAJEMEN',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.outline, letterSpacing: 1)),
                ),
                ...mgmtItems.map((item) => _SidebarItem(item: item, location: location)),
              ],
            ),
          ),

          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, size: 20),
            title: const Text('Keluar', style: TextStyle(fontSize: 14)),
            onTap: () => onLogout(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Mobile Drawer ────────────────────────────────────────────────────────────
class _MobileDrawer extends ConsumerWidget {
  final String location;
  final List<_NavItem> navItems;
  final List<_NavItem> mgmtItems;
  final AsyncValue<Map<String, dynamic>?> sessionAsync;
  final Function(BuildContext) onLogout;
  final Function(BuildContext, Map<String, dynamic>?) onSessionAction;

  const _MobileDrawer({
    required this.location,
    required this.navItems,
    required this.mgmtItems,
    required this.sessionAsync,
    required this.onLogout,
    required this.onSessionAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.restaurant_menu, color: Theme.of(context).colorScheme.primary, size: 36),
                const SizedBox(height: 8),
                Text('POS Resto Modern', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.primary)),
              ],
            ),
          ),
          ...navItems.map((item) => ListTile(
            leading: Icon(item.icon),
            title: Text(item.label),
            selected: location == item.path,
            onTap: () { Navigator.pop(context); context.go(item.path); },
          )),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('MANAJEMEN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          ...mgmtItems.map((item) => ListTile(
            leading: Icon(item.icon),
            title: Text(item.label),
            selected: location == item.path,
            onTap: () { Navigator.pop(context); context.go(item.path); },
          )),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Keluar'),
            onTap: () => onLogout(context),
          ),
        ],
      ),
    );
  }
}

// ─── Sidebar Item ─────────────────────────────────────────────────────────────
class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final String location;

  const _SidebarItem({required this.item, required this.location});

  @override
  Widget build(BuildContext context) {
    final isSelected = location == item.path;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(
          isSelected ? item.selectedIcon : item.icon,
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          size: 22,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? colorScheme.primary : null,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
        ),
        selected: isSelected,
        selectedTileColor: colorScheme.primaryContainer,
        onTap: () => context.go(item.path),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem(this.path, this.icon, this.selectedIcon, this.label);
}

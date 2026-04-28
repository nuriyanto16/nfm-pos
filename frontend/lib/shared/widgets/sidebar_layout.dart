import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_client.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'floating_chatbot.dart';

// ─── User Info & Menu Provider ─────────────────────────────────────────────────
final authMeProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('auth/me');
  return response.data['user'] as Map<String, dynamic>;
});

IconData _getIconData(String? name) {
  switch (name) {
    case 'dashboard': return Icons.dashboard;
    case 'shopping_cart': return Icons.shopping_cart;
    case 'kitchen': return Icons.kitchen;
    case 'receipt_long': return Icons.receipt_long;
    case 'book': return Icons.book;
    case 'restaurant_menu': return Icons.restaurant_menu;
    case 'category': return Icons.category;
    case 'table_restaurant': return Icons.table_restaurant;
    case 'settings': return Icons.settings;
    case 'people': return Icons.people;
    case 'inventory_2': return Icons.inventory_2;
    case 'local_offer': return Icons.local_offer;
    case 'business': return Icons.business;
    case 'local_shipping': return Icons.local_shipping;
    case 'description': return Icons.description;
    case 'account_tree': return Icons.account_tree;
    case 'history_edu': return Icons.history_edu;
    case 'warehouse': return Icons.warehouse;
    case 'input': return Icons.input;
    case 'output': return Icons.output;
    case 'corporate_fare': return Icons.corporate_fare;
    case 'insights': return Icons.insights;
    case 'chat': return Icons.chat;
    case 'history': return Icons.history;
    case 'school': return Icons.school;
    default: return Icons.circle;
  }
}


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
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final isWide = MediaQuery.of(context).size.width >= 900;
    final sessionAsync = ref.watch(cashierSessionProvider);
    final authMeAsync = ref.watch(authMeProvider);

    return authMeAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error loading menus: $e'))),
      data: (user) {
        final menus = List<dynamic>.from(user['role']?['menus'] as List? ?? []);
        
        if (!isWide) {
          return _buildMobileLayout(context, location, sessionAsync, user, menus);
        }
        return _buildDesktopLayout(context, location, sessionAsync, user, menus);
      },
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context, String location, AsyncValue<Map<String, dynamic>?> sessionAsync, Map<String, dynamic> user, List<dynamic> menus) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              _DesktopSidebar(
                location: location,
                user: user,
                menus: menus,
                sessionAsync: sessionAsync,
                onLogout: _logout,
                onSessionAction: _handleSessionAction,
              ),
              Expanded(child: widget.child),
            ],
          ),
          const FloatingChatbot(),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, String location, AsyncValue<Map<String, dynamic>?> sessionAsync, Map<String, dynamic> user, List<dynamic> menus) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFM POS'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _MobileDrawer(
        location: location,
        user: user,
        menus: menus,
        sessionAsync: sessionAsync,
        onLogout: _logout,
        onSessionAction: _handleSessionAction,
      ),
      body: Stack(
        children: [
          widget.child,
          const FloatingChatbot(),
        ],
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
  final Map<String, dynamic> user;
  final List<dynamic> menus;
  final AsyncValue<Map<String, dynamic>?> sessionAsync;
  final Function(BuildContext) onLogout;
  final Function(BuildContext, Map<String, dynamic>?) onSessionAction;

  const _DesktopSidebar({
    required this.location,
    required this.user,
    required this.menus,
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
          ref.watch(settingsProvider).when(
            data: (settings) {
              final logoUrl = settings['logo_url'];
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colorScheme.primary, colorScheme.primary.withRed(200)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (logoUrl != null && logoUrl.toString().isNotEmpty && logoUrl.toString() != '/')
                      Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            )
                          ],
                          image: DecorationImage(
                            image: NetworkImage('${ref.watch(imageBaseUrlProvider)}$logoUrl'),
                            fit: BoxFit.contain,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 64,
                        height: 64,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.restaurant, color: Colors.white, size: 40),
                      ),
                    const Text(
                      'NFM POS',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white, letterSpacing: 0.5),
                    ),
                    Text(
                      'Smart Restaurant Solution',
                      style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            },
            loading: () => Container(height: 140, color: colorScheme.primary),
            error: (_, __) => Container(height: 140, color: colorScheme.primary, child: const Center(child: Text('NFM POS', style: TextStyle(color: Colors.white)))),
          ),

          // ─── Profile Section ──────────────────────────────────────
          InkWell(
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
                      (user['username'] ?? 'U').substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['username'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(user['role']?['name'] ?? '-', style: TextStyle(fontSize: 11, color: colorScheme.outline)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: colorScheme.outline),
                ],
              ),
            ),
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
              children: menus.map((menu) {
                if (menu['is_header'] == true) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      menu['title']?.toUpperCase() ?? '',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.outline, letterSpacing: 1),
                    ),
                  );
                }
                final iconData = _getIconData(menu['icon']);
                return _SidebarItem(
                  title: menu['title'] ?? '',
                  path: menu['path'] ?? '',
                  icon: iconData,
                  location: location,
                );
              }).toList(),
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
  final Map<String, dynamic> user;
  final List<dynamic> menus;
  final AsyncValue<Map<String, dynamic>?> sessionAsync;
  final Function(BuildContext) onLogout;
  final Function(BuildContext, Map<String, dynamic>?) onSessionAction;

  const _MobileDrawer({
    required this.location,
    required this.user,
    required this.menus,
    required this.sessionAsync,
    required this.onLogout,
    required this.onSessionAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ref.watch(settingsProvider).when(
            data: (settings) {
              final logoUrl = settings['logo_url'];
              return DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.primaryContainer],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (logoUrl != null && logoUrl.toString().isNotEmpty && logoUrl.toString() != '/')
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                          image: DecorationImage(
                            image: NetworkImage('${ref.watch(imageBaseUrlProvider)}$logoUrl'),
                            fit: BoxFit.contain,
                          ),
                        ),
                      )
                    else
                      const Icon(Icons.restaurant, color: Colors.white, size: 48),
                    const SizedBox(height: 8),
                    const Text('NFM POS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                  ],
                ),
              );
            },
            loading: () => DrawerHeader(child: Container()),
            error: (_, __) => const DrawerHeader(child: Text('NFM POS')),
          ),
          ...menus.map((menu) {
            if (menu['is_header'] == true) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(menu['title'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              );
            }
            return ListTile(
              leading: Icon(_getIconData(menu['icon'])),
              title: Text(menu['title'] ?? ''),
              selected: location == menu['path'],
              onTap: () { Navigator.pop(context); context.go(menu['path']); },
            );
          }),
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
  final String title;
  final String path;
  final IconData icon;
  final String location;

  const _SidebarItem({
    required this.title,
    required this.path,
    required this.icon,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = location == path;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(
          icon,
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? colorScheme.primary : null,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
        ),
        selected: isSelected,
        selectedTileColor: colorScheme.primaryContainer,
        onTap: () => context.go(path),
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

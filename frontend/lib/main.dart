import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/profile_screen.dart';
import 'features/order/presentation/pos_screen.dart';
import 'features/order/presentation/order_detail_screen.dart';
import 'features/payment/presentation/payment_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/kitchen/presentation/kitchen_display_screen.dart';
import 'features/user/presentation/user_management_screen.dart';
import 'features/menu/presentation/menu_management_screen.dart';
import 'features/promo/presentation/promo_management_screen.dart';
import 'features/supplier/presentation/supplier_management_screen.dart';
import 'features/customer/presentation/customer_management_screen.dart';
import 'features/order/presentation/order_list_screen.dart';
import 'features/branch/presentation/branch_management_screen.dart';
import 'features/table/presentation/table_management_screen.dart';
import 'features/report/presentation/financial_report_screen.dart';
import 'features/report/presentation/ingredient_report_screen.dart';
import 'features/finance/presentation/coa_management_screen.dart';
import 'features/finance/presentation/journal_list_screen.dart';
import 'features/finance/presentation/general_ledger_screen.dart';
import 'features/ingredient/presentation/ingredient_management_screen.dart';
import 'features/ingredient/presentation/stock_management_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/wa_log/presentation/wa_log_screen.dart';
import 'shared/widgets/sidebar_layout.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await dotenv.load(fileName: ".env");
  runApp(
    const ProviderScope(
      child: PosApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => SidebarLayout(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/pos',
          builder: (context, state) => const PosScreen(),
        ),
        GoRoute(
          path: '/payment',
          builder: (context, state) {
            final idStr = state.uri.queryParameters['orderId'];
            final orderId = idStr != null ? int.tryParse(idStr) : null;
            return PaymentScreen(orderId: orderId);
          },
        ),
        GoRoute(
          path: '/kitchen',
          builder: (context, state) => const KitchenDisplayScreen(),
        ),
        GoRoute(
          path: '/orders',
          builder: (context, state) => const OrderListScreen(),
        ),
        GoRoute(
          path: '/orders/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return OrderDetailScreen(orderId: id);
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/customers',
          builder: (context, state) => const CustomerManagementScreen(),
        ),
        // Management routes
        GoRoute(
          path: '/menus',
          builder: (context, state) => const MenuManagementScreen(),
        ),
        GoRoute(
          path: '/promos',
          builder: (context, state) => const PromoManagementScreen(),
        ),
        GoRoute(
          path: '/users',
          builder: (context, state) => const UserManagementScreen(),
        ),
        GoRoute(
          path: '/roles',
          builder: (context, state) => const RoleManagementScreen(),
        ),
        GoRoute(
          path: '/suppliers',
          builder: (context, state) => const SupplierManagementScreen(),
        ),
        GoRoute(
          path: '/branches',
          builder: (context, state) => const BranchManagementScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const FinancialReportScreen(),
        ),
        GoRoute(
          path: '/manage-tables',
          builder: (context, state) => const TableManagementScreen(),
        ),
        GoRoute(
          path: '/finance/coa',
          builder: (context, state) => const CoaManagementScreen(),
        ),
        GoRoute(
          path: '/finance/journal',
          builder: (context, state) => const JournalListScreen(),
        ),
        GoRoute(
          path: '/finance/ledger',
          builder: (context, state) => const GeneralLedgerScreen(),
        ),
        GoRoute(
          path: '/ingredients',
          builder: (context, state) => const IngredientManagementScreen(),
        ),
        GoRoute(
          path: '/stock',
          builder: (context, state) => const StockManagementScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/reports/ingredients',
          builder: (context, state) => const IngredientReportScreen(),
        ),
        GoRoute(
          path: '/wa-logs',
          builder: (context, state) => const WALogScreen(),
        ),
      ],
    ),
  ],
);

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'POS Resto Modern',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE65100), // Deep orange
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE65100),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}

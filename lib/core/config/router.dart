import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/profile_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/products/product_list_screen.dart';
import '../../features/products/product_form_screen.dart';
import '../../features/products/product_detail_screen.dart';
import '../../features/barcode/barcode_scanner_screen.dart';
import '../../features/barcode/barcode_label_screen.dart';
import '../../features/stock_in/stock_in_screen.dart';
import '../../features/stock_out/stock_out_screen.dart';
import '../../features/inventory/inventory_screen.dart';
import '../../features/inventory/stock_card_screen.dart';
import '../../features/inventory/stock_opname_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/users/user_management_screen.dart';
import '../../features/settings/master_data_screen.dart';
import '../../features/testing/maestro_test_screen.dart';
import '../../shared/models/product.dart';
import '../../shared/models/inventory_item.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return AppScaffold(
          currentRoute: state.uri.path,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/products',
          builder: (context, state) => const ProductListScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const ProductFormScreen(),
            ),
            GoRoute(
              path: 'edit',
              builder: (context, state) => ProductFormScreen(
                productToEdit: state.extra as Product?,
              ),
            ),
            GoRoute(
              path: 'detail/:id',
              builder: (context, state) => ProductDetailScreen(
                productId: state.pathParameters['id']!,
                product: state.extra as Product?,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/barcode/scan',
          builder: (context, state) => const BarcodeScannerScreen(),
        ),
        GoRoute(
          path: '/barcode/print',
          builder: (context, state) {
            final product = state.extra as Product;
            return BarcodeLabelScreen(product: product);
          },
        ),
        GoRoute(
          path: '/stock-in',
          builder: (context, state) => const StockInScreen(),
        ),
        GoRoute(
          path: '/stock-out',
          builder: (context, state) => const StockOutScreen(),
        ),
        GoRoute(
          path: '/inventory',
          builder: (context, state) => const InventoryScreen(),
          routes: [
            GoRoute(
              path: 'card/:id',
              builder: (context, state) => StockCardScreen(
                productId: state.pathParameters['id']!,
                inventoryItem: state.extra as InventoryItem?,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/opname',
          builder: (context, state) => const StockOpnameScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/master',
          builder: (context, state) => const MasterDataScreen(),
        ),
        GoRoute(
          path: '/users',
          builder: (context, state) => const UserManagementScreen(),
        ),
        GoRoute(
          path: '/testing',
          builder: (context, state) => const MaestroTestScreen(),
        ),
      ],
    ),
  ],
);


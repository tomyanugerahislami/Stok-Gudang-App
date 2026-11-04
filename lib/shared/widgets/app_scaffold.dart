import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../../core/utils/responsive.dart';
import '../models/user_profile.dart';
import '../models/warehouse.dart';

class NavDestinationItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final bool Function(UserProfile? profile) isVisible;

  NavDestinationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    required this.isVisible,
  });
}

class AppScaffold extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const AppScaffold({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  static final List<NavDestinationItem> navItems = [
    NavDestinationItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      route: '/',
      isVisible: (_) => true,
    ),
    NavDestinationItem(
      label: 'Produk',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      route: '/products',
      isVisible: (_) => true,
    ),
    NavDestinationItem(
      label: 'Scan Barcode',
      icon: Icons.qr_code_scanner_outlined,
      selectedIcon: Icons.qr_code_scanner,
      route: '/barcode/scan',
      isVisible: (_) => true,
    ),
    NavDestinationItem(
      label: 'Barang Masuk',
      icon: Icons.move_to_inbox_outlined,
      selectedIcon: Icons.move_to_inbox,
      route: '/stock-in',
      isVisible: (p) => p == null || p.canCreateTransaction,
    ),
    NavDestinationItem(
      label: 'Barang Keluar',
      icon: Icons.outbox_outlined,
      selectedIcon: Icons.outbox,
      route: '/stock-out',
      isVisible: (p) => p == null || p.canCreateTransaction,
    ),
    NavDestinationItem(
      label: 'Stok & Mutasi',
      icon: Icons.format_list_bulleted_outlined,
      selectedIcon: Icons.format_list_bulleted,
      route: '/inventory',
      isVisible: (_) => true,
    ),
    NavDestinationItem(
      label: 'Stok Opname',
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check,
      route: '/opname',
      isVisible: (p) => p == null || p.isAdmin || p.isStaff,
    ),
    NavDestinationItem(
      label: 'Laporan',
      icon: Icons.assessment_outlined,
      selectedIcon: Icons.assessment,
      route: '/reports',
      isVisible: (p) => p == null || p.isAdmin || p.isManager,
    ),
    NavDestinationItem(
      label: 'Master Data',
      icon: Icons.folder_shared_outlined,
      selectedIcon: Icons.folder_shared,
      route: '/master',
      isVisible: (p) => p == null || p.isAdmin,
    ),
    NavDestinationItem(
      label: 'Pengguna',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      route: '/users',
      isVisible: (p) => p == null || p.isAdmin,
    ),
    NavDestinationItem(
      label: 'UI Testing',
      icon: Icons.bug_report_outlined,
      selectedIcon: Icons.bug_report,
      route: '/testing',
      isVisible: (p) => p == null || p.isAdmin,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.value;
    final warehousesAsync = ref.watch(warehousesProvider);
    final selectedWarehouse = ref.watch(selectedWarehouseProvider);

    final visibleItems = navItems.where((item) => item.isVisible(profile)).toList();

    return Responsive(
      mobile: _buildMobileScaffold(context, ref, profile, visibleItems, warehousesAsync.value, selectedWarehouse),
      tablet: _buildTabletScaffold(context, ref, profile, visibleItems, warehousesAsync.value, selectedWarehouse),
      desktop: _buildDesktopScaffold(context, ref, profile, visibleItems, warehousesAsync.value, selectedWarehouse),
    );
  }

  // --- Mobile Scaffold ---
  Widget _buildMobileScaffold(
    BuildContext context,
    WidgetRef ref,
    UserProfile? profile,
    List<NavDestinationItem> items,
    List<Warehouse>? warehouses,
    Warehouse? selectedWarehouse,
  ) {
    // Top 4 items for bottom bar
    final bottomNavItems = [
      items.firstWhere((i) => i.route == '/', orElse: () => items[0]),
      items.firstWhere((i) => i.route == '/products', orElse: () => items[0]),
      items.firstWhere((i) => i.route == '/stock-in', orElse: () => items[0]),
      items.firstWhere((i) => i.route == '/inventory', orElse: () => items[0]),
    ];

    int currentIndex = bottomNavItems.indexWhere((i) => currentRoute == i.route);
    if (currentIndex == -1) currentIndex = 0;

    return Scaffold(
      appBar: AppBar(
        title: _buildAppTitle(),
        actions: [
          _buildWarehouseSelector(context, ref, warehouses, selectedWarehouse),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan Barcode',
            onPressed: () => context.go('/barcode/scan'),
          ),
          _buildUserAvatarMenu(context, ref, profile),
        ],
      ),
      drawer: Drawer(
        child: _buildDrawerContent(context, ref, profile, items),
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (idx) {
          context.go(bottomNavItems[idx].route);
        },
        destinations: bottomNavItems.map((item) {
          return NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: item.label,
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/barcode/scan'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }

  // --- Tablet Scaffold ---
  Widget _buildTabletScaffold(
    BuildContext context,
    WidgetRef ref,
    UserProfile? profile,
    List<NavDestinationItem> items,
    List<Warehouse>? warehouses,
    Warehouse? selectedWarehouse,
  ) {
    int selectedIndex = items.indexWhere((i) => currentRoute.startsWith(i.route) && i.route != '/' ? true : currentRoute == i.route);
    if (selectedIndex == -1) selectedIndex = 0;

    return Scaffold(
      appBar: AppBar(
        title: _buildAppTitle(),
        actions: [
          _buildWarehouseSelector(context, ref, warehouses, selectedWarehouse),
          _buildUserAvatarMenu(context, ref, profile),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (idx) => context.go(items[idx].route),
            labelType: NavigationRailLabelType.selected,
            destinations: items.map((item) {
              return NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: Text(item.label, style: const TextStyle(fontSize: 11)),
              );
            }).toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  // --- Desktop Scaffold ---
  Widget _buildDesktopScaffold(
    BuildContext context,
    WidgetRef ref,
    UserProfile? profile,
    List<NavDestinationItem> items,
    List<Warehouse>? warehouses,
    Warehouse? selectedWarehouse,
  ) {
    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar
          Container(
            width: 250,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Material(
              color: Colors.white,
              child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.warehouse,
                          color: Theme.of(context).colorScheme.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stok Gudang',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Manajemen Stok v1.0',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    children: items.map((item) {
                      final isSelected = currentRoute == item.route ||
                          (item.route != '/' && currentRoute.startsWith(item.route));

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          tileColor: isSelected
                              ? Theme.of(context).colorScheme.primary.withAlpha(20)
                              : Colors.transparent,
                          leading: Icon(
                            isSelected ? item.selectedIcon : item.icon,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : const Color(0xFF64748B),
                            size: 20,
                          ),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : const Color(0xFF334155),
                              fontSize: 13,
                            ),
                          ),
                          onTap: () => context.go(item.route),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // User & Role Card at bottom of sidebar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(
                      top: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          (profile?.nama.isNotEmpty == true)
                              ? profile!.nama.substring(0, 1).toUpperCase()
                              : 'U',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              profile?.nama ?? 'Pengguna',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getRoleBadgeColor(profile?.role).withAlpha(30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                profile?.role ?? 'Staff Gudang',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getRoleBadgeColor(profile?.role),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, size: 18, color: Color(0xFF64748B)),
                        tooltip: 'Keluar',
                        onPressed: () => _handleLogout(context, ref),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
          // Main Body Area
          Expanded(
            child: Column(
              children: [
                // Top App Bar for Desktop
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Spacer(),
                      _buildWarehouseSelector(context, ref, warehouses, selectedWarehouse),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF475569)),
                        tooltip: 'Scan Barcode',
                        onPressed: () => context.go('/barcode/scan'),
                      ),
                      const SizedBox(width: 8),
                      _buildRoleSwitcher(context, ref, profile),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Subcomponents ---

  Widget _buildAppTitle() {
    return const Row(
      children: [
        Icon(Icons.warehouse, color: Color(0xFF1E3A8A)),
        SizedBox(width: 8),
        Text('Stok Gudang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  Widget _buildWarehouseSelector(
    BuildContext context,
    WidgetRef ref,
    List<Warehouse>? warehouses,
    Warehouse? selectedWarehouse,
  ) {
    if (warehouses == null || warehouses.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Warehouse?>(
          value: selectedWarehouse,
          hint: const Text('Semua Gudang', style: TextStyle(fontSize: 12)),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          items: [
            const DropdownMenuItem<Warehouse?>(
              value: null,
              child: Text('Semua Gudang', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            ...warehouses.map((w) {
              return DropdownMenuItem<Warehouse?>(
                value: w,
                child: Text('${w.kode} - ${w.nama}', style: const TextStyle(fontSize: 12)),
              );
            }),
          ],
          onChanged: (newWh) {
            ref.read(selectedWarehouseProvider.notifier).set(newWh);
            ref.invalidate(inventoryProvider);
          },
        ),
      ),
    );
  }

  Widget _buildRoleSwitcher(BuildContext context, WidgetRef ref, UserProfile? profile) {
    // Quick role switch for convenience during review & testing
    return PopupMenuButton<String>(
      tooltip: 'Ganti Role Pengguna',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _getRoleBadgeColor(profile?.role).withAlpha(25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _getRoleBadgeColor(profile?.role).withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.badge, size: 16, color: _getRoleBadgeColor(profile?.role)),
            const SizedBox(width: 6),
            Text(
              profile?.role ?? 'Role',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getRoleBadgeColor(profile?.role),
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
      onSelected: (role) {
        ref.read(supabaseServiceProvider).switchMockRole(role);
        ref.invalidate(currentProfileProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Beralih ke role: $role'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'Admin',
          child: Text('Admin (Akses Penuh)'),
        ),
        const PopupMenuItem(
          value: 'Staff Gudang',
          child: Text('Staff Gudang (Transaksi Masuk/Keluar)'),
        ),
        const PopupMenuItem(
          value: 'Manager',
          child: Text('Manager (Dashboard & Laporan)'),
        ),
      ],
    );
  }

  Widget _buildUserAvatarMenu(BuildContext context, WidgetRef ref, UserProfile? profile) {
    return PopupMenuButton<String>(
      icon: CircleAvatar(
        radius: 14,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Text(
          (profile?.nama.isNotEmpty == true) ? profile!.nama.substring(0, 1).toUpperCase() : 'U',
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
      onSelected: (val) {
        if (val == 'profile') {
          context.go('/profile');
        } else if (val == 'logout') {
          _handleLogout(context, ref);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile?.nama ?? 'Pengguna', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(profile?.role ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 18),
              SizedBox(width: 8),
              Text('Profil Saya'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Keluar', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerContent(
    BuildContext context,
    WidgetRef ref,
    UserProfile? profile,
    List<NavDestinationItem> items,
  ) {
    return Column(
      children: [
        UserAccountsDrawerHeader(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
          ),
          currentAccountPicture: CircleAvatar(
            backgroundColor: Colors.white,
            child: Text(
              (profile?.nama.isNotEmpty == true) ? profile!.nama.substring(0, 1).toUpperCase() : 'U',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          accountName: Text(profile?.nama ?? 'Pengguna Gudang', style: const TextStyle(fontWeight: FontWeight.bold)),
          accountEmail: Text('${profile?.email ?? ""} • ${profile?.role ?? ""}'),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: items.map((item) {
              final isSelected = currentRoute == item.route;
              return ListTile(
                leading: Icon(item.icon, color: isSelected ? Theme.of(context).colorScheme.primary : null),
                title: Text(
                  item.label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Theme.of(context).colorScheme.primary : null,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go(item.route);
                },
              );
            }).toList(),
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Keluar', style: TextStyle(color: Colors.red)),
          onTap: () => _handleLogout(context, ref),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    await ref.read(supabaseServiceProvider).signOut();
    ref.invalidate(currentProfileProvider);
    if (context.mounted) {
      context.go('/login');
    }
  }

  Color _getRoleBadgeColor(String? role) {
    switch (role) {
      case 'Admin':
        return const Color(0xFF7C3AED); // Purple
      case 'Manager':
        return const Color(0xFF0284C7); // Sky Blue
      case 'Staff Gudang':
      default:
        return const Color(0xFF0D9488); // Teal
    }
  }
}


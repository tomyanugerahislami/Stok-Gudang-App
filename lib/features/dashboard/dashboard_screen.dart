import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../shared/models/inventory_item.dart';
import '../../shared/models/stock_transaction.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final user = profileAsync.value;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardMetricsProvider);
        ref.invalidate(inventoryProvider);
        ref.invalidate(productsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome & Quick Action Header
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${user?.nama ?? "Pengguna"} 👋',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ringkasan aktivitas stok gudang hari ini (${Formatters.date(DateTime.now())})',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner, size: 18),
                      label: const Text('Scan'),
                      onPressed: () => context.go('/barcode/scan'),
                    ),
                    if (user == null || user.canCreateTransaction) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                        icon: const Icon(Icons.move_to_inbox, size: 18),
                        label: const Text('Barang Masuk'),
                        onPressed: () => context.go('/stock-in'),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C)),
                        icon: const Icon(Icons.outbox, size: 18),
                        label: const Text('Barang Keluar'),
                        onPressed: () => context.go('/stock-out'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Metrics Cards Grid
            metricsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Gagal memuat metrik: $err', style: const TextStyle(color: Color(0xFFDC2626))),
              ),
              data: (data) {
                final totalProducts = data['totalProducts'] as double;
                final totalStock = data['totalStock'] as double;
                final inToday = data['inToday'] as double;
                final outToday = data['outToday'] as double;
                final lowStockCount = data['lowStockCount'] as int;
                final lowStockItems = data['lowStockItems'] as List<InventoryItem>;
                final recentTransactions = data['recentTransactions'] as List<StockTransaction>;

                final isMobile = Responsive.isMobile(context);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stat cards row
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = constraints.maxWidth < 600 ? 2 : 4;
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: crossAxisCount == 2 ? 1.4 : 1.7,
                          children: [
                            _buildStatCard(
                              title: 'Jumlah Produk',
                              value: Formatters.number(totalProducts),
                              subtitle: 'Aktif di katalog',
                              icon: Icons.inventory_2,
                              color: const Color(0xFF2563EB),
                              onTap: () => context.go('/products'),
                            ),
                            _buildStatCard(
                              title: 'Total Stok',
                              value: Formatters.number(totalStock),
                              subtitle: 'Seluruh gudang',
                              icon: Icons.layers,
                              color: const Color(0xFF0D9488),
                              onTap: () => context.go('/inventory'),
                            ),
                            _buildStatCard(
                              title: 'Barang Masuk Hari Ini',
                              value: '+${Formatters.number(inToday)}',
                              subtitle: 'Item diterima',
                              icon: Icons.arrow_downward,
                              color: const Color(0xFF16A34A),
                              onTap: () => context.go('/inventory'),
                            ),
                            _buildStatCard(
                              title: 'Barang Keluar Hari Ini',
                              value: '-${Formatters.number(outToday)}',
                              subtitle: 'Item keluar',
                              icon: Icons.arrow_upward,
                              color: const Color(0xFFEA580C),
                              onTap: () => context.go('/inventory'),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Low Stock Alert Banner (if any)
                    if (lowStockCount > 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 28),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$lowStockCount Produk Mencapai Stok Minimum!',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF92400E),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Segera lakukan pengadaan barang masuk untuk produk yang stoknya menipis.',
                                    style: TextStyle(color: Color(0xFFB45309), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go('/inventory'),
                              child: const Text('Lihat Detail', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),

                    // Split Layout for Desktop / Stacked for Mobile: Low Stock Items & Recent Transactions
                    if (isMobile) ...[
                      _buildLowStockSection(context, lowStockItems),
                      const SizedBox(height: 24),
                      _buildRecentTransactionsSection(context, recentTransactions),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _buildLowStockSection(context, lowStockItems),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 6,
                            child: _buildRecentTransactionsSection(context, recentTransactions),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLowStockSection(BuildContext context, List<InventoryItem> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.inventory, size: 20, color: Color(0xFFD97706)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Peringatan Stok Minimum',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/inventory'),
                  child: const Text('Semua Stok', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const Divider(),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Semua produk memiliki stok di atas batas minimum 🎉',
                    style: TextStyle(color: Color(0xFF16A34A), fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.take(4).length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text('${item.productSku} • ${item.warehouseName}', style: const TextStyle(fontSize: 11)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Sisa: ${Formatters.number(item.quantity)} ${item.productUnit}',
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Min: ${Formatters.number(item.minimumStock)} ${item.productUnit}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsSection(BuildContext context, List<StockTransaction> transactions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.history, size: 20, color: Color(0xFF1E3A8A)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Transaksi Terbaru',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/inventory'),
                  child: const Text('Lihat Riwayat', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const Divider(),
            if (transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Belum ada transaksi tercatat.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.take(5).length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  final isIncoming = tx.tipe == 'IN';
                  final isOutgoing = tx.tipe == 'OUT';

                  final typeColor = isIncoming
                      ? const Color(0xFF16A34A)
                      : isOutgoing
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF2563EB);

                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: typeColor.withAlpha(25),
                      child: Icon(
                        isIncoming
                            ? Icons.arrow_downward
                            : isOutgoing
                                ? Icons.arrow_upward
                                : Icons.sync,
                        color: typeColor,
                        size: 16,
                      ),
                    ),
                    title: Text(
                      '${tx.nomorTransaksi} (${tx.tipe})',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    subtitle: Text(
                      '${Formatters.date(tx.tanggal)} • ${tx.supplierName ?? tx.customerName ?? tx.recipient ?? tx.warehouseName ?? ""}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (tx.isCompleted ? const Color(0xFF16A34A) : Colors.orange).withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tx.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: tx.isCompleted ? const Color(0xFF16A34A) : Colors.orange,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}


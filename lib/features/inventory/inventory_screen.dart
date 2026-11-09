import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../shared/models/inventory_item.dart';
import '../../shared/models/stock_transaction.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleCancelTransaction(StockTransaction tx) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Batalkan Transaksi ${tx.nomorTransaksi}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pembatalan akan mengembalikan seluruh mutasi stok secara atomik dan mencatat audit trail.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Alasan Pembatalan *',
                hintText: 'Salah input / pesanan dibatalkan',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tutup')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Batalkan Transaksi'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = ref.read(supabaseServiceProvider);
        await service.cancelTransaction(tx.id, reasonController.text.trim());

        ref.invalidate(inventoryProvider);
        ref.invalidate(transactionsProvider);
        ref.invalidate(dashboardMetricsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaksi berhasil dibatalkan dan stok dikembalikan')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: Colors.red, content: Text('Gagal membatalkan: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final selectedWh = ref.watch(selectedWarehouseProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stok Gudang & Mutasi',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedWh != null
                          ? 'Menampilkan stok untuk: ${selectedWh.nama}'
                          : 'Menampilkan stok untuk: Seluruh Gudang',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.fact_check, size: 18),
                      label: const Text('Stok Opname'),
                      onPressed: () => context.go('/opname'),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.assessment_outlined, size: 18),
                      label: const Text('Laporan'),
                      onPressed: () => context.go('/reports'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(icon: Icon(Icons.inventory, size: 18), text: 'Stok Terkini'),
                Tab(icon: Icon(Icons.history, size: 18), text: 'Riwayat Seluruh Mutasi'),
              ],
            ),
            const SizedBox(height: 16),

            // Tab View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Current Stock
                  inventoryAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Gagal memuat stok: $err')),
                    data: (items) => _buildStockList(context, items),
                  ),

                  // Tab 2: Transaction History
                  transactionsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Gagal memuat mutasi: $err')),
                    data: (txs) => _buildTransactionList(context, txs),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockList(BuildContext context, List<InventoryItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Tidak ada data stok untuk filter ini.'),
      );
    }

    final isDesktop = Responsive.isDesktop(context);

    if (isDesktop) {
      return Card(
        child: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columns: const [
                DataColumn(label: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Nama Produk', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Gudang', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Barcode', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Stok Saat Ini', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Stok Min', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: items.map((item) {
                final isLow = item.isLowStock;
                return DataRow(
                  cells: [
                    DataCell(Text(item.productSku, style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text(item.warehouseName)),
                    DataCell(Text(item.barcode, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                    DataCell(
                      Text(
                        '${Formatters.number(item.quantity)} ${item.productUnit}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isLow ? Colors.red : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    DataCell(Text('${Formatters.number(item.minimumStock)} ${item.productUnit}')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isLow ? Colors.red : Colors.green).withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isLow ? 'MENIPIS' : 'AMAN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isLow ? Colors.red : Colors.green.shade800,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          textStyle: const TextStyle(fontSize: 11),
                        ),
                        icon: const Icon(Icons.history_edu, size: 14),
                        label: const Text('Kartu Stok'),
                        onPressed: () {
                          context.go('/inventory/card/${item.productId}', extra: item);
                        },
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, idx) {
        final item = items[idx];
        final isLow = item.isLowStock;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${item.productSku} • ${item.warehouseName}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${Formatters.number(item.quantity)} ${item.productUnit}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isLow ? Colors.red : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  isLow ? 'Stok Menipis' : 'Stok Aman',
                  style: TextStyle(fontSize: 10, color: isLow ? Colors.red : Colors.green),
                ),
              ],
            ),
            onTap: () {
              context.go('/inventory/card/${item.productId}', extra: item);
            },
          ),
        );
      },
    );
  }

  Widget _buildTransactionList(BuildContext context, List<StockTransaction> transactions) {
    if (transactions.isEmpty) {
      return const Center(
        child: Text('Belum ada transaksi tercatat.'),
      );
    }

    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, idx) {
        final tx = transactions[idx];
        final isIncoming = tx.tipe == 'IN';
        final isOutgoing = tx.tipe == 'OUT';

        final color = isIncoming
            ? const Color(0xFF16A34A)
            : isOutgoing
                ? const Color(0xFFDC2626)
                : const Color(0xFF2563EB);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: color.withAlpha(25),
              child: Icon(
                isIncoming
                    ? Icons.arrow_downward
                    : isOutgoing
                        ? Icons.arrow_upward
                        : Icons.sync,
                color: color,
              ),
            ),
            title: Row(
              children: [
                Text(tx.nomorTransaksi, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tx.tipe,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              '${Formatters.date(tx.tanggal)} • ${tx.warehouseName ?? "Gudang"} • Oleh: ${tx.creatorName ?? "Staff"}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (tx.isCompleted ? Colors.green : Colors.grey).withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tx.status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: tx.isCompleted ? Colors.green.shade800 : Colors.grey.shade700,
                ),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tx.documentNumber != null && tx.documentNumber!.isNotEmpty)
                      Text('No Dokumen: ${tx.documentNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    if (tx.supplierName != null)
                      Text('Supplier: ${tx.supplierName}', style: const TextStyle(fontSize: 12)),
                    if (tx.customerName != null)
                      Text('Pelanggan: ${tx.customerName}', style: const TextStyle(fontSize: 12)),
                    if (tx.recipient != null && tx.recipient!.isNotEmpty)
                      Text('Penerima: ${tx.recipient}', style: const TextStyle(fontSize: 12)),
                    if (tx.catatan != null && tx.catatan!.isNotEmpty)
                      Text('Catatan: ${tx.catatan}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                    const Divider(height: 16),
                    const Text('Item Transaksi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    ...tx.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item.productName} (${item.productSku})', style: const TextStyle(fontSize: 12)),
                            Text(
                              '${isIncoming ? "+" : isOutgoing ? "-" : ""}${Formatters.number(item.quantity)} ${item.productUnit}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (tx.isCompleted) ...[
                      const Divider(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text('Batalkan Transaksi & Revert Stok', style: TextStyle(fontSize: 12)),
                          onPressed: () => _handleCancelTransaction(tx),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


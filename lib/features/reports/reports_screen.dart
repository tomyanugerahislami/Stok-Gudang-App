import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/inventory_item.dart';
import '../../shared/models/stock_transaction.dart';
import 'export_service.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _reportType = 'STOK'; // 'STOK', 'IN', 'OUT', 'LOW_STOCK'
  String? _warehouseId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final warehousesAsync = ref.watch(warehousesProvider);

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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Laporan & Analitik Stok',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Pantau pergerakan barang dan cetak laporan resmi dalam format PDF atau Excel',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 12,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.table_chart_outlined, color: Colors.green),
                      label: const Text('Ekspor Excel (.xlsx)'),
                      onPressed: _isExporting ? null : () => _handleExportExcel(inventoryAsync.value, transactionsAsync.value),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text('Ekspor PDF'),
                      onPressed: _isExporting ? null : () => _handleExportPdf(inventoryAsync.value, transactionsAsync.value),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Filter Toolbar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Report Type Selector
                    DropdownButton<String>(
                      value: _reportType,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 'STOK', child: Text('Laporan Stok Terkini')),
                        DropdownMenuItem(value: 'IN', child: Text('Laporan Barang Masuk')),
                        DropdownMenuItem(value: 'OUT', child: Text('Laporan Barang Keluar')),
                        DropdownMenuItem(value: 'LOW_STOCK', child: Text('Laporan Stok Minimum')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _reportType = val);
                      },
                    ),

                    // Warehouse filter
                    warehousesAsync.when(
                      data: (whs) => DropdownButton<String?>(
                        value: _warehouseId,
                        hint: const Text('Semua Gudang'),
                        underline: const SizedBox.shrink(),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Semua Gudang')),
                          ...whs.map((w) => DropdownMenuItem(value: w.id, child: Text(w.nama))),
                        ],
                        onChanged: (val) => setState(() => _warehouseId = val),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),

                    // Date range picker for transactions
                    if (_reportType == 'IN' || _reportType == 'OUT') ...[
                      OutlinedButton.icon(
                        icon: const Icon(Icons.date_range, size: 16),
                        label: Text('${Formatters.date(_startDate)} - ${Formatters.date(_endDate)}'),
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                          );
                          if (picked != null) {
                            setState(() {
                              _startDate = picked.start;
                              _endDate = picked.end;
                            });
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Live Preview Table
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildReportPreview(inventoryAsync, transactionsAsync),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportPreview(
    AsyncValue<List<InventoryItem>> inventoryAsync,
    AsyncValue<List<StockTransaction>> transactionsAsync,
  ) {
    if (_reportType == 'STOK' || _reportType == 'LOW_STOCK') {
      return inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (items) {
          var filtered = _warehouseId != null
              ? items.where((i) => i.warehouseId == _warehouseId).toList()
              : items;

          if (_reportType == 'LOW_STOCK') {
            filtered = filtered.where((i) => i.isLowStock).toList();
          }

          if (filtered.isEmpty) {
            return const Center(child: Text('Tidak ada data laporan.'));
          }

          return SingleChildScrollView(
            child: SizedBox(
              width: double.infinity,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('SKU')),
                  DataColumn(label: Text('Nama Produk')),
                  DataColumn(label: Text('Gudang')),
                  DataColumn(label: Text('Stok Saat Ini')),
                  DataColumn(label: Text('Batas Minimum')),
                  DataColumn(label: Text('Status')),
                ],
                rows: filtered.map((i) {
                  return DataRow(
                    cells: [
                      DataCell(Text(i.productSku, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(i.productName)),
                      DataCell(Text(i.warehouseName)),
                      DataCell(Text('${Formatters.number(i.quantity)} ${i.productUnit}', style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('${Formatters.number(i.minimumStock)} ${i.productUnit}')),
                      DataCell(
                        Text(
                          i.isLowStock ? 'MENIPIS' : 'AMAN',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: i.isLowStock ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      );
    } else {
      return transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (txs) {
          final filtered = txs.where((t) {
            if (t.tipe != _reportType) return false;
            if (_warehouseId != null && t.warehouseId != _warehouseId) return false;
            if (t.tanggal.isBefore(_startDate) || t.tanggal.isAfter(_endDate.add(const Duration(days: 1)))) {
              return false;
            }
            return true;
          }).toList();

          if (filtered.isEmpty) {
            return const Center(child: Text('Tidak ada transaksi pada periode ini.'));
          }

          return SingleChildScrollView(
            child: SizedBox(
              width: double.infinity,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('No Transaksi')),
                  DataColumn(label: Text('Tanggal')),
                  DataColumn(label: Text('Gudang')),
                  DataColumn(label: Text('Pihak Terkait')),
                  DataColumn(label: Text('No Dokumen')),
                  DataColumn(label: Text('Total Item')),
                  DataColumn(label: Text('Status')),
                ],
                rows: filtered.map((t) {
                  return DataRow(
                    cells: [
                      DataCell(Text(t.nomorTransaksi, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(Formatters.date(t.tanggal))),
                      DataCell(Text(t.warehouseName ?? '-')),
                      DataCell(Text(t.supplierName ?? t.customerName ?? t.recipient ?? '-')),
                      DataCell(Text(t.documentNumber ?? '-')),
                      DataCell(Text('${t.items.length} item')),
                      DataCell(Text(t.status)),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      );
    }
  }

  void _handleExportPdf(List<InventoryItem>? items, List<StockTransaction>? txs) async {
    setState(() => _isExporting = true);
    try {
      if (_reportType == 'STOK' || _reportType == 'LOW_STOCK') {
        if (items != null) {
          var filtered = _warehouseId != null
              ? items.where((i) => i.warehouseId == _warehouseId).toList()
              : items;
          if (_reportType == 'LOW_STOCK') {
            filtered = filtered.where((i) => i.isLowStock).toList();
          }
          await ExportService.exportStockReportPdf(items: filtered);
        }
      } else {
        if (txs != null) {
          final filtered = txs.where((t) => t.tipe == _reportType).toList();
          await ExportService.exportTransactionReportPdf(
            transactions: filtered,
            title: _reportType == 'IN' ? 'Laporan Barang Masuk' : 'Laporan Barang Keluar',
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _handleExportExcel(List<InventoryItem>? items, List<StockTransaction>? txs) async {
    setState(() => _isExporting = true);
    try {
      if (_reportType == 'STOK' || _reportType == 'LOW_STOCK') {
        if (items != null) {
          var filtered = _warehouseId != null
              ? items.where((i) => i.warehouseId == _warehouseId).toList()
              : items;
          if (_reportType == 'LOW_STOCK') {
            filtered = filtered.where((i) => i.isLowStock).toList();
          }
          await ExportService.exportStockReportExcel(items: filtered);
        }
      } else {
        if (txs != null) {
          final filtered = txs.where((t) => t.tipe == _reportType).toList();
          await ExportService.exportTransactionReportExcel(transactions: filtered);
        }
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}


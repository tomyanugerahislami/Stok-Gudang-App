import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/inventory_item.dart';
import '../../shared/models/stock_transaction.dart';

class ExportService {
  /// Export Stock Report to PDF
  static Future<void> exportStockReportPdf({
    required List<InventoryItem> items,
    String? warehouseName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Laporan Stok Gudang', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Gudang: ${warehouseName ?? "Semua Gudang"} • Dicetak: ${Formatters.dateTime(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text('Total Produk: ${items.length}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: ['No', 'SKU', 'Nama Produk', 'Gudang', 'Barcode', 'Stok Saat Ini', 'Stok Min', 'Status'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E3A8A)),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            data: List.generate(items.length, (idx) {
              final i = items[idx];
              return [
                '${idx + 1}',
                i.productSku,
                i.productName,
                i.warehouseName,
                i.barcode,
                '${Formatters.number(i.quantity)} ${i.productUnit}',
                '${Formatters.number(i.minimumStock)} ${i.productUnit}',
                i.isLowStock ? 'MENIPIS' : 'AMAN',
              ];
            }),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Laporan_Stok_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Export Stock Report to Excel (.xlsx)
  static Future<void> exportStockReportExcel({
    required List<InventoryItem> items,
    String? warehouseName,
  }) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel[excel.getDefaultSheet() ?? 'Laporan Stok'];

    // Header row
    sheet.appendRow([
      TextCellValue('No'),
      TextCellValue('SKU'),
      TextCellValue('Nama Produk'),
      TextCellValue('Gudang'),
      TextCellValue('Barcode'),
      TextCellValue('Stok Saat Ini'),
      TextCellValue('Satuan'),
      TextCellValue('Stok Minimum'),
      TextCellValue('Status'),
    ]);

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(item.productSku),
        TextCellValue(item.productName),
        TextCellValue(item.warehouseName),
        TextCellValue(item.barcode),
        DoubleCellValue(item.quantity),
        TextCellValue(item.productUnit),
        DoubleCellValue(item.minimumStock),
        TextCellValue(item.isLowStock ? 'MENIPIS' : 'AMAN'),
      ]);
    }

    final bytes = excel.save();
    if (bytes != null) {
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: 'Laporan_Stok_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      );
    }
  }

  /// Export Transaction Report to PDF
  static Future<void> exportTransactionReportPdf({
    required List<StockTransaction> transactions,
    required String title,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Dicetak: ${Formatters.dateTime(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text('Total Transaksi: ${transactions.length}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: ['No', 'No Transaksi', 'Tipe', 'Tanggal', 'Gudang', 'Pihak Terkait', 'No Dokumen', 'Status'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E3A8A)),
            cellStyle: const pw.TextStyle(fontSize: 9),
            data: List.generate(transactions.length, (idx) {
              final tx = transactions[idx];
              return [
                '${idx + 1}',
                tx.nomorTransaksi,
                tx.tipe,
                Formatters.date(tx.tanggal),
                tx.warehouseName ?? '-',
                tx.supplierName ?? tx.customerName ?? tx.recipient ?? '-',
                tx.documentNumber ?? '-',
                tx.status,
              ];
            }),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Laporan_Transaksi_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Export Transaction Report to Excel (.xlsx)
  static Future<void> exportTransactionReportExcel({
    required List<StockTransaction> transactions,
  }) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel[excel.getDefaultSheet() ?? 'Transaksi'];

    sheet.appendRow([
      TextCellValue('No'),
      TextCellValue('No Transaksi'),
      TextCellValue('Tipe'),
      TextCellValue('Tanggal'),
      TextCellValue('Gudang'),
      TextCellValue('Pihak Terkait'),
      TextCellValue('No Dokumen'),
      TextCellValue('Status'),
      TextCellValue('Petugas'),
      TextCellValue('Catatan'),
    ]);

    for (int i = 0; i < transactions.length; i++) {
      final tx = transactions[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(tx.nomorTransaksi),
        TextCellValue(tx.tipe),
        TextCellValue(Formatters.date(tx.tanggal)),
        TextCellValue(tx.warehouseName ?? ''),
        TextCellValue(tx.supplierName ?? tx.customerName ?? tx.recipient ?? ''),
        TextCellValue(tx.documentNumber ?? ''),
        TextCellValue(tx.status),
        TextCellValue(tx.creatorName ?? ''),
        TextCellValue(tx.catatan ?? ''),
      ]);
    }

    final bytes = excel.save();
    if (bytes != null) {
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: 'Laporan_Transaksi_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      );
    }
  }
}


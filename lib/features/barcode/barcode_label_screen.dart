import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../shared/models/product.dart';
import '../../core/utils/formatters.dart';

class BarcodeLabelScreen extends ConsumerStatefulWidget {
  final Product product;

  const BarcodeLabelScreen({super.key, required this.product});

  @override
  ConsumerState<BarcodeLabelScreen> createState() => _BarcodeLabelScreenState();
}

class _BarcodeLabelScreenState extends ConsumerState<BarcodeLabelScreen> {
  int _copies = 4;
  String _barcodeType = 'CODE128'; // 'CODE128' or 'QR'

  Future<void> _generateAndPrintPdf(bool isDirectPrint) async {
    final pdf = pw.Document();

    final isQr = _barcodeType == 'QR';
    final bwBarcode = isQr ? bw.Barcode.qrCode() : bw.Barcode.code128();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Label Barcode Produk - ${widget.product.nama}',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Total: $_copies label', style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(_copies, (index) {
                return pw.Container(
                  width: 170,
                  height: 100,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        widget.product.nama,
                        maxLines: 1,
                        overflow: pw.TextOverflow.clip,
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'SKU: ${widget.product.sku}',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                      pw.SizedBox(height: 4),
                      pw.SizedBox(
                        height: 45,
                        width: 140,
                        child: pw.BarcodeWidget(
                          barcode: bwBarcode,
                          data: widget.product.barcode,
                          drawText: !isQr,
                          textStyle: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ];
        },
      ),
    );

    if (isDirectPrint) {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Label_${widget.product.sku}.pdf',
      );
    } else {
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'Label_${widget.product.sku}.pdf',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prod = widget.product;
    final isQr = _barcodeType == 'QR';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cetak Label Barcode'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Settings Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Konfigurasi Label',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Format Barcode:', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 16),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'CODE128', label: Text('Code 128 (1D)')),
                                ButtonSegment(value: 'QR', label: Text('QR Code (2D)')),
                              ],
                              selected: {_barcodeType},
                              onSelectionChanged: (set) => setState(() => _barcodeType = set.first),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Jumlah Salinan:', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: _copies > 1 ? () => setState(() => _copies--) : null,
                            ),
                            Text(
                              '$_copies',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => setState(() => _copies++),
                            ),
                            const Spacer(),
                            Wrap(
                              spacing: 8,
                              children: [1, 4, 12, 24].map((count) {
                                return ActionChip(
                                  label: Text('$count pcs'),
                                  onPressed: () => setState(() => _copies = count),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Preview Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text(
                          'Preview Label Satuan',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: 240,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                prod.nama,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'SKU: ${prod.sku}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 75,
                                child: bw.BarcodeWidget(
                                  barcode: isQr ? bw.Barcode.qrCode() : bw.Barcode.code128(),
                                  data: prod.barcode,
                                  drawText: !isQr,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                Formatters.currency(prod.costPrice),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons: Cetak Printer vs Simpan PDF
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Simpan / Ekspor PDF'),
                        onPressed: () => _generateAndPrintPdf(false),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        icon: const Icon(Icons.print),
                        label: const Text('Cetak ke Printer'),
                        onPressed: () => _generateAndPrintPdf(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


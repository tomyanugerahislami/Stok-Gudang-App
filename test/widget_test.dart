import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stok_gudang_app/app.dart';
import 'package:stok_gudang_app/core/utils/formatters.dart';
import 'package:stok_gudang_app/shared/models/product.dart';
import 'package:stok_gudang_app/shared/models/warehouse.dart';
import 'package:stok_gudang_app/shared/models/stock_transaction.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Formatters.initialize();
  });

  group('Formatters & Utility Tests', () {
    test('Currency formatting formats Rupiah accurately', () {
      expect(Formatters.currency(50000), contains('50.000'));
      expect(Formatters.currency(0), contains('0'));
    });

    test('Number formatting formats quantities', () {
      expect(Formatters.number(1250), '1.250');
      expect(Formatters.number(10.5), '10,5');
    });

    test('Generators produce unique identifiers', () {
      final sku = Formatters.generateSKU();
      expect(sku.startsWith('PRD-'), isTrue);

      final barcode = Formatters.generateBarcode();
      expect(barcode.startsWith('899'), isTrue);
      expect(barcode.length, 12);

      final txIn = Formatters.generateTransactionNumber('IN');
      expect(txIn.startsWith('TRX-IN-'), isTrue);
    });
  });

  group('Model Serialization Tests', () {
    test('Product model creation and low stock detection', () {
      final p = Product(
        id: 'p-1',
        sku: 'SKU-001',
        nama: 'Barang Uji',
        barcode: '899000000001',
        minimumStock: 10,
        currentStock: 4,
      );

      expect(p.isLowStock, isTrue);
      expect(p.isActive, isTrue);
      expect(p.isArchived, isFalse);

      final safeProduct = p.copyWith(currentStock: 15);
      expect(safeProduct.isLowStock, isFalse);
    });

    test('Warehouse model serialization', () {
      final wh = Warehouse(
        id: 'wh-1',
        kode: 'GDG-01',
        nama: 'Gudang Pusat',
        alamat: 'Jl. Merdeka',
      );
      final json = wh.toJson();
      expect(json['kode'], 'GDG-01');

      final deserialized = Warehouse.fromJson(json);
      expect(deserialized.nama, 'Gudang Pusat');
    });

    test('StockTransaction model creation', () {
      final tx = StockTransaction(
        id: 'tx-1',
        nomorTransaksi: 'TRX-IN-001',
        tipe: 'IN',
        warehouseId: 'wh-1',
        tanggal: DateTime.now(),
        status: 'COMPLETED',
        items: [
          StockTransactionItem(
            productId: 'p-1',
            productName: 'Barang Uji',
            productSku: 'SKU-001',
            quantity: 50,
          ),
        ],
      );

      expect(tx.isCompleted, isTrue);
      expect(tx.items.length, 1);
      expect(tx.items.first.quantity, 50);
    });
  });

  testWidgets('App smoke test - verifies App loads', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: WarehouseStockApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(WarehouseStockApp), findsOneWidget);
  });
}

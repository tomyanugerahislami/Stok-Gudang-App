import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:math';

class Formatters {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _numberFormat = NumberFormat('#,##0.##', 'id_ID');

  static final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy HH:mm', 'id_ID');
  static final _dateIsoFormat = DateFormat('yyyy-MM-dd');

  static Future<void> initialize() async {
    try {
      await initializeDateFormatting('id_ID', null);
    } catch (_) {}
  }

  static String currency(dynamic value) {
    if (value == null) return 'Rp 0';
    if (value is String) {
      final parsed = double.tryParse(value) ?? 0;
      return _currencyFormat.format(parsed);
    }
    return _currencyFormat.format(value);
  }

  static String number(dynamic value) {
    if (value == null) return '0';
    if (value is String) {
      final parsed = double.tryParse(value) ?? 0;
      return _numberFormat.format(parsed);
    }
    return _numberFormat.format(value);
  }

  static String date(DateTime? date) {
    if (date == null) return '-';
    try {
      return _dateFormat.format(date);
    } catch (_) {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  static String dateTime(DateTime? date) {
    if (date == null) return '-';
    try {
      return _dateTimeFormat.format(date);
    } catch (_) {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  static String dateIso(DateTime? date) {
    if (date == null) return '';
    return _dateIsoFormat.format(date);
  }

  /// Generate a unique SKU: e.g. PRD-89423
  static String generateSKU([String prefix = 'PRD']) {
    final random = Random();
    final number = random.nextInt(900000) + 100000;
    return '$prefix-$number';
  }

  /// Generate a 12-13 digit unique barcode: e.g. 899 + random digits
  static String generateBarcode() {
    final random = Random();
    final randomDigits = List.generate(9, (_) => random.nextInt(10)).join();
    return '899$randomDigits';
  }

  /// Generate transaction number: e.g. TRX-IN-20261104-1234
  static String generateTransactionNumber(String type) {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    final random = Random().nextInt(9000) + 1000;
    return 'TRX-$type-$dateStr-$random';
  }

  /// Generate opname number: e.g. OPN-20261104-1234
  static String generateOpnameNumber() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    final random = Random().nextInt(9000) + 1000;
    return 'OPN-$dateStr-$random';
  }
}

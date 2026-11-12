import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/supabase_config.dart';
import 'core/utils/formatters.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Formatters.initialize();
  await SupabaseConfig.initialize();

  runApp(const ProviderScope(child: WarehouseStockApp()));
}

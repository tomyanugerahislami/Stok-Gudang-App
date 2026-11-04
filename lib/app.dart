import 'package:flutter/material.dart';
import 'core/config/router.dart';
import 'core/theme/app_theme.dart';

class WarehouseStockApp extends StatelessWidget {
  const WarehouseStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Warehouse Stock Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}


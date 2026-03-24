import 'package:flutter/material.dart';
import 'package:barcode_app/app/router/app_router.dart';
import 'package:barcode_app/app/theme/app_theme.dart';

class BarcodeApp extends StatelessWidget {
  const BarcodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Barcode App',
      theme: buildAppTheme(),
      routerConfig: buildRouter(),
    );
  }
}

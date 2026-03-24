import 'package:barcode_app/app/app.dart';
import 'package:barcode_app/app/bootstrap/bootstrap.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapApplication();
  runApp(const ProviderScope(child: BarcodeApp()));
}

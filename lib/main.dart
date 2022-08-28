import 'package:flutter/material.dart';
import 'package:signed_invoice_verif/screens/scanner_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MaterialApp(
      home: const MyApp(),
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ).copyWith(highlightColor: Colors.greenAccent.shade100.withAlpha(80)),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ScannerView();
  }
}

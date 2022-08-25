import 'package:flutter/material.dart';
import 'QRViewReader.dart';

void main() => runApp(const MaterialApp(home: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Read an invoice')),
      body: Center(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 10),
            const Text('Welcome to the application for authenticating invoices'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const QRViewReader(),
                ));
              },
              child: const Text('Scan a digital signature stamp'),
          )
          ]
        ),
      ),
    );
  }
}

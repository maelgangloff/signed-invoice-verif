import 'package:flutter/material.dart';
import 'QRViewReader.dart';

void main() => runApp(const MaterialApp(home: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify an invoice')),
      body: Center(
        child: Column(children: <Widget>[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.all(5),
            child: RichText(
                text: const TextSpan(
                    text:
                        '''Welcome to the application for authenticating invoices


The application works in two different modes:

- Reading of the invoice without authentication of the cryptographic signature (default mode). This mode is active when the lower left key is orange. The application only reads the contents of the stamp without verifying the signature.

- Verification of the authenticity of the invoice. This mode is active when the lower left key is green. The application will ask you to select the document issuer's public key file. When a stamp is scanned, the signature is verified. If the signature does not match, an error is thrown and the invoice is marked as not authentic.
''',
                    style: TextStyle(color: Colors.black, fontSize: 14.5))),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            autofocus: true,
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const QRViewReader(),
              ));
            },
            child: const Text('Scan a digital signature stamp'),
          )
        ]),
      ),
    );
  }
}

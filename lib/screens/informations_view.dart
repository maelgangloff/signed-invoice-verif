import 'package:flutter/material.dart';

class InformationsView extends StatelessWidget {
  const InformationsView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifying an invoice')),
      body: Center(
        child: Column(children: <Widget>[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.all(5),
            child: RichText(
              text: TextSpan(text: '''By default the app does not verify the signatures.
To verify a stamp, import the public key by clicking on the key icon.
You can toggle the flash with the flash button.
''', style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

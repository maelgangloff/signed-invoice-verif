import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InformationsView extends StatelessWidget {
  const InformationsView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Info')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Using the app",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Text('''By default the app does not verify the signatures.
To verify a stamp, import the public key by clicking on the key icon.
You can toggle the flash with the flash button.'''),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "About the app",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                        text: "This app is open source and published on "),
                    TextSpan(
                      text: "GitHub",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          launchUrl(
                              Uri.parse(
                                "https://github.com/maelgangloff/signed-invoice-verif",
                              ),
                              mode: LaunchMode.externalApplication);
                        },
                    ),
                    const TextSpan(
                        text:
                            ". Go there to contribute, donate, submit a feature request or a bug report? Any contributions are very welcome!")
                  ],
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

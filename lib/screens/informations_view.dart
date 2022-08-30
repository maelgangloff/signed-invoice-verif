import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class InformationsView extends StatelessWidget {
  const InformationsView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Information'),
          backgroundColor: Colors.amberAccent),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  AppLocalizations.of(context)!.usingTheApp,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(AppLocalizations.of(context)!.usingTheAppContent),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  AppLocalizations.of(context)!.aboutTheApp,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                        text:
                            AppLocalizations.of(context)!.aboutTheAppContent1),
                    TextSpan(
                      text: "signed-invoice",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          launchUrl(
                              Uri.parse(
                                "https://github.com/maelgangloff/signed-invoice",
                              ),
                              mode: LaunchMode.externalApplication);
                        },
                    ),
                    TextSpan(
                        text:
                            AppLocalizations.of(context)!.aboutTheAppContent2),
                    TextSpan(
                        text:
                            AppLocalizations.of(context)!.aboutTheAppContent3),
                    TextSpan(
                      text: "GitHub (maelgangloff/signed-invoice-verif)",
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
                    TextSpan(
                        text: AppLocalizations.of(context)!.aboutTheAppContent4)
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

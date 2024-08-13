import 'package:flutter/material.dart';
import 'package:mobile/app.dart';
import 'package:mobile/app_localization.dart';
import 'package:mobile/widgets/appbar.dart';

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String? _currentLanguage;

  @override
  Widget build(BuildContext context) {
    _currentLanguage ??= Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: MyAppBar(
        title: Text(
          AppLocalizations.of(context)!.translate("language_settings"),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          RadioListTile(
            title: Text(AppLocalizations.of(context)!.translate("english")),
            value: 'en',
            groupValue: _currentLanguage,
            selected: _currentLanguage == 'en',
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (value) {
              Locale locale = Locale('en');
              MyApp.of(context)?.setLocale(locale);

              _currentLanguage = value;
            },
          ),
          RadioListTile(
            title: Text(AppLocalizations.of(context)!.translate("turkish")),
            value: 'tr',
            groupValue: _currentLanguage,
            selected: _currentLanguage == 'tr',
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (value) {
              Locale locale = Locale('tr');
              MyApp.of(context)?.setLocale(locale);

              _currentLanguage = value;
            },
          ),
        ],
      ),
    );
  }
}

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

import 'package:flutter/material.dart';
import 'package:mobile/models/theme.dart';
import 'package:mobile/widgets/appbar.dart';
import 'package:provider/provider.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: MyAppBar(
        title: Text(
          "Theme Settings",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          RadioListTile(
            title: Text("Dark"),
            value: ThemeMode.dark,
            groupValue: Theme.of(context).brightness == Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light,
            // groupValue: themeProvider.themeMode,
            selected: Theme.of(context).brightness == Brightness.dark,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (value) {
              if (value != null) {
                themeProvider.setTheme(value);
              }
            },
          ),
          RadioListTile(
            title: Text("Light"),
            value: ThemeMode.light,
            groupValue: Theme.of(context).brightness == Brightness.light
                ? ThemeMode.light
                : ThemeMode.dark,
            // groupValue: themeProvider.themeMode,
            selected: Theme.of(context).brightness == Brightness.light,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (value) {
              if (value != null) {
                themeProvider.setTheme(value);
              }
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mobile/screens/settings/theme.dart';
import 'package:mobile/widgets/appbar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        title: Text(
          "Settings",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(
              "Theme",
            ),
            trailing: Icon(Icons.keyboard_arrow_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ThemeSettingsScreen(),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}

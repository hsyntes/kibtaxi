import 'package:flutter/material.dart';

class MyThemeData {
  static ThemeData get theme => ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFEE7E21),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFEE7E21),
          foregroundColor: Colors.white,
        ),
      );
}

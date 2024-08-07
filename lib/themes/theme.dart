import 'package:flutter/material.dart';

class MyThemeData {
  static ThemeData get theme => ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFEE7E21),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            // showSelectedLabels: false,
            // showUnselectedLabels: false,
            ),
      );
}

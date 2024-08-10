import 'package:flutter/material.dart';

class MyThemeData {
  static ThemeData get theme => ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFFA500),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          scrolledUnderElevation: 0,
          shadowColor: Colors.black54,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          showSelectedLabels: false,
          showUnselectedLabels: false,
        ),
      );
}

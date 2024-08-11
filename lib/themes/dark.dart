import 'package:flutter/material.dart';

class DarkThemeData {
  static ThemeData get theme => ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFA500),
          brightness: Brightness.dark,
        ),
        appBarTheme: AppBarTheme(
          // backgroundColor: Colors.white,
          scrolledUnderElevation: 0.25,
          shadowColor: Colors.black54,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFFFFA500),
          unselectedItemColor: Colors.white54,
          showSelectedLabels: false,
          showUnselectedLabels: false,
        ),
      );
}

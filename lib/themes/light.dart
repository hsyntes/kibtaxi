import 'package:flutter/material.dart';

class LightThemeData {
  static ThemeData get theme => ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFFA500),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          scrolledUnderElevation: 0.5,
          shadowColor: Colors.black54,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFFFFA500),
          unselectedItemColor: Colors.black54,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          enableFeedback: false,
          elevation: 0,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Colors.white,
          contentTextStyle: TextStyle(color: Colors.black),
          actionTextColor: Color(0xFFFFA500),
        ),
      );
}

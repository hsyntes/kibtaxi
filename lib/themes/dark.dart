import 'package:flutter/material.dart';

class DarkThemeData {
  static ThemeData get theme => ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFA500),
          brightness: Brightness.dark,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF030a0e),
          scrolledUnderElevation: 0,
        ),
        scaffoldBackgroundColor: Color(0xFF030a0e),
        cardTheme: CardTheme(color: Color(0xFF040D12)),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF030a0e),
          selectedItemColor: Color(0xFFFFA500),
          unselectedItemColor: Colors.white54,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          enableFeedback: false,
          elevation: 0,
        ),
        dialogTheme: DialogTheme(
          backgroundColor: Color(0xFF030a0e),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: Color(0xFF030a0e),
        ),
      );
}

import 'package:flutter/material.dart';

class DarkThemeData {
  static ThemeData get theme => ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFA500),
          brightness: Brightness.dark,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF040D12),
          scrolledUnderElevation: 0,
          shadowColor: Colors.black54,
        ),
        scaffoldBackgroundColor: Color(0xFF040D12),
        cardTheme: CardTheme(color: Color(0xFF030a0e)),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF040D12),
          selectedItemColor: Color(0xFFFFA500),
          unselectedItemColor: Colors.white54,
          showSelectedLabels: false,
          showUnselectedLabels: false,
        ),
        dialogTheme: DialogTheme(
          backgroundColor: Color(0xFF030a0e),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: Color(0xFF030a0e),
        ),
      );
}

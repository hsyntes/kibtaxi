import 'package:flutter/material.dart';
import 'package:mobile/screens/home.dart';
import 'package:mobile/screens/map.dart';
import 'package:mobile/themes/theme.dart';
import 'package:mobile/widgets/bottom_navigation.dart';

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    MapScreen(),
  ];

  void onTap(index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "CypruxTaxi",
      theme: MyThemeData.theme,
      home: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: MyBottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: onTap,
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

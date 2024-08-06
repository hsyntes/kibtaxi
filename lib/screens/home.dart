import 'package:flutter/material.dart';
import 'package:mobile/widgets/appbar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Column(
      children: [
        MyAppBar(
          title: const Text("CypruxTaxi"),
          actions: [
            IconButton(
              onPressed: () {
                print("Search");
              },
              icon: const Icon(Icons.search),
            ),
            IconButton(
              onPressed: () {
                print("Ellipsis");
              },
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
      ],
    ));
  }
}

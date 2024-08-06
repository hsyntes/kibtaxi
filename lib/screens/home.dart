import 'package:flutter/material.dart';
import 'package:mobile/widgets/appbar.dart';
import "package:flutter_svg/flutter_svg.dart";

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Column(
      children: [
        MyAppBar(
          title: SvgPicture.asset(
            'assets/brand.svg',
            fit: BoxFit.fitHeight,
            height: 36,
          ),
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

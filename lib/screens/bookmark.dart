import 'package:flutter/material.dart';
import 'package:mobile/widgets/appbar.dart';

class BookmarkScreen extends StatelessWidget {
  const BookmarkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        title: Text("Bookmarks"),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mobile/widgets/appbar.dart';

class _MySearchBarState extends State<MySearchBar> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16),
      child: SearchBar(
        elevation: WidgetStateProperty.all(1),
        leading: Icon(
          Icons.search,
          size: 20,
        ),
        hintText: "Search taxis",
        hintStyle: MaterialStateProperty.all(
          TextStyle(fontSize: 14),
        ),
        // trailing: [Icon(Icons.search)],
      ),
    );
  }
}

class MySearchBar extends StatefulWidget implements PreferredSizeWidget {
  const MySearchBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(42);

  @override
  State<MySearchBar> createState() => _MySearchBarState();
}

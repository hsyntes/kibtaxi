import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:mobile/app.dart";
import "package:mobile/models/bookmark.dart";
import "package:mobile/models/theme.dart";
import "package:provider/provider.dart";

void main() async {
  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider())
      ],
      child: MyApp(),
    ),
  );
}

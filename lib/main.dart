import "package:flutter/material.dart";
import "package:mobile/app.dart";
import "package:mobile/models/bookmark.dart";
import "package:mobile/models/theme.dart";
import "package:provider/provider.dart";

void main() {
  // WidgetsFlutterBinding.ensureInitialized();
  // SystemChrome.setSystemUIOverlayStyle(
  //   const SystemUiOverlayStyle(
  //     statusBarColor: Theme.of(context),
  //     statusBarIconBrightness: Brightness.dark,
  //   ),
  // );

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

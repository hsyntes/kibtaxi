import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:mobile/app.dart";
import "package:mobile/models/position.dart";
import "package:mobile/models/theme.dart";
import "package:provider/provider.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // SystemChrome.setSystemUIOverlayStyle(
  //   const SystemUiOverlayStyle(
  //     statusBarColor: Theme.of(context),
  //     statusBarIconBrightness: Brightness.dark,
  //   ),
  // );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

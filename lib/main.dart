import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:mobile/app.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFEE7E21),
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

import "package:flutter/material.dart";

class PositionProvider with ChangeNotifier {
  late double _latitude;
  late double _longitude;

  double get latitude => _latitude;
  double get longitude => _longitude;

  void updatePosition(double latitude, double longitude) {
    _latitude = latitude;
    _longitude = longitude;

    notifyListeners();
  }
}

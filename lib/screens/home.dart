import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/widgets/appbar.dart';
import "package:flutter_svg/flutter_svg.dart";
import 'package:permission_handler/permission_handler.dart';
import "package:http/http.dart" as http;

class _HomeScreenState extends State<HomeScreen> {
  late Future<dynamic> _taxis;

  Future<void> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      await Permission.locationWhenInUse.request();
    }
  }

  Future<dynamic> _getTaxis() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission locationPermission = await Geolocator.checkPermission();

    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
      return;
    }

    if (locationPermission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    try {
      final latitude = position.latitude;
      final longitude = position.longitude;

      final response = await http.get(
        Uri.parse(
            'http://192.168.128.108:8000/api/taxis?lat=$latitude&long=$longitude'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception("Failed fetching data.");
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  void initState() {
    super.initState();
    _taxis = _requestLocationPermission().then((_) => _getTaxis());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          MyAppBar(
            title: SvgPicture.asset(
              'assets/brand.svg',
              fit: BoxFit.fitHeight,
              // height: 40,
              height: kToolbarHeight * 0.7,
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
          FutureBuilder<dynamic>(
            future: _taxis,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text("${snapshot.error}"),
                );
              }

              if (snapshot.hasData) {
                print("data: ${snapshot.data}");
                return const Center(
                  child: Text("Fetched!"),
                );
              } else {
                return const Center(
                  child: Text("Something went wrong!"),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

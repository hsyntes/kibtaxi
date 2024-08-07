import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/widgets/appbar.dart';
import "package:flutter_svg/flutter_svg.dart";
import 'package:permission_handler/permission_handler.dart';
import "package:http/http.dart" as http;

class _HomeScreenState extends State<HomeScreen> {
  final List<dynamic> _data = [];
  bool _isTaxisLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 3;

  Future<void> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      await Permission.locationWhenInUse.request();
    }
  }

  Future<dynamic> _getTaxis() async {
    if (_isTaxisLoading || !_hasMore) return;

    setState(() {
      _isTaxisLoading = true;
    });

    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();

      setState(() {
        _isTaxisLoading = false;
      });

      return;
    }

    LocationPermission locationPermission = await Geolocator.checkPermission();

    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();

      setState(() {
        _isTaxisLoading = false;
      });

      return;
    }

    if (locationPermission == LocationPermission.deniedForever) {
      setState(() {
        _isTaxisLoading = false;
      });

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
            'http://192.168.128.108:8000/api/taxis?lat=$latitude&long=$longitude&page=$_currentPage&limit=$_limit'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> taxis = data['data']['taxis'] as List<dynamic>;

        if (taxis.isEmpty) {
          _hasMore = false;
        } else {
          _data.addAll(taxis);
          _currentPage++;
        }
      } else {
        throw Exception("Failed fetching data.");
      }
    } catch (e) {
      throw Exception(e);
    } finally {
      setState(() {
        _isTaxisLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _requestLocationPermission().then((_) => _getTaxis());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
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
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (!_isTaxisLoading &&
              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            _getTaxis();
          }

          return true;
        },
        child: ListView.builder(
          itemCount: _data.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _data.length) {
              return const Padding(
                padding: EdgeInsets.all(14),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final taxi = _data[index];
            print('taxi: $taxi');

            return ListTile(
              title: Text("${taxi['taxi_name']}"),
              subtitle: Text("${taxi['taxi_city']}"),
            );
          },
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

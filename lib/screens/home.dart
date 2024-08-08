import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/widgets/appbar.dart';
import "package:flutter_svg/flutter_svg.dart";
import 'package:permission_handler/permission_handler.dart';
import "package:http/http.dart" as http;
import "package:geocoding/geocoding.dart";

class _HomeScreenState extends State<HomeScreen> {
  Position? _position;
  final List<dynamic> _taxiData = [];
  // final List<dynamic>? _popularTaxis = [];
  // late Future<dynamic> _popularTaxis;
  Future<dynamic>? _popularTaxis;
  bool _isTaxisLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 3;
  String? _city;

  Future<void> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      await Permission.locationWhenInUse.request();
    }
  }

  Future<void> _getPosition() async {
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

    setState(() {
      _position = position;
    });
  }

  Future<void> _getCity() async {
    try {
      List<Placemark> placemark =
          await placemarkFromCoordinates(35.156738, 33.878208);

      if (placemark.isNotEmpty) {
        String? city = placemark.first.locality ?? "your area";

        setState(() {
          _city = city;
        });
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<dynamic> _getPopularTaxis() async {
    try {
      final response = await http.get(Uri.parse(
          "http://192.168.123.108:8000/api/taxis/popular?lat=35.095335&long=33.930475"));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      throw Exception("Something went wrong! $e");
    }
  }

  Future<void> _getTaxis() async {
    try {
      final latitude = _position?.latitude;
      final longitude = _position?.longitude;

      final response = await http.get(
        Uri.parse(
          'http://192.168.128.108:8000/api/taxis?lat=35.095335&long=33.930475&page=$_currentPage&limit=$_limit',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> taxis = data['data']['taxis'];

        if (taxis.isEmpty) {
          setState(() {
            _hasMore = false;
            _isTaxisLoading = false;
          });
        } else {
          _taxiData.addAll(taxis);
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

  Future<void> _initializeData() async {
    await _requestLocationPermission();
    await _getPosition();
    await _getCity();

    setState(() {
      _popularTaxis = _getPopularTaxis();
    });

    await _getTaxis();
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
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
      body: FutureBuilder<dynamic>(
        future: _popularTaxis,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(); // Show loading indicator
          }

          if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}"); // Provide error details
          }

          if (snapshot.hasData) {
            if (snapshot.data != null &&
                snapshot.data is Map<String, dynamic>) {
              final data = snapshot.data as Map<String, dynamic>;
              final List<dynamic> taxis = data['data']['taxis'] ?? [];

              if (taxis.isEmpty) {
                return const Text("No taxis available.");
              }

              print("data: $taxis");
              return const Text("OK");
            } else {
              return const Text("Unexpected data format.");
            }
          } else {
            return const Text("Not fetched any data.");
          }
        },
      ),
      // body: Padding(
      //   padding: EdgeInsets.all(16),
      //   child: Column(
      //     children: [
      //       Row(
      //         children: [
      //           const Icon(
      //             Icons.my_location,
      //             size: 18,
      //           ),
      //           const SizedBox(
      //             width: 4,
      //           ),
      //           Text(
      //             "Most popular in $_city",
      //             textAlign: TextAlign.left,
      //             style: const TextStyle(fontSize: 16),
      //           )
      //         ],
      //       ),
      //       SizedBox(height: 8),
      //       Row(
      //         children: [],
      //       ),
      //       NotificationListener<ScrollNotification>(
      //         onNotification: (scrollInfo) {
      //           if (!_isTaxisLoading &&
      //               scrollInfo.metrics.pixels ==
      //                   scrollInfo.metrics.maxScrollExtent) {
      //             _getTaxis();
      //           }
      //
      //           return true;
      //         },
      //         child: Expanded(
      //           child: ListView.builder(
      //             itemCount: _taxiData.length + (_hasMore ? 1 : 0),
      //             itemBuilder: (context, index) {
      //               if (index == _taxiData.length || _isTaxisLoading) {
      //                 return const Padding(
      //                   padding: EdgeInsets.all(14),
      //                   child: Center(
      //                     child: CircularProgressIndicator(),
      //                   ),
      //                 );
      //               }
      //
      //               final taxi = _taxiData[index];
      //               print('taxi: $taxi');
      //
      //               return Column(
      //                 children: [
      //                   ListTile(
      //                     title: Text(
      //                       taxi['taxi_name'],
      //                     ),
      //                     tileColor: Colors.blueAccent,
      //                     horizontalTitleGap: 8,
      //                   )
      //                 ],
      //               );
      //             },
      //           ),
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

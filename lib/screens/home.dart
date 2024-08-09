import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/widgets/appbar.dart';
import "package:flutter_svg/flutter_svg.dart";
import 'package:permission_handler/permission_handler.dart';
import "package:http/http.dart" as http;
import "package:geocoding/geocoding.dart";
import 'package:skeletonizer/skeletonizer.dart';

class _HomeScreenState extends State<HomeScreen> {
  Position? _position;
  final List<dynamic> _taxiData = [];
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
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData) {
            return Skeletonizer.zone(
                child: Column(
              children: [
                SizedBox(
                  height: 16,
                ),
                Card(
                  elevation: 0,
                  child: ListTile(
                    leading: Bone.circle(
                      size: 48,
                    ),
                    title: Bone.text(
                      words: 2,
                    ),
                    subtitle: Bone.text(
                      words: 1,
                    ),
                  ),
                ),
              ],
            ));
          }

          if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}"); // Provide error details
          }

          if (snapshot.hasData) {
            final data = snapshot.data as Map<String, dynamic>;
            final List<dynamic> taxis = data['data']['taxis'] ?? [];

            print('taxis: $taxis');

            return Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.my_location, size: 18),
                      SizedBox(width: 4),
                      Text("Most popular in $_city"),
                    ],
                  ),
                  SizedBox(height: 16),
                  CarouselSlider.builder(
                    itemCount: taxis.length,
                    options: CarouselOptions(
                      height: MediaQuery.of(context).size.height * .35,
                      autoPlay: false,
                      enlargeCenterPage: true,
                      enableInfiniteScroll: false,
                      initialPage: 0,
                      padEnds: true,
                      viewportFraction: 1,
                    ),
                    itemBuilder: (context, index, realIndex) {
                      final taxi = taxis[index];

                      return Card(
                        elevation: 1,
                        child: Stack(
                          children: [
                            ListTile(
                              leading: taxi['taxi_profile'] != null
                                  ? ClipOval(
                                      child: Image.network(
                                        taxi['taxi_profile'],
                                        width: 56,
                                        height: 56,
                                        semanticLabel: "Profile Image",
                                      ),
                                    )
                                  : CircleAvatar(),
                              title: Text(taxi['taxi_name']),
                              trailing: Icon(
                                Icons.bookmark_outline,
                                color: Colors.black54,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "@${taxi['taxi_username']}",
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.black54,
                                      ),
                                      SizedBox(
                                        width: 2,
                                      ),
                                      Text(
                                        "${taxi['taxi_city']}",
                                        style: TextStyle(color: Colors.black54),
                                      )
                                    ],
                                  ),
                                  Text(
                                    "${taxi['taxi_address']}",
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  SizedBox(
                                    height: 16,
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "${taxi['taxi_popularity']}",
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      SizedBox(width: 3),
                                      RatingBar.builder(
                                        updateOnDrag: false,
                                        itemCount: 5,
                                        itemSize: 16,
                                        allowHalfRating: true,
                                        ignoreGestures: true,
                                        initialRating: taxi['taxi_popularity'],
                                        itemBuilder: (context, _) => Icon(
                                          Icons.star,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        unratedColor: Colors.black26,
                                        onRatingUpdate: (rating) {},
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                            SizedBox(
                              height: 16,
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () {},
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.blueAccent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(18),
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.phone,
                                            size: 18,
                                            semanticLabel: "Phone",
                                          ),
                                          SizedBox(width: 6),
                                          Text("Phone")
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 0),
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () {},
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                            bottomRight: Radius.circular(18),
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            MaterialCommunityIcons.whatsapp,
                                            size: 18,
                                            semanticLabel: "WhatsApp",
                                          ),
                                          SizedBox(width: 6),
                                          Text("WhatsApp")
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }

          return Text("");
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// NotificationListener<ScrollNotification>(
// onNotification: (scrollInfo) {
// if (!_isTaxisLoading &&
// scrollInfo.metrics.pixels ==
// scrollInfo.metrics.maxScrollExtent) {
// _getTaxis();
// }
//
// return true;
// },
// child: Expanded(
// child: ListView.builder(
// itemCount: _taxiData.length + (_hasMore ? 1 : 0),
// ),
// itemBuilder: (context, index) {
// if (index == _taxiData.length || _isTaxisLoading) {
// return const Padding(
// padding: EdgeInsets.all(14),
// child: Center(
// child: CircularProgressIndicator(),
// ),
// );
// }
//
// final taxi = _taxiData[index];
// print('taxi: $taxi');
//
// return Column(
// children: [
// ListTile(
// title: Text(
// taxi['taxi_name'],
// ),
// tileColor: Colors.blueAccent,
// horizontalTitleGap: 8,
// )
// ],
// );
// },

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/screens/bookmark.dart';
import 'package:mobile/screens/home.dart';
import 'package:mobile/screens/map.dart';
import 'package:mobile/screens/search.dart';
import 'package:mobile/themes/dark.dart';
import 'package:mobile/themes/light.dart';
import "package:http/http.dart" as http;
import 'package:mobile/widgets/bottom_navigation.dart';

class _MyAppState extends State<MyApp>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late Future<dynamic> _position;
  int _currentIndex = 0;

  AnimationController? _animationController;
  Animation<double>? _animation;

  Future<void> _checkApiHealth() async {
    try {
      final response = await http.get(
        Uri.parse("http://192.168.88.24:8000/api"),
      );

      print("Connection to the server status: ${response.statusCode}");

      if (response.statusCode == 200) {
        print("Connection to the server is successful.");
      }
    } catch (e) {
      throw Exception("Connection to the server is failed.");
    }
  }

  Future<dynamic> _getPosition() async {
    bool isLocationServiceEnabled;
    LocationPermission locationPermission;

    isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!isLocationServiceEnabled) {
      return Future.error('Location services are disabled');
    }

    locationPermission = await Geolocator.checkPermission();

    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();

      if (locationPermission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (locationPermission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return position;
  }

  void onTap(index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void onUpdated() {
    setState(() {
      _position = _getPosition();
    });
  }

  void _handleLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    print(permission != LocationPermission.denied);
    print(permission != LocationPermission.deniedForever);

    if (permission != LocationPermission.denied ||
        permission != LocationPermission.deniedForever) {
      setState(() {
        _position = _getPosition();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      _handleLocationPermission();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController!.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _checkApiHealth();
    _position = _getPosition();

    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animation = Tween<double>(begin: 0.25, end: .75).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeIn),
    );

    _animationController!.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "Cyprux Taxi",
        theme: LightThemeData.theme,
        darkTheme: DarkThemeData.theme,
        home: Scaffold(
          body: FutureBuilder<dynamic>(
            future: _position,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * .3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Theme.of(context).colorScheme.primary,
                            size: 42,
                          ),
                          SizedBox(height: 8),
                          FadeTransition(
                            opacity: _animation!,
                            child: Text(
                              'Finding your location',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * .4,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SpinKitRipple(
                            size: MediaQuery.of(context).size.width * 0.5,
                            duration: Duration(milliseconds: 2000),
                            itemBuilder: (context, index) {
                              return DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(360),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * .2,
                      height: MediaQuery.of(context).size.height * .3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/icons/app_icon.png",
                            fit: BoxFit.contain,
                          )
                        ],
                      ),
                    )
                  ],
                );
              }

              if (snapshot.hasError) {
                if (snapshot.error.toString() ==
                    'Location services are disabled') {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height * .8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              color: Theme.of(context).primaryColor,
                              size: 42,
                            ),
                            SizedBox(height: 8),
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                "Location services are disabled. Please enable location services to use CypruxTaxi.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () async {
                                await Geolocator.openLocationSettings();

                                Geolocator.getServiceStatusStream()
                                    .listen((status) async {
                                  print("status: $status");

                                  if (status == ServiceStatus.enabled) {
                                    setState(() {
                                      _position = _getPosition();
                                    });
                                  }
                                });
                              },
                              child: Text("Enable Location Services"),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * .2,
                        height: MediaQuery.of(context).size.height * .2,
                        child: Image.asset(
                          "assets/icons/app_icon.png",
                          fit: BoxFit.contain,
                        ),
                      )
                    ],
                  );
                } else if (snapshot.error.toString() ==
                    'Location permissions are denied') {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height * .8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              color: Theme.of(context).primaryColor,
                              size: 42,
                            ),
                            SizedBox(height: 8),
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                "Location permissions are denied.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () async {
                                setState(() {
                                  _position = _getPosition();
                                });
                              },
                              child: Text("Enable Location Permissions"),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * .2,
                        height: MediaQuery.of(context).size.height * .2,
                        child: Image.asset(
                          "assets/icons/app_icon.png",
                          fit: BoxFit.contain,
                        ),
                      )
                    ],
                  );
                } else if (snapshot.error.toString() ==
                    "Location permissions are permanently denied") {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height * .8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              color: Theme.of(context).primaryColor,
                              size: 42,
                            ),
                            SizedBox(height: 8),
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                "Location permissions are permanently denied on this app. Please open your location settings & allow location access permissions to CypruxTaxi.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () async {
                                await Geolocator.openLocationSettings();

                                Geolocator.getServiceStatusStream()
                                    .listen((status) async {
                                  print("status: $status");

                                  if (status == ServiceStatus.enabled) {
                                    setState(() {
                                      _position = _getPosition();
                                    });
                                  }
                                });
                              },
                              child: Text("Open Location Settings"),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * .2,
                        height: MediaQuery.of(context).size.height * .2,
                        child: Image.asset(
                          "assets/icons/app_icon.png",
                          fit: BoxFit.contain,
                        ),
                      )
                    ],
                  );
                }
              }

              if (snapshot.hasData) {
                final List<Widget> _screens = [
                  HomeScreen(position: snapshot.data),
                  // SearchScreen(),
                  // MapScreen(),
                  BookmarkScreen(),
                ];

                return Scaffold(
                  body: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                  bottomNavigationBar: MyBottomNavigationBar(
                    currentIndex: _currentIndex,
                    onTap: onTap,
                  ),
                );
              }

              return Text("Something went worng!");
            },
          ),
        ));
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

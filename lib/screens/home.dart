import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:mobile/screens/profile.dart';
import 'package:mobile/widgets/appbar.dart';
import "package:http/http.dart" as http;
import "package:geocoding/geocoding.dart";
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<dynamic> _taxis = [];
  Future<dynamic>? _popularTaxis;
  bool _isTaxisLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 4;
  String? _city;

  Future<void> _getCity() async {
    try {
      List<Placemark> placemark = await placemarkFromCoordinates(
          widget.position.latitude, widget.position.longitude);

      String? city;

      if (placemark.first.locality!.isNotEmpty) {
        city = placemark.first.locality;
      } else if (placemark.first.locality!.isNotEmpty) {
        city = placemark.first.subLocality;
      } else if (placemark.first.subAdministrativeArea!.isNotEmpty) {
        city = placemark.first.subAdministrativeArea;
      } else if (placemark.first.administrativeArea!.isNotEmpty) {
        city = placemark.first.administrativeArea;
      } else {
        city = "your area";
      }

      setState(() {
        _city = city;
      });
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<dynamic> _getPopularTaxis() async {
    try {
      final response = await http.get(Uri.parse(
          "http://192.168.88.141:8000/api/taxis/popular?lat=35.095335&long=33.930475"));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      throw Exception("Something went wrong! $e");
    }
  }

  Future<void> _getTaxis() async {
    setState(() {
      _isTaxisLoading = true;
    });

    try {
      // final latitude = widget.position.latitude;
      // final longitude = widget.position.longitude;

      final response = await http.get(
        Uri.parse(
          'http://192.168.88.141:8000/api/taxis?lat=35.095335&long=33.930475&page=$_currentPage&limit=$_limit',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> taxis = data['data']['taxis'];

        setState(() {
          if (taxis.isEmpty) {
            _hasMore = false;
          } else {
            _taxis.addAll(taxis);
            _currentPage++;
          }
        });
      } else {
        throw Exception("Failed fetching data.");
      }
    } catch (e) {
    } finally {
      setState(() {
        _isTaxisLoading = false;
      });
    }
  }

  Future<void> _initialize() async {
    await _getCity();

    setState(() {
      _popularTaxis = _getPopularTaxis();
    });

    await _getTaxis();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initialize();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !_isTaxisLoading &&
          _hasMore) {
        _getTaxis();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        title: Image.asset(
          Theme.of(context).brightness == Brightness.dark
              ? 'assets/icons/brand.light.png'
              : "assets/icons/brand.dark.png",
          // height: kToolbarHeight * .6,
          height: 30,
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
            icon: const Icon(Icons.menu),
          ),
        ],
      ),
      body: FutureBuilder<dynamic>(
        future: _popularTaxis,
        builder: (context, snapshot) {
          print("position: ${widget.position}");

          if (snapshot.connectionState == ConnectionState.waiting) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 1),
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Getting most popular taxis",
                              style: TextStyle(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white54
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: 10,
                    (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(right: 16, left: 16),
                        child: Skeletonizer.zone(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Bone.circle(size: 48),
                            title: Bone.text(words: 2),
                            subtitle: Bone.text(words: 1),
                            trailing: Bone.icon(),
                            isThreeLine: true,
                          ),
                        ),
                      );
                    },
                  ),
                )
              ],
            );
          }

          if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}"); // Provide error details
          }

          if (snapshot.hasData) {
            final data = snapshot.data as Map<String, dynamic>;
            final List<dynamic> taxis = data['data']['taxis'];

            return CustomScrollView(
              controller: _scrollController,
              // physics: ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.rocket_launch,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Most popular in $_city",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        CarouselSlider.builder(
                          itemCount: taxis.length,
                          options: CarouselOptions(
                            // height: MediaQuery.of(context).size.height * .3,
                            autoPlay: false,
                            enlargeCenterPage: true,
                            enableInfiniteScroll: false,
                            initialPage: 0,
                            viewportFraction: 1,
                          ),
                          itemBuilder: (context, index, realIndex) {
                            final taxi = taxis[index];

                            return Card(
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
                                        : SizedBox(
                                            width: 72,
                                            height: 72,
                                            child: CircleAvatar(),
                                          ),
                                    title: Text(
                                      taxi['taxi_name'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.bookmark_outline),
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white54
                                          : Colors.black54,
                                      onPressed: () {
                                        print("Added to bookmarks!");
                                      },
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "@${taxi['taxi_username']}",
                                          style: TextStyle(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white54
                                                    : Colors.black54,
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 16,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white54
                                                  : Colors.black54,
                                            ),
                                            SizedBox(
                                              width: 2,
                                            ),
                                            Text(
                                              "${taxi['taxi_city']}",
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.white54
                                                    : Colors.black54,
                                                fontSize: 12,
                                              ),
                                            )
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          "${taxi['taxi_address']}",
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        SizedBox(
                                          height: 8,
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              "${taxi['taxi_popularity']}",
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                            ),
                                            SizedBox(width: 3),
                                            RatingBar.builder(
                                              updateOnDrag: false,
                                              itemCount: 5,
                                              itemSize: 14,
                                              allowHalfRating: true,
                                              ignoreGestures: true,
                                              initialRating:
                                                  taxi['taxi_popularity'],
                                              itemBuilder: (context, _) => Icon(
                                                Icons.star,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                              unratedColor: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white24
                                                  : Colors.black26,
                                              onRatingUpdate: (rating) {},
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    isThreeLine: true,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProfileScreen(
                                            id: taxi['_id'],
                                            appBarTitle: taxi['taxi_name'],
                                          ),
                                        ),
                                      );
                                    },
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
                                            onPressed: () async {
                                              await launchUrl(
                                                Uri(
                                                  scheme: "tel",
                                                  path: taxi['taxi_phone'],
                                                ),
                                              );
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  Colors.blueAccent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.only(
                                                  bottomLeft:
                                                      Radius.circular(18),
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
                                        Expanded(
                                          child: TextButton(
                                            onPressed: () async {
                                              await launchUrl(
                                                Uri(
                                                  scheme: "https",
                                                  host: "api.whatsapp.com",
                                                  path: "send",
                                                  queryParameters: {
                                                    'phone': taxi['taxi_phone']
                                                  },
                                                ),
                                              );
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.green,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.only(
                                                  bottomRight:
                                                      Radius.circular(18),
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
                                                  MaterialCommunityIcons
                                                      .whatsapp,
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
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.my_location,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Others around you",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: _taxis.length + (_isTaxisLoading ? 1 : 0),
                    (context, index) {
                      if (index == _taxis.length) {
                        return Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      final taxi = _taxis[index];

                      return ListTile(
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
                        title: Text(
                          taxi['taxi_name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.bookmark_outline),
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white54
                              : Colors.black54,
                          onPressed: () {
                            print("Added to the bookmarks!");
                          },
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "@${taxi['taxi_username']}",
                              style: TextStyle(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white54
                                    : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white54
                                      : Colors.black54,
                                ),
                                SizedBox(
                                  width: 2,
                                ),
                                Text(
                                  "${taxi['taxi_city']}",
                                  style: TextStyle(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white54
                                        : Colors.black54,
                                    fontSize: 12,
                                  ),
                                )
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              "${taxi['taxi_address']}",
                              style: TextStyle(fontSize: 12),
                            ),
                            SizedBox(
                              height: 8,
                            ),
                            Row(
                              children: [
                                Text(
                                  "${taxi['taxi_popularity']}",
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                SizedBox(width: 3),
                                RatingBar.builder(
                                  updateOnDrag: false,
                                  itemCount: 5,
                                  itemSize: 14,
                                  allowHalfRating: true,
                                  ignoreGestures: true,
                                  initialRating: taxi['taxi_popularity'],
                                  itemBuilder: (context, _) => Icon(
                                    Icons.star,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  unratedColor: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white24
                                      : Colors.black26,
                                  onRatingUpdate: (rating) {},
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    await launchUrl(
                                      Uri(
                                        scheme: "tel",
                                        path: taxi['taxi_phone'],
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blueAccent,
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                TextButton(
                                  onPressed: () async {
                                    await launchUrl(
                                      Uri(
                                        scheme: "https",
                                        host: "api.whatsapp.com",
                                        path: "send",
                                        queryParameters: {
                                          'phone': taxi['taxi_phone']
                                        },
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.green,
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                              ],
                            )
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen(
                                id: taxi['_id'],
                                appBarTitle: taxi['taxi_name'],
                              ),
                            ),
                          );
                        },
                        isThreeLine: true,
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return Text("");
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final position;
  const HomeScreen({this.position, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

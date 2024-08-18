import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import "package:http/http.dart" as http;
import "package:geocoding/geocoding.dart";
import 'package:kibtaxi/app_localization.dart';
import 'package:kibtaxi/providers/bookmark.dart';
import 'package:kibtaxi/screens/profile.dart';
import 'package:kibtaxi/screens/settings/settings.dart';
import 'package:kibtaxi/utils/helpers.dart';
import 'package:kibtaxi/widgets/appbar.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';
import "package:fluttertoast/fluttertoast.dart";

Route _createSettingsRoute() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => SettingsScreen(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeOut;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      // Apply the animation using SlideTransition
      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  late Map<String, dynamic> position = {"latitude": null, "longitude": null};
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
          position['latitude'], position['longitude']);

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
          "${dotenv.env['API_URL']}/taxis/popular?lat=${position['latitude']}&long=${position['longitude']}"));

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
      final response = await http.get(
        Uri.parse(
          "${dotenv.env['API_URL']}/taxis?lat=${position['latitude']}&long=${position['longitude']}&page=$_currentPage&limit=$_limit",
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

  void changePosition({required double latitude, required double longitude}) {
    setState(() {
      position = {
        "latitude": latitude,
        "longitude": longitude,
      };

      _popularTaxis = _getPopularTaxis();
      _getTaxis();
      _getCity();
    });
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

    position['latitude'] = widget.position.latitude;
    position['longitude'] = widget.position.longitude;

    _initialize();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !_isTaxisLoading) {
        _getTaxis();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkProvider = Provider.of<BookmarkProvider>(context);

    return Scaffold(
      appBar: MyAppBar(
        title: GestureDetector(
          child: Image.asset(
            Theme.of(context).brightness == Brightness.dark
                ? 'assets/icons/brand.light.png'
                : 'assets/icons/brand.dark.png',
            height: 32,
          ),
          onTap: () {
            _scrollController.animateTo(0.0,
                duration: Duration(milliseconds: 500), curve: Curves.easeOut);
          },
        ),
        actions: [
          // IconButton(
          //   onPressed: () {},
          //   icon: const Icon(Icons.search),
          // ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                _createSettingsRoute(),
              );
            },
            icon: const Icon(Icons.menu),
          ),
        ],
      ),
      body: FutureBuilder<dynamic>(
        future: _popularTaxis,
        builder: (context, snapshot) {
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
                              AppLocalizations.of(context)!
                                  .translate("getting_most_popular"),
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

          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(
                child: Text("Error: ${snapshot.error}"),
              ); // Provide error details
            }

            if (!snapshot.hasData ||
                snapshot.data.isEmpty ||
                snapshot.data['data']['taxis'].length == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                      SizedBox(height: 4),
                      Center(
                        child: Text(
                          AppLocalizations.of(context)!.translate("in_trnc"),
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 8),
                  Column(
                    children: [
                      Center(
                        child: Text(
                          AppLocalizations.of(context)!
                              .translate("near_taxis_error"),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 4),
                      TextButton(
                        onPressed: () {
                          showModalBottomSheet(
                            showDragHandle: true,
                            enableDrag: true,
                            context: context,
                            builder: (context) {
                              return SizedBox(
                                width: MediaQuery.of(context).size.width,
                                height:
                                    MediaQuery.of(context).size.height * 0.25,
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          changePosition(
                                            latitude: 35.2009463,
                                            longitude: 33.334945,
                                          );
                                          Navigator.pop(context);
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                        child: Text("Lefkoşa (Nicosia)"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          changePosition(
                                            latitude: 35.095335,
                                            longitude: 33.930475,
                                          );
                                          Navigator.pop(context);
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                        child: Text("Gazimağusa (Famagusta)"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          changePosition(
                                            latitude: 35.332305,
                                            longitude: 33.319577,
                                          );
                                          Navigator.pop(context);
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                        child: Text("Girne (Kyrenia)"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          changePosition(
                                            latitude: 35.345549,
                                            longitude: 33.161444,
                                          );
                                          Navigator.pop(context);
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                        child: Text("Lapta"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          changePosition(
                                            latitude: 35.198005,
                                            longitude: 32.993815,
                                          );
                                          Navigator.pop(context);
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                        child: Text("Güzelyurt (Morphou)"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          changePosition(
                                            latitude: 35.113689,
                                            longitude: 32.849653,
                                          );
                                          Navigator.pop(context);
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                        child: Text("Lefke"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          changePosition(
                                            latitude: 35.286091,
                                            longitude: 33.892211,
                                          );
                                          Navigator.pop(context);
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                        child: Text("İskele"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          changePosition(
                                              latitude: 35.598727,
                                              longitude: 34.380792);
                                          Navigator.pop(context);
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                        child: Text("Dipkarpaz"),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Text("Change Location"),
                      )
                    ],
                  )
                ],
              );
            }

            if (snapshot.hasData) {
              final data = snapshot.data as Map<String, dynamic>;
              final List<dynamic> taxis = data['data']['taxis'];

              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(left: 16, right: 16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.rocket_launch,
                                    size: 18,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    AppLocalizations.of(context)!.translate(
                                        'most_populars',
                                        params: {'city': "$_city"}),
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.clip,
                                    softWrap: true,
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    showDragHandle: true,
                                    enableDrag: true,
                                    context: context,
                                    builder: (context) {
                                      return SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.25,
                                        child: SingleChildScrollView(
                                          child: Column(
                                            children: [
                                              TextButton(
                                                onPressed: () {
                                                  changePosition(
                                                    latitude: 35.2009463,
                                                    longitude: 33.334945,
                                                  );
                                                  Navigator.pop(context);
                                                },
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.white
                                                          : Colors.black,
                                                ),
                                                child:
                                                    Text("Lefkoşa (Nicosia)"),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  changePosition(
                                                    latitude: 35.095335,
                                                    longitude: 33.930475,
                                                  );
                                                  Navigator.pop(context);
                                                },
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.white
                                                          : Colors.black,
                                                ),
                                                child: Text(
                                                    "Gazimağusa (Famagusta)"),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  changePosition(
                                                    latitude: 35.332305,
                                                    longitude: 33.319577,
                                                  );
                                                  Navigator.pop(context);
                                                },
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.white
                                                          : Colors.black,
                                                ),
                                                child: Text("Girne (Kyrenia)"),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  changePosition(
                                                    latitude: 35.345549,
                                                    longitude: 33.161444,
                                                  );
                                                  Navigator.pop(context);
                                                },
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.white
                                                          : Colors.black,
                                                ),
                                                child: Text("Lapta"),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  changePosition(
                                                    latitude: 35.198005,
                                                    longitude: 32.993815,
                                                  );
                                                  Navigator.pop(context);
                                                },
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.white
                                                          : Colors.black,
                                                ),
                                                child:
                                                    Text("Güzelyurt (Morphou)"),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  changePosition(
                                                    latitude: 35.113689,
                                                    longitude: 32.849653,
                                                  );
                                                  Navigator.pop(context);
                                                },
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.white
                                                          : Colors.black,
                                                ),
                                                child: Text("Lefke"),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  changePosition(
                                                    latitude: 35.286091,
                                                    longitude: 33.892211,
                                                  );
                                                  Navigator.pop(context);
                                                },
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.white
                                                          : Colors.black,
                                                ),
                                                child: Text("İskele"),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  changePosition(
                                                      latitude: 35.598727,
                                                      longitude: 34.380792);
                                                  Navigator.pop(context);
                                                },
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.white
                                                          : Colors.black,
                                                ),
                                                child: Text("Dipkarpaz"),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: Text("Change"),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          CarouselSlider.builder(
                            itemCount: taxis.length,
                            options: CarouselOptions(
                              height: MediaQuery.of(context).size.width > 360
                                  ? MediaQuery.of(context).size.height * .28
                                  : MediaQuery.of(context).size.height * .34,
                              autoPlay: true,
                              autoPlayInterval: Duration(milliseconds: 3500),
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
                                                semanticLabel: "Profile Image",
                                                loadingBuilder:
                                                    (context, child, progress) {
                                                  if (progress == null)
                                                    return child;
                                                  else
                                                    return Skeletonizer.zone(
                                                      child: Bone.square(
                                                        size: 56,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16),
                                                      ),
                                                    );
                                                },
                                              ),
                                            )
                                          : SizedBox(
                                              width: 56,
                                              height: 56,
                                              child: CircleAvatar(),
                                            ),
                                      title: Text(
                                        taxi['taxi_name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(
                                            bookmarkProvider.isBookmarked(taxi)
                                                ? Icons.bookmark
                                                : Icons.bookmark_outline),
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white54
                                            : Colors.black54,
                                        onPressed: () async {
                                          if (bookmarkProvider
                                              .isBookmarked(taxi)) {
                                            await bookmarkProvider
                                                .removeBookmark(taxi);

                                            Fluttertoast.showToast(
                                              msg: AppLocalizations.of(context)!
                                                  .translate("taxi_removed"),
                                              toastLength: Toast.LENGTH_SHORT,
                                              gravity: ToastGravity.BOTTOM,
                                              timeInSecForIosWeb: 1,
                                              textColor: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                              backgroundColor: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.black
                                                  : Colors.white,
                                            );
                                          } else {
                                            await bookmarkProvider
                                                .setBookmark(taxi);

                                            Fluttertoast.showToast(
                                              msg: AppLocalizations.of(context)!
                                                  .translate("taxi_added"),
                                              toastLength: Toast.LENGTH_SHORT,
                                              gravity: ToastGravity.BOTTOM,
                                              timeInSecForIosWeb: 1,
                                              textColor: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                              backgroundColor: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.black
                                                  : Colors.white,
                                            );
                                          }
                                        },
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "@${taxi['taxi_username']}",
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white54
                                                  : Colors.black54,
                                              fontSize: 12,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Row(
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
                                              SizedBox(width: 2),
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
                                          SizedBox(height: 4),
                                          Tooltip(
                                            message: AppLocalizations.of(
                                                    context)!
                                                .translate(
                                                    "rating_score_google_maps"),
                                            textStyle: TextStyle(
                                                fontSize: 14,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                          .colorScheme
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Color(0xFF030a0e)
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            showDuration:
                                                Duration(milliseconds: 2500),
                                            triggerMode: TooltipTriggerMode.tap,
                                            child: Row(
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
                                                  itemSize: 16,
                                                  allowHalfRating: true,
                                                  ignoreGestures: true,
                                                  initialRating:
                                                      taxi['taxi_popularity']
                                                          .toDouble(),
                                                  itemBuilder: (context, _) =>
                                                      Icon(
                                                    Icons.star,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                                  unratedColor:
                                                      Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.white24
                                                          : Colors.black26,
                                                  onRatingUpdate: (rating) {},
                                                ),
                                                SizedBox(width: 3),
                                                Icon(
                                                  Icons.info,
                                                  size: 16,
                                                  // color: Colors.blueAccent,
                                                )
                                              ],
                                            ),
                                          )
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
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18)),
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
                                              onPressed: () {
                                                makePhoneCall(context,
                                                    taxi['taxi_phone']);
                                              },
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    Colors.blueAccent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    bottomLeft:
                                                        Radius.circular(16),
                                                  ),
                                                ),
                                                elevation: 0,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.phone,
                                                    size: 18,
                                                  ),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    AppLocalizations.of(
                                                            context)!
                                                        .translate('phone'),
                                                  )
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
                                                      'phone':
                                                          taxi['taxi_phone']
                                                    },
                                                  ),
                                                );
                                              },
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.green,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    bottomRight:
                                                        Radius.circular(16),
                                                  ),
                                                ),
                                                elevation: 0,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    MaterialCommunityIcons
                                                        .whatsapp,
                                                    size: 18,
                                                  ),
                                                  SizedBox(width: 6),
                                                  Text("WhatsApp")
                                                ],
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              );
                            },
                          )
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
                                AppLocalizations.of(context)!
                                    .translate("others_around"),
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }

                        final taxi = _taxis[index];

                        return InkWell(
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
                          focusColor: Color(0xFF141d21),
                          hoverColor: Color(0xFF141d21),
                          // overlayColor:
                          //     MaterialStateProperty.all(Color(0xFF141d21)),
                          child: Column(
                            children: [
                              ListTile(
                                leading: taxi['taxi_profile'] != null
                                    ? ClipOval(
                                        child: Image.network(
                                          taxi['taxi_profile'],
                                          width: 40,
                                          height: 40,
                                          semanticLabel: "Profile Image",
                                          loadingBuilder:
                                              (context, child, progress) {
                                            if (progress == null)
                                              return child;
                                            else
                                              return Skeletonizer.zone(
                                                child: Bone.square(
                                                  size: 40,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                              );
                                          },
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
                                  icon: Icon(bookmarkProvider.isBookmarked(taxi)
                                      ? Icons.bookmark
                                      : Icons.bookmark_outline),
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white54
                                      : Colors.black54,
                                  onPressed: () async {
                                    if (bookmarkProvider.isBookmarked(taxi)) {
                                      await bookmarkProvider
                                          .removeBookmark(taxi);

                                      Fluttertoast.showToast(
                                        msg: AppLocalizations.of(context)!
                                            .translate("taxi_removed"),
                                        toastLength: Toast.LENGTH_SHORT,
                                        gravity: ToastGravity.BOTTOM,
                                        timeInSecForIosWeb: 1,
                                        textColor:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Colors.black,
                                        backgroundColor:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.black
                                                : Colors.white,
                                      );
                                    } else {
                                      await bookmarkProvider.setBookmark(taxi);

                                      Fluttertoast.showToast(
                                        msg: AppLocalizations.of(context)!
                                            .translate("taxi_added"),
                                        toastLength: Toast.LENGTH_SHORT,
                                        gravity: ToastGravity.BOTTOM,
                                        timeInSecForIosWeb: 1,
                                        textColor:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Colors.black,
                                        backgroundColor:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.black
                                                : Colors.white,
                                      );
                                    }
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white54
                                              : Colors.black54,
                                        ),
                                        SizedBox(width: 2),
                                        Text(
                                          "${taxi['taxi_city']}",
                                          style: TextStyle(
                                            color:
                                                Theme.of(context).brightness ==
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
                                    SizedBox(height: 4),
                                    Tooltip(
                                      message: AppLocalizations.of(context)!
                                          .translate(
                                              "rating_score_google_maps"),
                                      textStyle: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.black),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                                    .colorScheme
                                                    .brightness ==
                                                Brightness.dark
                                            ? Color(0xFF030a0e)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      showDuration:
                                          Duration(milliseconds: 2500),
                                      triggerMode: TooltipTriggerMode.tap,
                                      child: Row(
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
                                            itemSize: 16,
                                            allowHalfRating: true,
                                            ignoreGestures: true,
                                            initialRating:
                                                taxi['taxi_popularity']
                                                    .toDouble(),
                                            itemBuilder: (context, _) => Icon(
                                              Icons.star,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                            unratedColor:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white24
                                                    : Colors.black26,
                                            onRatingUpdate: (rating) {},
                                          ),
                                          SizedBox(width: 3),
                                          Icon(
                                            Icons.info,
                                            size: 16,
                                            // color: Colors.blueAccent,
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 16, right: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        makePhoneCall(
                                            context, taxi['taxi_phone']);
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.blueAccent,
                                        elevation: 0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.phone,
                                            size: 18,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            AppLocalizations.of(context)!
                                                .translate('phone'),
                                          )
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            MaterialCommunityIcons.whatsapp,
                                            size: 18,
                                          ),
                                          SizedBox(width: 6),
                                          Text("WhatsApp")
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (index < taxi.length - 1)
                                SizedBox(
                                  height: 16,
                                )
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }

            return Center(
              child: Text("Something went wrong."),
            );
          }

          return Center(
            child: SizedBox(
              width: 192,
              height: 192,
              child: Image.asset(Theme.of(context).brightness == Brightness.dark
                  ? 'assets/icons/splash.light.png'
                  : 'assets/icons/splash.png'),
            ),
          );
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final position;

  const HomeScreen({required this.position, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

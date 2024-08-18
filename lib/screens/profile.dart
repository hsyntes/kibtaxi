import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:kibtaxi/app_localization.dart';
import 'package:kibtaxi/providers/bookmark.dart';
import 'package:kibtaxi/utils/helpers.dart';
import 'package:kibtaxi/widgets/appbar.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<dynamic> _taxi;

  Future<dynamic> _getTaxi() async {
    try {
      final response = await http
          .get(Uri.parse("${dotenv.env['API_URL']}/taxis/id/${widget.id}"));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  void initState() {
    super.initState();
    _taxi = _getTaxi();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkProvider = Provider.of<BookmarkProvider>(context);

    return Scaffold(
      appBar: MyAppBar(
        title: Text(
          widget.appBarTitle,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<dynamic>(
        future: _taxi,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Skeletonizer.zone(
              child: ListTile(
                leading: Bone.circle(size: 48),
                title: Bone.text(words: 2),
                subtitle: Bone.text(words: 1),
                trailing: Bone.icon(),
                isThreeLine: true,
              ),
            );
          }

          if (snapshot.hasData) {
            final taxi = snapshot.data['data']['taxi'];

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      ListTile(
                        leading: taxi['taxi_profile'] != null
                            ? ClipOval(
                                child: Image.network(
                                  taxi['taxi_profile'],
                                  semanticLabel: "Profile Image",
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null)
                                      return child;
                                    else
                                      return Skeletonizer.zone(
                                        child: Bone.square(
                                          size: 56,
                                          borderRadius:
                                              BorderRadius.circular(16),
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
                        title: Text(taxi['taxi_name']),
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
                            SizedBox(height: 4),
                            Tooltip(
                              message: AppLocalizations.of(context)!
                                  .translate("rating_score_google_maps"),
                              textStyle: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).colorScheme.brightness ==
                                            Brightness.dark
                                        ? Colors.black
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              showDuration: Duration(milliseconds: 2500),
                              triggerMode: TooltipTriggerMode.tap,
                              child: Row(
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
                                    itemSize: 16,
                                    allowHalfRating: true,
                                    ignoreGestures: true,
                                    initialRating:
                                        taxi['taxi_popularity'].toDouble(),
                                    itemBuilder: (context, _) => Icon(
                                      Icons.star,
                                      color:
                                          Theme.of(context).colorScheme.primary,
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
                        trailing: IconButton(
                          onPressed: () async {
                            if (bookmarkProvider.isBookmarked(taxi)) {
                              await bookmarkProvider.removeBookmark(taxi);

                              Fluttertoast.showToast(
                                msg: AppLocalizations.of(context)!
                                    .translate("taxi_removed"),
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                timeInSecForIosWeb: 1,
                                textColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                                backgroundColor: Theme.of(context).brightness ==
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
                                textColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                                backgroundColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.black
                                    : Colors.white,
                              );
                            }
                          },
                          icon: Icon(
                            bookmarkProvider.isBookmarked(taxi)
                                ? Icons.bookmark
                                : Icons.bookmark_outline,
                            color: bookmarkProvider.isBookmarked(taxi)
                                ? Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black
                                : Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white54
                                    : Colors.black54,
                          ),
                        ),
                        isThreeLine: true,
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: EdgeInsets.only(right: 16, left: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                makePhoneCall(context, taxi['taxi_phone']);
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                mainAxisAlignment: MainAxisAlignment.center,
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
                      )
                    ],
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverPadding(
                  padding: EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      // crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      childCount: taxi['taxi_photos']?.length ?? 0,
                      (context, index) {
                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                backgroundColor: Colors.transparent,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 6,
                                      sigmaY: 6,
                                    ),
                                    child: Hero(
                                      transitionOnUserGestures: true,
                                      tag: 'imageHero$index',
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          taxi['taxi_photos'][index],
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              taxi['taxi_photos'][index],
                              loadingBuilder: (context, child, progress) {
                                if (progress == null)
                                  return child;
                                else
                                  return Skeletonizer.zone(
                                    child: Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Bone.square(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              ],
            );
          }

          return Text("");
        },
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  final appBarTitle;
  final id;
  const ProfileScreen({required this.id, required this.appBarTitle, super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

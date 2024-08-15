import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kibtaxi/app_localization.dart';
import 'package:kibtaxi/models/bookmark.dart';
import 'package:kibtaxi/screens/profile.dart';
import 'package:kibtaxi/widgets/appbar.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class BookmarkScreen extends StatelessWidget {
  const BookmarkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookmarkProvider = Provider.of<BookmarkProvider>(context);
    final taxis = bookmarkProvider.bookmarks;

    return Scaffold(
      appBar: MyAppBar(
        leading: Icon(
          Icons.bookmark,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          AppLocalizations.of(context)!.translate("my_taxis"),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: taxis.length != 0
            ? [
                IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        showDragHandle: true,
                        context: context,
                        builder: (context) {
                          return SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height * .1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(context);

                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          insetPadding: EdgeInsets.all(4),
                                          title: Row(
                                            children: [
                                              Icon(
                                                Icons.bookmark,
                                                size: 14,
                                              ),
                                              SizedBox(width: 4),
                                              Text(AppLocalizations.of(context)!
                                                  .translate("remove_all"))
                                            ],
                                          ),
                                          titleTextStyle: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black,
                                          ),
                                          content: Text(
                                            AppLocalizations.of(context)!
                                                .translate(
                                                    "want_to_remove_all"),
                                          ),
                                          contentTextStyle: TextStyle(
                                            fontSize: 14,
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black,
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () async {
                                                Navigator.pop(context);
                                                await bookmarkProvider
                                                    .removeAllBookmarks();
                                              },
                                              child: Text(
                                                AppLocalizations.of(context)!
                                                    .translate("yes"),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .translate("remove_all"),
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    icon: Icon(Icons.menu))
              ]
            : null,
      ),
      body: taxis.length != 0
          ? ListView.builder(
              itemCount: taxis.length,
              itemBuilder: (context, index) {
                final taxi = taxis[index];

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
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white54
                              : Colors.black54,
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
                                SizedBox(width: 2),
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
                            SizedBox(height: 8),
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
                          ],
                        ),
                        isThreeLine: true,
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 16, right: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                      ),
                      if (index < taxi.length - 1)
                        SizedBox(
                          height: 16,
                        )
                    ],
                  ),
                );
              },
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Text(
                    AppLocalizations.of(context)!.translate("nothing_to_show"),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white54
                          : Colors.black54,
                    ),
                  ),
                )
              ],
            ),
    );
  }
}

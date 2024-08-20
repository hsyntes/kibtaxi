import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kibtaxi/app_localization.dart';
import 'package:kibtaxi/providers/bookmark.dart';
import 'package:kibtaxi/screens/profile.dart';
import 'package:kibtaxi/services/ad_service.dart';
import 'package:kibtaxi/utils/helpers.dart';
import 'package:kibtaxi/widgets/appbar.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class _BookmarkScreenState extends State<BookmarkScreen> {
  final InterstitialAds _interstitialAds = InterstitialAds();

  @override
  void initState() {
    super.initState();
  }

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
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: taxis.isNotEmpty
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
                                          insetPadding: const EdgeInsets.all(4),
                                          title: Row(
                                            children: [
                                              const Icon(
                                                Icons.bookmark,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 4),
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
                                                style: const TextStyle(
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
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.menu))
              ]
            : null,
      ),
      body: taxis.isNotEmpty
          ? ListView.builder(
              itemCount: taxis.length,
              itemBuilder: (context, index) {
                final taxi = taxis[index];

                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        _interstitialAds.showAd(onAdClosed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen(
                                id: taxi['_id'],
                                appBarTitle: taxi['taxi_name'],
                              ),
                            ),
                          );
                        });
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
                                : const CircleAvatar(),
                            title: Text(
                              taxi['taxi_name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.bookmark),
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
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
                                    textColor: Theme.of(context).brightness ==
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
                                const SizedBox(height: 8),
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
                                    const SizedBox(width: 1),
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
                                const SizedBox(height: 4),
                                Text(
                                  "${taxi['taxi_address']}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 4),
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
                                    color: Theme.of(context)
                                                .colorScheme
                                                .brightness ==
                                            Brightness.dark
                                        ? Colors.black
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  showDuration:
                                      const Duration(milliseconds: 2500),
                                  triggerMode: TooltipTriggerMode.tap,
                                  child: Row(
                                    children: [
                                      Text(
                                        "${taxi['taxi_popularity']['rating']}",
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      RatingBar.builder(
                                        updateOnDrag: false,
                                        itemCount: 5,
                                        itemSize: 16,
                                        allowHalfRating: true,
                                        ignoreGestures: true,
                                        initialRating: taxi['taxi_popularity']
                                                ['rating']
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
                                      const SizedBox(width: 3),
                                      Text(
                                        "(${taxi['taxi_popularity']['voted']})",
                                        style: TextStyle(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white24
                                              : Colors.black26,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      const Icon(
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
                            padding: const EdgeInsets.only(left: 16, right: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    _interstitialAds.showAd(onAdClosed: () {
                                      makePhoneCall(
                                          context, taxi['taxi_phone']);
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blueAccent,
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.phone,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppLocalizations.of(context)!
                                            .translate('phone'),
                                      )
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _interstitialAds.showAd(
                                        onAdClosed: () async {
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
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.green,
                                    elevation: 0,
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        MaterialCommunityIcons.whatsapp,
                                        size: 18,
                                      ),
                                      SizedBox(width: 4),
                                      Text("WhatsApp")
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index != taxis.length - 1) const SizedBox(height: 16),
                    if (index < 1)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: BannerAdWidget(),
                      ),
                  ],
                );
              },
            )
          : Stack(
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
                ),
                const Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: BannerAdWidget(),
                )
              ],
            ),
    );
  }
}

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

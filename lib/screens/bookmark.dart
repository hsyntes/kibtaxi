import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:mobile/models/bookmark.dart';
import 'package:mobile/screens/profile.dart';
import 'package:mobile/widgets/appbar.dart';
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
        title: Text(
          "My Taxis",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.builder(
        itemCount: taxis.length,
        itemBuilder: (context, index) {
          final taxi = taxis[index];

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
              icon: Icon(bookmarkProvider.isBookmarked(taxi)
                  ? Icons.bookmark
                  : Icons.bookmark_outline),
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.black54,
              onPressed: () async {
                if (bookmarkProvider.isBookmarked(taxi))
                  await bookmarkProvider.removeBookmark(taxi);
                else
                  await bookmarkProvider.setBookmark(taxi);
              },
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "@${taxi['taxi_username']}",
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
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
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white54
                          : Colors.black54,
                    ),
                    SizedBox(
                      width: 2,
                    ),
                    Text(
                      "${taxi['taxi_city']}",
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
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
                        color: Theme.of(context).colorScheme.primary,
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
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      unratedColor:
                          Theme.of(context).brightness == Brightness.dark
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
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                            queryParameters: {'phone': taxi['taxi_phone']},
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                        elevation: 0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
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
    );
  }
}

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAds {
  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;
  Function? _onAdClosedCallback;

  final String adUnitId = Platform.isAndroid
      ? dotenv.env["ANDROID_CA_APP_PUB"].toString()
      : dotenv.env["IOS_CA_APP_PUB"].toString();

  void loadAd() {
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {},
              onAdImpression: (ad) {},
              onAdFailedToShowFullScreenContent: (ad, err) {
                ad.dispose();
                _isAdReady = false;
              },
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _isAdReady = false;

                if (_onAdClosedCallback != null) {
                  _onAdClosedCallback!();
                }
              },
              onAdClicked: (ad) {});

          debugPrint('$ad loaded.');
          _interstitialAd = ad;
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd failed to load: $error');
          _isAdReady = false;
        },
      ),
    );
  }

  void showAd({required Function onAdClosed}) {
    if (_interstitialAd != null && _isAdReady) {
      _onAdClosedCallback = onAdClosed;
      _interstitialAd!.show();
      _interstitialAd = null;

      Future.delayed(const Duration(milliseconds: 30000), () {
        loadAd();
      });
    } else {
      debugPrint('InterstitialAd is not ready yet or already disposed.');

      onAdClosed();

      // loadAd();
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
  }
}

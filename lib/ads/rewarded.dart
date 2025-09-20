import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAds {
  /// The AdMob ad unit to show for rewarded ads.
  /// TODO: replace this test ad unit with your own ad unit
  final String rewardedAdUnitId = Platform.isAndroid
      // Use this ad unit on Android...
      ? 'ca-app-pub-8379581354079241/5395347502'
      // ... or this one on iOS.
      : 'ca-app-pub-8379581354079241/5395347502';

  /// Rewarded ad instance.
  RewardedAd? _rewardedAd;

  /// Loads a rewarded ad.
  Future<void> loadRewardedAd() async {
    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          debugPrint('Rewarded ad loaded successfully.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedAd failed to load: $error');
          loadRewardedAd(); // Retry loading the ad
        },
      ),
    );
  }

  /// Displays the rewarded ad and returns true only when the ad is dismissed.
  Future<bool> showRewardedAd(BuildContext context) async {
    if (_rewardedAd == null) {
      debugPrint('Warning: attempt to show rewarded ad before it is loaded.');
      return false;
    }

    final Completer<bool> completer = Completer<bool>();

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        Fluttertoast.showToast(
          msg: "Undoing last move",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.SNACKBAR,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 14.0,
        );
      },
    );

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('Rewarded ad dismissed.');
        ad.dispose();
        loadRewardedAd(); // Load another ad after dismissal
        completer.complete(true); // Resolve with true when ad is dismissed
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('Failed to show rewarded ad: $error');
        Fluttertoast.showToast(
          msg: "Failed to show ad",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        ad.dispose();
        completer.complete(false); // Resolve with false on failure
      },
    );

    return completer.future;
  }
}
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AutoUpdater {
  static const String apkUrl = "https://github.com/malikkashifawan7/Transport_manager/releases/latest/download/app-release.apk";

  static void checkAndDownloadUpdate(BuildContext context) async {
    final Uri url = Uri.parse(apkUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch $apkUrl");
    }
  }
}

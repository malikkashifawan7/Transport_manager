import 'package:flutter/material.dart';
import 'package:flutter_app_installer/flutter_app_installer.dart';

class AutoUpdater {
  static const String apkUrl = "https://github.com/malikkashifawan7/Transport_manager/releases/latest/download/app-release.apk";

  static void checkAndDownloadUpdate(BuildContext context) async {
    final FlutterAppInstaller appInstaller = FlutterAppInstaller();
    try {
      await appInstaller.installApk(filePath: apkUrl);
    } catch (e) {
      debugPrint("Update error: $e");
    }
  }
}


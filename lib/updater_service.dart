import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';

class AutoUpdater {
  static const String apkUrl = "https://github.com/malikkashifawan7/Transport_manager/releases/latest/download/app-release.apk";

  static void checkAndDownloadUpdate(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          title: Text('Updating Application...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(),
              SizedBox(height: 16),
              Text('Downloading latest release APK from GitHub...'),
            ],
          ),
        );
      },
    );

    try {
      OtaUpdate().execute(apkUrl).listen(
        (OtaEvent event) {
          if (event.status == OtaStatus.INSTALLING) {
            Navigator.pop(context);
          }
        },
      );
    } catch (e) {
      Navigator.pop(context);
    }
  }
}


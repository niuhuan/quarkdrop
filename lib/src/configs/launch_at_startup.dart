import 'dart:io';

import 'package:flutter/services.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';

bool autoStartup = false;
bool autoStartupAvailable = true;

Future<void> initAutoStartup() async {
  final packageInfo = await PackageInfo.fromPlatform();
  launchAtStartup.setup(
    appName: packageInfo.appName,
    appPath: Platform.resolvedExecutable,
    packageName: packageInfo.packageName,
  );
  try {
    autoStartup = await launchAtStartup.isEnabled();
    autoStartupAvailable = true;
  } on MissingPluginException {
    autoStartup = false;
    autoStartupAvailable = false;
  } on PlatformException {
    autoStartup = false;
    autoStartupAvailable = false;
  }
}

Future<void> setAutoStartup(bool enable) async {
  try {
    if (enable) {
      await launchAtStartup.enable();
    } else {
      await launchAtStartup.disable();
    }
    autoStartup = enable;
    autoStartupAvailable = true;
  } on MissingPluginException {
    autoStartup = false;
    autoStartupAvailable = false;
  } on PlatformException {
    autoStartup = false;
    autoStartupAvailable = false;
  }
}

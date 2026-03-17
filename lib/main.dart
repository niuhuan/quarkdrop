import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:quarkdrop/src/app/quarkdrop_app.dart';
import 'package:quarkdrop/src/configs/desktop_layout.dart';
import 'package:quarkdrop/src/configs/launch_at_startup.dart';
import 'package:quarkdrop/src/platform/platform_paths.dart';
import 'package:quarkdrop/src/rust/api/simple.dart' as rust_simple;
import 'package:quarkdrop/src/rust/frb_generated.dart';
import 'package:quarkdrop/src/state/app_store.dart';

bool get _isDesktop =>
    Platform.isMacOS || Platform.isWindows || Platform.isLinux;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_isDesktop) {
    await initDesktopWindow();
    await initDesktopTray();
    await initAutoStartup();
  }
  await RustLib.init();
  final platformPaths = await PlatformPathsResolver.resolve();
  rust_simple.configureApp(configDir: platformPaths.configDir);
  final store = AppStore(platformPaths: platformPaths);
  await store.bootstrap();

  runApp(QuarkDropApp(store: store));
}

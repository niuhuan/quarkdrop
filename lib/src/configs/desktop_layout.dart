import 'dart:io';

import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class DesktopWindowListener with WindowListener {
  const DesktopWindowListener();

  @override
  Future<void> onWindowClose() async {
    await windowManager.hide();
    if (Platform.isMacOS) {
      await windowManager.setSkipTaskbar(true);
    }
  }
}

class DesktopTrayListener with TrayListener {
  const DesktopTrayListener();

  @override
  void onTrayIconMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  Future<void> onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'show_window') {
      await windowManager.show();
      if (Platform.isMacOS) {
        await windowManager.setSkipTaskbar(false);
      }
    } else if (menuItem.key == 'exit_app') {
      exit(0);
    }
  }
}

const _windowListener = DesktopWindowListener();
const _trayListener = DesktopTrayListener();

Future<void> initDesktopWindow() async {
  await windowManager.ensureInitialized();
  await windowManager.setPreventClose(true);
  windowManager.addListener(_windowListener);
}

Future<void> initDesktopTray() async {
  await trayManager.setIcon(
    Platform.isWindows ? 'lib/assets/app_icon.ico' : 'lib/assets/app_icon.png',
  );
  final menu = Menu(
    items: [
      MenuItem(key: 'show_window', label: 'Show Window'),
      MenuItem.separator(),
      MenuItem(key: 'exit_app', label: 'Quit'),
    ],
  );
  await trayManager.setContextMenu(menu);
  trayManager.addListener(_trayListener);
}

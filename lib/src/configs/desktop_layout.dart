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
bool get _isDesktopPlatform =>
    Platform.isMacOS || Platform.isWindows || Platform.isLinux;

Future<void> _setTrayContextMenu({
  required String showWindowLabel,
  required String quitLabel,
}) async {
  if (!_isDesktopPlatform) {
    return;
  }
  final menu = Menu(
    items: [
      MenuItem(key: 'show_window', label: showWindowLabel),
      MenuItem.separator(),
      MenuItem(key: 'exit_app', label: quitLabel),
    ],
  );
  await trayManager.setContextMenu(menu);
}

Future<void> initDesktopWindow() async {
  if (!_isDesktopPlatform) {
    return;
  }
  await windowManager.ensureInitialized();
  await windowManager.setPreventClose(true);
  windowManager.addListener(_windowListener);
}

Future<void> initDesktopTray() async {
  if (!_isDesktopPlatform) {
    return;
  }
  if (Platform.isMacOS) {
    await trayManager.setIcon(
      'lib/assets/tray_icon_template.png',
      isTemplate: true,
    );
  } else {
    await trayManager.setIcon(
      Platform.isWindows
          ? 'lib/assets/app_icon.ico'
          : 'lib/assets/app_icon.png',
    );
  }
  await _setTrayContextMenu(showWindowLabel: 'Show Window', quitLabel: 'Quit');
  trayManager.addListener(_trayListener);
}

Future<void> updateDesktopTrayMenu({
  required String showWindowLabel,
  required String quitLabel,
}) async {
  if (!_isDesktopPlatform) {
    return;
  }
  await _setTrayContextMenu(
    showWindowLabel: showWindowLabel,
    quitLabel: quitLabel,
  );
}

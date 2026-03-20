import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:quarkdrop/src/l10n/l10n.dart';
import 'package:quarkdrop/src/state/app_store.dart';
import 'package:window_manager/window_manager.dart';

class AutoMinimizeOverlay extends StatefulWidget {
  const AutoMinimizeOverlay({
    super.key,
    required this.store,
    required this.child,
  });

  final AppStore store;
  final Widget child;

  @override
  State<AutoMinimizeOverlay> createState() => _AutoMinimizeOverlayState();
}

class _AutoMinimizeOverlayState extends State<AutoMinimizeOverlay> {
  static bool _hasRun = false;

  int? _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!_hasRun) {
      _hasRun = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  Future<void> _hideToTray() async {
    await windowManager.hide();
    if (Platform.isMacOS) {
      await windowManager.setSkipTaskbar(true);
    }
  }

  void _start() {
    if (!mounted) return;
    final enabled = widget.store.autoMinimizeOnStart.value;
    if (!enabled) {
      if (Platform.isWindows) {
        // Windows no longer auto-shows in the runner, so explicitly show the
        // window when startup auto-minimize is disabled.
        windowManager.show();
      }
      return;
    }

    final delay = widget.store.autoMinimizeDelaySeconds.value;
    if (delay == 0) {
      _hideToTray();
      return;
    }

    if (Platform.isWindows) {
      // For delayed minimize on Windows, show first so the countdown overlay
      // is visible before we hide the app to the tray.
      windowManager.show();
    }
    setState(() {
      _remainingSeconds = delay;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _timer?.cancel();
        return;
      }
      final next = (_remainingSeconds ?? 0) - 1;
      if (next <= 0) {
        _timer?.cancel();
        setState(() {
          _remainingSeconds = null;
        });
        _hideToTray();
      } else {
        setState(() {
          _remainingSeconds = next;
        });
      }
    });
  }

  void _cancel() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = null;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_remainingSeconds != null) _buildOverlay(context),
      ],
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final l10n = context.l10n;
    return Positioned.fill(
      child: GestureDetector(
        onTap: _cancel,
        behavior: HitTestBehavior.opaque,
        child: ColoredBox(
          color: const Color(0xB3000000),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.autoMinimizeOverlayCountdown(_remainingSeconds!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.autoMinimizeOverlayCancel,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

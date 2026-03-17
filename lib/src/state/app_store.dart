import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:file_selector/file_selector.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quarkdrop/l10n/generated/app_localizations.dart';
import 'package:quarkdrop/src/configs/screen_wakelock.dart';
import 'package:quarkdrop/src/l10n/app_locale.dart';
import 'package:quarkdrop/src/models/inbox_job.dart';
import 'package:quarkdrop/src/models/pending_send_item.dart';
import 'package:quarkdrop/src/models/transfer_job.dart';
import 'package:quarkdrop/src/platform/platform_paths.dart';
import 'package:quarkdrop/src/rust/api/app.dart' as rust_api;
import 'package:signals_flutter/signals_flutter.dart';
import 'package:window_manager/window_manager.dart';

part 'app_store_auth.dart';
part 'app_store_bootstrap.dart';
part 'app_store_send_receive.dart';
part 'app_store_transfers.dart';
part 'app_store_settings.dart';

enum BootstrapPhase {
  booting,
  passwordRequired,
  loginRequired,
  cloudDeviceSelection,
  ready,
}

enum AppDestination { send, inbox, transfers, settings }

class AppStore with WidgetsBindingObserver, WindowListener {
  AppStore({required this.platformPaths}) {
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      windowManager.addListener(this);
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      windowManager.removeListener(this);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppVisible = true;
      refresh();
      _checkPolling();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _isAppVisible = false;
      _checkPolling();
    }
  }

  @override
  void onWindowFocus() {
    _isAppVisible = true;
    refresh();
    _checkPolling();
  }

  @override
  void onWindowBlur() {
    _isAppVisible = false;
    _checkPolling();
  }

  @override
  void onWindowRestore() {
    _isAppVisible = true;
    refresh();
    _checkPolling();
  }

  @override
  void onWindowMinimize() {
    _isAppVisible = false;
    _checkPolling();
  }

  final PlatformPaths platformPaths;
  bool _isAppVisible = true;
  bool _justLoggedIn = false;
  int _authDowngradeStreak = 0;
  int _backgroundTransferOperations = 0;
  bool _refreshQueued = false;
  final _activeAutoReceives = <String>{};
  Timer? _pollingTimer;
  Timer? _mailboxTimer;

  final bootstrapPhase = signal(
    BootstrapPhase.booting,
    debugLabel: 'bootstrapPhase',
  );
  final destination = signal(AppDestination.send, debugLabel: 'destination');
  final inboxJobs = signal(<InboxJob>[], debugLabel: 'inboxJobs');
  final transferJobs = signal(<TransferJob>[], debugLabel: 'transferJobs');
  final selectedTransferId = signal<String?>(
    null,
    debugLabel: 'selectedTransferId',
  );
  final selectedPeerDeviceId = signal<String?>(
    null,
    debugLabel: 'selectedPeerDeviceId',
  );
  final lastErrorMessage = signal<String?>(
    null,
    debugLabel: 'lastErrorMessage',
  );
  final loginInProgress = signal(false, debugLabel: 'loginInProgress');
  final loginCookieDraft = signal('', debugLabel: 'loginCookieDraft');
  final quarkLoginUrl = signal('', debugLabel: 'quarkLoginUrl');
  final sendInProgress = signal(false, debugLabel: 'sendInProgress');
  final sendStatusMessage = signal<String?>(
    null,
    debugLabel: 'sendStatusMessage',
  );
  final pendingSendItems = signal<List<PendingSendItem>>(
    const [],
    debugLabel: 'pendingSendItems',
  );
  final selectedMailboxJobIds = signal<Set<String>>(
    <String>{},
    debugLabel: 'selectedMailboxJobIds',
  );
  final lastSentPath = signal<String?>(null, debugLabel: 'lastSentPath');
  final receiveInProgress = signal(false, debugLabel: 'receiveInProgress');
  final receiveStatusMessage = signal<String?>(
    null,
    debugLabel: 'receiveStatusMessage',
  );
  final mailboxStatusMessage = signal<String?>(
    null,
    debugLabel: 'mailboxStatusMessage',
  );
  final lastReceivePath = signal<String?>(null, debugLabel: 'lastReceivePath');
  final resumeInProgress = signal(false, debugLabel: 'resumeInProgress');
  final resumeStatusMessage = signal<String?>(
    null,
    debugLabel: 'resumeStatusMessage',
  );
  final transferActionInProgress = signal(
    false,
    debugLabel: 'transferActionInProgress',
  );
  final transferActionStatusMessage = signal<String?>(
    null,
    debugLabel: 'transferActionStatusMessage',
  );
  final deviceNameSaving = signal(false, debugLabel: 'deviceNameSaving');
  final deviceNameStatusMessage = signal<String?>(
    null,
    debugLabel: 'deviceNameStatusMessage',
  );
  final signOutInProgress = signal(false, debugLabel: 'signOutInProgress');
  final preferredDownloadDir = signal<String?>(
    null,
    debugLabel: 'preferredDownloadDir',
  );
  final localePreferenceCode = signal<String?>(
    null,
    debugLabel: 'localePreferenceCode',
  );
  final autoReceiveEnabled = signal<bool>(
    false,
    debugLabel: 'autoReceiveEnabled',
  );
  final navigateAfterTransfer = signal<bool>(
    true,
    debugLabel: 'navigateAfterTransfer',
  );
  final pollIntervalSeconds = signal<int>(
    30,
    debugLabel: 'pollIntervalSeconds',
  );
  final maxConcurrentUploads = signal<int>(
    2,
    debugLabel: 'maxConcurrentUploads',
  );
  final maxConcurrentDownloads = signal<int>(
    2,
    debugLabel: 'maxConcurrentDownloads',
  );
  final keepScreenOnDuringTransfer = signal<bool>(
    true,
    debugLabel: 'keepScreenOnDuringTransfer',
  );
  final downloadDirectorySaving = signal(
    false,
    debugLabel: 'downloadDirectorySaving',
  );
  final downloadDirectoryStatusMessage = signal<String?>(
    null,
    debugLabel: 'downloadDirectoryStatusMessage',
  );
  final protocolNames = signal<rust_api.ProtocolNames?>(
    null,
    debugLabel: 'protocolNames',
  );
  final deviceSnapshot = signal<rust_api.DeviceSnapshot?>(
    null,
    debugLabel: 'deviceSnapshot',
  );
  final currentAuthState = signal<rust_api.AuthState?>(
    null,
    debugLabel: 'currentAuthState',
  );
  final rememberedDevices = signal<List<rust_api.RememberedDevice>>(
    const [],
    debugLabel: 'rememberedDevices',
  );
  final peerDevices = signal<List<rust_api.PeerDevice>>(
    const [],
    debugLabel: 'peerDevices',
  );
  final localeStatusMessage = signal<String?>(
    null,
    debugLabel: 'localeStatusMessage',
  );

  Locale get effectiveLocale {
    final option = appLocaleOptionFromCode(localePreferenceCode.value);
    return option?.locale ??
        resolveSupportedAppLocale(PlatformDispatcher.instance.locales);
  }

  AppLocalizations get l10n => lookupAppLocalizations(effectiveLocale);

  late final currentTitle = computed<String>(() {
    switch (destination.value) {
      case AppDestination.send:
        return 'Send';
      case AppDestination.inbox:
        return 'Mailbox';
      case AppDestination.transfers:
        return 'Transfers';
      case AppDestination.settings:
        return 'Settings';
    }
  }, debugLabel: 'currentTitle');

  late final selectedTransfer = computed<TransferJob?>(() {
    final currentId = selectedTransferId.value;
    if (currentId == null) {
      return null;
    }

    for (final job in transferJobs.value) {
      if (job.id == currentId) {
        return job;
      }
    }
    return null;
  }, debugLabel: 'selectedTransfer');

  late final selectedPeerDevice = computed<rust_api.PeerDevice?>(() {
    final currentId = selectedPeerDeviceId.value;
    if (currentId == null) {
      return null;
    }

    for (final peer in peerDevices.value) {
      if (peer.deviceId == currentId) {
        return peer;
      }
    }
    return null;
  }, debugLabel: 'selectedPeerDevice');
}

import 'dart:async';
import 'dart:io';
import 'dart:ui';

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

enum BootstrapPhase {
  booting,
  passwordRequired,
  loginRequired,
  cloudDeviceSelection,
  ready,
}

enum AppDestination { send, inbox, transfers, settings }

class AppStore {
  AppStore({required this.platformPaths});

  bool _justLoggedIn = false;
  final PlatformPaths platformPaths;
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

  Timer? _pollingTimer;
  Timer? _mailboxTimer;

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

  Future<void> bootstrap() async {
    await _loadShell();
  }

  Future<void> refresh() async {
    try {
      final snapshot = await rust_api.shellSnapshot();
      _applySnapshot(snapshot);
    } catch (error) {
      lastErrorMessage.value = error.toString();
    }
  }

  void _checkPolling() {
    final active =
        transferJobs.value.any(
          (job) =>
              job.stage != TransferStage.completed &&
              job.stage != TransferStage.failed,
        ) ||
        sendInProgress.value ||
        receiveInProgress.value;

    if (active && _pollingTimer == null) {
      _pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        refresh();
      });
    } else if (!active && _pollingTimer != null) {
      _pollingTimer?.cancel();
      _pollingTimer = null;
    }
    // Keep screen on during active transfers (mobile only)
    ScreenWakelock.setKeepScreenOn(active && keepScreenOnDuringTransfer.value);
    // Mailbox polling - always active when authenticated
    if (bootstrapPhase.value == BootstrapPhase.ready && _mailboxTimer == null) {
      final interval = pollIntervalSeconds.value.clamp(5, 300);
      _mailboxTimer = Timer.periodic(Duration(seconds: interval), (_) {
        refresh();
      });
    } else if (bootstrapPhase.value != BootstrapPhase.ready &&
        _mailboxTimer != null) {
      _mailboxTimer?.cancel();
      _mailboxTimer = null;
    }
  }

  Future<bool> submitManualCookie(String cookie) async {
    return _submitCookie(cookie, fromWebView: false);
  }

  Future<bool> submitWebViewCookie(String cookie) async {
    return _submitCookie(cookie, fromWebView: true);
  }

  Future<bool> _submitCookie(String cookie, {required bool fromWebView}) async {
    final normalized = cookie.trim();
    if (!fromWebView) {
      loginCookieDraft.value = cookie;
    }

    if (normalized.isEmpty) {
      lastErrorMessage.value = l10n.errorPasteQuarkCookie;
      bootstrapPhase.value = BootstrapPhase.loginRequired;
      return false;
    }

    loginInProgress.value = true;
    lastErrorMessage.value = null;
    try {
      if (fromWebView) {
        rust_api.saveWebviewCookieString(cookie: normalized);
      } else {
        rust_api.saveCookieString(cookie: normalized);
      }
      loginCookieDraft.value = '';
      _justLoggedIn = true;
      await refresh();
      destination.value = AppDestination.send;
      return true;
    } catch (error) {
      bootstrapPhase.value = BootstrapPhase.loginRequired;
      lastErrorMessage.value = error.toString();
      return false;
    } finally {
      loginInProgress.value = false;
    }
  }

  void completeLogin() {
    submitManualCookie(loginCookieDraft.value);
  }

  void updateCookieDraft(String value) {
    loginCookieDraft.value = value;
    if (lastErrorMessage.value != null) {
      lastErrorMessage.value = null;
    }
  }

  Future<void> restoreRememberedDevice(String deviceId) async {
    loginInProgress.value = true;
    lastErrorMessage.value = null;
    try {
      rust_api.restoreRememberedDevice(deviceId: deviceId);
      await refresh();
    } catch (error) {
      lastErrorMessage.value = error.toString();
      bootstrapPhase.value = BootstrapPhase.loginRequired;
    } finally {
      loginInProgress.value = false;
    }
  }

  Future<void> bindCloudDevice(String deviceId) async {
    loginInProgress.value = true;
    lastErrorMessage.value = null;
    try {
      rust_api.bindCloudDevice(deviceId: deviceId);
      bootstrapPhase.value = BootstrapPhase.ready;
      await refresh();
    } catch (error) {
      lastErrorMessage.value = error.toString();
    } finally {
      loginInProgress.value = false;
    }
  }

  void skipCloudDeviceSelection() {
    bootstrapPhase.value = BootstrapPhase.ready;
  }

  void selectDestination(AppDestination next) {
    destination.value = next;
  }

  void selectTransfer(String transferId) {
    selectedTransferId.value = transferId;
    destination.value = AppDestination.transfers;
  }

  Future<void> signOut({required bool deleteRemoteMailbox}) async {
    signOutInProgress.value = true;
    try {
      await rust_api.signOut(deleteRemoteMailbox: deleteRemoteMailbox);
      destination.value = AppDestination.send;
      selectedTransferId.value = null;
      deviceSnapshot.value = null;
      peerDevices.value = const [];
      selectedPeerDeviceId.value = null;
      preferredDownloadDir.value = null;
      mailboxStatusMessage.value = null;
      pendingSendItems.value = const [];
      selectedMailboxJobIds.value = <String>{};
      transferActionStatusMessage.value = null;
      lastErrorMessage.value = null;
      await _loadShell();
    } catch (error) {
      lastErrorMessage.value = error.toString();
    } finally {
      signOutInProgress.value = false;
    }
  }

  Future<void> saveDeviceName(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      lastErrorMessage.value = l10n.errorDeviceNameEmpty;
      return;
    }
    deviceNameSaving.value = true;
    deviceNameStatusMessage.value = null;
    lastErrorMessage.value = null;
    try {
      final saved = rust_api.saveDeviceName(name: normalized);
      deviceNameStatusMessage.value = l10n.statusSavedDeviceName(saved);
      await refresh();
    } catch (error) {
      deviceNameStatusMessage.value = error.toString();
      lastErrorMessage.value = error.toString();
    } finally {
      deviceNameSaving.value = false;
    }
  }

  Future<void> choosePreferredDownloadDirectory() async {
    downloadDirectorySaving.value = true;
    downloadDirectoryStatusMessage.value = null;
    lastErrorMessage.value = null;
    try {
      var path = await getDirectoryPath(
        confirmButtonText: l10n.actionUseThisFolder,
      );
      if (path == null || path.trim().isEmpty) {
        return;
      }
      final saved = rust_api.savePreferredDownloadDir(path: path);
      preferredDownloadDir.value = saved;
      downloadDirectoryStatusMessage.value = l10n
          .statusDefaultDownloadFolderSet(saved);
    } catch (error) {
      downloadDirectoryStatusMessage.value = error.toString();
      lastErrorMessage.value = error.toString();
    } finally {
      downloadDirectorySaving.value = false;
    }
  }

  Future<void> clearPreferredDownloadDirectory() async {
    downloadDirectorySaving.value = true;
    downloadDirectoryStatusMessage.value = null;
    lastErrorMessage.value = null;
    try {
      rust_api.clearPreferredDownloadDir();
      preferredDownloadDir.value = null;
      downloadDirectoryStatusMessage.value =
          l10n.statusClearedSavedDownloadFolder;
    } catch (error) {
      downloadDirectoryStatusMessage.value = error.toString();
      lastErrorMessage.value = error.toString();
    } finally {
      downloadDirectorySaving.value = false;
    }
  }

  Future<void> setLocalePreference(String? code) async {
    localeStatusMessage.value = null;
    lastErrorMessage.value = null;
    try {
      if (code == null || code.isEmpty) {
        rust_api.clearPreferredLocale();
        localePreferenceCode.value = null;
        localeStatusMessage.value = l10n.statusLanguageFollowsSystem;
      } else {
        final saved = rust_api.savePreferredLocale(code: code);
        localePreferenceCode.value = saved;
        localeStatusMessage.value = l10n.statusLanguageSaved;
      }
    } catch (error) {
      localeStatusMessage.value = error.toString();
      lastErrorMessage.value = error.toString();
    }
  }

  void toggleAutoReceive(bool enabled) {
    try {
      rust_api.setAutoReceiveEnabled(enabled: enabled);
      autoReceiveEnabled.value = enabled;
    } catch (error) {
      lastErrorMessage.value = error.toString();
    }
  }

  void toggleNavigateAfterTransfer(bool enabled) {
    try {
      rust_api.setNavigateAfterTransfer(enabled: enabled);
      navigateAfterTransfer.value = enabled;
    } catch (error) {
      lastErrorMessage.value = error.toString();
    }
  }

  void setPollInterval(int seconds) {
    try {
      final saved = rust_api.setPollIntervalSeconds(seconds: seconds);
      pollIntervalSeconds.value = saved;
      // Restart mailbox timer with new interval
      _mailboxTimer?.cancel();
      _mailboxTimer = null;
      _checkPolling();
    } catch (error) {
      lastErrorMessage.value = error.toString();
    }
  }

  void toggleKeepScreenOnDuringTransfer(bool enabled) {
    try {
      rust_api.setKeepScreenOnDuringTransfer(enabled: enabled);
      keepScreenOnDuringTransfer.value = enabled;
      _checkPolling();
    } catch (error) {
      lastErrorMessage.value = error.toString();
    }
  }

  Future<void> createCloudPassword(String password) async {
    await rust_api.createCloudPassword(password: password);
    await refresh();
  }

  Future<void> verifyCloudPassword(String password) async {
    await rust_api.verifyCloudPassword(password: password);
    await refresh();
  }

  Future<void> changeCloudPassword(
    String oldPassword,
    String newPassword,
  ) async {
    await rust_api.changeCloudPassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
    await refresh();
  }

  Future<void> addPhotosToSendQueue() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isEmpty) return;
    _mergePendingSendItems(
      images
          .map(
            (image) => PendingSendItem(
              path: image.path,
              name: image.name,
              kind: PendingSendKind.file,
            ),
          )
          .toList(growable: false),
    );
  }

  void _applySnapshot(rust_api.ShellSnapshot snapshot) {
    protocolNames.value = snapshot.protocolNames;
    deviceSnapshot.value = snapshot.deviceSnapshot;
    currentAuthState.value = snapshot.authState;
    peerDevices.value = snapshot.peerDevices;
    transferJobs.value = snapshot.transferPreviews
        .map(_mapTransferPreview)
        .toList();
    inboxJobs.value = snapshot.inboxPreviews
        .map(
          (preview) => _mapInboxPreview(preview, previousJobs: inboxJobs.value),
        )
        .toList();

    if (autoReceiveEnabled.value) {
      for (final job in inboxJobs.value) {
        if (job.isReady && job.status != MailboxJobStatus.autoReceiving) {
          // Fire and forget
          _autoReceiveJob(job);
        }
      }
    }

    final currentId = selectedTransferId.value;
    if (currentId != null &&
        !transferJobs.value.any((job) => job.id == currentId)) {
      selectedTransferId.value = null;
    }
    selectedTransferId.value ??= transferJobs.value.isEmpty
        ? null
        : transferJobs.value.first.id;
    final currentPeerId = selectedPeerDeviceId.value;
    if (currentPeerId != null &&
        !peerDevices.value.any((peer) => peer.deviceId == currentPeerId)) {
      selectedPeerDeviceId.value = null;
    }
    selectedPeerDeviceId.value ??= peerDevices.value.isEmpty
        ? null
        : peerDevices.value.first.deviceId;

    final phase = switch (snapshot.authState) {
      rust_api.AuthState.loginRequired => BootstrapPhase.loginRequired,
      rust_api.AuthState.needCreatePassword => BootstrapPhase.passwordRequired,
      rust_api.AuthState.needVerifyPassword => BootstrapPhase.passwordRequired,
      rust_api.AuthState.ready => BootstrapPhase.ready,
    };

    if (phase == BootstrapPhase.ready) {
      if (_justLoggedIn && peerDevices.value.isNotEmpty) {
        bootstrapPhase.value = BootstrapPhase.cloudDeviceSelection;
      } else if (bootstrapPhase.value != BootstrapPhase.cloudDeviceSelection) {
        bootstrapPhase.value = BootstrapPhase.ready;
      }
    } else {
      bootstrapPhase.value = phase;
    }
    _justLoggedIn = false;
    selectedMailboxJobIds.value = selectedMailboxJobIds.value
        .where((jobId) => inboxJobs.value.any((job) => job.id == jobId))
        .toSet();

    _checkPolling();
  }

  void selectPeerDevice(String deviceId) {
    selectedPeerDeviceId.value = deviceId;
    destination.value = AppDestination.send;
  }

  Future<void> addFilesToSendQueue() async {
    final files = await openFiles(
      acceptedTypeGroups: const [XTypeGroup(label: 'Any file')],
      confirmButtonText: l10n.actionAdd,
    );
    if (files.isEmpty) {
      return;
    }
    _mergePendingSendItems(
      files
          .map(
            (file) => PendingSendItem(
              path: file.path,
              name: file.name,
              kind: PendingSendKind.file,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<void> addDirectoryToSendQueue() async {
    var path = await getDirectoryPath(confirmButtonText: l10n.actionAddFolder);
    if (path == null || path.trim().isEmpty) {
      return;
    }
    final name = path
        .split(Platform.pathSeparator)
        .where((e) => e.isNotEmpty)
        .last;
    _mergePendingSendItems([
      PendingSendItem(path: path, name: name, kind: PendingSendKind.directory),
    ]);
  }

  void removePendingSendItem(String path) {
    pendingSendItems.value = pendingSendItems.value
        .where((item) => item.path != path)
        .toList(growable: false);
  }

  void clearPendingSendItems() {
    pendingSendItems.value = const [];
  }

  Future<void> sendPendingSelection() async {
    final peer = selectedPeerDevice.value;
    if (peer == null) {
      sendStatusMessage.value = l10n.errorChooseTargetDevice;
      destination.value = AppDestination.send;
      return;
    }
    if (pendingSendItems.value.isEmpty) {
      sendStatusMessage.value = l10n.errorAddItemsBeforeTransfer;
      destination.value = AppDestination.send;
      return;
    }

    sendInProgress.value = true;
    sendStatusMessage.value = l10n.statusSendingItems(
      pendingSendItems.value.length,
      peer.label,
    );

    if (navigateAfterTransfer.value) {
      destination.value = AppDestination.transfers;
    }
    _checkPolling();

    try {
      final items = pendingSendItems.value;
      final jobIds = <String>[];
      for (final item in items) {
        lastSentPath.value = item.path;
        sendStatusMessage.value = l10n.statusSendingItem(item.name, peer.label);
        final jobId = await rust_api.sendLocalPath(
          peerMailboxFolderId: peer.mailboxFolderId,
          peerDeviceId: peer.deviceId,
          peerLabel: peer.label,
          sourcePath: item.path,
        );
        jobIds.add(jobId);
      }
      pendingSendItems.value = const [];
      sendStatusMessage.value = l10n.statusQueuedTransferJobs(
        jobIds.length,
        peer.label,
      );
      await refresh();
      _focusTransferJobIds(jobIds);
    } catch (error) {
      sendStatusMessage.value = error.toString();
      lastErrorMessage.value = error.toString();
    } finally {
      sendInProgress.value = false;
      _checkPolling();
    }
  }

  Future<void> pickOutputAndReceive(InboxJob job) async {
    selectedMailboxJobIds.value = {job.id};
    await receiveSelectedMailboxJobs();
  }

  void toggleMailboxJobSelection(String jobId, bool selected) {
    final next = selectedMailboxJobIds.value.toSet();
    if (selected) {
      next.add(jobId);
    } else {
      next.remove(jobId);
    }
    selectedMailboxJobIds.value = next;
  }

  void clearMailboxSelection() {
    selectedMailboxJobIds.value = <String>{};
  }

  Future<void> receiveSelectedMailboxJobs() async {
    final selectedIds = selectedMailboxJobIds.value;
    if (selectedIds.isEmpty) {
      mailboxStatusMessage.value = l10n.errorSelectRelayJobsFirst;
      destination.value = AppDestination.inbox;
      return;
    }
    final jobs = inboxJobs.value
        .where((job) => selectedIds.contains(job.id) && job.isReady)
        .toList(growable: false);
    if (jobs.isEmpty) {
      mailboxStatusMessage.value = l10n.errorNoReadyRelayJobsSelected;
      return;
    }

    final outputDir = await _resolveReceiveOutputDirectory();
    if (outputDir == null) {
      return;
    }

    receiveInProgress.value = true;
    receiveStatusMessage.value = l10n.statusReceivingSelectedJobs(
      jobs.length,
      outputDir,
    );
    mailboxStatusMessage.value = l10n.statusReceivingSelectedRelayJobs(
      jobs.length,
    );
    lastReceivePath.value = outputDir;
    if (navigateAfterTransfer.value) {
      destination.value = AppDestination.transfers;
    }
    _checkPolling();

    try {
      final jobIds = <String>[];
      for (final job in jobs) {
        _setMailboxJobStatus(
          job.id,
          MailboxJobStatus.autoReceiving,
          statusMessage: l10n.statusSavingInto(outputDir),
        );
        final jobId = await rust_api.receiveJob(
          jobFolderId: job.id,
          outputDir: outputDir,
        );
        jobIds.add(jobId);
      }
      receiveStatusMessage.value = l10n.statusReceivedRelayJobs(
        jobIds.length,
        outputDir,
      );
      mailboxStatusMessage.value = l10n.statusReceivedAndCleanedRelayJobs(
        jobIds.length,
      );
      selectedMailboxJobIds.value = <String>{};
      await refresh();
      _focusTransferJobIds(jobIds);
    } catch (error) {
      receiveStatusMessage.value = error.toString();
      lastErrorMessage.value = error.toString();
      mailboxStatusMessage.value = l10n.errorFailedReceivingSelectedRelayJobs;
      for (final job in jobs) {
        _setMailboxJobStatus(
          job.id,
          MailboxJobStatus.failed,
          statusMessage: error.toString(),
        );
      }
    } finally {
      receiveInProgress.value = false;
      _checkPolling();
    }
  }

  Future<String?> _resolveReceiveOutputDirectory() async {
    if (preferredDownloadDir.value?.isNotEmpty ?? false) {
      return preferredDownloadDir.value;
    }
    if (!platformPaths.requiresDownloadPicker &&
        (platformPaths.downloadDir?.isNotEmpty ?? false)) {
      return platformPaths.downloadDir;
    }
    var path = await getDirectoryPath(
      confirmButtonText: l10n.actionDownloadHere,
    );
    if (path != null && Platform.isMacOS && !path.startsWith('/')) {
      path = '/$path';
    }
    return path;
  }

  Future<void> resumeTransfer(TransferJob job) async {
    if (job.stage != TransferStage.failed) {
      return;
    }
    resumeInProgress.value = true;
    resumeStatusMessage.value = l10n.statusResumingTransfer(job.title);
    destination.value = AppDestination.transfers;
    try {
      final jobId = await rust_api.resumeTask(jobId: job.id);
      resumeStatusMessage.value = l10n.statusResumedTransfer(job.title, jobId);
      await refresh();
      _focusTransferJobIds([jobId]);
      destination.value = AppDestination.transfers;
    } catch (error) {
      resumeStatusMessage.value = error.toString();
      lastErrorMessage.value = error.toString();
    } finally {
      resumeInProgress.value = false;
    }
  }

  Future<void> clearCompletedTransfers() async {
    transferActionInProgress.value = true;
    transferActionStatusMessage.value = null;
    try {
      final removed = rust_api.clearCompletedTransfers();
      transferActionStatusMessage.value = l10n.statusClearedCompletedTransfers(
        removed,
      );
      await refresh();
    } catch (error) {
      transferActionStatusMessage.value = error.toString();
      lastErrorMessage.value = error.toString();
    } finally {
      transferActionInProgress.value = false;
    }
  }

  Future<void> deleteTransfer(TransferJob job) async {
    transferActionInProgress.value = true;
    transferActionStatusMessage.value = l10n.statusDeletingRemoteTransferJob(
      job.title,
    );
    try {
      await rust_api.deleteTransfer(jobId: job.id);
      transferActionStatusMessage.value = l10n.statusDeletedRemoteTransferJob(
        job.title,
      );
      if (selectedTransferId.value == job.id) {
        selectedTransferId.value = null;
      }
      await refresh();
    } catch (error) {
      transferActionStatusMessage.value = error.toString();
      lastErrorMessage.value = error.toString();
    } finally {
      transferActionInProgress.value = false;
    }
  }

  TransferJob _mapTransferPreview(rust_api.TransferPreview preview) {
    return TransferJob(
      id: preview.id,
      title: preview.title,
      subtitle: preview.subtitle,
      progress: preview.progress.clamp(0, 1),
      stage: switch (preview.stage) {
        rust_api.TransferStage.preparing => TransferStage.preparing,
        rust_api.TransferStage.uploadingBlobs => TransferStage.uploading,
        rust_api.TransferStage.uploadingManifest =>
          TransferStage.uploadingManifest,
        rust_api.TransferStage.uploadingCommit => TransferStage.uploadingCommit,
        rust_api.TransferStage.downloadingBlobs => TransferStage.downloading,
        rust_api.TransferStage.verifying => TransferStage.verifying,
        rust_api.TransferStage.cleanupRemote => TransferStage.cleaningRemote,
        rust_api.TransferStage.failed => TransferStage.failed,
        rust_api.TransferStage.done => TransferStage.completed,
      },
      direction: switch (preview.direction) {
        rust_api.TransferDirection.send => TransferDirection.send,
        rust_api.TransferDirection.receive => TransferDirection.receive,
      },
    );
  }

  InboxJob _mapInboxPreview(
    rust_api.InboxPreview preview, {
    required List<InboxJob> previousJobs,
  }) {
    InboxJob? previous;
    for (final job in previousJobs) {
      if (job.id == preview.id) {
        previous = job;
        break;
      }
    }
    return InboxJob(
      id: preview.id,
      sender: preview.sender,
      rootName: preview.rootName,
      summary: preview.summary,
      sizeLabel: preview.sizeLabel,
      receivedAtLabel: preview.receivedAtLabel,
      isReady: preview.isReady,
      status: previous?.status ?? MailboxJobStatus.queued,
      statusMessage: previous?.statusMessage,
    );
  }

  final _activeAutoReceives = <String>{};

  void _autoReceiveJob(InboxJob job) async {
    if (_activeAutoReceives.contains(job.id)) {
      return;
    }

    final outputDir = preferredDownloadDir.value ?? platformPaths.downloadDir;
    if (outputDir == null) {
      return;
    }

    _activeAutoReceives.add(job.id);
    _setMailboxJobStatus(
      job.id,
      MailboxJobStatus.autoReceiving,
      statusMessage: l10n.statusAutoReceiveSavingJob,
    );
    mailboxStatusMessage.value = l10n.statusAutoReceiving(
      job.rootName,
      job.sender,
    );

    try {
      final jobId = await rust_api.receiveJob(
        jobFolderId: job.id,
        outputDir: outputDir,
      );
      mailboxStatusMessage.value = l10n.statusAutoReceived(job.rootName);
      await refresh();
      _focusTransferJobIds([jobId]);
    } catch (e) {
      lastErrorMessage.value = l10n.errorAutoReceiveFailed(job.rootName, '$e');
      mailboxStatusMessage.value = l10n.errorAutoReceiveFailedShort(
        job.rootName,
      );
      _setMailboxJobStatus(
        job.id,
        MailboxJobStatus.failed,
        statusMessage: e.toString(),
      );
    } finally {
      _activeAutoReceives.remove(job.id);
    }
  }

  void _setMailboxJobStatus(
    String jobId,
    MailboxJobStatus status, {
    String? statusMessage,
  }) {
    inboxJobs.value = inboxJobs.value
        .map(
          (job) => job.id == jobId
              ? job.copyWith(status: status, statusMessage: statusMessage)
              : job,
        )
        .toList(growable: false);
  }

  void _mergePendingSendItems(List<PendingSendItem> additions) {
    final merged = <PendingSendItem>[...pendingSendItems.value];
    for (final item in additions) {
      if (!merged.any((existing) => existing.path == item.path)) {
        merged.add(item);
      }
    }
    pendingSendItems.value = merged;
  }

  void _focusTransferJobIds(Iterable<String> jobIds) {
    final ids = jobIds.toSet();
    for (final job in transferJobs.value) {
      if (ids.contains(job.id)) {
        selectedTransferId.value = job.id;
        if (navigateAfterTransfer.value) {
          destination.value = AppDestination.transfers;
        }
        return;
      }
    }
  }

  Future<void> _loadShell() async {
    bootstrapPhase.value = BootstrapPhase.booting;
    lastErrorMessage.value = null;
    quarkLoginUrl.value = rust_api.quarkLoginUrl();

    try {
      rememberedDevices.value = rust_api.rememberedDevices();
      final preferredLocale = rust_api.preferredLocale().trim();
      localePreferenceCode.value = preferredLocale.isEmpty
          ? null
          : preferredLocale;
      final preferredDir = rust_api.preferredDownloadDir().trim();
      preferredDownloadDir.value = preferredDir.isEmpty ? null : preferredDir;
      try {
        autoReceiveEnabled.value = rust_api.autoReceiveEnabled();
      } catch (_) {}
      try {
        navigateAfterTransfer.value = rust_api.navigateAfterTransfer();
      } catch (_) {}
      try {
        pollIntervalSeconds.value = rust_api.pollIntervalSeconds();
      } catch (_) {}
      try {
        keepScreenOnDuringTransfer.value = rust_api
            .keepScreenOnDuringTransfer();
      } catch (_) {}
      final snapshot = await rust_api.shellSnapshot();
      _applySnapshot(snapshot);
    } catch (error) {
      transferJobs.value = const [];
      inboxJobs.value = const [];
      deviceSnapshot.value = null;
      peerDevices.value = const [];
      selectedPeerDeviceId.value = null;
      selectedTransferId.value = null;
      preferredDownloadDir.value = null;
      bootstrapPhase.value = BootstrapPhase.loginRequired;
      lastErrorMessage.value = error.toString();
    }
  }
}

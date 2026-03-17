part of 'app_store.dart';

extension AppStoreBootstrap on AppStore {
  Future<void> bootstrap() async {
    await _loadShell();
  }

  Future<void>? _refreshFuture;

  Future<void> refresh() {
    if (_refreshFuture != null) {
      _refreshQueued = true;
      return _refreshFuture!;
    }

    _refreshFuture = () async {
      do {
        _refreshQueued = false;
        try {
          final snapshot = await rust_api.shellSnapshot();
          _applySnapshot(snapshot);
        } catch (error) {
          lastErrorMessage.value = error.toString();
        }
      } while (_refreshQueued);
      _refreshFuture = null;
    }();

    return _refreshFuture!;
  }

  void _checkPolling() {
    final active =
        transferJobs.value.any(
          (job) =>
              job.stage != TransferStage.completed &&
              job.stage != TransferStage.failed,
        ) ||
        sendInProgress.value ||
        receiveInProgress.value ||
        _backgroundTransferOperations > 0;

    final shouldPollCurrentTransfers = active && _isAppVisible;

    if (shouldPollCurrentTransfers && _pollingTimer == null) {
      _pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        unawaited(refresh());
      });
    } else if (!shouldPollCurrentTransfers && _pollingTimer != null) {
      _pollingTimer?.cancel();
      _pollingTimer = null;
    }

    ScreenWakelock.setKeepScreenOn(active && keepScreenOnDuringTransfer.value);

    final shouldPollMailbox = bootstrapPhase.value == BootstrapPhase.ready && _isAppVisible;

    if (shouldPollMailbox && _mailboxTimer == null) {
      final interval = pollIntervalSeconds.value.clamp(5, 300);
      _mailboxTimer = Timer.periodic(Duration(seconds: interval), (_) {
        unawaited(refresh());
      });
    } else if (!shouldPollMailbox && _mailboxTimer != null) {
      _mailboxTimer?.cancel();
      _mailboxTimer = null;
    }
  }

  void _beginBackgroundTransferOperation() {
    _backgroundTransferOperations += 1;
    _checkPolling();
  }

  void _endBackgroundTransferOperation() {
    if (_backgroundTransferOperations > 0) {
      _backgroundTransferOperations -= 1;
    }
    _checkPolling();
  }

  void _applySnapshot(rust_api.ShellSnapshot snapshot) {
    protocolNames.value = snapshot.protocolNames;
    deviceSnapshot.value = snapshot.deviceSnapshot;
    currentAuthState.value = snapshot.authState;
    peerDevices.value = snapshot.peerDevices;
    transferJobs.value = snapshot.transferPreviews
        .map(_mapTransferPreview)
        .toList(growable: false);
    inboxJobs.value = snapshot.inboxPreviews
        .map(
          (preview) => _mapInboxPreview(preview, previousJobs: inboxJobs.value),
        )
        .toList(growable: false);

    if (autoReceiveEnabled.value) {
      for (final job in inboxJobs.value) {
        if (job.isReady && job.status != MailboxJobStatus.autoReceiving) {
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

    final nextPhase = switch (snapshot.authState) {
      rust_api.AuthState.loginRequired => BootstrapPhase.loginRequired,
      rust_api.AuthState.needCreatePassword => BootstrapPhase.passwordRequired,
      rust_api.AuthState.needVerifyPassword => BootstrapPhase.passwordRequired,
      rust_api.AuthState.ready => BootstrapPhase.ready,
    };

    if (nextPhase == BootstrapPhase.ready) {
      _authDowngradeStreak = 0;
      if (_justLoggedIn && peerDevices.value.isNotEmpty) {
        bootstrapPhase.value = BootstrapPhase.cloudDeviceSelection;
      } else if (bootstrapPhase.value != BootstrapPhase.cloudDeviceSelection) {
        bootstrapPhase.value = BootstrapPhase.ready;
      }
    } else {
      final isReadyLike =
          bootstrapPhase.value == BootstrapPhase.ready ||
          bootstrapPhase.value == BootstrapPhase.cloudDeviceSelection;
      if (isReadyLike) {
        _authDowngradeStreak += 1;
        if (_authDowngradeStreak >= 2) {
          bootstrapPhase.value = nextPhase;
        }
      } else {
        bootstrapPhase.value = nextPhase;
      }
    }

    _justLoggedIn = false;
    selectedMailboxJobIds.value = selectedMailboxJobIds.value
        .where((jobId) => inboxJobs.value.any((job) => job.id == jobId))
        .toSet();

    _checkPolling();
  }

  Future<void> _loadShell() async {
    bootstrapPhase.value = BootstrapPhase.booting;
    lastErrorMessage.value = null;
    quarkLoginUrl.value = rust_api.quarkLoginUrl();
    _authDowngradeStreak = 0;

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
        maxConcurrentUploads.value = rust_api.maxConcurrentUploads();
      } catch (_) {}
      try {
        maxConcurrentDownloads.value = rust_api.maxConcurrentDownloads();
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

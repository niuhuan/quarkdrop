part of 'app_store.dart';

extension AppStoreSendReceive on AppStore {
  void selectDestination(AppDestination next) {
    destination.value = next;
  }

  void selectTransfer(String transferId) {
    selectedTransferId.value = transferId;
    destination.value = AppDestination.transfers;
  }

  void selectPeerDevice(String deviceId) {
    selectedPeerDeviceId.value = deviceId;
    destination.value = AppDestination.send;
  }

  Future<void> addPhotosToSendQueue() async {
    try {
      final picker = ImagePicker();
      List<XFile> images;
      try {
        images = await picker.pickMultiImage();
      } catch (e) {
        // Fallback for some iOS versions where full metadata causes an error without permissions
        images = await picker.pickMultiImage(requestFullMetadata: false);
      }
      if (images.isEmpty) {
        return;
      }
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
    } catch (e) {
      lastErrorMessage.value = e.toString();
    }
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

    final items = pendingSendItems.value;
    if (items.isEmpty) {
      sendStatusMessage.value = l10n.errorAddItemsBeforeTransfer;
      destination.value = AppDestination.send;
      return;
    }

    sendInProgress.value = true;
    sendStatusMessage.value = l10n.statusSendingItems(items.length, peer.label);
    if (navigateAfterTransfer.value) {
      destination.value = AppDestination.transfers;
    }
    pendingSendItems.value = const [];
    _checkPolling();

    for (final item in items) {
      lastSentPath.value = item.path;
      _queueSendItem(item, peer);
    }

    sendStatusMessage.value = l10n.statusQueuedTransferJobs(
      items.length,
      peer.label,
    );
    sendInProgress.value = false;
    _checkPolling();
    await refresh();
  }

  void _queueSendItem(PendingSendItem item, rust_api.PeerDevice peer) {
    _beginBackgroundTransferOperation();
    unawaited(() async {
      try {
        final jobId = await rust_api.sendLocalPath(
          peerMailboxFolderId: peer.mailboxFolderId,
          peerDeviceId: peer.deviceId,
          peerLabel: peer.label,
          sourcePath: item.path,
        );
        await refresh();
        _focusTransferJobIds([jobId]);
      } catch (error) {
        sendStatusMessage.value = error.toString();
        lastErrorMessage.value = error.toString();
      } finally {
        _endBackgroundTransferOperation();
      }
    }());
  }

  Future<void> pickOutputAndReceive(InboxJob job) async {
    selectedMailboxJobIds.value = {job.id};
    await receiveSelectedMailboxJobs();
  }

  Future<void> rejectInboxJob(String jobId) async {
    try {
      await rust_api.rejectInboxJob(jobFolderId: jobId);
      inboxJobs.value = inboxJobs.value
          .where((j) => j.id != jobId)
          .toList(growable: false);
      selectedMailboxJobIds.value = selectedMailboxJobIds.value
          .where((id) => id != jobId)
          .toSet();
    } catch (error) {
      lastErrorMessage.value = error.toString();
    }
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
        .where(
          (job) =>
              selectedIds.contains(job.id) &&
              job.isReady &&
              job.status != MailboxJobStatus.autoReceiving,
        )
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
    selectedMailboxJobIds.value = <String>{};
    _checkPolling();

    for (final job in jobs) {
      _setMailboxJobStatus(
        job.id,
        MailboxJobStatus.autoReceiving,
        statusMessage: l10n.statusSavingInto(outputDir),
      );
      _queueReceiveJob(job, outputDir);
    }

    receiveStatusMessage.value = l10n.statusReceivedRelayJobs(
      jobs.length,
      outputDir,
    );
    mailboxStatusMessage.value = l10n.statusReceivedAndCleanedRelayJobs(
      jobs.length,
    );
    receiveInProgress.value = false;
    _checkPolling();
    await refresh();
  }

  void _queueReceiveJob(InboxJob job, String outputDir) {
    _beginBackgroundTransferOperation();
    unawaited(() async {
      try {
        final jobId = await rust_api.receiveJob(
          jobFolderId: job.id,
          outputDir: outputDir,
        );
        await refresh();
        _focusTransferJobIds([jobId]);
      } catch (error) {
        receiveStatusMessage.value = error.toString();
        mailboxStatusMessage.value = l10n.errorFailedReceivingSelectedRelayJobs;
        lastErrorMessage.value = error.toString();
        _setMailboxJobStatus(
          job.id,
          MailboxJobStatus.failed,
          statusMessage: error.toString(),
        );
      } finally {
        _endBackgroundTransferOperation();
      }
    }());
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

  void _autoReceiveJob(InboxJob job) {
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
    _beginBackgroundTransferOperation();

    unawaited(() async {
      try {
        final jobId = await rust_api.receiveJob(
          jobFolderId: job.id,
          outputDir: outputDir,
        );
        mailboxStatusMessage.value = l10n.statusAutoReceived(job.rootName);
        await refresh();
        _focusTransferJobIds([jobId]);
      } catch (error) {
        lastErrorMessage.value = l10n.errorAutoReceiveFailed(
          job.rootName,
          '$error',
        );
        mailboxStatusMessage.value = l10n.errorAutoReceiveFailedShort(
          job.rootName,
        );
        _setMailboxJobStatus(
          job.id,
          MailboxJobStatus.failed,
          statusMessage: error.toString(),
        );
      } finally {
        _activeAutoReceives.remove(job.id);
        _endBackgroundTransferOperation();
      }
    }());
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
}

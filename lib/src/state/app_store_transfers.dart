part of 'app_store.dart';

extension AppStoreTransfers on AppStore {
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
      counterpartLabel: preview.counterpartLabel,
      sizeLabel: preview.sizeLabel,
      transferredSizeLabel: preview.transferredSizeLabel,
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
}

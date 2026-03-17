// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'QuarkDrop';

  @override
  String get setupDeviceTitle => 'Set Up Your Device';

  @override
  String get setupDeviceSubtitle => 'Name this device and choose how to join.';

  @override
  String get deviceNameTitle => 'Device Name';

  @override
  String get deviceNameSubtitle =>
      'This name will be visible to other devices.';

  @override
  String get deviceNameFieldLabel => 'Device name';

  @override
  String get existingDevicesTitle => 'Existing Devices';

  @override
  String get existingDevicesSubtitle =>
      'We found device folders in your cloud. Bind to an existing one or continue as new.';

  @override
  String get actionBind => 'Bind';

  @override
  String get actionContinueAsNewDevice => 'Continue as New Device';

  @override
  String get errorPasswordEmpty => 'Password cannot be empty.';

  @override
  String get errorPasswordsDoNotMatch => 'Passwords do not match.';

  @override
  String get setCloudPasswordTitle => 'Set Cloud Password';

  @override
  String get verifyCloudPasswordTitle => 'Verify Cloud Password';

  @override
  String get setCloudPasswordSubtitle =>
      'Set a cloud password to encrypt your device keys.';

  @override
  String get verifyCloudPasswordSubtitle =>
      'Enter your cloud password to unlock this device.';

  @override
  String get newPasswordLabel => 'New Password';

  @override
  String get cloudPasswordLabel => 'Cloud Password';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get rememberPasswordOnDevice => 'Remember password on this device';

  @override
  String get actionSetPassword => 'Set Password';

  @override
  String get actionVerify => 'Verify';

  @override
  String get preparingQuarkDropTitle => 'Preparing QuarkDrop';

  @override
  String get preparingQuarkDropSubtitle =>
      'Bootstrapping the encrypted relay workspace.';

  @override
  String get loginSubtitle => 'Sign in with your Quark account to continue.';

  @override
  String get actionUseBrowserLogin => 'Use Browser Login';

  @override
  String get actionUseCookieLogin => 'Use Cookie Login';

  @override
  String get quarkCookieLabel => 'Quark Cookie';

  @override
  String get actionPaste => 'Paste';

  @override
  String get actionValidating => 'Validating...';

  @override
  String get actionSignIn => 'Sign In';

  @override
  String get webLoginInitialStatus =>
      'Sign in to Quark, then tap Complete Login to import the cookies.';

  @override
  String get webLoginFreshSessionReady =>
      'Fresh login session ready. Sign in to Quark, then tap Complete Login.';

  @override
  String webLoginResetFailed(Object error) {
    return 'Failed to reset the embedded browser session: $error';
  }

  @override
  String get webLoginImportingCookies =>
      'Importing Quark cookies from the embedded browser...';

  @override
  String get webLoginNoValidatedSession =>
      'No validated Quark session yet. Finish the login flow, then tap Complete Login again.';

  @override
  String webLoginCookieCaptureFailed(Object error) {
    return 'Cookie capture failed: $error';
  }

  @override
  String get embeddedQuarkLoginTitle => 'Embedded Quark Login';

  @override
  String get actionCompleteLogin => 'Complete Login';

  @override
  String get webLoginPageLoaded =>
      'Page loaded. Finish the Quark login flow, then tap Complete Login.';

  @override
  String webLoginLoadFailed(Object error) {
    return 'Web login failed to load: $error';
  }

  @override
  String get navSend => 'Send';

  @override
  String get navMailbox => 'Mailbox';

  @override
  String get navTransfers => 'Transfers';

  @override
  String get navSettings => 'Settings';

  @override
  String get noPeerDevicesTitle => 'No peer devices yet';

  @override
  String get noPeerDevicesBody =>
      'No other device is available yet. Open QuarkDrop on another device and sign in first.';

  @override
  String get sendTargetLabel => 'Send Target';

  @override
  String get actionSelect => 'Select';

  @override
  String get noTransfersTitle => 'No transfers';

  @override
  String get noTransfersBody => 'Jobs matching this filter will appear here.';

  @override
  String get noTransferHistoryTitle => 'No transfer history yet';

  @override
  String get noTransferHistoryBody =>
      'Send a file or receive a mailbox job to build the transfer queue.';

  @override
  String get transfersTitle => 'Transfers';

  @override
  String get transfersSubtitle => 'Upload and download history.';

  @override
  String get actionClearCompleted => 'Clear Completed';

  @override
  String tabPending(Object count) {
    return 'Pending ($count)';
  }

  @override
  String tabSendQueuePending(Object count) {
    return 'Send ($count)';
  }

  @override
  String tabReceiveQueueCompleted(Object count) {
    return 'Received ($count)';
  }

  @override
  String tabCompleted(Object count) {
    return 'Done ($count)';
  }

  @override
  String get selectTransferTitle => 'Select a transfer';

  @override
  String get selectTransferBody =>
      'Choose a row from the queue to inspect its state and available actions.';

  @override
  String get selectedTransferTitle => 'Selected Transfer';

  @override
  String get selectedTransferSubtitle =>
      'Current status, direction, and recovery actions.';

  @override
  String get sendJobLabel => 'Send job';

  @override
  String get receiveJobLabel => 'Receive job';

  @override
  String get actionResumeTransfer => 'Resume Transfer';

  @override
  String get actionDeleteRemoteJob => 'Delete Remote Job';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'Device, storage, and sign-out.';

  @override
  String get downloadFolderChooseBeforeReceiving =>
      'Choose a folder before receiving';

  @override
  String get latestErrorTitle => 'Latest Error';

  @override
  String get directionSend => 'Send';

  @override
  String get directionReceive => 'Receive';

  @override
  String accountLabel(Object authSource) {
    return 'Account: $authSource';
  }

  @override
  String get errorNewPasswordEmpty => 'New password cannot be empty.';

  @override
  String get cloudPasswordCardTitle => 'Cloud Password';

  @override
  String get cloudPasswordCardSubtitle =>
      'Change your cloud password. All device keys will be re-encrypted.';

  @override
  String get currentPasswordLabel => 'Current Password';

  @override
  String get confirmNewPasswordLabel => 'Confirm New Password';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionChangePassword => 'Change Password';

  @override
  String get cloudPasswordUpdated => 'Cloud password updated.';

  @override
  String get rememberPasswordTitle => 'Remember Password';

  @override
  String get rememberPasswordEnabled =>
      'The device key is saved. Auto-unlock is enabled.';

  @override
  String get rememberPasswordDisabled =>
      'Save the device key so password is not required on next launch.';

  @override
  String get savedPasswordEnabled =>
      'Password saved. The app will auto-unlock on next launch.';

  @override
  String get savedPasswordCleared => 'Saved password cleared.';

  @override
  String genericFailed(Object error) {
    return 'Failed: $error';
  }

  @override
  String get launchAtStartupTitle => 'Launch at Startup';

  @override
  String get launchAtStartupUnavailable =>
      'This platform integration is not wired up yet for the current build.';

  @override
  String get launchAtStartupEnabled =>
      'The app will start automatically when you log in.';

  @override
  String get launchAtStartupDisabled =>
      'Enable to start the app automatically at system boot.';

  @override
  String get openDataFolderTitle => 'Open Data Folder';

  @override
  String get openDataFolderSubtitle =>
      'Open the app configuration directory in the file manager. (Debug only)';

  @override
  String failedOpenDataFolder(Object error) {
    return 'Failed to open data folder: $error';
  }

  @override
  String get backgroundTitle => 'Background';

  @override
  String get backgroundBatteryDisabled =>
      'Battery optimization is disabled. The app can run in the background.';

  @override
  String get backgroundBatteryEnabled =>
      'Disable battery optimization to prevent background transfers from being interrupted.';

  @override
  String get actionDisableBatteryOptimization => 'Disable Battery Optimization';

  @override
  String get actionOpenAppSettings => 'Open App Settings';

  @override
  String get signOutTitle => 'Sign Out';

  @override
  String get signOutSubtitle => 'Remove mailbox and clear saved session.';

  @override
  String get signOutConfirmBody => 'All local transfer tasks will be removed.';

  @override
  String get signOutDeleteCloudFolder =>
      'Delete cloud folder and local task list';

  @override
  String get signOutDeleteCloudHint =>
      'Other devices will no longer be able to send files to the current device.';

  @override
  String get signOutKeepCloudHint =>
      'Files will not be received for this account until you re-login and bind.';

  @override
  String get downloadFolderTitle => 'Download Folder';

  @override
  String get actionChooseFolder => 'Choose Folder';

  @override
  String get actionUseDefault => 'Use Default';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageFollowingSystem => 'Following system language.';

  @override
  String get languageFollowSystemOption => 'Follow System';

  @override
  String get languageEnglishUsOption => 'English';

  @override
  String get languageSimplifiedChineseOption => '简体中文';

  @override
  String get languageTraditionalChineseOption => '繁體中文';

  @override
  String get languageJapaneseOption => '日本語';

  @override
  String get languageKoreanOption => '한국어';

  @override
  String get stagePreparing => 'Preparing';

  @override
  String get stageUploading => 'Uploading';

  @override
  String get stageManifest => 'Manifest';

  @override
  String get stageCommit => 'Commit';

  @override
  String get stageDownloading => 'Downloading';

  @override
  String get stageVerifying => 'Verifying';

  @override
  String get stageCleanup => 'Cleanup';

  @override
  String get stageFailed => 'Failed';

  @override
  String get stageDone => 'Done';

  @override
  String get transferFailedWaitingRecovery =>
      'Transfer failed and is waiting for recovery.';

  @override
  String get transferCompletedSuccessfully =>
      'Transfer completed successfully.';

  @override
  String transferPercentComplete(Object percent) {
    return '$percent% complete';
  }

  @override
  String get transferNeedsAttention => 'Needs attention';

  @override
  String get transferCompleted => 'Completed';

  @override
  String get transferActive => 'Active';

  @override
  String get mailboxPollIntervalTitle => 'Mailbox Poll Interval';

  @override
  String mailboxPollIntervalSubtitle(Object seconds) {
    return '${seconds}s - how often to check for new files.';
  }

  @override
  String secondsShort(Object seconds) {
    return '${seconds}s';
  }

  @override
  String get autoReceiveFilesTitle => 'Auto-Receive Files';

  @override
  String get autoReceiveFilesSubtitle =>
      'Automatically download incoming files to your default download directory.';

  @override
  String get autoNavigateTransfersTitle => 'Auto-Navigate to Transfers';

  @override
  String get autoNavigateTransfersSubtitle =>
      'After sending or receiving, automatically switch to the Transfers page.';

  @override
  String get keepScreenOnTitle => 'Keep Screen On During Transfer';

  @override
  String get keepScreenOnSubtitle =>
      'Prevent the screen from turning off while files are being sent or received.';

  @override
  String mailboxSelectedCount(Object count) {
    return '$count selected';
  }

  @override
  String mailboxItemsCount(Object count) {
    return '$count items in mailbox';
  }

  @override
  String get actionReceive => 'Receive';

  @override
  String actionReceiveCount(Object count) {
    return 'Receive $count';
  }

  @override
  String get mailboxEmptyTitle => 'No relay jobs in the mailbox';

  @override
  String get mailboxEmptyBody =>
      'Incoming encrypted jobs will appear here after another device sends them.';

  @override
  String mailboxFromSender(Object sender, Object sizeLabel) {
    return 'From $sender - $sizeLabel';
  }

  @override
  String get sendComposerChooseDevice =>
      'Choose a device below, then build your send batch.';

  @override
  String sendComposerReadyToSend(Object target) {
    return 'Ready to send to $target.';
  }

  @override
  String get actionAddFiles => 'Add Files';

  @override
  String get actionAddFolder => 'Add Folder';

  @override
  String get actionAddPhotos => 'Add Photos';

  @override
  String get actionClearBatch => 'Clear Batch';

  @override
  String get actionSendBatch => 'Send Batch';

  @override
  String actionSendItemCount(Object count) {
    return 'Send $count Item(s)';
  }

  @override
  String get sendComposerEmpty => 'No files or folders added yet.';

  @override
  String get actionUseThisFolder => 'Use This Folder';

  @override
  String get actionShowWindow => 'Show Window';

  @override
  String get actionQuit => 'Quit';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionDownloadHere => 'Download Here';

  @override
  String get errorPasteQuarkCookie =>
      'Please paste a Quark cookie before continuing.';

  @override
  String get errorDeviceNameEmpty => 'Device name cannot be empty.';

  @override
  String statusSavedDeviceName(Object name) {
    return 'Saved device name as `$name`.';
  }

  @override
  String statusDefaultDownloadFolderSet(Object path) {
    return 'Default download folder set to `$path`.';
  }

  @override
  String get statusClearedSavedDownloadFolder =>
      'Cleared the saved download folder.';

  @override
  String get statusLanguageFollowsSystem =>
      'Language will now follow the system setting.';

  @override
  String get statusLanguageSaved => 'Language preference saved.';

  @override
  String get errorChooseTargetDevice =>
      'Choose a target device before sending.';

  @override
  String get errorAddItemsBeforeTransfer =>
      'Add one or more files or folders before starting a transfer.';

  @override
  String statusSendingItems(Object count, Object peer) {
    return 'Sending $count item(s) to $peer...';
  }

  @override
  String statusSendingItem(Object item, Object peer) {
    return 'Sending `$item` to $peer...';
  }

  @override
  String statusQueuedTransferJobs(Object count, Object peer) {
    return 'Queued $count transfer job(s) to $peer.';
  }

  @override
  String get errorSelectRelayJobsFirst =>
      'Select one or more relay jobs first.';

  @override
  String get errorNoReadyRelayJobsSelected =>
      'No ready relay jobs are selected.';

  @override
  String statusReceivingSelectedJobs(Object count, Object path) {
    return 'Receiving $count selected job(s) into `$path`...';
  }

  @override
  String statusReceivingSelectedRelayJobs(Object count) {
    return 'Receiving $count selected relay job(s).';
  }

  @override
  String statusSavingInto(Object path) {
    return 'Saving into `$path`.';
  }

  @override
  String statusReceivedRelayJobs(Object count, Object path) {
    return 'Received $count relay job(s) into `$path`.';
  }

  @override
  String statusReceivedAndCleanedRelayJobs(Object count) {
    return 'Received $count relay job(s) and cleaned remote relays.';
  }

  @override
  String get errorFailedReceivingSelectedRelayJobs =>
      'Failed while receiving selected relay jobs.';

  @override
  String statusResumingTransfer(Object title) {
    return 'Resuming `$title` from saved JSON task state...';
  }

  @override
  String statusResumedTransfer(Object jobId, Object title) {
    return 'Resumed `$title` successfully. Task `$jobId` advanced from saved state.';
  }

  @override
  String statusClearedCompletedTransfers(Object count) {
    return 'Cleared $count completed transfer entries.';
  }

  @override
  String statusDeletingRemoteTransferJob(Object title) {
    return 'Deleting remote transfer job `$title`...';
  }

  @override
  String statusDeletedRemoteTransferJob(Object title) {
    return 'Deleted remote transfer job `$title` and removed local history.';
  }

  @override
  String get statusAutoReceiveSavingJob =>
      'Auto-receive is saving this relay job now.';

  @override
  String statusAutoReceiving(Object name, Object sender) {
    return 'Auto-receiving `$name` from $sender.';
  }

  @override
  String statusAutoReceived(Object name) {
    return 'Auto-received `$name` and cleaned the remote relay.';
  }

  @override
  String errorAutoReceiveFailed(Object error, Object name) {
    return 'Auto-receive failed for $name: $error';
  }

  @override
  String errorAutoReceiveFailedShort(Object name) {
    return 'Auto-receive failed for `$name`.';
  }

  @override
  String get actionReject => 'Reject';

  @override
  String get maxConcurrentUploadsTitle => 'Max Concurrent Uploads';

  @override
  String maxConcurrentUploadsSubtitle(Object count) {
    return '$count upload(s) at a time';
  }

  @override
  String get maxConcurrentDownloadsTitle => 'Max Concurrent Downloads';

  @override
  String maxConcurrentDownloadsSubtitle(Object count) {
    return '$count download(s) at a time';
  }
}

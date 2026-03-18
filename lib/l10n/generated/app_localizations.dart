import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'QuarkDrop'**
  String get appTitle;

  /// No description provided for @setupDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Up Your Device'**
  String get setupDeviceTitle;

  /// No description provided for @setupDeviceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name this device and choose how to join.'**
  String get setupDeviceSubtitle;

  /// No description provided for @deviceNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Device Name'**
  String get deviceNameTitle;

  /// No description provided for @deviceNameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This name will be visible to other devices.'**
  String get deviceNameSubtitle;

  /// No description provided for @deviceNameFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Device name'**
  String get deviceNameFieldLabel;

  /// No description provided for @existingDevicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Existing Devices'**
  String get existingDevicesTitle;

  /// No description provided for @existingDevicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We found device folders in your cloud. Bind to an existing one or continue as new.'**
  String get existingDevicesSubtitle;

  /// No description provided for @currentDeviceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Current device. Cleanup is allowed, deletion is disabled.'**
  String get currentDeviceSubtitle;

  /// No description provided for @deviceMailboxManageEntry.
  ///
  /// In en, this message translates to:
  /// **'Mailbox'**
  String get deviceMailboxManageEntry;

  /// No description provided for @garbageCleanupEntry.
  ///
  /// In en, this message translates to:
  /// **'Cleanup'**
  String get garbageCleanupEntry;

  /// No description provided for @deviceMailboxManageTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} Mailbox'**
  String deviceMailboxManageTitle(Object device);

  /// No description provided for @deviceMailboxManageHintTitle.
  ///
  /// In en, this message translates to:
  /// **'Review this device mailbox'**
  String get deviceMailboxManageHintTitle;

  /// No description provided for @deviceMailboxManageHintBody.
  ///
  /// In en, this message translates to:
  /// **'This screen will group the remote mailbox into completed jobs, incomplete jobs, broken jobs, and other files so each item can later be deleted safely.'**
  String get deviceMailboxManageHintBody;

  /// No description provided for @deviceMaintenanceActiveTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Active transfers detected'**
  String get deviceMaintenanceActiveTransferTitle;

  /// No description provided for @deviceMaintenanceActiveTransferBody.
  ///
  /// In en, this message translates to:
  /// **'Try to run mailbox management and garbage cleanup when no send or receive task is still active. Device operations will be temporarily disabled during cleanup.'**
  String get deviceMaintenanceActiveTransferBody;

  /// No description provided for @deviceCleanupCategoryReadyTasks.
  ///
  /// In en, this message translates to:
  /// **'Pending Download Tasks'**
  String get deviceCleanupCategoryReadyTasks;

  /// No description provided for @deviceCleanupCategoryReadyTasksBody.
  ///
  /// In en, this message translates to:
  /// **'Remote jobs that are complete and still waiting for this device to download them will appear here.'**
  String get deviceCleanupCategoryReadyTasksBody;

  /// No description provided for @deviceCleanupCategoryIncompleteUploads.
  ///
  /// In en, this message translates to:
  /// **'Incomplete Upload Tasks'**
  String get deviceCleanupCategoryIncompleteUploads;

  /// No description provided for @deviceCleanupCategoryIncompleteUploadsBody.
  ///
  /// In en, this message translates to:
  /// **'Partially uploaded tasks left behind by interrupted senders will appear here and should be reviewed before deletion.'**
  String get deviceCleanupCategoryIncompleteUploadsBody;

  /// No description provided for @deviceCleanupCategoryBrokenTasks.
  ///
  /// In en, this message translates to:
  /// **'Broken Tasks'**
  String get deviceCleanupCategoryBrokenTasks;

  /// No description provided for @deviceCleanupCategoryBrokenTasksBody.
  ///
  /// In en, this message translates to:
  /// **'Items that look like jobs but fail parsing, validation, or integrity checks will appear here.'**
  String get deviceCleanupCategoryBrokenTasksBody;

  /// No description provided for @deviceCleanupCategoryOtherFiles.
  ///
  /// In en, this message translates to:
  /// **'Other Files'**
  String get deviceCleanupCategoryOtherFiles;

  /// No description provided for @deviceCleanupCategoryOtherFilesBody.
  ///
  /// In en, this message translates to:
  /// **'Regular files, folders, or leftovers that are not part of the QuarkDrop protocol will appear here.'**
  String get deviceCleanupCategoryOtherFilesBody;

  /// No description provided for @deviceCleanupEmptyPreview.
  ///
  /// In en, this message translates to:
  /// **'Scan results will be shown here.'**
  String get deviceCleanupEmptyPreview;

  /// No description provided for @deviceMaintenanceBusyDeletingMailbox.
  ///
  /// In en, this message translates to:
  /// **'Processing mailbox items. Please wait…'**
  String get deviceMaintenanceBusyDeletingMailbox;

  /// No description provided for @deviceMaintenanceBusyGarbageCleanup.
  ///
  /// In en, this message translates to:
  /// **'Scanning or cleaning garbage data. Please wait…'**
  String get deviceMaintenanceBusyGarbageCleanup;

  /// No description provided for @garbageCleanupTitle.
  ///
  /// In en, this message translates to:
  /// **'Garbage Cleanup'**
  String get garbageCleanupTitle;

  /// No description provided for @garbageCleanupHintBody.
  ///
  /// In en, this message translates to:
  /// **'This page will aggregate the same cleanup categories across all devices: pending download tasks, incomplete upload tasks, broken tasks, and other files. The first version shows the planned scan layout.'**
  String get garbageCleanupHintBody;

  /// No description provided for @cleanupSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} items · {size}'**
  String cleanupSummaryLabel(Object count, Object size);

  /// No description provided for @actionBind.
  ///
  /// In en, this message translates to:
  /// **'Bind'**
  String get actionBind;

  /// No description provided for @actionContinueAsNewDevice.
  ///
  /// In en, this message translates to:
  /// **'Continue as New Device'**
  String get actionContinueAsNewDevice;

  /// No description provided for @errorPasswordEmpty.
  ///
  /// In en, this message translates to:
  /// **'Password cannot be empty.'**
  String get errorPasswordEmpty;

  /// No description provided for @errorPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get errorPasswordsDoNotMatch;

  /// No description provided for @setCloudPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Cloud Password'**
  String get setCloudPasswordTitle;

  /// No description provided for @verifyCloudPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Cloud Password'**
  String get verifyCloudPasswordTitle;

  /// No description provided for @setCloudPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set a cloud password to encrypt your device keys.'**
  String get setCloudPasswordSubtitle;

  /// No description provided for @verifyCloudPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your cloud password to unlock this device.'**
  String get verifyCloudPasswordSubtitle;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordLabel;

  /// No description provided for @cloudPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Cloud Password'**
  String get cloudPasswordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @rememberPasswordOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Remember password on this device'**
  String get rememberPasswordOnDevice;

  /// No description provided for @actionSetPassword.
  ///
  /// In en, this message translates to:
  /// **'Set Password'**
  String get actionSetPassword;

  /// No description provided for @actionVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get actionVerify;

  /// No description provided for @preparingQuarkDropTitle.
  ///
  /// In en, this message translates to:
  /// **'Preparing QuarkDrop'**
  String get preparingQuarkDropTitle;

  /// No description provided for @preparingQuarkDropSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bootstrapping the encrypted relay workspace.'**
  String get preparingQuarkDropSubtitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your Quark account to continue.'**
  String get loginSubtitle;

  /// No description provided for @actionUseBrowserLogin.
  ///
  /// In en, this message translates to:
  /// **'Use Browser Login'**
  String get actionUseBrowserLogin;

  /// No description provided for @actionUseCookieLogin.
  ///
  /// In en, this message translates to:
  /// **'Use Cookie Login'**
  String get actionUseCookieLogin;

  /// No description provided for @quarkCookieLabel.
  ///
  /// In en, this message translates to:
  /// **'Quark Cookie'**
  String get quarkCookieLabel;

  /// No description provided for @actionPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get actionPaste;

  /// No description provided for @actionValidating.
  ///
  /// In en, this message translates to:
  /// **'Validating...'**
  String get actionValidating;

  /// No description provided for @actionSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get actionSignIn;

  /// No description provided for @webLoginInitialStatus.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Quark, then tap Complete Login to import the cookies.'**
  String get webLoginInitialStatus;

  /// No description provided for @webLoginFreshSessionReady.
  ///
  /// In en, this message translates to:
  /// **'Fresh login session ready. Sign in to Quark, then tap Complete Login.'**
  String get webLoginFreshSessionReady;

  /// No description provided for @webLoginResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset the embedded browser session: {error}'**
  String webLoginResetFailed(Object error);

  /// No description provided for @webLoginImportingCookies.
  ///
  /// In en, this message translates to:
  /// **'Importing Quark cookies from the embedded browser...'**
  String get webLoginImportingCookies;

  /// No description provided for @webLoginNoValidatedSession.
  ///
  /// In en, this message translates to:
  /// **'No validated Quark session yet. Finish the login flow, then tap Complete Login again.'**
  String get webLoginNoValidatedSession;

  /// No description provided for @webLoginCookieCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'Cookie capture failed: {error}'**
  String webLoginCookieCaptureFailed(Object error);

  /// No description provided for @embeddedQuarkLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Embedded Quark Login'**
  String get embeddedQuarkLoginTitle;

  /// No description provided for @actionCompleteLogin.
  ///
  /// In en, this message translates to:
  /// **'Complete Login'**
  String get actionCompleteLogin;

  /// No description provided for @webLoginPageLoaded.
  ///
  /// In en, this message translates to:
  /// **'Page loaded. Finish the Quark login flow, then tap Complete Login.'**
  String get webLoginPageLoaded;

  /// No description provided for @webLoginLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Web login failed to load: {error}'**
  String webLoginLoadFailed(Object error);

  /// No description provided for @navSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get navSend;

  /// No description provided for @navMailbox.
  ///
  /// In en, this message translates to:
  /// **'Mailbox'**
  String get navMailbox;

  /// No description provided for @navTransfers.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get navTransfers;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @noPeerDevicesTitle.
  ///
  /// In en, this message translates to:
  /// **'No peer devices yet'**
  String get noPeerDevicesTitle;

  /// No description provided for @noPeerDevicesBody.
  ///
  /// In en, this message translates to:
  /// **'No other device is available yet. Open QuarkDrop on another device and sign in first.'**
  String get noPeerDevicesBody;

  /// No description provided for @sendTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Send Target'**
  String get sendTargetLabel;

  /// No description provided for @actionSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get actionSelect;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @noTransfersTitle.
  ///
  /// In en, this message translates to:
  /// **'No transfers'**
  String get noTransfersTitle;

  /// No description provided for @noTransfersBody.
  ///
  /// In en, this message translates to:
  /// **'Jobs matching this filter will appear here.'**
  String get noTransfersBody;

  /// No description provided for @noTransferHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'No transfer history yet'**
  String get noTransferHistoryTitle;

  /// No description provided for @noTransferHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'Send a file or receive a mailbox job to build the transfer queue.'**
  String get noTransferHistoryBody;

  /// No description provided for @transfersTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get transfersTitle;

  /// No description provided for @transfersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload and download history.'**
  String get transfersSubtitle;

  /// No description provided for @actionClearCompleted.
  ///
  /// In en, this message translates to:
  /// **'Clear Completed'**
  String get actionClearCompleted;

  /// No description provided for @tabUnfinished.
  ///
  /// In en, this message translates to:
  /// **'Unfinished ({count})'**
  String tabUnfinished(Object count);

  /// No description provided for @tabSending.
  ///
  /// In en, this message translates to:
  /// **'Sending ({count})'**
  String tabSending(Object count);

  /// No description provided for @tabReceiving.
  ///
  /// In en, this message translates to:
  /// **'Receiving ({count})'**
  String tabReceiving(Object count);

  /// No description provided for @tabCompleted.
  ///
  /// In en, this message translates to:
  /// **'Done ({count})'**
  String tabCompleted(Object count);

  /// No description provided for @tabAll.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String tabAll(Object count);

  /// No description provided for @selectTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a transfer'**
  String get selectTransferTitle;

  /// No description provided for @selectTransferBody.
  ///
  /// In en, this message translates to:
  /// **'Choose a row from the queue to inspect its state and available actions.'**
  String get selectTransferBody;

  /// No description provided for @selectedTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Selected Transfer'**
  String get selectedTransferTitle;

  /// No description provided for @selectedTransferSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Current status, direction, and recovery actions.'**
  String get selectedTransferSubtitle;

  /// No description provided for @sendJobLabel.
  ///
  /// In en, this message translates to:
  /// **'Send job'**
  String get sendJobLabel;

  /// No description provided for @receiveJobLabel.
  ///
  /// In en, this message translates to:
  /// **'Receive job'**
  String get receiveJobLabel;

  /// No description provided for @actionResumeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Resume Transfer'**
  String get actionResumeTransfer;

  /// No description provided for @actionDeleteDevice.
  ///
  /// In en, this message translates to:
  /// **'Delete Device'**
  String get actionDeleteDevice;

  /// No description provided for @actionDeleteDeviceHint.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this device and its mailbox?'**
  String get actionDeleteDeviceHint;

  /// No description provided for @actionDeleteRemoteJob.
  ///
  /// In en, this message translates to:
  /// **'Delete Remote Job'**
  String get actionDeleteRemoteJob;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Device, storage, and sign-out.'**
  String get settingsSubtitle;

  /// No description provided for @downloadFolderChooseBeforeReceiving.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder before receiving'**
  String get downloadFolderChooseBeforeReceiving;

  /// No description provided for @latestErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Latest Error'**
  String get latestErrorTitle;

  /// No description provided for @directionSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get directionSend;

  /// No description provided for @directionReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get directionReceive;

  /// No description provided for @accountLabel.
  ///
  /// In en, this message translates to:
  /// **'Account: {authSource}'**
  String accountLabel(Object authSource);

  /// No description provided for @deviceIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Device ID: {deviceId}'**
  String deviceIdLabel(Object deviceId);

  /// No description provided for @errorNewPasswordEmpty.
  ///
  /// In en, this message translates to:
  /// **'New password cannot be empty.'**
  String get errorNewPasswordEmpty;

  /// No description provided for @cloudPasswordCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud Password'**
  String get cloudPasswordCardTitle;

  /// No description provided for @cloudPasswordCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change your cloud password. All device keys will be re-encrypted.'**
  String get cloudPasswordCardSubtitle;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPasswordLabel;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPasswordLabel;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get actionChangePassword;

  /// No description provided for @cloudPasswordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Cloud password updated.'**
  String get cloudPasswordUpdated;

  /// No description provided for @rememberPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Remember Password'**
  String get rememberPasswordTitle;

  /// No description provided for @rememberPasswordEnabled.
  ///
  /// In en, this message translates to:
  /// **'The device key is saved. Auto-unlock is enabled.'**
  String get rememberPasswordEnabled;

  /// No description provided for @rememberPasswordDisabled.
  ///
  /// In en, this message translates to:
  /// **'Save the device key so password is not required on next launch.'**
  String get rememberPasswordDisabled;

  /// No description provided for @savedPasswordEnabled.
  ///
  /// In en, this message translates to:
  /// **'Password saved. The app will auto-unlock on next launch.'**
  String get savedPasswordEnabled;

  /// No description provided for @savedPasswordCleared.
  ///
  /// In en, this message translates to:
  /// **'Saved password cleared.'**
  String get savedPasswordCleared;

  /// No description provided for @genericFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String genericFailed(Object error);

  /// No description provided for @launchAtStartupTitle.
  ///
  /// In en, this message translates to:
  /// **'Launch at Startup'**
  String get launchAtStartupTitle;

  /// No description provided for @launchAtStartupUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This platform integration is not wired up yet for the current build.'**
  String get launchAtStartupUnavailable;

  /// No description provided for @launchAtStartupEnabled.
  ///
  /// In en, this message translates to:
  /// **'The app will start automatically when you log in.'**
  String get launchAtStartupEnabled;

  /// No description provided for @launchAtStartupDisabled.
  ///
  /// In en, this message translates to:
  /// **'Enable to start the app automatically at system boot.'**
  String get launchAtStartupDisabled;

  /// No description provided for @openDataFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Open Data Folder'**
  String get openDataFolderTitle;

  /// No description provided for @openDataFolderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the app configuration directory in the file manager. (Debug only)'**
  String get openDataFolderSubtitle;

  /// No description provided for @failedOpenDataFolder.
  ///
  /// In en, this message translates to:
  /// **'Failed to open data folder: {error}'**
  String failedOpenDataFolder(Object error);

  /// No description provided for @backgroundTitle.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get backgroundTitle;

  /// No description provided for @backgroundBatteryDisabled.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization is disabled. The app can run in the background.'**
  String get backgroundBatteryDisabled;

  /// No description provided for @backgroundBatteryEnabled.
  ///
  /// In en, this message translates to:
  /// **'Disable battery optimization to prevent background transfers from being interrupted.'**
  String get backgroundBatteryEnabled;

  /// No description provided for @actionDisableBatteryOptimization.
  ///
  /// In en, this message translates to:
  /// **'Disable Battery Optimization'**
  String get actionDisableBatteryOptimization;

  /// No description provided for @actionOpenAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open App Settings'**
  String get actionOpenAppSettings;

  /// No description provided for @signOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutTitle;

  /// No description provided for @signOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove mailbox and clear saved session.'**
  String get signOutSubtitle;

  /// No description provided for @signOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'All local transfer tasks will be removed.'**
  String get signOutConfirmBody;

  /// No description provided for @signOutDeleteCloudFolder.
  ///
  /// In en, this message translates to:
  /// **'Delete cloud folder and local task list'**
  String get signOutDeleteCloudFolder;

  /// No description provided for @signOutDeleteCloudHint.
  ///
  /// In en, this message translates to:
  /// **'Other devices will no longer be able to send files to the current device.'**
  String get signOutDeleteCloudHint;

  /// No description provided for @signOutKeepCloudHint.
  ///
  /// In en, this message translates to:
  /// **'Files will not be received for this account until you re-login and bind.'**
  String get signOutKeepCloudHint;

  /// No description provided for @downloadFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Download Folder'**
  String get downloadFolderTitle;

  /// No description provided for @actionChooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose Folder'**
  String get actionChooseFolder;

  /// No description provided for @actionUseDefault.
  ///
  /// In en, this message translates to:
  /// **'Use Default'**
  String get actionUseDefault;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageFollowingSystem.
  ///
  /// In en, this message translates to:
  /// **'Following system language.'**
  String get languageFollowingSystem;

  /// No description provided for @languageFollowSystemOption.
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get languageFollowSystemOption;

  /// No description provided for @languageEnglishUsOption.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglishUsOption;

  /// No description provided for @languageSimplifiedChineseOption.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get languageSimplifiedChineseOption;

  /// No description provided for @languageTraditionalChineseOption.
  ///
  /// In en, this message translates to:
  /// **'繁體中文'**
  String get languageTraditionalChineseOption;

  /// No description provided for @languageJapaneseOption.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get languageJapaneseOption;

  /// No description provided for @languageKoreanOption.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get languageKoreanOption;

  /// No description provided for @themeModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeModeTitle;

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @stagePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get stagePreparing;

  /// No description provided for @stageUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get stageUploading;

  /// No description provided for @stageManifest.
  ///
  /// In en, this message translates to:
  /// **'Manifest'**
  String get stageManifest;

  /// No description provided for @stageCommit.
  ///
  /// In en, this message translates to:
  /// **'Commit'**
  String get stageCommit;

  /// No description provided for @stageDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get stageDownloading;

  /// No description provided for @stageVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying'**
  String get stageVerifying;

  /// No description provided for @stageCleanup.
  ///
  /// In en, this message translates to:
  /// **'Cleanup'**
  String get stageCleanup;

  /// No description provided for @stageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get stageFailed;

  /// No description provided for @stageDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get stageDone;

  /// No description provided for @transferFailedWaitingRecovery.
  ///
  /// In en, this message translates to:
  /// **'Transfer failed and is waiting for recovery.'**
  String get transferFailedWaitingRecovery;

  /// No description provided for @transferCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Transfer completed successfully.'**
  String get transferCompletedSuccessfully;

  /// No description provided for @transferPercentComplete.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String transferPercentComplete(Object percent);

  /// No description provided for @transferNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get transferNeedsAttention;

  /// No description provided for @transferCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get transferCompleted;

  /// No description provided for @transferActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get transferActive;

  /// No description provided for @mailboxPollIntervalTitle.
  ///
  /// In en, this message translates to:
  /// **'Mailbox Poll Interval'**
  String get mailboxPollIntervalTitle;

  /// No description provided for @mailboxPollIntervalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s - how often to check for new files.'**
  String mailboxPollIntervalSubtitle(Object seconds);

  /// No description provided for @secondsShort.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String secondsShort(Object seconds);

  /// No description provided for @autoReceiveFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-Receive Files'**
  String get autoReceiveFilesTitle;

  /// No description provided for @autoReceiveFilesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically download incoming files to your default download directory.'**
  String get autoReceiveFilesSubtitle;

  /// No description provided for @autoNavigateTransfersTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-Navigate to Transfers'**
  String get autoNavigateTransfersTitle;

  /// No description provided for @autoNavigateTransfersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'After sending or receiving, automatically switch to the Transfers page.'**
  String get autoNavigateTransfersSubtitle;

  /// No description provided for @keepScreenOnTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep Screen On During Transfer'**
  String get keepScreenOnTitle;

  /// No description provided for @keepScreenOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prevent the screen from turning off while files are being sent or received.'**
  String get keepScreenOnSubtitle;

  /// No description provided for @mailboxSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String mailboxSelectedCount(Object count);

  /// No description provided for @mailboxItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items in mailbox'**
  String mailboxItemsCount(Object count);

  /// No description provided for @actionReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get actionReceive;

  /// No description provided for @actionReceiveCount.
  ///
  /// In en, this message translates to:
  /// **'Receive {count}'**
  String actionReceiveCount(Object count);

  /// No description provided for @mailboxEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No relay jobs in the mailbox'**
  String get mailboxEmptyTitle;

  /// No description provided for @mailboxEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Incoming encrypted jobs will appear here after another device sends them.'**
  String get mailboxEmptyBody;

  /// No description provided for @mailboxFromSender.
  ///
  /// In en, this message translates to:
  /// **'From {sender} - {sizeLabel}'**
  String mailboxFromSender(Object sender, Object sizeLabel);

  /// No description provided for @sendComposerChooseDevice.
  ///
  /// In en, this message translates to:
  /// **'Choose a device below, then build your send batch.'**
  String get sendComposerChooseDevice;

  /// No description provided for @sendComposerReadyToSend.
  ///
  /// In en, this message translates to:
  /// **'Ready to send to {target}.'**
  String sendComposerReadyToSend(Object target);

  /// No description provided for @actionAddFiles.
  ///
  /// In en, this message translates to:
  /// **'Add Files'**
  String get actionAddFiles;

  /// No description provided for @actionAddFolder.
  ///
  /// In en, this message translates to:
  /// **'Add Folder'**
  String get actionAddFolder;

  /// No description provided for @actionAddMedia.
  ///
  /// In en, this message translates to:
  /// **'Add Media'**
  String get actionAddMedia;

  /// No description provided for @actionClearBatch.
  ///
  /// In en, this message translates to:
  /// **'Clear Batch'**
  String get actionClearBatch;

  /// No description provided for @actionSendBatch.
  ///
  /// In en, this message translates to:
  /// **'Send Batch'**
  String get actionSendBatch;

  /// No description provided for @actionSendItemCount.
  ///
  /// In en, this message translates to:
  /// **'Send {count} Item(s)'**
  String actionSendItemCount(Object count);

  /// No description provided for @sendComposerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No files or folders added yet.'**
  String get sendComposerEmpty;

  /// No description provided for @actionUseThisFolder.
  ///
  /// In en, this message translates to:
  /// **'Use This Folder'**
  String get actionUseThisFolder;

  /// No description provided for @actionShowWindow.
  ///
  /// In en, this message translates to:
  /// **'Show Window'**
  String get actionShowWindow;

  /// No description provided for @actionQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get actionQuit;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionDownloadHere.
  ///
  /// In en, this message translates to:
  /// **'Download Here'**
  String get actionDownloadHere;

  /// No description provided for @errorPasteQuarkCookie.
  ///
  /// In en, this message translates to:
  /// **'Please paste a Quark cookie before continuing.'**
  String get errorPasteQuarkCookie;

  /// No description provided for @errorDeviceNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Device name cannot be empty.'**
  String get errorDeviceNameEmpty;

  /// No description provided for @statusSavedDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Saved device name as `{name}`.'**
  String statusSavedDeviceName(Object name);

  /// No description provided for @statusDefaultDownloadFolderSet.
  ///
  /// In en, this message translates to:
  /// **'Default download folder set to `{path}`.'**
  String statusDefaultDownloadFolderSet(Object path);

  /// No description provided for @statusClearedSavedDownloadFolder.
  ///
  /// In en, this message translates to:
  /// **'Cleared the saved download folder.'**
  String get statusClearedSavedDownloadFolder;

  /// No description provided for @statusLanguageFollowsSystem.
  ///
  /// In en, this message translates to:
  /// **'Language will now follow the system setting.'**
  String get statusLanguageFollowsSystem;

  /// No description provided for @statusLanguageSaved.
  ///
  /// In en, this message translates to:
  /// **'Language preference saved.'**
  String get statusLanguageSaved;

  /// No description provided for @errorChooseTargetDevice.
  ///
  /// In en, this message translates to:
  /// **'Choose a target device before sending.'**
  String get errorChooseTargetDevice;

  /// No description provided for @errorAddItemsBeforeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Add one or more files or folders before starting a transfer.'**
  String get errorAddItemsBeforeTransfer;

  /// No description provided for @statusSendingItems.
  ///
  /// In en, this message translates to:
  /// **'Sending {count} item(s) to {peer}...'**
  String statusSendingItems(Object count, Object peer);

  /// No description provided for @statusSendingItem.
  ///
  /// In en, this message translates to:
  /// **'Sending `{item}` to {peer}...'**
  String statusSendingItem(Object item, Object peer);

  /// No description provided for @statusQueuedTransferJobs.
  ///
  /// In en, this message translates to:
  /// **'Queued {count} transfer job(s) to {peer}.'**
  String statusQueuedTransferJobs(Object count, Object peer);

  /// No description provided for @errorSelectRelayJobsFirst.
  ///
  /// In en, this message translates to:
  /// **'Select one or more relay jobs first.'**
  String get errorSelectRelayJobsFirst;

  /// No description provided for @errorNoReadyRelayJobsSelected.
  ///
  /// In en, this message translates to:
  /// **'No ready relay jobs are selected.'**
  String get errorNoReadyRelayJobsSelected;

  /// No description provided for @statusReceivingSelectedJobs.
  ///
  /// In en, this message translates to:
  /// **'Receiving {count} selected job(s) into `{path}`...'**
  String statusReceivingSelectedJobs(Object count, Object path);

  /// No description provided for @statusReceivingSelectedRelayJobs.
  ///
  /// In en, this message translates to:
  /// **'Receiving {count} selected relay job(s).'**
  String statusReceivingSelectedRelayJobs(Object count);

  /// No description provided for @statusSavingInto.
  ///
  /// In en, this message translates to:
  /// **'Saving into `{path}`.'**
  String statusSavingInto(Object path);

  /// No description provided for @statusReceivedRelayJobs.
  ///
  /// In en, this message translates to:
  /// **'Received {count} relay job(s) into `{path}`.'**
  String statusReceivedRelayJobs(Object count, Object path);

  /// No description provided for @statusReceivedAndCleanedRelayJobs.
  ///
  /// In en, this message translates to:
  /// **'Received {count} relay job(s) and cleaned remote relays.'**
  String statusReceivedAndCleanedRelayJobs(Object count);

  /// No description provided for @errorFailedReceivingSelectedRelayJobs.
  ///
  /// In en, this message translates to:
  /// **'Failed while receiving selected relay jobs.'**
  String get errorFailedReceivingSelectedRelayJobs;

  /// No description provided for @statusResumingTransfer.
  ///
  /// In en, this message translates to:
  /// **'Resuming `{title}` from saved JSON task state...'**
  String statusResumingTransfer(Object title);

  /// No description provided for @statusResumedTransfer.
  ///
  /// In en, this message translates to:
  /// **'Resumed `{title}` successfully. Task `{jobId}` advanced from saved state.'**
  String statusResumedTransfer(Object jobId, Object title);

  /// No description provided for @statusClearedCompletedTransfers.
  ///
  /// In en, this message translates to:
  /// **'Cleared {count} completed transfer entries.'**
  String statusClearedCompletedTransfers(Object count);

  /// No description provided for @statusDeletingRemoteTransferJob.
  ///
  /// In en, this message translates to:
  /// **'Deleting remote transfer job `{title}`...'**
  String statusDeletingRemoteTransferJob(Object title);

  /// No description provided for @statusDeletedRemoteTransferJob.
  ///
  /// In en, this message translates to:
  /// **'Deleted remote transfer job `{title}` and removed local history.'**
  String statusDeletedRemoteTransferJob(Object title);

  /// No description provided for @statusAutoReceiveSavingJob.
  ///
  /// In en, this message translates to:
  /// **'Auto-receive is saving this relay job now.'**
  String get statusAutoReceiveSavingJob;

  /// No description provided for @statusAutoReceiving.
  ///
  /// In en, this message translates to:
  /// **'Auto-receiving `{name}` from {sender}.'**
  String statusAutoReceiving(Object name, Object sender);

  /// No description provided for @statusAutoReceived.
  ///
  /// In en, this message translates to:
  /// **'Auto-received `{name}` and cleaned the remote relay.'**
  String statusAutoReceived(Object name);

  /// No description provided for @errorAutoReceiveFailed.
  ///
  /// In en, this message translates to:
  /// **'Auto-receive failed for {name}: {error}'**
  String errorAutoReceiveFailed(Object error, Object name);

  /// No description provided for @errorAutoReceiveFailedShort.
  ///
  /// In en, this message translates to:
  /// **'Auto-receive failed for `{name}`.'**
  String errorAutoReceiveFailedShort(Object name);

  /// No description provided for @actionReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get actionReject;

  /// No description provided for @maxConcurrentUploadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Max Concurrent Uploads'**
  String get maxConcurrentUploadsTitle;

  /// No description provided for @maxConcurrentUploadsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} upload(s) at a time'**
  String maxConcurrentUploadsSubtitle(Object count);

  /// No description provided for @maxConcurrentDownloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Max Concurrent Downloads'**
  String get maxConcurrentDownloadsTitle;

  /// No description provided for @maxConcurrentDownloadsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} download(s) at a time'**
  String maxConcurrentDownloadsSubtitle(Object count);

  /// No description provided for @settingMinimizeToTrayTitle.
  ///
  /// In en, this message translates to:
  /// **'Minimize to tray on close'**
  String get settingMinimizeToTrayTitle;

  /// No description provided for @settingMinimizeToTrayDescription.
  ///
  /// In en, this message translates to:
  /// **'Minimize to Tray'**
  String get settingMinimizeToTrayDescription;

  /// No description provided for @settingPeerDiscoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Peer Discovery Interval'**
  String get settingPeerDiscoveryTitle;

  /// No description provided for @settingPeerDiscoveryDescription.
  ///
  /// In en, this message translates to:
  /// **'Interval for refreshing cloud device names (Minutes)'**
  String get settingPeerDiscoveryDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

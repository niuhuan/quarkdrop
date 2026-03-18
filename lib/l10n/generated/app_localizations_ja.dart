// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'QuarkDrop';

  @override
  String get setupDeviceTitle => 'デバイスを設定';

  @override
  String get setupDeviceSubtitle => 'このデバイスに名前を付け、参加方法を選択します。';

  @override
  String get deviceNameTitle => 'デバイス名';

  @override
  String get deviceNameSubtitle => 'この名前は他のデバイスに表示されます。';

  @override
  String get deviceNameFieldLabel => 'デバイス名';

  @override
  String get existingDevicesTitle => '既存のデバイス';

  @override
  String get existingDevicesSubtitle =>
      'クラウド内にデバイスフォルダが見つかりました。既存デバイスにバインドするか、新しいデバイスとして続行できます。';

  @override
  String get actionBind => 'バインド';

  @override
  String get actionContinueAsNewDevice => '新しいデバイスとして続行';

  @override
  String get errorPasswordEmpty => 'パスワードは空にできません。';

  @override
  String get errorPasswordsDoNotMatch => 'パスワードが一致しません。';

  @override
  String get setCloudPasswordTitle => 'クラウドパスワードを設定';

  @override
  String get verifyCloudPasswordTitle => 'クラウドパスワードを確認';

  @override
  String get setCloudPasswordSubtitle => 'デバイス鍵を暗号化するためのクラウドパスワードを設定します。';

  @override
  String get verifyCloudPasswordSubtitle => 'このデバイスを解除するためにクラウドパスワードを入力してください。';

  @override
  String get newPasswordLabel => '新しいパスワード';

  @override
  String get cloudPasswordLabel => 'クラウドパスワード';

  @override
  String get confirmPasswordLabel => 'パスワード確認';

  @override
  String get rememberPasswordOnDevice => 'このデバイスでパスワードを保存する';

  @override
  String get actionSetPassword => 'パスワードを設定';

  @override
  String get actionVerify => '確認';

  @override
  String get preparingQuarkDropTitle => 'QuarkDrop を準備中';

  @override
  String get preparingQuarkDropSubtitle => '暗号化中継ワークスペースを初期化しています。';

  @override
  String get loginSubtitle => '続行するには Quark アカウントでサインインしてください。';

  @override
  String get actionUseBrowserLogin => 'ブラウザでログイン';

  @override
  String get actionUseCookieLogin => 'Cookie でログイン';

  @override
  String get quarkCookieLabel => 'Quark Cookie';

  @override
  String get actionPaste => '貼り付け';

  @override
  String get actionValidating => '検証中...';

  @override
  String get actionSignIn => 'サインイン';

  @override
  String get webLoginInitialStatus =>
      'Quark にサインインしてから、「ログイン完了」をタップして Cookie を取り込みます。';

  @override
  String get webLoginFreshSessionReady =>
      '新しいログインセッションの準備ができました。Quark にサインインしてから「ログイン完了」をタップしてください。';

  @override
  String webLoginResetFailed(Object error) {
    return '組み込みブラウザセッションのリセットに失敗しました: $error';
  }

  @override
  String get webLoginImportingCookies => '組み込みブラウザから Quark Cookie を取り込んでいます...';

  @override
  String get webLoginNoValidatedSession =>
      '有効な Quark セッションがまだありません。ログインを完了してから再度「ログイン完了」をタップしてください。';

  @override
  String webLoginCookieCaptureFailed(Object error) {
    return 'Cookie の取得に失敗しました: $error';
  }

  @override
  String get embeddedQuarkLoginTitle => '組み込み Quark ログイン';

  @override
  String get actionCompleteLogin => 'ログイン完了';

  @override
  String get webLoginPageLoaded =>
      'ページが読み込まれました。Quark のログインを完了してから「ログイン完了」をタップしてください。';

  @override
  String webLoginLoadFailed(Object error) {
    return 'Web ログインの読み込みに失敗しました: $error';
  }

  @override
  String get navSend => '送信';

  @override
  String get navMailbox => 'メールボックス';

  @override
  String get navTransfers => '転送';

  @override
  String get navSettings => '設定';

  @override
  String get noPeerDevicesTitle => '利用可能なデバイスがありません';

  @override
  String get noPeerDevicesBody =>
      'まだ他のデバイスが利用できません。別のデバイスで QuarkDrop を開いてサインインしてください。';

  @override
  String get sendTargetLabel => '送信先';

  @override
  String get actionSelect => '選択';

  @override
  String get noTransfersTitle => '転送がありません';

  @override
  String get noTransfersBody => 'このフィルターに一致するジョブがここに表示されます。';

  @override
  String get noTransferHistoryTitle => '転送履歴がありません';

  @override
  String get noTransferHistoryBody => 'ファイル送信またはメールボックス受信を行うと、転送キューがここに表示されます。';

  @override
  String get transfersTitle => '転送';

  @override
  String get transfersSubtitle => 'アップロードとダウンロードの履歴。';

  @override
  String get actionClearCompleted => '完了済みを削除';

  @override
  String tabUnfinished(Object count) {
    return '未完了 ($count)';
  }

  @override
  String tabSending(Object count) {
    return '送信中 ($count)';
  }

  @override
  String tabReceiving(Object count) {
    return '受信中 ($count)';
  }

  @override
  String tabCompleted(Object count) {
    return '完了 ($count)';
  }

  @override
  String tabAll(Object count) {
    return 'すべて ($count)';
  }

  @override
  String get selectTransferTitle => '転送を選択';

  @override
  String get selectTransferBody => 'キューから行を選択すると、状態と利用可能な操作を確認できます。';

  @override
  String get selectedTransferTitle => '選択中の転送';

  @override
  String get selectedTransferSubtitle => '現在の状態、方向、回復操作。';

  @override
  String get sendJobLabel => '送信ジョブ';

  @override
  String get receiveJobLabel => '受信ジョブ';

  @override
  String get actionResumeTransfer => '転送を再開';

  @override
  String get actionDeleteDevice => 'Delete Device';

  @override
  String get actionDeleteDeviceHint =>
      'Are you sure you want to delete this device and its mailbox?';

  @override
  String get actionDeleteRemoteJob => 'リモートジョブを削除';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSubtitle => 'デバイス、保存先、サインアウト。';

  @override
  String get downloadFolderChooseBeforeReceiving => '受信前にフォルダを選択してください';

  @override
  String get latestErrorTitle => '最新のエラー';

  @override
  String get directionSend => '送信';

  @override
  String get directionReceive => '受信';

  @override
  String accountLabel(Object authSource) {
    return 'アカウント: $authSource';
  }

  @override
  String get errorNewPasswordEmpty => '新しいパスワードは空にできません。';

  @override
  String get cloudPasswordCardTitle => 'クラウドパスワード';

  @override
  String get cloudPasswordCardSubtitle => 'クラウドパスワードを変更します。すべてのデバイス鍵が再暗号化されます。';

  @override
  String get currentPasswordLabel => '現在のパスワード';

  @override
  String get confirmNewPasswordLabel => '新しいパスワードを確認';

  @override
  String get actionCancel => 'キャンセル';

  @override
  String get actionChangePassword => 'パスワード変更';

  @override
  String get cloudPasswordUpdated => 'クラウドパスワードを更新しました。';

  @override
  String get rememberPasswordTitle => 'パスワードを記憶';

  @override
  String get rememberPasswordEnabled => 'デバイス鍵が保存され、自動解除が有効です。';

  @override
  String get rememberPasswordDisabled => 'デバイス鍵を保存し、次回起動時のパスワード入力を省略します。';

  @override
  String get savedPasswordEnabled => 'パスワードを保存しました。次回起動時に自動解除されます。';

  @override
  String get savedPasswordCleared => '保存済みパスワードを削除しました。';

  @override
  String genericFailed(Object error) {
    return '失敗: $error';
  }

  @override
  String get launchAtStartupTitle => '起動時に自動開始';

  @override
  String get launchAtStartupUnavailable => 'このビルドではまだこのプラットフォーム連携が有効化されていません。';

  @override
  String get launchAtStartupEnabled => 'ログイン時にアプリが自動的に起動します。';

  @override
  String get launchAtStartupDisabled => '有効にすると、システム起動時にアプリが自動的に起動します。';

  @override
  String get openDataFolderTitle => 'データフォルダを開く';

  @override
  String get openDataFolderSubtitle => 'ファイルマネージャーでアプリ設定ディレクトリを開きます。（デバッグ専用）';

  @override
  String failedOpenDataFolder(Object error) {
    return 'データフォルダを開けませんでした: $error';
  }

  @override
  String get backgroundTitle => 'バックグラウンド';

  @override
  String get backgroundBatteryDisabled => 'バッテリー最適化は無効です。アプリはバックグラウンドで動作できます。';

  @override
  String get backgroundBatteryEnabled =>
      'バックグラウンド転送が中断されないよう、バッテリー最適化を無効にしてください。';

  @override
  String get actionDisableBatteryOptimization => 'バッテリー最適化を無効化';

  @override
  String get actionOpenAppSettings => 'アプリ設定を開く';

  @override
  String get signOutTitle => 'サインアウト';

  @override
  String get signOutSubtitle => 'メールボックスを削除し、保存済みセッションをクリアします。';

  @override
  String get signOutConfirmBody => 'すべてのローカル転送タスクが削除されます。';

  @override
  String get signOutDeleteCloudFolder => 'クラウドフォルダとローカルタスクリストを削除';

  @override
  String get signOutDeleteCloudHint => '他のデバイスはこのデバイスにファイルを送れなくなります。';

  @override
  String get signOutKeepCloudHint => '再ログインしてバインドするまで、このアカウントではファイルを受信できません。';

  @override
  String get downloadFolderTitle => 'ダウンロードフォルダ';

  @override
  String get actionChooseFolder => 'フォルダを選択';

  @override
  String get actionUseDefault => 'デフォルトを使用';

  @override
  String get languageTitle => '言語';

  @override
  String get languageFollowingSystem => 'システム言語に従います。';

  @override
  String get languageFollowSystemOption => 'システムに従う';

  @override
  String get languageEnglishUsOption => '英語';

  @override
  String get languageSimplifiedChineseOption => '簡体字中国語';

  @override
  String get languageTraditionalChineseOption => '繁体字中国語';

  @override
  String get languageJapaneseOption => '日本語';

  @override
  String get languageKoreanOption => '韓国語';

  @override
  String get themeModeTitle => 'テーマモード';

  @override
  String get themeModeSystem => 'システム';

  @override
  String get themeModeLight => 'ライト';

  @override
  String get themeModeDark => 'ダーク';

  @override
  String get stagePreparing => '準備中';

  @override
  String get stageUploading => 'アップロード中';

  @override
  String get stageManifest => 'マニフェスト';

  @override
  String get stageCommit => 'コミット';

  @override
  String get stageDownloading => 'ダウンロード中';

  @override
  String get stageVerifying => '検証中';

  @override
  String get stageCleanup => 'クリーンアップ';

  @override
  String get stageFailed => '失敗';

  @override
  String get stageDone => '完了';

  @override
  String get transferFailedWaitingRecovery => '転送に失敗し、回復待ちです。';

  @override
  String get transferCompletedSuccessfully => '転送が正常に完了しました。';

  @override
  String transferPercentComplete(Object percent) {
    return '$percent% 完了';
  }

  @override
  String get transferNeedsAttention => '要対応';

  @override
  String get transferCompleted => '完了';

  @override
  String get transferActive => '進行中';

  @override
  String get mailboxPollIntervalTitle => 'メールボックス確認間隔';

  @override
  String mailboxPollIntervalSubtitle(Object seconds) {
    return '$seconds 秒ごとに新しいファイルを確認します。';
  }

  @override
  String secondsShort(Object seconds) {
    return '$seconds 秒';
  }

  @override
  String get autoReceiveFilesTitle => '自動受信';

  @override
  String get autoReceiveFilesSubtitle => '受信ファイルをデフォルトのダウンロードディレクトリに自動保存します。';

  @override
  String get autoNavigateTransfersTitle => '転送ページへ自動移動';

  @override
  String get autoNavigateTransfersSubtitle => '送信または受信後、自動的に転送ページへ切り替えます。';

  @override
  String get keepScreenOnTitle => '転送中は画面をオンのままにする';

  @override
  String get keepScreenOnSubtitle => 'ファイル送受信中に画面が消えないようにします。';

  @override
  String mailboxSelectedCount(Object count) {
    return '$count 件を選択中';
  }

  @override
  String mailboxItemsCount(Object count) {
    return 'メールボックスに $count 件';
  }

  @override
  String get actionReceive => '受信';

  @override
  String actionReceiveCount(Object count) {
    return '$count 件受信';
  }

  @override
  String get mailboxEmptyTitle => 'メールボックスに中継ジョブがありません';

  @override
  String get mailboxEmptyBody => '他のデバイスが暗号化ジョブを送信すると、ここに表示されます。';

  @override
  String mailboxFromSender(Object sender, Object sizeLabel) {
    return '$sender から - $sizeLabel';
  }

  @override
  String get sendComposerChooseDevice => '下でデバイスを選択してから、送信バッチを作成してください。';

  @override
  String sendComposerReadyToSend(Object target) {
    return '$target へ送信する準備ができました。';
  }

  @override
  String get actionAddFiles => 'ファイルを追加';

  @override
  String get actionAddFolder => 'フォルダを追加';

  @override
  String get actionAddMedia => 'メディアを追加';

  @override
  String get actionClearBatch => 'バッチをクリア';

  @override
  String get actionSendBatch => 'バッチ送信';

  @override
  String actionSendItemCount(Object count) {
    return '$count 件送信';
  }

  @override
  String get sendComposerEmpty => 'まだファイルやフォルダが追加されていません。';

  @override
  String get actionUseThisFolder => 'このフォルダを使用';

  @override
  String get actionShowWindow => 'ウィンドウを表示';

  @override
  String get actionQuit => '終了';

  @override
  String get actionAdd => '追加';

  @override
  String get actionDownloadHere => 'ここにダウンロード';

  @override
  String get errorPasteQuarkCookie => '続行する前に Quark Cookie を貼り付けてください。';

  @override
  String get errorDeviceNameEmpty => 'デバイス名は空にできません。';

  @override
  String statusSavedDeviceName(Object name) {
    return 'デバイス名を `$name` として保存しました。';
  }

  @override
  String statusDefaultDownloadFolderSet(Object path) {
    return 'デフォルトのダウンロードフォルダを `$path` に設定しました。';
  }

  @override
  String get statusClearedSavedDownloadFolder => '保存済みダウンロードフォルダをクリアしました。';

  @override
  String get statusLanguageFollowsSystem => '言語はシステム設定に従います。';

  @override
  String get statusLanguageSaved => '言語設定を保存しました。';

  @override
  String get errorChooseTargetDevice => '送信前に対象デバイスを選択してください。';

  @override
  String get errorAddItemsBeforeTransfer =>
      '転送を開始する前に、1 つ以上のファイルまたはフォルダを追加してください。';

  @override
  String statusSendingItems(Object count, Object peer) {
    return '$peer に $count 件送信中...';
  }

  @override
  String statusSendingItem(Object item, Object peer) {
    return '$peer に `$item` を送信中...';
  }

  @override
  String statusQueuedTransferJobs(Object count, Object peer) {
    return '$peer へ $count 件の転送ジョブをキューに追加しました。';
  }

  @override
  String get errorSelectRelayJobsFirst => '最初に 1 件以上の中継ジョブを選択してください。';

  @override
  String get errorNoReadyRelayJobsSelected => '選択された中継ジョブに受信可能な項目がありません。';

  @override
  String statusReceivingSelectedJobs(Object count, Object path) {
    return '$count 件を `$path` に受信中...';
  }

  @override
  String statusReceivingSelectedRelayJobs(Object count) {
    return '$count 件の中継ジョブを受信中です。';
  }

  @override
  String statusSavingInto(Object path) {
    return '`$path` に保存中。';
  }

  @override
  String statusReceivedRelayJobs(Object count, Object path) {
    return '$count 件の中継ジョブを `$path` に受信しました。';
  }

  @override
  String statusReceivedAndCleanedRelayJobs(Object count) {
    return '$count 件の中継ジョブを受信し、リモート中継を削除しました。';
  }

  @override
  String get errorFailedReceivingSelectedRelayJobs => '選択した中継ジョブの受信中に失敗しました。';

  @override
  String statusResumingTransfer(Object title) {
    return '保存済み JSON タスク状態から `$title` を再開中...';
  }

  @override
  String statusResumedTransfer(Object jobId, Object title) {
    return '`$title` を正常に再開しました。タスク `$jobId` は保存状態から進行しました。';
  }

  @override
  String statusClearedCompletedTransfers(Object count) {
    return '完了済み転送 $count 件を削除しました。';
  }

  @override
  String statusDeletingRemoteTransferJob(Object title) {
    return 'リモート転送ジョブ `$title` を削除中...';
  }

  @override
  String statusDeletedRemoteTransferJob(Object title) {
    return 'リモート転送ジョブ `$title` を削除し、ローカル履歴も削除しました。';
  }

  @override
  String get statusAutoReceiveSavingJob => '自動受信がこの中継ジョブを保存しています。';

  @override
  String statusAutoReceiving(Object name, Object sender) {
    return '$sender から `$name` を自動受信中です。';
  }

  @override
  String statusAutoReceived(Object name) {
    return '`$name` を自動受信し、リモート中継を削除しました。';
  }

  @override
  String errorAutoReceiveFailed(Object error, Object name) {
    return '`$name` の自動受信に失敗しました: $error';
  }

  @override
  String errorAutoReceiveFailedShort(Object name) {
    return '`$name` の自動受信に失敗しました。';
  }

  @override
  String get actionReject => '拒否';

  @override
  String get maxConcurrentUploadsTitle => '最大同時アップロード数';

  @override
  String maxConcurrentUploadsSubtitle(Object count) {
    return '同時に $count 件アップロード';
  }

  @override
  String get maxConcurrentDownloadsTitle => '最大同時ダウンロード数';

  @override
  String maxConcurrentDownloadsSubtitle(Object count) {
    return '同時に $count 件ダウンロード';
  }

  @override
  String get settingMinimizeToTrayTitle => '閉じる時にトレイへ最小化';

  @override
  String get settingMinimizeToTrayDescription => 'トレイに最小化';

  @override
  String get settingPeerDiscoveryTitle => 'ピア探索間隔';

  @override
  String get settingPeerDiscoveryDescription => 'クラウド上のデバイス名を更新する間隔（分）';
}

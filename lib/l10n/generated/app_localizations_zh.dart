// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'QuarkDrop';

  @override
  String get setupDeviceTitle => '设置此设备';

  @override
  String get setupDeviceSubtitle => '为此设备命名，并选择加入方式。';

  @override
  String get deviceNameTitle => '设备名称';

  @override
  String get deviceNameSubtitle => '此名称会显示给其他设备。';

  @override
  String get deviceNameFieldLabel => '设备名称';

  @override
  String get existingDevicesTitle => '已有设备';

  @override
  String get existingDevicesSubtitle => '我们在你的网盘中找到了设备目录。你可以绑定已有设备，或继续创建新设备。';

  @override
  String get actionBind => '绑定';

  @override
  String get actionContinueAsNewDevice => '作为新设备继续';

  @override
  String get errorPasswordEmpty => '密码不能为空。';

  @override
  String get errorPasswordsDoNotMatch => '两次输入的密码不一致。';

  @override
  String get setCloudPasswordTitle => '设置云密码';

  @override
  String get verifyCloudPasswordTitle => '验证云密码';

  @override
  String get setCloudPasswordSubtitle => '设置一个云密码来加密你的设备密钥。';

  @override
  String get verifyCloudPasswordSubtitle => '输入云密码以解锁当前设备。';

  @override
  String get newPasswordLabel => '新密码';

  @override
  String get cloudPasswordLabel => '云密码';

  @override
  String get confirmPasswordLabel => '确认密码';

  @override
  String get rememberPasswordOnDevice => '在此设备记住密码';

  @override
  String get actionSetPassword => '设置密码';

  @override
  String get actionVerify => '验证';

  @override
  String get preparingQuarkDropTitle => '正在准备 QuarkDrop';

  @override
  String get preparingQuarkDropSubtitle => '正在初始化加密中转工作区。';

  @override
  String get loginSubtitle => '使用夸克账号登录后继续。';

  @override
  String get actionUseBrowserLogin => '使用浏览器登录';

  @override
  String get actionUseCookieLogin => '使用 Cookie 登录';

  @override
  String get quarkCookieLabel => '夸克 Cookie';

  @override
  String get actionPaste => '粘贴';

  @override
  String get actionValidating => '验证中...';

  @override
  String get actionSignIn => '登录';

  @override
  String get webLoginInitialStatus => '登录夸克后，点击“完成登录”导入 Cookie。';

  @override
  String get webLoginFreshSessionReady => '新的登录会话已准备好。登录夸克后，点击“完成登录”。';

  @override
  String webLoginResetFailed(Object error) {
    return '重置内嵌浏览器会话失败：$error';
  }

  @override
  String get webLoginImportingCookies => '正在从内嵌浏览器导入夸克 Cookie...';

  @override
  String get webLoginNoValidatedSession => '还没有可用的夸克会话。请先完成登录流程，再点击“完成登录”。';

  @override
  String webLoginCookieCaptureFailed(Object error) {
    return '抓取 Cookie 失败：$error';
  }

  @override
  String get embeddedQuarkLoginTitle => '内嵌夸克登录';

  @override
  String get actionCompleteLogin => '完成登录';

  @override
  String get webLoginPageLoaded => '页面已加载。请完成夸克登录流程，然后点击“完成登录”。';

  @override
  String webLoginLoadFailed(Object error) {
    return '网页登录加载失败：$error';
  }

  @override
  String get navSend => '发送';

  @override
  String get navMailbox => '收件箱';

  @override
  String get navTransfers => '传输';

  @override
  String get navSettings => '设置';

  @override
  String get noPeerDevicesTitle => '还没有可用设备';

  @override
  String get noPeerDevicesBody => '目前没有其他设备可用。请先在另一台设备上打开 QuarkDrop 并登录。';

  @override
  String get sendTargetLabel => '发送目标';

  @override
  String get actionSelect => '选择';

  @override
  String get noTransfersTitle => '暂无传输';

  @override
  String get noTransfersBody => '符合当前筛选条件的任务会显示在这里。';

  @override
  String get noTransferHistoryTitle => '还没有传输记录';

  @override
  String get noTransferHistoryBody => '发送文件或接收中转任务后，传输队列会显示在这里。';

  @override
  String get transfersTitle => '传输';

  @override
  String get transfersSubtitle => '上传和下载历史。';

  @override
  String get actionClearCompleted => '清除已完成';

  @override
  String tabPending(Object count) {
    return '未完成（$count）';
  }

  @override
  String tabSendQueuePending(Object count) {
    return '发送（$count）';
  }

  @override
  String tabReceiveQueueCompleted(Object count) {
    return '已接收（$count）';
  }

  @override
  String tabCompleted(Object count) {
    return '已完成（$count）';
  }

  @override
  String get selectTransferTitle => '选择一个传输';

  @override
  String get selectTransferBody => '从队列中选择一项，以查看其状态和可用操作。';

  @override
  String get selectedTransferTitle => '已选传输';

  @override
  String get selectedTransferSubtitle => '当前状态、方向和恢复操作。';

  @override
  String get sendJobLabel => '发送任务';

  @override
  String get receiveJobLabel => '接收任务';

  @override
  String get actionResumeTransfer => '恢复传输';

  @override
  String get actionDeleteRemoteJob => '删除远端任务';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSubtitle => '设备、存储和退出登录。';

  @override
  String get downloadFolderChooseBeforeReceiving => '接收前先选择一个文件夹';

  @override
  String get latestErrorTitle => '最近错误';

  @override
  String get directionSend => '发送';

  @override
  String get directionReceive => '接收';

  @override
  String accountLabel(Object authSource) {
    return '账号：$authSource';
  }

  @override
  String get errorNewPasswordEmpty => '新密码不能为空。';

  @override
  String get cloudPasswordCardTitle => '云密码';

  @override
  String get cloudPasswordCardSubtitle => '修改云密码。所有设备密钥都会重新加密。';

  @override
  String get currentPasswordLabel => '当前密码';

  @override
  String get confirmNewPasswordLabel => '确认新密码';

  @override
  String get actionCancel => '取消';

  @override
  String get actionChangePassword => '修改密码';

  @override
  String get cloudPasswordUpdated => '云密码已更新。';

  @override
  String get rememberPasswordTitle => '记住密码';

  @override
  String get rememberPasswordEnabled => '设备密钥已保存，已启用自动解锁。';

  @override
  String get rememberPasswordDisabled => '保存设备密钥，这样下次启动时无需再次输入密码。';

  @override
  String get savedPasswordEnabled => '密码已保存。应用将在下次启动时自动解锁。';

  @override
  String get savedPasswordCleared => '已清除保存的密码。';

  @override
  String genericFailed(Object error) {
    return '失败：$error';
  }

  @override
  String get launchAtStartupTitle => '开机启动';

  @override
  String get launchAtStartupUnavailable => '当前构建尚未接好该平台集成。';

  @override
  String get launchAtStartupEnabled => '登录系统后，应用会自动启动。';

  @override
  String get launchAtStartupDisabled => '启用后，应用会在系统启动时自动启动。';

  @override
  String get openDataFolderTitle => '打开数据文件夹';

  @override
  String get openDataFolderSubtitle => '在文件管理器中打开应用配置目录。（仅调试模式）';

  @override
  String failedOpenDataFolder(Object error) {
    return '打开数据文件夹失败：$error';
  }

  @override
  String get backgroundTitle => '后台';

  @override
  String get backgroundBatteryDisabled => '已关闭电池优化，应用可以在后台运行。';

  @override
  String get backgroundBatteryEnabled => '关闭电池优化，避免后台传输被中断。';

  @override
  String get actionDisableBatteryOptimization => '关闭电池优化';

  @override
  String get actionOpenAppSettings => '打开应用设置';

  @override
  String get signOutTitle => '退出登录';

  @override
  String get signOutSubtitle => '移除邮箱并清除已保存会话。';

  @override
  String get signOutConfirmBody => '所有本地传输任务都会被移除。';

  @override
  String get signOutDeleteCloudFolder => '删除云端文件夹和本地任务列表';

  @override
  String get signOutDeleteCloudHint => '其他设备将无法再向当前设备发送文件。';

  @override
  String get signOutKeepCloudHint => '在重新登录并绑定之前，此账号将不会接收文件。';

  @override
  String get downloadFolderTitle => '下载文件夹';

  @override
  String get actionChooseFolder => '选择文件夹';

  @override
  String get actionUseDefault => '使用默认';

  @override
  String get languageTitle => '语言';

  @override
  String get languageFollowingSystem => '跟随系统语言。';

  @override
  String get languageFollowSystemOption => '跟随系统';

  @override
  String get languageEnglishUsOption => '英语';

  @override
  String get languageSimplifiedChineseOption => '简体中文';

  @override
  String get languageTraditionalChineseOption => '繁體中文';

  @override
  String get languageJapaneseOption => '日语';

  @override
  String get languageKoreanOption => '韩语';

  @override
  String get stagePreparing => '准备中';

  @override
  String get stageUploading => '上传中';

  @override
  String get stageManifest => '清单';

  @override
  String get stageCommit => '提交';

  @override
  String get stageDownloading => '下载中';

  @override
  String get stageVerifying => '校验中';

  @override
  String get stageCleanup => '清理中';

  @override
  String get stageFailed => '失败';

  @override
  String get stageDone => '完成';

  @override
  String get transferFailedWaitingRecovery => '传输失败，等待恢复。';

  @override
  String get transferCompletedSuccessfully => '传输已成功完成。';

  @override
  String transferPercentComplete(Object percent) {
    return '已完成 $percent%';
  }

  @override
  String get transferNeedsAttention => '需要处理';

  @override
  String get transferCompleted => '已完成';

  @override
  String get transferActive => '进行中';

  @override
  String get mailboxPollIntervalTitle => '收件箱轮询间隔';

  @override
  String mailboxPollIntervalSubtitle(Object seconds) {
    return '$seconds 秒检查一次新文件。';
  }

  @override
  String secondsShort(Object seconds) {
    return '$seconds 秒';
  }

  @override
  String get autoReceiveFilesTitle => '自动接收文件';

  @override
  String get autoReceiveFilesSubtitle => '自动将收到的文件下载到默认下载目录。';

  @override
  String get autoNavigateTransfersTitle => '自动跳转到传输页';

  @override
  String get autoNavigateTransfersSubtitle => '发送或接收完成后，自动切换到传输页面。';

  @override
  String get keepScreenOnTitle => '传输时保持屏幕常亮';

  @override
  String get keepScreenOnSubtitle => '发送或接收文件时，防止屏幕自动熄灭。';

  @override
  String mailboxSelectedCount(Object count) {
    return '已选择 $count 项';
  }

  @override
  String mailboxItemsCount(Object count) {
    return '收件箱中有 $count 项';
  }

  @override
  String get actionReceive => '接收';

  @override
  String actionReceiveCount(Object count) {
    return '接收 $count 项';
  }

  @override
  String get mailboxEmptyTitle => '收件箱中没有中转任务';

  @override
  String get mailboxEmptyBody => '其他设备发送加密任务后，会显示在这里。';

  @override
  String mailboxFromSender(Object sender, Object sizeLabel) {
    return '来自 $sender · $sizeLabel';
  }

  @override
  String get sendComposerChooseDevice => '先在下方选择设备，然后开始构建发送批次。';

  @override
  String sendComposerReadyToSend(Object target) {
    return '已准备好发送到 $target。';
  }

  @override
  String get actionAddFiles => '添加文件';

  @override
  String get actionAddFolder => '添加文件夹';

  @override
  String get actionAddPhotos => '添加照片';

  @override
  String get actionClearBatch => '清空批次';

  @override
  String get actionSendBatch => '发送批次';

  @override
  String actionSendItemCount(Object count) {
    return '发送 $count 项';
  }

  @override
  String get sendComposerEmpty => '还没有添加文件或文件夹。';

  @override
  String get actionUseThisFolder => '使用此文件夹';

  @override
  String get actionShowWindow => '显示窗口';

  @override
  String get actionQuit => '退出';

  @override
  String get actionAdd => '添加';

  @override
  String get actionDownloadHere => '下载到此处';

  @override
  String get errorPasteQuarkCookie => '继续之前请先粘贴夸克 Cookie。';

  @override
  String get errorDeviceNameEmpty => '设备名称不能为空。';

  @override
  String statusSavedDeviceName(Object name) {
    return '已将设备名称保存为 `$name`。';
  }

  @override
  String statusDefaultDownloadFolderSet(Object path) {
    return '默认下载文件夹已设置为 `$path`。';
  }

  @override
  String get statusClearedSavedDownloadFolder => '已清除保存的下载文件夹。';

  @override
  String get statusLanguageFollowsSystem => '语言将跟随系统设置。';

  @override
  String get statusLanguageSaved => '语言偏好已保存。';

  @override
  String get errorChooseTargetDevice => '发送前请先选择目标设备。';

  @override
  String get errorAddItemsBeforeTransfer => '开始传输前请先添加一个或多个文件或文件夹。';

  @override
  String statusSendingItems(Object count, Object peer) {
    return '正在向 $peer 发送 $count 项...';
  }

  @override
  String statusSendingItem(Object item, Object peer) {
    return '正在向 $peer 发送 `$item`...';
  }

  @override
  String statusQueuedTransferJobs(Object count, Object peer) {
    return '已向 $peer 排队 $count 个传输任务。';
  }

  @override
  String get errorSelectRelayJobsFirst => '请先选择一个或多个中转任务。';

  @override
  String get errorNoReadyRelayJobsSelected => '所选中转任务中没有可接收的项目。';

  @override
  String statusReceivingSelectedJobs(Object count, Object path) {
    return '正在接收到 `$path`，共 $count 项...';
  }

  @override
  String statusReceivingSelectedRelayJobs(Object count) {
    return '正在接收 $count 个中转任务。';
  }

  @override
  String statusSavingInto(Object path) {
    return '正在保存到 `$path`。';
  }

  @override
  String statusReceivedRelayJobs(Object count, Object path) {
    return '已接收到 `$path`，共 $count 个中转任务。';
  }

  @override
  String statusReceivedAndCleanedRelayJobs(Object count) {
    return '已接收 $count 个中转任务，并清理远端中转文件。';
  }

  @override
  String get errorFailedReceivingSelectedRelayJobs => '接收所选中转任务时失败。';

  @override
  String statusResumingTransfer(Object title) {
    return '正在从保存的 JSON 任务状态恢复 `$title`...';
  }

  @override
  String statusResumedTransfer(Object jobId, Object title) {
    return '已成功恢复 `$title`。任务 `$jobId` 已从保存状态继续。';
  }

  @override
  String statusClearedCompletedTransfers(Object count) {
    return '已清除 $count 条已完成传输记录。';
  }

  @override
  String statusDeletingRemoteTransferJob(Object title) {
    return '正在删除远端传输任务 `$title`...';
  }

  @override
  String statusDeletedRemoteTransferJob(Object title) {
    return '已删除远端传输任务 `$title`，并移除本地历史记录。';
  }

  @override
  String get statusAutoReceiveSavingJob => '自动接收正在保存这个中转任务。';

  @override
  String statusAutoReceiving(Object name, Object sender) {
    return '正在从 $sender 自动接收 `$name`。';
  }

  @override
  String statusAutoReceived(Object name) {
    return '已自动接收 `$name`，并清理远端中转文件。';
  }

  @override
  String errorAutoReceiveFailed(Object error, Object name) {
    return '自动接收 `$name` 失败：$error';
  }

  @override
  String errorAutoReceiveFailedShort(Object name) {
    return '自动接收 `$name` 失败。';
  }

  @override
  String get actionReject => '拒绝';

  @override
  String get maxConcurrentUploadsTitle => '最大同时上传数';

  @override
  String maxConcurrentUploadsSubtitle(Object count) {
    return '同时上传 $count 个文件';
  }

  @override
  String get maxConcurrentDownloadsTitle => '最大同时下载数';

  @override
  String maxConcurrentDownloadsSubtitle(Object count) {
    return '同时下载 $count 个文件';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get appTitle => 'QuarkDrop';

  @override
  String get setupDeviceTitle => '设置此设备';

  @override
  String get setupDeviceSubtitle => '为此设备命名，并选择加入方式。';

  @override
  String get deviceNameTitle => '设备名称';

  @override
  String get deviceNameSubtitle => '此名称会显示给其他设备。';

  @override
  String get deviceNameFieldLabel => '设备名称';

  @override
  String get existingDevicesTitle => '已有设备';

  @override
  String get existingDevicesSubtitle => '我们在你的网盘中找到了设备目录。你可以绑定已有设备，或继续创建新设备。';

  @override
  String get actionBind => '绑定';

  @override
  String get actionContinueAsNewDevice => '作为新设备继续';

  @override
  String get errorPasswordEmpty => '密码不能为空。';

  @override
  String get errorPasswordsDoNotMatch => '两次输入的密码不一致。';

  @override
  String get setCloudPasswordTitle => '设置云密码';

  @override
  String get verifyCloudPasswordTitle => '验证云密码';

  @override
  String get setCloudPasswordSubtitle => '设置一个云密码来加密你的设备密钥。';

  @override
  String get verifyCloudPasswordSubtitle => '输入云密码以解锁当前设备。';

  @override
  String get newPasswordLabel => '新密码';

  @override
  String get cloudPasswordLabel => '云密码';

  @override
  String get confirmPasswordLabel => '确认密码';

  @override
  String get rememberPasswordOnDevice => '在此设备记住密码';

  @override
  String get actionSetPassword => '设置密码';

  @override
  String get actionVerify => '验证';

  @override
  String get preparingQuarkDropTitle => '正在准备 QuarkDrop';

  @override
  String get preparingQuarkDropSubtitle => '正在初始化加密中转工作区。';

  @override
  String get loginSubtitle => '使用夸克账号登录后继续。';

  @override
  String get actionUseBrowserLogin => '使用浏览器登录';

  @override
  String get actionUseCookieLogin => '使用 Cookie 登录';

  @override
  String get quarkCookieLabel => '夸克 Cookie';

  @override
  String get actionPaste => '粘贴';

  @override
  String get actionValidating => '验证中...';

  @override
  String get actionSignIn => '登录';

  @override
  String get webLoginInitialStatus => '登录夸克后，点击“完成登录”导入 Cookie。';

  @override
  String get webLoginFreshSessionReady => '新的登录会话已准备好。登录夸克后，点击“完成登录”。';

  @override
  String webLoginResetFailed(Object error) {
    return '重置内嵌浏览器会话失败：$error';
  }

  @override
  String get webLoginImportingCookies => '正在从内嵌浏览器导入夸克 Cookie...';

  @override
  String get webLoginNoValidatedSession => '还没有可用的夸克会话。请先完成登录流程，再点击“完成登录”。';

  @override
  String webLoginCookieCaptureFailed(Object error) {
    return '抓取 Cookie 失败：$error';
  }

  @override
  String get embeddedQuarkLoginTitle => '内嵌夸克登录';

  @override
  String get actionCompleteLogin => '完成登录';

  @override
  String get webLoginPageLoaded => '页面已加载。请完成夸克登录流程，然后点击“完成登录”。';

  @override
  String webLoginLoadFailed(Object error) {
    return '网页登录加载失败：$error';
  }

  @override
  String get navSend => '发送';

  @override
  String get navMailbox => '收件箱';

  @override
  String get navTransfers => '传输';

  @override
  String get navSettings => '设置';

  @override
  String get noPeerDevicesTitle => '还没有可用设备';

  @override
  String get noPeerDevicesBody => '目前没有其他设备可用。请先在另一台设备上打开 QuarkDrop 并登录。';

  @override
  String get sendTargetLabel => '发送目标';

  @override
  String get actionSelect => '选择';

  @override
  String get noTransfersTitle => '暂无传输';

  @override
  String get noTransfersBody => '符合当前筛选条件的任务会显示在这里。';

  @override
  String get noTransferHistoryTitle => '还没有传输记录';

  @override
  String get noTransferHistoryBody => '发送文件或接收中转任务后，传输队列会显示在这里。';

  @override
  String get transfersTitle => '传输';

  @override
  String get transfersSubtitle => '上传和下载历史。';

  @override
  String get actionClearCompleted => '清除已完成';

  @override
  String tabPending(Object count) {
    return '未完成（$count）';
  }

  @override
  String tabSendQueuePending(Object count) {
    return '发送（$count）';
  }

  @override
  String tabReceiveQueueCompleted(Object count) {
    return '已接收（$count）';
  }

  @override
  String tabCompleted(Object count) {
    return '已完成（$count）';
  }

  @override
  String get selectTransferTitle => '选择一个传输';

  @override
  String get selectTransferBody => '从队列中选择一项，以查看其状态和可用操作。';

  @override
  String get selectedTransferTitle => '已选传输';

  @override
  String get selectedTransferSubtitle => '当前状态、方向和恢复操作。';

  @override
  String get sendJobLabel => '发送任务';

  @override
  String get receiveJobLabel => '接收任务';

  @override
  String get actionResumeTransfer => '恢复传输';

  @override
  String get actionDeleteRemoteJob => '删除远端任务';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSubtitle => '设备、存储和退出登录。';

  @override
  String get downloadFolderChooseBeforeReceiving => '接收前先选择一个文件夹';

  @override
  String get latestErrorTitle => '最近错误';

  @override
  String get directionSend => '发送';

  @override
  String get directionReceive => '接收';

  @override
  String accountLabel(Object authSource) {
    return '账号：$authSource';
  }

  @override
  String get errorNewPasswordEmpty => '新密码不能为空。';

  @override
  String get cloudPasswordCardTitle => '云密码';

  @override
  String get cloudPasswordCardSubtitle => '修改云密码。所有设备密钥都会重新加密。';

  @override
  String get currentPasswordLabel => '当前密码';

  @override
  String get confirmNewPasswordLabel => '确认新密码';

  @override
  String get actionCancel => '取消';

  @override
  String get actionChangePassword => '修改密码';

  @override
  String get cloudPasswordUpdated => '云密码已更新。';

  @override
  String get rememberPasswordTitle => '记住密码';

  @override
  String get rememberPasswordEnabled => '设备密钥已保存，已启用自动解锁。';

  @override
  String get rememberPasswordDisabled => '保存设备密钥，这样下次启动时无需再次输入密码。';

  @override
  String get savedPasswordEnabled => '密码已保存。应用将在下次启动时自动解锁。';

  @override
  String get savedPasswordCleared => '已清除保存的密码。';

  @override
  String genericFailed(Object error) {
    return '失败：$error';
  }

  @override
  String get launchAtStartupTitle => '开机启动';

  @override
  String get launchAtStartupUnavailable => '当前构建尚未接好该平台集成。';

  @override
  String get launchAtStartupEnabled => '登录系统后，应用会自动启动。';

  @override
  String get launchAtStartupDisabled => '启用后，应用会在系统启动时自动启动。';

  @override
  String get openDataFolderTitle => '打开数据文件夹';

  @override
  String get openDataFolderSubtitle => '在文件管理器中打开应用配置目录。（仅调试模式）';

  @override
  String failedOpenDataFolder(Object error) {
    return '打开数据文件夹失败：$error';
  }

  @override
  String get backgroundTitle => '后台';

  @override
  String get backgroundBatteryDisabled => '已关闭电池优化，应用可以在后台运行。';

  @override
  String get backgroundBatteryEnabled => '关闭电池优化，避免后台传输被中断。';

  @override
  String get actionDisableBatteryOptimization => '关闭电池优化';

  @override
  String get actionOpenAppSettings => '打开应用设置';

  @override
  String get signOutTitle => '退出登录';

  @override
  String get signOutSubtitle => '移除邮箱并清除已保存会话。';

  @override
  String get signOutConfirmBody => '所有本地传输任务都会被移除。';

  @override
  String get signOutDeleteCloudFolder => '删除云端文件夹和本地任务列表';

  @override
  String get signOutDeleteCloudHint => '其他设备将无法再向当前设备发送文件。';

  @override
  String get signOutKeepCloudHint => '在重新登录并绑定之前，此账号将不会接收文件。';

  @override
  String get downloadFolderTitle => '下载文件夹';

  @override
  String get actionChooseFolder => '选择文件夹';

  @override
  String get actionUseDefault => '使用默认';

  @override
  String get languageTitle => '语言';

  @override
  String get languageFollowingSystem => '跟随系统语言。';

  @override
  String get languageFollowSystemOption => '跟随系统';

  @override
  String get languageEnglishUsOption => '英语';

  @override
  String get languageSimplifiedChineseOption => '简体中文';

  @override
  String get languageTraditionalChineseOption => '繁體中文';

  @override
  String get languageJapaneseOption => '日语';

  @override
  String get languageKoreanOption => '韩语';

  @override
  String get stagePreparing => '准备中';

  @override
  String get stageUploading => '上传中';

  @override
  String get stageManifest => '清单';

  @override
  String get stageCommit => '提交';

  @override
  String get stageDownloading => '下载中';

  @override
  String get stageVerifying => '校验中';

  @override
  String get stageCleanup => '清理中';

  @override
  String get stageFailed => '失败';

  @override
  String get stageDone => '完成';

  @override
  String get transferFailedWaitingRecovery => '传输失败，等待恢复。';

  @override
  String get transferCompletedSuccessfully => '传输已成功完成。';

  @override
  String transferPercentComplete(Object percent) {
    return '已完成 $percent%';
  }

  @override
  String get transferNeedsAttention => '需要处理';

  @override
  String get transferCompleted => '已完成';

  @override
  String get transferActive => '进行中';

  @override
  String get mailboxPollIntervalTitle => '收件箱轮询间隔';

  @override
  String mailboxPollIntervalSubtitle(Object seconds) {
    return '$seconds 秒检查一次新文件。';
  }

  @override
  String secondsShort(Object seconds) {
    return '$seconds 秒';
  }

  @override
  String get autoReceiveFilesTitle => '自动接收文件';

  @override
  String get autoReceiveFilesSubtitle => '自动将收到的文件下载到默认下载目录。';

  @override
  String get autoNavigateTransfersTitle => '自动跳转到传输页';

  @override
  String get autoNavigateTransfersSubtitle => '发送或接收完成后，自动切换到传输页面。';

  @override
  String get keepScreenOnTitle => '传输时保持屏幕常亮';

  @override
  String get keepScreenOnSubtitle => '发送或接收文件时，防止屏幕自动熄灭。';

  @override
  String mailboxSelectedCount(Object count) {
    return '已选择 $count 项';
  }

  @override
  String mailboxItemsCount(Object count) {
    return '收件箱中有 $count 项';
  }

  @override
  String get actionReceive => '接收';

  @override
  String actionReceiveCount(Object count) {
    return '接收 $count 项';
  }

  @override
  String get mailboxEmptyTitle => '收件箱中没有中转任务';

  @override
  String get mailboxEmptyBody => '其他设备发送加密任务后，会显示在这里。';

  @override
  String mailboxFromSender(Object sender, Object sizeLabel) {
    return '来自 $sender · $sizeLabel';
  }

  @override
  String get sendComposerChooseDevice => '先在下方选择设备，然后开始构建发送批次。';

  @override
  String sendComposerReadyToSend(Object target) {
    return '已准备好发送到 $target。';
  }

  @override
  String get actionAddFiles => '添加文件';

  @override
  String get actionAddFolder => '添加文件夹';

  @override
  String get actionAddPhotos => '添加照片';

  @override
  String get actionClearBatch => '清空批次';

  @override
  String get actionSendBatch => '发送批次';

  @override
  String actionSendItemCount(Object count) {
    return '发送 $count 项';
  }

  @override
  String get sendComposerEmpty => '还没有添加文件或文件夹。';

  @override
  String get actionUseThisFolder => '使用此文件夹';

  @override
  String get actionShowWindow => '显示窗口';

  @override
  String get actionQuit => '退出';

  @override
  String get actionAdd => '添加';

  @override
  String get actionDownloadHere => '下载到此处';

  @override
  String get errorPasteQuarkCookie => '继续之前请先粘贴夸克 Cookie。';

  @override
  String get errorDeviceNameEmpty => '设备名称不能为空。';

  @override
  String statusSavedDeviceName(Object name) {
    return '已将设备名称保存为 `$name`。';
  }

  @override
  String statusDefaultDownloadFolderSet(Object path) {
    return '默认下载文件夹已设置为 `$path`。';
  }

  @override
  String get statusClearedSavedDownloadFolder => '已清除保存的下载文件夹。';

  @override
  String get statusLanguageFollowsSystem => '语言将跟随系统设置。';

  @override
  String get statusLanguageSaved => '语言偏好已保存。';

  @override
  String get errorChooseTargetDevice => '发送前请先选择目标设备。';

  @override
  String get errorAddItemsBeforeTransfer => '开始传输前请先添加一个或多个文件或文件夹。';

  @override
  String statusSendingItems(Object count, Object peer) {
    return '正在向 $peer 发送 $count 项...';
  }

  @override
  String statusSendingItem(Object item, Object peer) {
    return '正在向 $peer 发送 `$item`...';
  }

  @override
  String statusQueuedTransferJobs(Object count, Object peer) {
    return '已向 $peer 排队 $count 个传输任务。';
  }

  @override
  String get errorSelectRelayJobsFirst => '请先选择一个或多个中转任务。';

  @override
  String get errorNoReadyRelayJobsSelected => '所选中转任务中没有可接收的项目。';

  @override
  String statusReceivingSelectedJobs(Object count, Object path) {
    return '正在接收到 `$path`，共 $count 项...';
  }

  @override
  String statusReceivingSelectedRelayJobs(Object count) {
    return '正在接收 $count 个中转任务。';
  }

  @override
  String statusSavingInto(Object path) {
    return '正在保存到 `$path`。';
  }

  @override
  String statusReceivedRelayJobs(Object count, Object path) {
    return '已接收到 `$path`，共 $count 个中转任务。';
  }

  @override
  String statusReceivedAndCleanedRelayJobs(Object count) {
    return '已接收 $count 个中转任务，并清理远端中转文件。';
  }

  @override
  String get errorFailedReceivingSelectedRelayJobs => '接收所选中转任务时失败。';

  @override
  String statusResumingTransfer(Object title) {
    return '正在从保存的 JSON 任务状态恢复 `$title`...';
  }

  @override
  String statusResumedTransfer(Object jobId, Object title) {
    return '已成功恢复 `$title`。任务 `$jobId` 已从保存状态继续。';
  }

  @override
  String statusClearedCompletedTransfers(Object count) {
    return '已清除 $count 条已完成传输记录。';
  }

  @override
  String statusDeletingRemoteTransferJob(Object title) {
    return '正在删除远端传输任务 `$title`...';
  }

  @override
  String statusDeletedRemoteTransferJob(Object title) {
    return '已删除远端传输任务 `$title`，并移除本地历史记录。';
  }

  @override
  String get statusAutoReceiveSavingJob => '自动接收正在保存这个中转任务。';

  @override
  String statusAutoReceiving(Object name, Object sender) {
    return '正在从 $sender 自动接收 `$name`。';
  }

  @override
  String statusAutoReceived(Object name) {
    return '已自动接收 `$name`，并清理远端中转文件。';
  }

  @override
  String errorAutoReceiveFailed(Object error, Object name) {
    return '自动接收 `$name` 失败：$error';
  }

  @override
  String errorAutoReceiveFailedShort(Object name) {
    return '自动接收 `$name` 失败。';
  }

  @override
  String get actionReject => '拒绝';

  @override
  String get maxConcurrentUploadsTitle => '最大同时上传数';

  @override
  String maxConcurrentUploadsSubtitle(Object count) {
    return '同时上传 $count 个文件';
  }

  @override
  String get maxConcurrentDownloadsTitle => '最大同时下载数';

  @override
  String maxConcurrentDownloadsSubtitle(Object count) {
    return '同时下载 $count 个文件';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appTitle => 'QuarkDrop';

  @override
  String get setupDeviceTitle => '設定此裝置';

  @override
  String get setupDeviceSubtitle => '為此裝置命名，並選擇加入方式。';

  @override
  String get deviceNameTitle => '裝置名稱';

  @override
  String get deviceNameSubtitle => '此名稱會顯示給其他裝置。';

  @override
  String get deviceNameFieldLabel => '裝置名稱';

  @override
  String get existingDevicesTitle => '現有裝置';

  @override
  String get existingDevicesSubtitle => '我們在你的雲端中找到裝置資料夾。你可以綁定現有裝置，或繼續建立新裝置。';

  @override
  String get actionBind => '綁定';

  @override
  String get actionContinueAsNewDevice => '作為新裝置繼續';

  @override
  String get errorPasswordEmpty => '密碼不能為空。';

  @override
  String get errorPasswordsDoNotMatch => '兩次輸入的密碼不一致。';

  @override
  String get setCloudPasswordTitle => '設定雲端密碼';

  @override
  String get verifyCloudPasswordTitle => '驗證雲端密碼';

  @override
  String get setCloudPasswordSubtitle => '設定一個雲端密碼來加密你的裝置金鑰。';

  @override
  String get verifyCloudPasswordSubtitle => '輸入雲端密碼以解鎖目前裝置。';

  @override
  String get newPasswordLabel => '新密碼';

  @override
  String get cloudPasswordLabel => '雲端密碼';

  @override
  String get confirmPasswordLabel => '確認密碼';

  @override
  String get rememberPasswordOnDevice => '在此裝置記住密碼';

  @override
  String get actionSetPassword => '設定密碼';

  @override
  String get actionVerify => '驗證';

  @override
  String get preparingQuarkDropTitle => '正在準備 QuarkDrop';

  @override
  String get preparingQuarkDropSubtitle => '正在初始化加密中繼工作區。';

  @override
  String get loginSubtitle => '使用夸克帳號登入後繼續。';

  @override
  String get actionUseBrowserLogin => '使用瀏覽器登入';

  @override
  String get actionUseCookieLogin => '使用 Cookie 登入';

  @override
  String get quarkCookieLabel => '夸克 Cookie';

  @override
  String get actionPaste => '貼上';

  @override
  String get actionValidating => '驗證中...';

  @override
  String get actionSignIn => '登入';

  @override
  String get webLoginInitialStatus => '登入夸克後，點擊「完成登入」匯入 Cookie。';

  @override
  String get webLoginFreshSessionReady => '新的登入工作階段已準備好。登入夸克後，點擊「完成登入」。';

  @override
  String webLoginResetFailed(Object error) {
    return '重設內嵌瀏覽器工作階段失敗：$error';
  }

  @override
  String get webLoginImportingCookies => '正在從內嵌瀏覽器匯入夸克 Cookie...';

  @override
  String get webLoginNoValidatedSession => '尚未取得可用的夸克工作階段。請先完成登入流程，再點擊「完成登入」。';

  @override
  String webLoginCookieCaptureFailed(Object error) {
    return '擷取 Cookie 失敗：$error';
  }

  @override
  String get embeddedQuarkLoginTitle => '內嵌夸克登入';

  @override
  String get actionCompleteLogin => '完成登入';

  @override
  String get webLoginPageLoaded => '頁面已載入。請完成夸克登入流程，然後點擊「完成登入」。';

  @override
  String webLoginLoadFailed(Object error) {
    return '網頁登入載入失敗：$error';
  }

  @override
  String get navSend => '傳送';

  @override
  String get navMailbox => '收件匣';

  @override
  String get navTransfers => '傳輸';

  @override
  String get navSettings => '設定';

  @override
  String get noPeerDevicesTitle => '還沒有可用裝置';

  @override
  String get noPeerDevicesBody => '目前沒有其他裝置可用。請先在另一台裝置上開啟 QuarkDrop 並登入。';

  @override
  String get sendTargetLabel => '傳送目標';

  @override
  String get actionSelect => '選擇';

  @override
  String get noTransfersTitle => '尚無傳輸';

  @override
  String get noTransfersBody => '符合目前篩選條件的任務會顯示在這裡。';

  @override
  String get noTransferHistoryTitle => '還沒有傳輸記錄';

  @override
  String get noTransferHistoryBody => '傳送檔案或接收中繼任務後，傳輸佇列會顯示在這裡。';

  @override
  String get transfersTitle => '傳輸';

  @override
  String get transfersSubtitle => '上傳與下載歷史。';

  @override
  String get actionClearCompleted => '清除已完成';

  @override
  String tabPending(Object count) {
    return '未完成（$count）';
  }

  @override
  String tabSendQueuePending(Object count) {
    return '傳送（$count）';
  }

  @override
  String tabReceiveQueueCompleted(Object count) {
    return '已接收（$count）';
  }

  @override
  String tabCompleted(Object count) {
    return '已完成（$count）';
  }

  @override
  String get selectTransferTitle => '選擇一個傳輸';

  @override
  String get selectTransferBody => '從佇列中選擇一列，以查看其狀態與可用操作。';

  @override
  String get selectedTransferTitle => '已選傳輸';

  @override
  String get selectedTransferSubtitle => '目前狀態、方向與恢復操作。';

  @override
  String get sendJobLabel => '傳送任務';

  @override
  String get receiveJobLabel => '接收任務';

  @override
  String get actionResumeTransfer => '恢復傳輸';

  @override
  String get actionDeleteRemoteJob => '刪除遠端任務';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSubtitle => '裝置、儲存與登出。';

  @override
  String get downloadFolderChooseBeforeReceiving => '接收前先選擇一個資料夾';

  @override
  String get latestErrorTitle => '最近錯誤';

  @override
  String get directionSend => '傳送';

  @override
  String get directionReceive => '接收';

  @override
  String accountLabel(Object authSource) {
    return '帳號：$authSource';
  }

  @override
  String get errorNewPasswordEmpty => '新密碼不能為空。';

  @override
  String get cloudPasswordCardTitle => '雲端密碼';

  @override
  String get cloudPasswordCardSubtitle => '修改雲端密碼。所有裝置金鑰都會重新加密。';

  @override
  String get currentPasswordLabel => '目前密碼';

  @override
  String get confirmNewPasswordLabel => '確認新密碼';

  @override
  String get actionCancel => '取消';

  @override
  String get actionChangePassword => '修改密碼';

  @override
  String get cloudPasswordUpdated => '雲端密碼已更新。';

  @override
  String get rememberPasswordTitle => '記住密碼';

  @override
  String get rememberPasswordEnabled => '裝置金鑰已儲存，已啟用自動解鎖。';

  @override
  String get rememberPasswordDisabled => '儲存裝置金鑰，下次啟動時就不需要再次輸入密碼。';

  @override
  String get savedPasswordEnabled => '密碼已儲存。應用程式將在下次啟動時自動解鎖。';

  @override
  String get savedPasswordCleared => '已清除儲存的密碼。';

  @override
  String genericFailed(Object error) {
    return '失敗：$error';
  }

  @override
  String get launchAtStartupTitle => '開機啟動';

  @override
  String get launchAtStartupUnavailable => '目前版本尚未接好這個平台整合。';

  @override
  String get launchAtStartupEnabled => '登入系統後，應用程式會自動啟動。';

  @override
  String get launchAtStartupDisabled => '啟用後，應用程式會在系統啟動時自動啟動。';

  @override
  String get openDataFolderTitle => '開啟資料資料夾';

  @override
  String get openDataFolderSubtitle => '在檔案管理器中開啟應用程式設定目錄。（僅除錯模式）';

  @override
  String failedOpenDataFolder(Object error) {
    return '開啟資料資料夾失敗：$error';
  }

  @override
  String get backgroundTitle => '背景';

  @override
  String get backgroundBatteryDisabled => '已停用電池最佳化，應用程式可以在背景執行。';

  @override
  String get backgroundBatteryEnabled => '停用電池最佳化，避免背景傳輸被中斷。';

  @override
  String get actionDisableBatteryOptimization => '停用電池最佳化';

  @override
  String get actionOpenAppSettings => '開啟應用程式設定';

  @override
  String get signOutTitle => '登出';

  @override
  String get signOutSubtitle => '移除信箱並清除已儲存工作階段。';

  @override
  String get signOutConfirmBody => '所有本機傳輸任務都會被移除。';

  @override
  String get signOutDeleteCloudFolder => '刪除雲端資料夾與本機任務清單';

  @override
  String get signOutDeleteCloudHint => '其他裝置將無法再向目前裝置傳送檔案。';

  @override
  String get signOutKeepCloudHint => '在重新登入並綁定之前，此帳號將不會接收檔案。';

  @override
  String get downloadFolderTitle => '下載資料夾';

  @override
  String get actionChooseFolder => '選擇資料夾';

  @override
  String get actionUseDefault => '使用預設值';

  @override
  String get languageTitle => '語言';

  @override
  String get languageFollowingSystem => '跟隨系統語言。';

  @override
  String get languageFollowSystemOption => '跟隨系統';

  @override
  String get languageEnglishUsOption => '英語';

  @override
  String get languageSimplifiedChineseOption => '簡體中文';

  @override
  String get languageTraditionalChineseOption => '繁體中文';

  @override
  String get languageJapaneseOption => '日語';

  @override
  String get languageKoreanOption => '韓語';

  @override
  String get stagePreparing => '準備中';

  @override
  String get stageUploading => '上傳中';

  @override
  String get stageManifest => '清單';

  @override
  String get stageCommit => '提交';

  @override
  String get stageDownloading => '下載中';

  @override
  String get stageVerifying => '驗證中';

  @override
  String get stageCleanup => '清理中';

  @override
  String get stageFailed => '失敗';

  @override
  String get stageDone => '完成';

  @override
  String get transferFailedWaitingRecovery => '傳輸失敗，等待恢復。';

  @override
  String get transferCompletedSuccessfully => '傳輸已成功完成。';

  @override
  String transferPercentComplete(Object percent) {
    return '已完成 $percent%';
  }

  @override
  String get transferNeedsAttention => '需要處理';

  @override
  String get transferCompleted => '已完成';

  @override
  String get transferActive => '進行中';

  @override
  String get mailboxPollIntervalTitle => '收件匣輪詢間隔';

  @override
  String mailboxPollIntervalSubtitle(Object seconds) {
    return '每 $seconds 秒檢查一次新檔案。';
  }

  @override
  String secondsShort(Object seconds) {
    return '$seconds 秒';
  }

  @override
  String get autoReceiveFilesTitle => '自動接收檔案';

  @override
  String get autoReceiveFilesSubtitle => '自動將收到的檔案下載到預設下載目錄。';

  @override
  String get autoNavigateTransfersTitle => '自動跳轉到傳輸頁';

  @override
  String get autoNavigateTransfersSubtitle => '傳送或接收後，自動切換到傳輸頁面。';

  @override
  String get keepScreenOnTitle => '傳輸時保持螢幕常亮';

  @override
  String get keepScreenOnSubtitle => '傳送或接收檔案時，防止螢幕自動關閉。';

  @override
  String mailboxSelectedCount(Object count) {
    return '已選擇 $count 項';
  }

  @override
  String mailboxItemsCount(Object count) {
    return '收件匣中有 $count 項';
  }

  @override
  String get actionReceive => '接收';

  @override
  String actionReceiveCount(Object count) {
    return '接收 $count 項';
  }

  @override
  String get mailboxEmptyTitle => '收件匣中沒有中繼任務';

  @override
  String get mailboxEmptyBody => '其他裝置傳送加密任務後，會顯示在這裡。';

  @override
  String mailboxFromSender(Object sender, Object sizeLabel) {
    return '來自 $sender · $sizeLabel';
  }

  @override
  String get sendComposerChooseDevice => '先在下方選擇裝置，然後開始建立傳送批次。';

  @override
  String sendComposerReadyToSend(Object target) {
    return '已準備好傳送到 $target。';
  }

  @override
  String get actionAddFiles => '新增檔案';

  @override
  String get actionAddFolder => '新增資料夾';

  @override
  String get actionAddPhotos => '新增照片';

  @override
  String get actionClearBatch => '清空批次';

  @override
  String get actionSendBatch => '傳送批次';

  @override
  String actionSendItemCount(Object count) {
    return '傳送 $count 項';
  }

  @override
  String get sendComposerEmpty => '尚未新增任何檔案或資料夾。';

  @override
  String get actionUseThisFolder => '使用此資料夾';

  @override
  String get actionShowWindow => '顯示視窗';

  @override
  String get actionQuit => '結束';

  @override
  String get actionAdd => '新增';

  @override
  String get actionDownloadHere => '下載到此處';

  @override
  String get errorPasteQuarkCookie => '繼續前請先貼上夸克 Cookie。';

  @override
  String get errorDeviceNameEmpty => '裝置名稱不能為空。';

  @override
  String statusSavedDeviceName(Object name) {
    return '已將裝置名稱儲存為 `$name`。';
  }

  @override
  String statusDefaultDownloadFolderSet(Object path) {
    return '預設下載資料夾已設為 `$path`。';
  }

  @override
  String get statusClearedSavedDownloadFolder => '已清除已儲存的下載資料夾。';

  @override
  String get statusLanguageFollowsSystem => '語言將跟隨系統設定。';

  @override
  String get statusLanguageSaved => '語言偏好已儲存。';

  @override
  String get errorChooseTargetDevice => '傳送前請先選擇目標裝置。';

  @override
  String get errorAddItemsBeforeTransfer => '開始傳輸前請先新增一個或多個檔案或資料夾。';

  @override
  String statusSendingItems(Object count, Object peer) {
    return '正在向 $peer 傳送 $count 項...';
  }

  @override
  String statusSendingItem(Object item, Object peer) {
    return '正在向 $peer 傳送 `$item`...';
  }

  @override
  String statusQueuedTransferJobs(Object count, Object peer) {
    return '已向 $peer 排入 $count 個傳輸任務。';
  }

  @override
  String get errorSelectRelayJobsFirst => '請先選擇一個或多個中繼任務。';

  @override
  String get errorNoReadyRelayJobsSelected => '所選中繼任務中沒有可接收的項目。';

  @override
  String statusReceivingSelectedJobs(Object count, Object path) {
    return '正在接收到 `$path`，共 $count 項...';
  }

  @override
  String statusReceivingSelectedRelayJobs(Object count) {
    return '正在接收 $count 個中繼任務。';
  }

  @override
  String statusSavingInto(Object path) {
    return '正在儲存到 `$path`。';
  }

  @override
  String statusReceivedRelayJobs(Object count, Object path) {
    return '已接收到 `$path`，共 $count 個中繼任務。';
  }

  @override
  String statusReceivedAndCleanedRelayJobs(Object count) {
    return '已接收 $count 個中繼任務，並清理遠端中繼檔案。';
  }

  @override
  String get errorFailedReceivingSelectedRelayJobs => '接收所選中繼任務時失敗。';

  @override
  String statusResumingTransfer(Object title) {
    return '正在從已儲存的 JSON 任務狀態恢復 `$title`...';
  }

  @override
  String statusResumedTransfer(Object jobId, Object title) {
    return '已成功恢復 `$title`。任務 `$jobId` 已從已儲存狀態繼續。';
  }

  @override
  String statusClearedCompletedTransfers(Object count) {
    return '已清除 $count 筆已完成傳輸記錄。';
  }

  @override
  String statusDeletingRemoteTransferJob(Object title) {
    return '正在刪除遠端傳輸任務 `$title`...';
  }

  @override
  String statusDeletedRemoteTransferJob(Object title) {
    return '已刪除遠端傳輸任務 `$title`，並移除本機歷史記錄。';
  }

  @override
  String get statusAutoReceiveSavingJob => '自動接收正在儲存這個中繼任務。';

  @override
  String statusAutoReceiving(Object name, Object sender) {
    return '正在從 $sender 自動接收 `$name`。';
  }

  @override
  String statusAutoReceived(Object name) {
    return '已自動接收 `$name`，並清理遠端中繼檔案。';
  }

  @override
  String errorAutoReceiveFailed(Object error, Object name) {
    return '自動接收 `$name` 失敗：$error';
  }

  @override
  String errorAutoReceiveFailedShort(Object name) {
    return '自動接收 `$name` 失敗。';
  }

  @override
  String get actionReject => '拒絕';

  @override
  String get maxConcurrentUploadsTitle => '最大同時上傳數';

  @override
  String maxConcurrentUploadsSubtitle(Object count) {
    return '同時上傳 $count 個檔案';
  }

  @override
  String get maxConcurrentDownloadsTitle => '最大同時下載數';

  @override
  String maxConcurrentDownloadsSubtitle(Object count) {
    return '同時下載 $count 個檔案';
  }
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'QuarkDrop';

  @override
  String get setupDeviceTitle => '기기 설정';

  @override
  String get setupDeviceSubtitle => '이 기기의 이름을 지정하고 참여 방식을 선택하세요.';

  @override
  String get deviceNameTitle => '기기 이름';

  @override
  String get deviceNameSubtitle => '이 이름은 다른 기기에서 보입니다.';

  @override
  String get deviceNameFieldLabel => '기기 이름';

  @override
  String get existingDevicesTitle => '기존 기기';

  @override
  String get existingDevicesSubtitle =>
      '클라우드에서 기기 폴더를 찾았습니다. 기존 기기에 바인드하거나 새 기기로 계속할 수 있습니다.';

  @override
  String get actionBind => '바인드';

  @override
  String get actionContinueAsNewDevice => '새 기기로 계속';

  @override
  String get errorPasswordEmpty => '비밀번호는 비워둘 수 없습니다.';

  @override
  String get errorPasswordsDoNotMatch => '비밀번호가 일치하지 않습니다.';

  @override
  String get setCloudPasswordTitle => '클라우드 비밀번호 설정';

  @override
  String get verifyCloudPasswordTitle => '클라우드 비밀번호 확인';

  @override
  String get setCloudPasswordSubtitle => '기기 키를 암호화할 클라우드 비밀번호를 설정하세요.';

  @override
  String get verifyCloudPasswordSubtitle => '이 기기를 잠금 해제하려면 클라우드 비밀번호를 입력하세요.';

  @override
  String get newPasswordLabel => '새 비밀번호';

  @override
  String get cloudPasswordLabel => '클라우드 비밀번호';

  @override
  String get confirmPasswordLabel => '비밀번호 확인';

  @override
  String get rememberPasswordOnDevice => '이 기기에 비밀번호 저장';

  @override
  String get actionSetPassword => '비밀번호 설정';

  @override
  String get actionVerify => '확인';

  @override
  String get preparingQuarkDropTitle => 'QuarkDrop 준비 중';

  @override
  String get preparingQuarkDropSubtitle => '암호화 릴레이 작업 공간을 초기화하는 중입니다.';

  @override
  String get loginSubtitle => '계속하려면 Quark 계정으로 로그인하세요.';

  @override
  String get actionUseBrowserLogin => '브라우저 로그인 사용';

  @override
  String get actionUseCookieLogin => 'Cookie 로그인 사용';

  @override
  String get quarkCookieLabel => 'Quark Cookie';

  @override
  String get actionPaste => '붙여넣기';

  @override
  String get actionValidating => '확인 중...';

  @override
  String get actionSignIn => '로그인';

  @override
  String get webLoginInitialStatus =>
      'Quark 에 로그인한 다음 \'로그인 완료\'를 눌러 Cookie 를 가져오세요.';

  @override
  String get webLoginFreshSessionReady =>
      '새 로그인 세션이 준비되었습니다. Quark 에 로그인한 다음 \'로그인 완료\'를 누르세요.';

  @override
  String webLoginResetFailed(Object error) {
    return '내장 브라우저 세션 초기화에 실패했습니다: $error';
  }

  @override
  String get webLoginImportingCookies => '내장 브라우저에서 Quark Cookie 를 가져오는 중...';

  @override
  String get webLoginNoValidatedSession =>
      '아직 유효한 Quark 세션이 없습니다. 로그인 흐름을 완료한 다음 다시 \'로그인 완료\'를 누르세요.';

  @override
  String webLoginCookieCaptureFailed(Object error) {
    return 'Cookie 캡처 실패: $error';
  }

  @override
  String get embeddedQuarkLoginTitle => '내장 Quark 로그인';

  @override
  String get actionCompleteLogin => '로그인 완료';

  @override
  String get webLoginPageLoaded =>
      '페이지가 로드되었습니다. Quark 로그인 흐름을 완료한 다음 \'로그인 완료\'를 누르세요.';

  @override
  String webLoginLoadFailed(Object error) {
    return '웹 로그인 로드 실패: $error';
  }

  @override
  String get navSend => '보내기';

  @override
  String get navMailbox => '메일박스';

  @override
  String get navTransfers => '전송';

  @override
  String get navSettings => '설정';

  @override
  String get noPeerDevicesTitle => '사용 가능한 기기가 없습니다';

  @override
  String get noPeerDevicesBody =>
      '아직 다른 기기를 사용할 수 없습니다. 다른 기기에서 QuarkDrop 을 열고 먼저 로그인하세요.';

  @override
  String get sendTargetLabel => '전송 대상';

  @override
  String get actionSelect => '선택';

  @override
  String get noTransfersTitle => '전송 없음';

  @override
  String get noTransfersBody => '현재 필터와 일치하는 작업이 여기에 표시됩니다.';

  @override
  String get noTransferHistoryTitle => '전송 기록이 없습니다';

  @override
  String get noTransferHistoryBody =>
      '파일을 보내거나 메일박스 작업을 수신하면 전송 대기열이 여기에 표시됩니다.';

  @override
  String get transfersTitle => '전송';

  @override
  String get transfersSubtitle => '업로드 및 다운로드 기록.';

  @override
  String get actionClearCompleted => '완료 항목 지우기';

  @override
  String tabAll(Object count) {
    return '전체 ($count)';
  }

  @override
  String tabUpload(Object count) {
    return '업로드 ($count)';
  }

  @override
  String tabDownload(Object count) {
    return '다운로드 ($count)';
  }

  @override
  String get selectTransferTitle => '전송 선택';

  @override
  String get selectTransferBody => '대기열에서 항목을 선택하면 상태와 가능한 작업을 볼 수 있습니다.';

  @override
  String get selectedTransferTitle => '선택된 전송';

  @override
  String get selectedTransferSubtitle => '현재 상태, 방향 및 복구 작업.';

  @override
  String get sendJobLabel => '보내기 작업';

  @override
  String get receiveJobLabel => '받기 작업';

  @override
  String get actionResumeTransfer => '전송 재개';

  @override
  String get actionDeleteRemoteJob => '원격 작업 삭제';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsSubtitle => '기기, 저장소 및 로그아웃.';

  @override
  String get downloadFolderChooseBeforeReceiving => '수신 전에 폴더를 선택하세요';

  @override
  String get latestErrorTitle => '최근 오류';

  @override
  String get directionSend => '보내기';

  @override
  String get directionReceive => '받기';

  @override
  String accountLabel(Object authSource) {
    return '계정: $authSource';
  }

  @override
  String get errorNewPasswordEmpty => '새 비밀번호는 비워둘 수 없습니다.';

  @override
  String get cloudPasswordCardTitle => '클라우드 비밀번호';

  @override
  String get cloudPasswordCardSubtitle =>
      '클라우드 비밀번호를 변경합니다. 모든 기기 키가 다시 암호화됩니다.';

  @override
  String get currentPasswordLabel => '현재 비밀번호';

  @override
  String get confirmNewPasswordLabel => '새 비밀번호 확인';

  @override
  String get actionCancel => '취소';

  @override
  String get actionChangePassword => '비밀번호 변경';

  @override
  String get cloudPasswordUpdated => '클라우드 비밀번호가 업데이트되었습니다.';

  @override
  String get rememberPasswordTitle => '비밀번호 기억';

  @override
  String get rememberPasswordEnabled => '기기 키가 저장되어 자동 잠금 해제가 활성화되었습니다.';

  @override
  String get rememberPasswordDisabled => '다음 실행 시 비밀번호 입력이 필요 없도록 기기 키를 저장합니다.';

  @override
  String get savedPasswordEnabled => '비밀번호가 저장되었습니다. 다음 실행 시 자동 잠금 해제됩니다.';

  @override
  String get savedPasswordCleared => '저장된 비밀번호를 지웠습니다.';

  @override
  String genericFailed(Object error) {
    return '실패: $error';
  }

  @override
  String get launchAtStartupTitle => '시작 시 실행';

  @override
  String get launchAtStartupUnavailable => '현재 빌드에서는 이 플랫폼 연동이 아직 연결되지 않았습니다.';

  @override
  String get launchAtStartupEnabled => '로그인하면 앱이 자동으로 시작됩니다.';

  @override
  String get launchAtStartupDisabled => '활성화하면 시스템 부팅 시 앱이 자동으로 시작됩니다.';

  @override
  String get openDataFolderTitle => '데이터 폴더 열기';

  @override
  String get openDataFolderSubtitle => '파일 관리자에서 앱 설정 디렉터리를 엽니다. (디버그 전용)';

  @override
  String failedOpenDataFolder(Object error) {
    return '데이터 폴더 열기 실패: $error';
  }

  @override
  String get backgroundTitle => '백그라운드';

  @override
  String get backgroundBatteryDisabled =>
      '배터리 최적화가 비활성화되었습니다. 앱이 백그라운드에서 실행될 수 있습니다.';

  @override
  String get backgroundBatteryEnabled => '백그라운드 전송이 중단되지 않도록 배터리 최적화를 비활성화하세요.';

  @override
  String get actionDisableBatteryOptimization => '배터리 최적화 비활성화';

  @override
  String get actionOpenAppSettings => '앱 설정 열기';

  @override
  String get signOutTitle => '로그아웃';

  @override
  String get signOutSubtitle => '메일박스를 제거하고 저장된 세션을 지웁니다.';

  @override
  String get signOutConfirmBody => '모든 로컬 전송 작업이 제거됩니다.';

  @override
  String get signOutDeleteCloudFolder => '클라우드 폴더와 로컬 작업 목록 삭제';

  @override
  String get signOutDeleteCloudHint => '다른 기기에서 현재 기기로 더 이상 파일을 보낼 수 없습니다.';

  @override
  String get signOutKeepCloudHint => '다시 로그인하고 바인드하기 전까지 이 계정은 파일을 수신하지 않습니다.';

  @override
  String get downloadFolderTitle => '다운로드 폴더';

  @override
  String get actionChooseFolder => '폴더 선택';

  @override
  String get actionUseDefault => '기본값 사용';

  @override
  String get languageTitle => '언어';

  @override
  String get languageFollowingSystem => '시스템 언어를 따릅니다.';

  @override
  String get languageFollowSystemOption => '시스템 따르기';

  @override
  String get languageEnglishUsOption => '영어';

  @override
  String get languageSimplifiedChineseOption => '중국어 간체';

  @override
  String get languageTraditionalChineseOption => '중국어 번체';

  @override
  String get languageJapaneseOption => '일본어';

  @override
  String get languageKoreanOption => '한국어';

  @override
  String get stagePreparing => '준비 중';

  @override
  String get stageUploading => '업로드 중';

  @override
  String get stageManifest => '매니페스트';

  @override
  String get stageCommit => '커밋';

  @override
  String get stageDownloading => '다운로드 중';

  @override
  String get stageVerifying => '검증 중';

  @override
  String get stageCleanup => '정리 중';

  @override
  String get stageFailed => '실패';

  @override
  String get stageDone => '완료';

  @override
  String get transferFailedWaitingRecovery => '전송이 실패했고 복구를 기다리고 있습니다.';

  @override
  String get transferCompletedSuccessfully => '전송이 성공적으로 완료되었습니다.';

  @override
  String transferPercentComplete(Object percent) {
    return '$percent% 완료';
  }

  @override
  String get transferNeedsAttention => '확인 필요';

  @override
  String get transferCompleted => '완료됨';

  @override
  String get transferActive => '진행 중';

  @override
  String get mailboxPollIntervalTitle => '메일박스 확인 주기';

  @override
  String mailboxPollIntervalSubtitle(Object seconds) {
    return '$seconds초마다 새 파일을 확인합니다.';
  }

  @override
  String secondsShort(Object seconds) {
    return '$seconds초';
  }

  @override
  String get autoReceiveFilesTitle => '파일 자동 수신';

  @override
  String get autoReceiveFilesSubtitle => '수신 파일을 기본 다운로드 디렉터리로 자동 저장합니다.';

  @override
  String get autoNavigateTransfersTitle => '전송 페이지로 자동 이동';

  @override
  String get autoNavigateTransfersSubtitle => '보내기 또는 받기 후 자동으로 전송 페이지로 전환합니다.';

  @override
  String get keepScreenOnTitle => '전송 중 화면 켜두기';

  @override
  String get keepScreenOnSubtitle => '파일을 보내거나 받는 동안 화면이 꺼지지 않도록 합니다.';

  @override
  String mailboxSelectedCount(Object count) {
    return '$count개 선택됨';
  }

  @override
  String mailboxItemsCount(Object count) {
    return '메일박스에 $count개';
  }

  @override
  String get actionReceive => '받기';

  @override
  String actionReceiveCount(Object count) {
    return '$count개 받기';
  }

  @override
  String get mailboxEmptyTitle => '메일박스에 릴레이 작업이 없습니다';

  @override
  String get mailboxEmptyBody => '다른 기기가 암호화된 작업을 보내면 여기에 표시됩니다.';

  @override
  String mailboxFromSender(Object sender, Object sizeLabel) {
    return '$sender에서 - $sizeLabel';
  }

  @override
  String get sendComposerChooseDevice => '아래에서 기기를 선택한 다음 전송 배치를 구성하세요.';

  @override
  String sendComposerReadyToSend(Object target) {
    return '$target(으)로 보낼 준비가 되었습니다.';
  }

  @override
  String get actionAddFiles => '파일 추가';

  @override
  String get actionAddFolder => '폴더 추가';

  @override
  String get actionAddPhotos => '사진 추가';

  @override
  String get actionClearBatch => '배치 비우기';

  @override
  String get actionSendBatch => '배치 보내기';

  @override
  String actionSendItemCount(Object count) {
    return '$count개 보내기';
  }

  @override
  String get sendComposerEmpty => '아직 파일이나 폴더가 추가되지 않았습니다.';

  @override
  String get actionUseThisFolder => '이 폴더 사용';

  @override
  String get actionShowWindow => '창 표시';

  @override
  String get actionQuit => '종료';

  @override
  String get actionAdd => '추가';

  @override
  String get actionDownloadHere => '여기에 다운로드';

  @override
  String get errorPasteQuarkCookie => '계속하기 전에 Quark Cookie 를 붙여넣으세요.';

  @override
  String get errorDeviceNameEmpty => '기기 이름은 비워둘 수 없습니다.';

  @override
  String statusSavedDeviceName(Object name) {
    return '기기 이름을 `$name`(으)로 저장했습니다.';
  }

  @override
  String statusDefaultDownloadFolderSet(Object path) {
    return '기본 다운로드 폴더를 `$path`(으)로 설정했습니다.';
  }

  @override
  String get statusClearedSavedDownloadFolder => '저장된 다운로드 폴더를 지웠습니다.';

  @override
  String get statusLanguageFollowsSystem => '언어가 이제 시스템 설정을 따릅니다.';

  @override
  String get statusLanguageSaved => '언어 설정이 저장되었습니다.';

  @override
  String get errorChooseTargetDevice => '보내기 전에 대상 기기를 선택하세요.';

  @override
  String get errorAddItemsBeforeTransfer =>
      '전송을 시작하기 전에 하나 이상의 파일 또는 폴더를 추가하세요.';

  @override
  String statusSendingItems(Object count, Object peer) {
    return '$peer(으)로 $count개 전송 중...';
  }

  @override
  String statusSendingItem(Object item, Object peer) {
    return '$peer(으)로 `$item` 전송 중...';
  }

  @override
  String statusQueuedTransferJobs(Object count, Object peer) {
    return '$peer에게 전송 작업 $count개를 대기열에 추가했습니다.';
  }

  @override
  String get errorSelectRelayJobsFirst => '먼저 하나 이상의 릴레이 작업을 선택하세요.';

  @override
  String get errorNoReadyRelayJobsSelected => '선택한 릴레이 작업 중 수신 가능한 항목이 없습니다.';

  @override
  String statusReceivingSelectedJobs(Object count, Object path) {
    return '$count개 작업을 `$path`(으)로 수신 중...';
  }

  @override
  String statusReceivingSelectedRelayJobs(Object count) {
    return '선택한 릴레이 작업 $count개를 수신 중입니다.';
  }

  @override
  String statusSavingInto(Object path) {
    return '`$path`에 저장 중.';
  }

  @override
  String statusReceivedRelayJobs(Object count, Object path) {
    return '릴레이 작업 $count개를 `$path`에 수신했습니다.';
  }

  @override
  String statusReceivedAndCleanedRelayJobs(Object count) {
    return '릴레이 작업 $count개를 수신하고 원격 릴레이를 정리했습니다.';
  }

  @override
  String get errorFailedReceivingSelectedRelayJobs => '선택한 릴레이 작업 수신 중 실패했습니다.';

  @override
  String statusResumingTransfer(Object title) {
    return '저장된 JSON 작업 상태에서 `$title` 재개 중...';
  }

  @override
  String statusResumedTransfer(Object jobId, Object title) {
    return '`$title` 재개 성공. 작업 `$jobId`가 저장된 상태에서 진행되었습니다.';
  }

  @override
  String statusClearedCompletedTransfers(Object count) {
    return '완료된 전송 항목 $count개를 지웠습니다.';
  }

  @override
  String statusDeletingRemoteTransferJob(Object title) {
    return '원격 전송 작업 `$title` 삭제 중...';
  }

  @override
  String statusDeletedRemoteTransferJob(Object title) {
    return '원격 전송 작업 `$title`을 삭제하고 로컬 기록도 제거했습니다.';
  }

  @override
  String get statusAutoReceiveSavingJob => '자동 수신이 이 릴레이 작업을 저장하고 있습니다.';

  @override
  String statusAutoReceiving(Object name, Object sender) {
    return '$sender에서 `$name` 자동 수신 중.';
  }

  @override
  String statusAutoReceived(Object name) {
    return '`$name` 자동 수신 완료 및 원격 릴레이 정리 완료.';
  }

  @override
  String errorAutoReceiveFailed(Object error, Object name) {
    return '`$name` 자동 수신 실패: $error';
  }

  @override
  String errorAutoReceiveFailedShort(Object name) {
    return '`$name` 자동 수신 실패.';
  }
}

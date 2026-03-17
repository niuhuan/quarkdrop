part of 'app_store.dart';

extension AppStoreAuth on AppStore {
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
    unawaited(submitManualCookie(loginCookieDraft.value));
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
}

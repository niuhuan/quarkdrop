part of 'app_store.dart';

extension AppStoreSettings on AppStore {
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
      final path = await getDirectoryPath(
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
      _mailboxTimer?.cancel();
      _mailboxTimer = null;
      _checkPolling();
    } catch (error) {
      lastErrorMessage.value = error.toString();
    }
  }

  void setMaxConcurrentUploads(int count) {
    try {
      final saved = rust_api.setMaxConcurrentUploads(count: count);
      maxConcurrentUploads.value = saved;
    } catch (error) {
      lastErrorMessage.value = error.toString();
    }
  }

  void setMaxConcurrentDownloads(int count) {
    try {
      final saved = rust_api.setMaxConcurrentDownloads(count: count);
      maxConcurrentDownloads.value = saved;
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

  void toggleMinimizeToTray(bool enabled) {
    try {
      rust_api.setMinimizeToTray(enabled: enabled);
      minimizeToTray.value = enabled;
      if (!enabled && autoMinimizeOnStart.value) {
        rust_api.setAutoMinimizeOnStart(enabled: false);
        autoMinimizeOnStart.value = false;
      }
    } catch (error) {
      lastErrorMessage.value = error.toString();
    }
  }

  void toggleAutoMinimizeOnStart(bool enabled) {
    try {
      rust_api.setAutoMinimizeOnStart(enabled: enabled);
      autoMinimizeOnStart.value = enabled;
      if (enabled && !minimizeToTray.value) {
        rust_api.setMinimizeToTray(enabled: true);
        minimizeToTray.value = true;
      }
    } catch (error) {
      lastErrorMessage.value = error.toString();
    }
  }

  void setAutoMinimizeDelay(int seconds) {
    try {
      final saved = rust_api.setAutoMinimizeDelaySeconds(seconds: seconds);
      autoMinimizeDelaySeconds.value = saved;
    } catch (error) {
      lastErrorMessage.value = error.toString();
    }
  }

  void setPeerDiscoveryIntervalMinutes(int minutes) {
    try {
      final saved = rust_api.setPeerDiscoveryIntervalMinutes(minutes: minutes);
      peerDiscoveryIntervalMinutes.value = saved;
    } catch (error) {
      lastErrorMessage.value = error.toString();
    }
  }

  void setThemeMode(String mode) {
    try {
      final saved = rust_api.setThemeMode(mode: mode);
      themeMode.value = saved;
    } catch (error) {
      lastErrorMessage.value = error.toString();
    }
  }
}

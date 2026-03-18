part of 'home_shell.dart';

class _SettingsPane extends StatelessWidget {
  const _SettingsPane({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Watch((context) {
      final device = store.deviceSnapshot.value;
      final lastError = store.lastErrorMessage.value;
      final preferredDownloadDir = store.preferredDownloadDir.value;
      final platformPaths = store.platformPaths;
      final downloadStatus = store.downloadDirectoryStatusMessage.value;
      final localeStatus = store.localeStatusMessage.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _PaneTitle(title: l10n.settingsTitle),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (device != null) ...[
                  _DeviceSettingsCard(
                    store: store,
                    deviceName: device.deviceName,
                    deviceId: device.deviceId,
                    authSource: device.authSource,
                  ),
                  const SizedBox(height: 14),
                  ManageDevicesCard(store: store),
                  const SizedBox(height: 14),
                ],
                if (!Platform.isIOS)
                  _DownloadDirectoryCard(
                    store: store,
                    currentPath:
                        preferredDownloadDir ??
                        platformPaths.downloadDir ??
                        l10n.downloadFolderChooseBeforeReceiving,
                    statusMessage: downloadStatus,
                  ),
                if (!Platform.isIOS) const SizedBox(height: 14),
                _ThemeModeCard(store: store),
                const SizedBox(height: 14),
                _LanguageCard(store: store, statusMessage: localeStatus),
                const SizedBox(height: 14),
                _AutoReceiveCard(store: store),
                const SizedBox(height: 14),
                _NavigateAfterTransferCard(store: store),
                const SizedBox(height: 14),
                if (!Platform.isAndroid && !Platform.isIOS) ...[
                  _MinimizeToTrayCard(store: store),
                  const SizedBox(height: 14),
                  _AutoMinimizeCard(store: store),
                  const SizedBox(height: 14),
                ],
                if (Platform.isAndroid || Platform.isIOS) ...[
                  _KeepScreenOnCard(store: store),
                  const SizedBox(height: 14),
                ],
                _PeerDiscoveryCard(store: store),
                const SizedBox(height: 14),
                _PollIntervalCard(store: store),
                const SizedBox(height: 14),
                _ConcurrentUploadsCard(store: store),
                const SizedBox(height: 14),
                _ConcurrentDownloadsCard(store: store),
                const SizedBox(height: 14),
                _PasswordCard(store: store),
                const SizedBox(height: 14),
                const _SavedPasswordCard(),
                const SizedBox(height: 14),
                if (!Platform.isIOS && !Platform.isAndroid) ...[
                  const _AutoStartCard(),
                  const SizedBox(height: 14),
                ],
                if (Platform.isAndroid) ...[
                  const _BackgroundServiceCard(),
                  const SizedBox(height: 14),
                ],
                if (kDebugMode && !Platform.isIOS && !Platform.isAndroid) ...[
                  const _OpenDataFolderCard(),
                  const SizedBox(height: 14),
                ],
                _SignOutCard(store: store),
                if (lastError != null) ...[
                  const SizedBox(height: 14),
                  _InfoCard(
                    title: l10n.latestErrorTitle,
                    body: lastError,
                    icon: Icons.warning_amber_rounded,
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _DeviceSettingsCard extends StatefulWidget {
  const _DeviceSettingsCard({
    required this.store,
    required this.deviceName,
    required this.deviceId,
    required this.authSource,
  });

  final AppStore store;
  final String deviceName;
  final String deviceId;
  final String authSource;

  @override
  State<_DeviceSettingsCard> createState() => _DeviceSettingsCardState();
}

class _DeviceSettingsCardState extends State<_DeviceSettingsCard> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.deviceName);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _DeviceSettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.deviceName != oldWidget.deviceName &&
        widget.deviceName != _controller.text) {
      _controller.text = widget.deviceName;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await widget.store.saveDeviceName(_controller.text);
    if (mounted && widget.store.lastErrorMessage.value == null) {
      setState(() {
        _editing = false;
      });
      _focusNode.unfocus();
    }
  }

  void _startEditing() {
    setState(() {
      _editing = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Watch((context) {
      final saving = widget.store.deviceNameSaving.value;
      return Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.deviceNameTitle,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.accountLabel(widget.authSource),
                style: const TextStyle(color: Color(0xFF5C6A64), fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.deviceIdLabel(widget.deviceId),
                style: const TextStyle(color: Color(0xFF5C6A64), fontSize: 13),
              ),
              const SizedBox(height: 12),
              if (_editing)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        enabled: !saving,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      onPressed: saving ? null : _submit,
                      icon: saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded),
                    ),
                  ],
                )
              else
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _startEditing,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _controller.text,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        const Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: Color(0xFF8A7E6F),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _PasswordCard extends StatefulWidget {
  const _PasswordCard({required this.store});

  final AppStore store;

  @override
  State<_PasswordCard> createState() => _PasswordCardState();
}

class _PasswordCardState extends State<_PasswordCard> {
  bool _editing = false;
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _editing = !_editing;
      _error = null;
      if (!_editing) {
        _oldController.clear();
        _newController.clear();
        _confirmController.clear();
      }
    });
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final newPassword = _newController.text;
    final confirm = _confirmController.text;
    if (newPassword.isEmpty) {
      setState(() => _error = l10n.errorNewPasswordEmpty);
      return;
    }
    if (newPassword != confirm) {
      setState(() => _error = l10n.errorPasswordsDoNotMatch);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.store.changeCloudPassword(_oldController.text, newPassword);
      setState(() {
        _editing = false;
        _oldController.clear();
        _newController.clear();
        _confirmController.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(context.l10n.cloudPasswordUpdated),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            ),
          );
      }
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE7DED0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _saving ? null : _toggle,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.cloudPasswordCardTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    _editing
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF5C6A64),
                  ),
                ],
              ),
              if (!_editing)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.cloudPasswordCardSubtitle,
                    style: const TextStyle(
                      color: Color(0xFF5C6A64),
                      fontSize: 13,
                    ),
                  ),
                ),
              if (_editing) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _oldController,
                  obscureText: true,
                  enabled: !_saving,
                  decoration: InputDecoration(
                    labelText: l10n.currentPasswordLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _newController,
                  obscureText: true,
                  enabled: !_saving,
                  decoration: InputDecoration(
                    labelText: l10n.newPasswordLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _confirmController,
                  obscureText: true,
                  enabled: !_saving,
                  onSubmitted: (_) => _save(),
                  decoration: InputDecoration(
                    labelText: l10n.confirmNewPasswordLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFF9B3D16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : _toggle,
                      child: Text(l10n.actionCancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(l10n.actionChangePassword),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedPasswordCard extends StatefulWidget {
  const _SavedPasswordCard();

  @override
  State<_SavedPasswordCard> createState() => _SavedPasswordCardState();
}

class _SavedPasswordCardState extends State<_SavedPasswordCard> {
  late bool _hasSaved = rust_api.hasSavedKey();

  void _toggle() {
    final l10n = context.l10n;
    try {
      if (_hasSaved) {
        rust_api.clearSavedKey();
      } else {
        rust_api.saveAutoUnlockKey();
      }
      setState(() => _hasSaved = rust_api.hasSavedKey());
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _hasSaved ? l10n.savedPasswordEnabled : l10n.savedPasswordCleared,
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          ),
        );
    } catch (error) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(context.l10n.genericFailed('$error')),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE7DED0)),
      ),
      child: SwitchListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        secondary: const Icon(Icons.key_rounded, size: 22),
        title: Text(
          l10n.rememberPasswordTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          _hasSaved
              ? l10n.rememberPasswordEnabled
              : l10n.rememberPasswordDisabled,
          style: const TextStyle(color: Color(0xFF5C6A64), fontSize: 13),
        ),
        value: _hasSaved,
        onChanged: (_) => _toggle(),
      ),
    );
  }
}

class _AutoStartCard extends StatefulWidget {
  const _AutoStartCard();

  @override
  State<_AutoStartCard> createState() => _AutoStartCardState();
}

class _AutoStartCardState extends State<_AutoStartCard> {
  bool _enabled = startup.autoStartup;
  bool _available = startup.autoStartupAvailable;

  Future<void> _toggle(bool value) async {
    await startup.setAutoStartup(value);
    setState(() {
      _enabled = startup.autoStartup;
      _available = startup.autoStartupAvailable;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE7DED0)),
      ),
      child: SwitchListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        secondary: Icon(_enabled ? Icons.power : Icons.power_off, size: 22),
        title: Text(
          l10n.launchAtStartupTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          !_available
              ? l10n.launchAtStartupUnavailable
              : _enabled
              ? l10n.launchAtStartupEnabled
              : l10n.launchAtStartupDisabled,
          style: const TextStyle(color: Color(0xFF5C6A64), fontSize: 13),
        ),
        value: _enabled,
        onChanged: _available ? _toggle : null,
      ),
    );
  }
}

class _OpenDataFolderCard extends StatelessWidget {
  const _OpenDataFolderCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE7DED0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          try {
            rust_api.openDataFolder();
          } catch (error) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                SnackBar(
                  content: Text(l10n.failedOpenDataFolder('$error')),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                ),
              );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(Icons.folder_open_rounded, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.openDataFolderTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.openDataFolderSubtitle,
                      style: const TextStyle(
                        color: Color(0xFF5C6A64),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.open_in_new_rounded,
                size: 20,
                color: Color(0xFF5C6A64),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackgroundServiceCard extends StatefulWidget {
  const _BackgroundServiceCard();

  @override
  State<_BackgroundServiceCard> createState() => _BackgroundServiceCardState();
}

class _BackgroundServiceCardState extends State<_BackgroundServiceCard> {
  static const _channel = MethodChannel('quarkdrop/background');
  bool _ignoringBattery = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
      if (mounted) {
        setState(() {
          _ignoringBattery = result ?? false;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _requestBatteryOptimization() async {
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
      await Future.delayed(const Duration(seconds: 1));
      await _checkStatus();
    } catch (_) {}
  }

  Future<void> _openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE7DED0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.battery_saver_rounded, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.backgroundTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else ...[
              Text(
                _ignoringBattery
                    ? l10n.backgroundBatteryDisabled
                    : l10n.backgroundBatteryEnabled,
                style: const TextStyle(color: Color(0xFF5C6A64), fontSize: 13),
              ),
              const SizedBox(height: 12),
              if (!_ignoringBattery)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _requestBatteryOptimization,
                    icon: const Icon(Icons.battery_alert_rounded, size: 18),
                    label: Text(l10n.actionDisableBatteryOptimization),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openAppSettings,
                  icon: const Icon(Icons.settings_rounded, size: 18),
                  label: Text(l10n.actionOpenAppSettings),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SignOutCard extends StatelessWidget {
  const _SignOutCard({required this.store});

  final AppStore store;

  void _showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _SignOutConfirmDialog(store: store),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Watch((context) {
      final busy = store.signOutInProgress.value;
      return Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.signOutTitle,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.signOutSubtitle,
                      style: const TextStyle(
                        color: Color(0xFF5C6A64),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: busy ? null : () => _showConfirmDialog(context),
                icon: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_rounded),
                tooltip: l10n.signOutTitle,
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _SignOutConfirmDialog extends StatefulWidget {
  const _SignOutConfirmDialog({required this.store});

  final AppStore store;

  @override
  State<_SignOutConfirmDialog> createState() => _SignOutConfirmDialogState();
}

class _SignOutConfirmDialogState extends State<_SignOutConfirmDialog> {
  bool _deleteRemote = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.signOutTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.signOutConfirmBody),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _deleteRemote = !_deleteRemote),
            child: Row(
              children: [
                Checkbox(
                  value: _deleteRemote,
                  onChanged: (value) =>
                      setState(() => _deleteRemote = value ?? true),
                ),
                Expanded(
                  child: Text(
                    l10n.signOutDeleteCloudFolder,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _deleteRemote
                ? l10n.signOutDeleteCloudHint
                : l10n.signOutKeepCloudHint,
            style: const TextStyle(color: Color(0xFF5C6A64), fontSize: 13),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.store.signOut(deleteRemoteMailbox: _deleteRemote);
          },
          child: Text(l10n.signOutTitle),
        ),
      ],
    );
  }
}

class _DownloadDirectoryCard extends StatelessWidget {
  const _DownloadDirectoryCard({
    required this.store,
    required this.currentPath,
    required this.statusMessage,
  });

  final AppStore store;
  final String currentPath;
  final String? statusMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Watch((context) {
      final saving = store.downloadDirectorySaving.value;
      final hasCustomDir =
          store.preferredDownloadDir.value?.isNotEmpty ?? false;
      return Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.downloadFolderTitle,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        currentPath,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF5C6A64),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.filledTonal(
                    onPressed: saving
                        ? null
                        : () => store.choosePreferredDownloadDirectory(),
                    icon: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.folder_open_rounded),
                    tooltip: l10n.actionChooseFolder,
                  ),
                  if (hasCustomDir)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: IconButton(
                        onPressed: saving
                            ? null
                            : () => store.clearPreferredDownloadDirectory(),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        tooltip: l10n.actionUseDefault,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _ThemeModeCard extends StatelessWidget {
  const _ThemeModeCard({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Watch((context) {
      final String currentCode = store.themeMode.value;
      return Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.themeModeTitle,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _themeModeName(l10n, currentCode),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                initialValue: currentCode,
                onSelected: (code) {
                  store.setThemeMode(code);
                },
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      value: 'system',
                      child: Text(l10n.themeModeSystem),
                    ),
                    PopupMenuItem(
                      value: 'light',
                      child: Text(l10n.themeModeLight),
                    ),
                    PopupMenuItem(
                      value: 'dark',
                      child: Text(l10n.themeModeDark),
                    ),
                  ];
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    l10n.actionSelect,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  String _themeModeName(dynamic l10n, String code) {
    switch (code) {
      case 'light':
        return l10n.themeModeLight;
      case 'dark':
        return l10n.themeModeDark;
      default:
        return l10n.themeModeSystem;
    }
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({required this.store, required this.statusMessage});

  final AppStore store;
  final String? statusMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Watch((context) {
      final selectedCode = store.localePreferenceCode.value;
      return Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.languageTitle,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                selectedCode == null
                    ? l10n.languageFollowingSystem
                    : _labelForLocaleCode(context, selectedCode),
                style: const TextStyle(color: Color(0xFF5C6A64), fontSize: 13),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: selectedCode,
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(),
                  labelText: l10n.languageTitle,
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.languageFollowSystemOption),
                  ),
                  ...supportedAppLocaleOptions.map(
                    (option) => DropdownMenuItem<String?>(
                      value: option.code,
                      child: Text(_labelForLocaleCode(context, option.code)),
                    ),
                  ),
                ],
                onChanged: store.setLocalePreference,
              ),
              if (statusMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  statusMessage!,
                  style: const TextStyle(
                    color: Color(0xFF5C6A64),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  String _labelForLocaleCode(BuildContext context, String code) {
    final l10n = context.l10n;
    switch (code) {
      case 'en':
        return l10n.languageEnglishUsOption;
      case 'zh_Hans':
        return l10n.languageSimplifiedChineseOption;
      case 'zh_Hant':
        return l10n.languageTraditionalChineseOption;
      case 'ja':
        return l10n.languageJapaneseOption;
      case 'ko':
        return l10n.languageKoreanOption;
      default:
        return code;
    }
  }
}

class _PollIntervalCard extends StatefulWidget {
  const _PollIntervalCard({required this.store});

  final AppStore store;

  @override
  State<_PollIntervalCard> createState() => _PollIntervalCardState();
}

class _PollIntervalCardState extends State<_PollIntervalCard> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final seconds = widget.store.pollIntervalSeconds.watch(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _editing = !_editing),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.mailboxPollIntervalTitle,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.mailboxPollIntervalSubtitle(seconds),
                          style: const TextStyle(
                            color: Color(0xFF5C6A64),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _editing
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: const Color(0xFF8A7E6F),
                  ),
                ],
              ),
              if (_editing) ...[
                const SizedBox(height: 8),
                Slider(
                  value: seconds.toDouble(),
                  min: 5,
                  max: 300,
                  divisions: 59,
                  label: l10n.secondsShort(seconds),
                  onChanged: (value) =>
                      widget.store.setPollInterval(value.round()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConcurrentUploadsCard extends StatefulWidget {
  const _ConcurrentUploadsCard({required this.store});

  final AppStore store;

  @override
  State<_ConcurrentUploadsCard> createState() => _ConcurrentUploadsCardState();
}

class _ConcurrentUploadsCardState extends State<_ConcurrentUploadsCard> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final count = widget.store.maxConcurrentUploads.watch(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _editing = !_editing),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.maxConcurrentUploadsTitle,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.maxConcurrentUploadsSubtitle(count),
                          style: const TextStyle(
                            color: Color(0xFF5C6A64),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _editing
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: const Color(0xFF8A7E6F),
                  ),
                ],
              ),
              if (_editing) ...[
                const SizedBox(height: 8),
                Slider(
                  value: count.toDouble(),
                  min: 1,
                  max: 8,
                  divisions: 7,
                  label: '$count',
                  onChanged: (value) =>
                      widget.store.setMaxConcurrentUploads(value.round()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConcurrentDownloadsCard extends StatefulWidget {
  const _ConcurrentDownloadsCard({required this.store});

  final AppStore store;

  @override
  State<_ConcurrentDownloadsCard> createState() =>
      _ConcurrentDownloadsCardState();
}

class _ConcurrentDownloadsCardState extends State<_ConcurrentDownloadsCard> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final count = widget.store.maxConcurrentDownloads.watch(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _editing = !_editing),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.maxConcurrentDownloadsTitle,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.maxConcurrentDownloadsSubtitle(count),
                          style: const TextStyle(
                            color: Color(0xFF5C6A64),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _editing
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: const Color(0xFF8A7E6F),
                  ),
                ],
              ),
              if (_editing) ...[
                const SizedBox(height: 8),
                Slider(
                  value: count.toDouble(),
                  min: 1,
                  max: 8,
                  divisions: 7,
                  label: '$count',
                  onChanged: (value) =>
                      widget.store.setMaxConcurrentDownloads(value.round()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AutoReceiveCard extends StatelessWidget {
  const _AutoReceiveCard({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final enabled = store.autoReceiveEnabled.watch(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: SwitchListTile(
        title: Text(l10n.autoReceiveFilesTitle),
        subtitle: Text(l10n.autoReceiveFilesSubtitle),
        value: enabled,
        onChanged: store.toggleAutoReceive,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _NavigateAfterTransferCard extends StatelessWidget {
  const _NavigateAfterTransferCard({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final enabled = store.navigateAfterTransfer.watch(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: SwitchListTile(
        title: Text(l10n.autoNavigateTransfersTitle),
        subtitle: Text(l10n.autoNavigateTransfersSubtitle),
        value: enabled,
        onChanged: store.toggleNavigateAfterTransfer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _KeepScreenOnCard extends StatelessWidget {
  const _KeepScreenOnCard({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final enabled = store.keepScreenOnDuringTransfer.watch(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: SwitchListTile(
        title: Text(l10n.keepScreenOnTitle),
        subtitle: Text(l10n.keepScreenOnSubtitle),
        value: enabled,
        onChanged: store.toggleKeepScreenOnDuringTransfer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _MinimizeToTrayCard extends StatelessWidget {
  const _MinimizeToTrayCard({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    // using local translations as fallback if arb missed it
    // final title = context.l10n.settingMinimizeToTrayTitle;
    return Watch((context) {
      final l10n = context.l10n;
      final enabled = store.minimizeToTray.value;
      return Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: SwitchListTile(
          value: enabled,
          onChanged: store.toggleMinimizeToTray,
          title: Text(
            l10n.settingMinimizeToTrayTitle,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Text(
            l10n.settingMinimizeToTrayDescription,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      );
    });
  }
}

class _PeerDiscoveryCard extends StatefulWidget {
  const _PeerDiscoveryCard({required this.store});

  final AppStore store;

  @override
  State<_PeerDiscoveryCard> createState() => _PeerDiscoveryCardState();
}

class _AutoMinimizeCard extends StatelessWidget {
  const _AutoMinimizeCard({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final l10n = context.l10n;
      final enabled = store.autoMinimizeOnStart.value;
      final delay = store.autoMinimizeDelaySeconds.value;

      final subtitle = !enabled
          ? l10n.settingAutoMinimizeSubtitleOff
          : delay == 0
              ? l10n.settingAutoMinimizeSubtitleImmediate
              : l10n.settingAutoMinimizeSubtitleDelay(delay);

      return Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          title: Text(
            l10n.settingAutoMinimizeTitle,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
          shape: const Border(),
          collapsedShape: const Border(),
          children: [
            SwitchListTile(
              value: enabled,
              onChanged: store.toggleAutoMinimizeOnStart,
              title: Text(
                l10n.settingAutoMinimizeEnabled,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            if (enabled)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      l10n.settingAutoMinimizeDelay,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${delay}s'),
                    Expanded(
                      child: Slider(
                        value: delay.toDouble(),
                        min: 0,
                        max: 10,
                        divisions: 10,
                        label: delay == 0
                            ? l10n.settingAutoMinimizeSubtitleImmediate
                            : '${delay}s',
                        onChanged: (value) {
                          store.setAutoMinimizeDelay(value.round());
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _PeerDiscoveryCardState extends State<_PeerDiscoveryCard> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final l10n = context.l10n;
      final value = widget.store.peerDiscoveryIntervalMinutes.value;
      return Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            setState(() {
              _editing = !_editing;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.settingPeerDiscoveryTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.settingPeerDiscoveryDescription,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      _editing ? Icons.expand_less : Icons.expand_more,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                if (_editing) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16,
                            ),
                          ),
                          child: Slider(
                            value: value.toDouble(),
                            min: 1,
                            max: 60,
                            divisions: 59,
                            onChanged: (v) {
                              widget.store.setPeerDiscoveryIntervalMinutes(
                                v.round(),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '$value',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}

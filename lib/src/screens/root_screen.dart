import 'package:flutter/material.dart';
import 'package:quarkdrop/src/rust/api/app.dart' as rust_api;
import 'package:quarkdrop/src/screens/home_shell.dart';
import 'package:quarkdrop/src/screens/login_screen.dart';
import 'package:quarkdrop/src/state/app_store.dart';
import 'package:signals_flutter/signals_flutter.dart';

class RootScreen extends StatelessWidget {
  const RootScreen({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      switch (store.bootstrapPhase.value) {
        case BootstrapPhase.booting:
          return const _BootstrapScreen();
        case BootstrapPhase.passwordRequired:
          return _PasswordScreen(store: store);
        case BootstrapPhase.loginRequired:
          return LoginScreen(store: store);
        case BootstrapPhase.cloudDeviceSelection:
          return _CloudDeviceSelectionScreen(store: store);
        case BootstrapPhase.ready:
          return HomeShell(store: store);
      }
    });
  }
}

class _CloudDeviceSelectionScreen extends StatefulWidget {
  const _CloudDeviceSelectionScreen({required this.store});

  final AppStore store;

  @override
  State<_CloudDeviceSelectionScreen> createState() =>
      _CloudDeviceSelectionScreenState();
}

class _CloudDeviceSelectionScreenState
    extends State<_CloudDeviceSelectionScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.store.deviceSnapshot.value?.deviceName ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continueAsNew() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await widget.store.saveDeviceName(name);
    }
    widget.store.skipCloudDeviceSelection();
  }

  Future<void> _bindDevice(String deviceId) async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await widget.store.saveDeviceName(name);
    }
    await widget.store.bindCloudDevice(deviceId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Watch((context) {
              final inProgress = widget.store.loginInProgress.value;
              final error = widget.store.lastErrorMessage.value;
              final peers = widget.store.peerDevices.value;
              final nameField = _DeviceNameField(
                controller: _nameController,
                enabled: !inProgress,
              );
              final deviceList = _DeviceListSection(
                inProgress: inProgress,
                error: error,
                peers: peers,
                onBind: _bindDevice,
                onContinueAsNew: _continueAsNew,
              );
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _OrbMark(),
                  const SizedBox(height: 14),
                  const Text(
                    'Set Up Your Device',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Name this device and choose how to join.',
                    style: TextStyle(color: Color(0xFF54635D)),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 520) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: nameField),
                            const SizedBox(width: 20),
                            Expanded(child: deviceList),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          nameField,
                          const SizedBox(height: 20),
                          deviceList,
                        ],
                      );
                    },
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _DeviceNameField extends StatelessWidget {
  const _DeviceNameField({required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3EB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.devices_rounded, size: 32, color: Color(0xFFB44818)),
          const SizedBox(height: 12),
          const Text(
            'Device Name',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'This name will be visible to other devices.',
            style: TextStyle(color: Color(0xFF5C6A64)),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            enabled: enabled,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Device name',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceListSection extends StatelessWidget {
  const _DeviceListSection({
    required this.inProgress,
    required this.error,
    required this.peers,
    required this.onBind,
    required this.onContinueAsNew,
  });

  final bool inProgress;
  final String? error;
  final List<dynamic> peers;
  final Future<void> Function(String) onBind;
  final VoidCallback onContinueAsNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8DECF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Existing Devices',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'We found device folders in your cloud. Bind to an existing one or continue as new.',
            style: TextStyle(color: Color(0xFF5C6A64)),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEE8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                error!,
                style: const TextStyle(
                  color: Color(0xFF9B3D16),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (inProgress) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ] else ...[
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  for (final device in peers)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.cloud_sync_rounded),
                      title: Text(device.label),
                      subtitle: Text(device.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: FilledButton.tonal(
                        onPressed: () => onBind(device.deviceId),
                        child: const Text('Bind'),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 28),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onContinueAsNew,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Continue as New Device'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PasswordScreen extends StatefulWidget {
  const _PasswordScreen({required this.store});

  final AppStore store;

  @override
  State<_PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<_PasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _submitting = false;
  bool _rememberPassword = false;
  String? _error;

  bool get _isCreating {
    final snapshot = widget.store.deviceSnapshot.value;
    // If there's no snapshot or auth state indicates create, show create mode
    // The passwordRequired phase is reached from NeedCreatePassword or NeedVerifyPassword
    // We check the Rust-side auth state via the last shell snapshot result
    return snapshot?.mailboxStatusLabel == 'Password setup required';
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _error = 'Password cannot be empty.');
      return;
    }
    if (_isCreating && password != _confirmController.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      if (_isCreating) {
        await widget.store.createCloudPassword(password);
      } else {
        await widget.store.verifyCloudPassword(password);
        if (_rememberPassword) {
          rust_api.saveAutoUnlockKey();
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _OrbMark(),
                const SizedBox(height: 14),
                Text(
                  _isCreating ? 'Set Cloud Password' : 'Verify Cloud Password',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isCreating
                      ? 'Set a cloud password to encrypt your device keys.'
                      : 'Enter your cloud password to unlock this device.',
                  style: const TextStyle(color: Color(0xFF54635D)),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  enabled: !_submitting,
                  autofocus: true,
                  onSubmitted: (_) => _isCreating ? null : _submit(),
                  decoration: InputDecoration(
                    labelText: _isCreating ? 'New Password' : 'Cloud Password',
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (_isCreating) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: _confirmController,
                    obscureText: true,
                    enabled: !_submitting,
                    onSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                if (!_isCreating) ...[
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _rememberPassword,
                    onChanged: _submitting
                        ? null
                        : (v) => setState(() => _rememberPassword = v ?? false),
                    title: const Text(
                      'Remember password on this device',
                      style: TextStyle(fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEE8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Color(0xFF9B3D16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isCreating ? 'Set Password' : 'Verify'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFCF5EC), Color(0xFFE4F0EB)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _OrbMark(),
              SizedBox(height: 20),
              Text(
                'Preparing QuarkDrop',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 8),
              Text(
                'Bootstrapping the encrypted relay workspace.',
                style: TextStyle(color: Color(0xFF53635C)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrbMark extends StatelessWidget {
  const _OrbMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF20262A), Color(0xFFCB5C24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCB5C24).withValues(alpha: 0.25),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: const Icon(Icons.sync_alt_rounded, size: 34, color: Colors.white),
    );
  }
}

import 'package:flutter/material.dart';
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

class _CloudDeviceSelectionScreen extends StatelessWidget {
  const _CloudDeviceSelectionScreen({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recover Existing Device?'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'We found existing QuarkDrop device folders in your cloud storage. '
                'Do you want to bind this client to an existing folder, or continue as a new device?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Watch((context) {
                final inProgress = store.loginInProgress.value;
                final error = store.lastErrorMessage.value;
                if (inProgress) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Column(
                  children: [
                    if (error != null) ...[
                      Text(error, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                    ],
                    ...store.peerDevices.value.map((device) {
                      return ListTile(
                        leading: const Icon(Icons.cloud_sync),
                        title: Text(device.label),
                        subtitle: Text(device.subtitle),
                        trailing: ElevatedButton(
                          onPressed: () =>
                              store.bindCloudDevice(device.deviceId),
                          child: const Text('Bind'),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: store.skipCloudDeviceSelection,
                      child: const Text('Continue as New Device'),
                    ),
                  ],
                );
              }),
            ],
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

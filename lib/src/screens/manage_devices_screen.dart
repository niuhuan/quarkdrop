import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:quarkdrop/src/rust/api/app.dart' as rust_api;
import 'package:quarkdrop/src/state/app_store.dart';
import "package:quarkdrop/src/l10n/l10n.dart";
import 'device_mailbox_manage_screen.dart';
import 'garbage_cleanup_screen.dart';

class ManageDevicesScreen extends StatelessWidget {
  const ManageDevicesScreen({super.key, required this.store});

  final AppStore store;

  Future<void> _confirmDeletePeer(
    BuildContext context,
    rust_api.PeerDevice peer,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.actionDeleteDevice),
          content: Text(l10n.actionDeleteDeviceHint),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.actionCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.actionDeleteDevice),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      store.removePeerDevice(peer.deviceId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final peers = store.peerDevices.value;
      final currentDevice = store.deviceSnapshot.value;
      final l10n = context.l10n;
      final busy = store.deviceMaintenanceBusy.value;
      final busyMessage = store.deviceMaintenanceBusyMessage.value;
      final hasActiveTransferJobs = store.hasActiveTransferJobs.value;
      final devices = <_ManageDeviceRow>[
        if (currentDevice != null && currentDevice.mailboxFolderId.isNotEmpty)
          _ManageDeviceRow(
            deviceId: currentDevice.deviceId,
            mailboxFolderId: currentDevice.mailboxFolderId,
            label: currentDevice.deviceName,
            subtitle: l10n.currentDeviceSubtitle,
            isCurrent: true,
          ),
        ...peers.map(
          (peer) => _ManageDeviceRow(
            deviceId: peer.deviceId,
            mailboxFolderId: peer.mailboxFolderId,
            label: peer.label,
            subtitle: peer.subtitle,
            isCurrent: false,
          ),
        ),
      ];

      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.existingDevicesTitle),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                GarbageCleanupScreen(store: store),
                          ),
                        );
                      },
                icon: const Icon(Icons.cleaning_services_outlined),
                label: Text(l10n.actionCleanupAllDevices),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                if (hasActiveTransferJobs)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFFCC80)),
                    ),
                    child: Text(
                      l10n.deviceMaintenanceActiveTransferBody,
                      style: const TextStyle(height: 1.5),
                    ),
                  ),
                Expanded(
                  child: devices.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noPeerDevicesBody,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: devices.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final device = devices[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              title: Text(
                                device.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(device.subtitle),
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  IconButton(
                                    tooltip: l10n.deviceMailboxManageEntry,
                                    color:
                                        Theme.of(context).colorScheme.error,
                                    onPressed: busy
                                        ? null
                                        : () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    DeviceMailboxManageScreen(
                                                      store: store,
                                                      peer: rust_api.PeerDevice(
                                                        deviceId: device.deviceId,
                                                        mailboxFolderId:
                                                            device
                                                                .mailboxFolderId,
                                                        label: device.label,
                                                        subtitle:
                                                            device.subtitle,
                                                      ),
                                                    ),
                                              ),
                                            );
                                          },
                                    icon: const Icon(
                                      Icons.cleaning_services_outlined,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: device.isCurrent
                                        ? l10n.currentDeviceSubtitle
                                        : l10n.actionDeleteDevice,
                                    icon: const Icon(Icons.delete_outline),
                                    color:
                                        Theme.of(context).colorScheme.error,
                                    onPressed: device.isCurrent || busy
                                        ? null
                                        : () => _confirmDeletePeer(
                                              context,
                                              rust_api.PeerDevice(
                                                deviceId: device.deviceId,
                                                mailboxFolderId:
                                                    device.mailboxFolderId,
                                                label: device.label,
                                                subtitle: device.subtitle,
                                              ),
                                            ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
            if (busy)
              ColoredBox(
                color: const Color(0xB3000000),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 14),
                        Flexible(
                          child: Text(
                            busyMessage ??
                                l10n.deviceMaintenanceBusyGarbageCleanup,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _ManageDeviceRow {
  const _ManageDeviceRow({
    required this.deviceId,
    required this.mailboxFolderId,
    required this.label,
    required this.subtitle,
    required this.isCurrent,
  });

  final String deviceId;
  final String mailboxFolderId;
  final String label;
  final String subtitle;
  final bool isCurrent;
}

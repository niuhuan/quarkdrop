import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:quarkdrop/src/rust/api/app.dart' as rust_api;
import 'package:quarkdrop/src/state/app_store.dart';
import "package:quarkdrop/src/l10n/l10n.dart";

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
      final l10n = context.l10n;

      return Scaffold(
        appBar: AppBar(title: Text(l10n.existingDevicesTitle)),
        body: peers.isEmpty
            ? Center(
                child: Text(
                  l10n.noPeerDevicesBody,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: peers.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final peer = peers[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    title: Text(
                      peer.label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(peer.subtitle),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Theme.of(context).colorScheme.error,
                      onPressed: () => _confirmDeletePeer(context, peer),
                    ),
                  );
                },
              ),
      );
    });
  }
}

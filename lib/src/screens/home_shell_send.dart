part of 'home_shell.dart';

class _SendPane extends StatelessWidget {
  const _SendPane({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final peers = store.peerDevices.value;
      final selectedPeerId = store.selectedPeerDeviceId.value;
      final sendInProgress = store.sendInProgress.value;
      final pendingItems = store.pendingSendItems.value;
      String? selectedPeerLabel;
      for (final peer in peers) {
        if (peer.deviceId == selectedPeerId) {
          selectedPeerLabel = peer.label;
          break;
        }
      }
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SendComposerCard(
            pendingItems: pendingItems,
            sendInProgress: sendInProgress,
            selectedPeerLabel: selectedPeerLabel,
            onAddFiles: store.addFilesToSendQueue,
            onAddFolder: Platform.isIOS ? null : store.addDirectoryToSendQueue,
            onAddPhotos:
                (Platform.isIOS || Platform.isAndroid || Platform.isMacOS)
                ? store.addPhotosToSendQueue
                : null,
            onClear: store.clearPendingSendItems,
            onRemoveItem: store.removePendingSendItem,
            onSend: store.sendPendingSelection,
          ),
          const SizedBox(height: 18),
          if (peers.isEmpty)
            _EmptyPaneMessage(
              title: context.l10n.noPeerDevicesTitle,
              body: context.l10n.noPeerDevicesBody,
            )
          else
            ...peers.map((peer) {
              final selected = peer.deviceId == selectedPeerId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => store.selectPeerDevice(peer.deviceId),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: selected ? Theme.of(context).colorScheme.secondaryContainer : Theme.of(context).colorScheme.surface,
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFE1B48A)
                            : const Color(0xFFE7DED0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                peer.label,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                peer.subtitle,
                                style: const TextStyle(
                                  color: Color(0xFF5C6A64),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          _StatusBadge(
                            label: context.l10n.sendTargetLabel,
                            color: const Color(0xFF1E7A67),
                          )
                        else
                          OutlinedButton(
                            onPressed: () =>
                                store.selectPeerDevice(peer.deviceId),
                            child: Text(context.l10n.actionSelect),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      );
    });
  }
}

class _SendComposerCard extends StatelessWidget {
  const _SendComposerCard({
    required this.pendingItems,
    required this.sendInProgress,
    required this.selectedPeerLabel,
    required this.onAddFiles,
    required this.onAddFolder,
    required this.onAddPhotos,
    required this.onClear,
    required this.onRemoveItem,
    required this.onSend,
  });

  final List<PendingSendItem> pendingItems;
  final bool sendInProgress;
  final String? selectedPeerLabel;
  final Future<void> Function() onAddFiles;
  final Future<void> Function()? onAddFolder;
  final Future<void> Function()? onAddPhotos;
  final VoidCallback onClear;
  final ValueChanged<String> onRemoveItem;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedPeerLabel == null
                ? l10n.sendComposerChooseDevice
                : l10n.sendComposerReadyToSend(selectedPeerLabel!),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: sendInProgress ? null : onAddFiles,
                icon: const Icon(Icons.attach_file_rounded),
                label: Text(l10n.actionAddFiles),
              ),
              if (onAddFolder != null)
                OutlinedButton.icon(
                  onPressed: sendInProgress ? null : onAddFolder,
                  icon: const Icon(Icons.create_new_folder_rounded),
                  label: Text(l10n.actionAddFolder),
                ),
              if (onAddPhotos != null)
                OutlinedButton.icon(
                  onPressed: sendInProgress ? null : onAddPhotos,
                  icon: const Icon(Icons.photo_library_rounded),
                  label: Text(l10n.actionAddPhotos),
                ),
              OutlinedButton(
                onPressed: sendInProgress || pendingItems.isEmpty
                    ? null
                    : onClear,
                child: Text(l10n.actionClearBatch),
              ),
              FilledButton.icon(
                onPressed: sendInProgress || pendingItems.isEmpty
                    ? null
                    : onSend,
                icon: sendInProgress
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  pendingItems.isEmpty
                      ? l10n.actionSendBatch
                      : l10n.actionSendItemCount(pendingItems.length),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (pendingItems.isEmpty)
            Text(
              l10n.sendComposerEmpty,
              style: const TextStyle(color: Color(0xFF596860)),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: pendingItems
                  .map(
                    (item) => InputChip(
                      label: Text(item.name),
                      avatar: Icon(
                        item.kind == PendingSendKind.file
                            ? Icons.insert_drive_file_outlined
                            : Icons.folder_outlined,
                        size: 18,
                      ),
                      onDeleted: sendInProgress
                          ? null
                          : () => onRemoveItem(item.path),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

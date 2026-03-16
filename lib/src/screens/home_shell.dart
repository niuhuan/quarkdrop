import 'package:flutter/material.dart';
import 'package:quarkdrop/src/models/inbox_job.dart';
import 'package:quarkdrop/src/models/pending_send_item.dart';
import 'package:quarkdrop/src/models/transfer_job.dart';
import 'package:quarkdrop/src/rust/api/app.dart' as rust_api;
import 'package:quarkdrop/src/state/app_store.dart';
import 'package:signals_flutter/signals_flutter.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final destination = store.destination.value;
      final destinations = _visibleDestinations(store.autoReceiveEnabled.value);
      return LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 980;
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF7EEDF),
                    Color(0xFFF4F0E8),
                    Color(0xFFE3F0E8),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: desktop
                      ? _DesktopScaffold(store: store)
                      : _MobileScaffold(store: store),
                ),
              ),
            ),
            bottomNavigationBar: desktop
                ? null
                : Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: NavigationBar(
                        height: 72,
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        selectedIndex: _selectedDestinationIndex(
                          destination,
                          destinations,
                        ),
                        onDestinationSelected: (index) {
                          store.selectDestination(destinations[index]);
                        },
                        destinations: destinations
                            .map(_navigationDestinationFor)
                            .toList(growable: false),
                      ),
                    ),
                  ),
          );
        },
      );
    });
  }
}

class _DesktopScaffold extends StatelessWidget {
  const _DesktopScaffold({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DesktopRail(store: store),
        const SizedBox(width: 18),
        Expanded(flex: 9, child: _MainWorkspace(store: store)),
        const SizedBox(width: 18),
        SizedBox(width: 310, child: _ContextSidebar(store: store)),
      ],
    );
  }
}

class _MobileScaffold extends StatelessWidget {
  const _MobileScaffold({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MobileHeroHeader(store: store),
        const SizedBox(height: 14),
        Expanded(child: _MainWorkspace(store: store)),
      ],
    );
  }
}

class _DesktopRail extends StatelessWidget {
  const _DesktopRail({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final selected = store.destination.value;
      final autoReceiveEnabled = store.autoReceiveEnabled.value;
      final values = _visibleDestinations(autoReceiveEnabled);
      final destinations = values
          .map(_navigationRailDestinationFor)
          .toList(growable: false);

      // Fix if selected relies on a hidden destination
      int selectedIndex = values.indexOf(selected);
      if (selectedIndex == -1) {
        selectedIndex = 0; // Fallback
        WidgetsBinding.instance.addPostFrameCallback((_) {
          store.selectDestination(values.first);
        });
      }

      return Container(
        width: 258,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFE6DDCF)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9E7A59).withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E2327), Color(0xFFCA5E24)],
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'QuarkDrop',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: _SidebarSummary(store: store),
            ),
            Expanded(
              child: NavigationRail(
                minWidth: 78,
                minExtendedWidth: 220,
                backgroundColor: Colors.transparent,
                extended: true,
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) {
                  store.selectDestination(values[index]);
                },
                destinations: destinations,
              ),
            ),
          ],
        ),
      );
    });
  }
}

List<AppDestination> _visibleDestinations(bool autoReceiveEnabled) {
  return [
    AppDestination.send,
    if (autoReceiveEnabled) AppDestination.inbox,
    AppDestination.transfers,
    AppDestination.settings,
  ];
}

int _selectedDestinationIndex(
  AppDestination current,
  List<AppDestination> visibleDestinations,
) {
  final index = visibleDestinations.indexOf(current);
  return index == -1 ? 0 : index;
}

NavigationDestination _navigationDestinationFor(AppDestination destination) {
  switch (destination) {
    case AppDestination.send:
      return const NavigationDestination(
        icon: Icon(Icons.send_outlined),
        selectedIcon: Icon(Icons.send_rounded),
        label: 'Send',
      );
    case AppDestination.inbox:
      return const NavigationDestination(
        icon: Icon(Icons.inbox_outlined),
        selectedIcon: Icon(Icons.inbox_rounded),
        label: 'Mailbox',
      );
    case AppDestination.transfers:
      return const NavigationDestination(
        icon: Icon(Icons.sync_alt_outlined),
        selectedIcon: Icon(Icons.sync_alt_rounded),
        label: 'Transfers',
      );
    case AppDestination.settings:
      return const NavigationDestination(
        icon: Icon(Icons.tune_outlined),
        selectedIcon: Icon(Icons.tune_rounded),
        label: 'Settings',
      );
  }
}

NavigationRailDestination _navigationRailDestinationFor(
  AppDestination destination,
) {
  switch (destination) {
    case AppDestination.send:
      return const NavigationRailDestination(
        icon: Icon(Icons.send_outlined),
        selectedIcon: Icon(Icons.send_rounded),
        label: Text('Send'),
      );
    case AppDestination.inbox:
      return const NavigationRailDestination(
        icon: Icon(Icons.inbox_outlined),
        selectedIcon: Icon(Icons.inbox_rounded),
        label: Text('Mailbox'),
      );
    case AppDestination.transfers:
      return const NavigationRailDestination(
        icon: Icon(Icons.sync_alt_outlined),
        selectedIcon: Icon(Icons.sync_alt_rounded),
        label: Text('Transfers'),
      );
    case AppDestination.settings:
      return const NavigationRailDestination(
        icon: Icon(Icons.tune_outlined),
        selectedIcon: Icon(Icons.tune_rounded),
        label: Text('Settings'),
      );
  }
}

class _MainWorkspace extends StatelessWidget {
  const _MainWorkspace({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final destination = store.destination.value;
      return Column(
        children: [
          _WorkspaceHeader(title: store.currentTitle.value, store: store),
          const SizedBox(height: 16),
          Expanded(child: _buildPane(destination)),
        ],
      );
    });
  }

  Widget _buildPane(AppDestination destination) {
    switch (destination) {
      case AppDestination.send:
        return _SendPane(store: store);
      case AppDestination.inbox:
        return _InboxPane(store: store);
      case AppDestination.transfers:
        return _TransfersPane(store: store);
      case AppDestination.settings:
        return _SettingsPane(store: store);
    }
  }
}

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({required this.title, required this.store});

  final String title;
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final device = store.deviceSnapshot.value;
    final transferCount = store.transferJobs.value.length;
    final mailboxCount = store.inboxJobs.value.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE7DDCE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9E7A59).withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _eyebrowForTitle(title),
                  style: const TextStyle(
                    color: Color(0xFF8A5A37),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _headerDescription(title, store.autoReceiveEnabled.value),
                  style: const TextStyle(
                    color: Color(0xFF5C6A64),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            children: [
              _HeaderStatPill(
                label: 'Device',
                value: device?.deviceName ?? 'Unknown',
              ),
              _HeaderStatPill(label: 'Mailbox', value: '$mailboxCount'),
              _HeaderStatPill(label: 'Transfers', value: '$transferCount'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileHeroHeader extends StatelessWidget {
  const _MobileHeroHeader({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final title = store.currentTitle.value;
    final device = store.deviceSnapshot.value;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2327), Color(0xFFCA5E24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCA5E24).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            device == null
                ? 'Encrypted relay workspace'
                : '${device.deviceName} on Quark relay',
            style: const TextStyle(color: Color(0xFFF4DED1), height: 1.4),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _DarkHeroChip(
                label: '${store.transferJobs.value.length} transfers',
              ),
              _DarkHeroChip(
                label: store.autoReceiveEnabled.value
                    ? 'Mailbox on'
                    : 'Mailbox hidden',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContextSidebar extends StatelessWidget {
  const _ContextSidebar({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ContextCard(
          title: 'Workspace',
          child: _SidebarSummary(store: store),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _ContextCard(
            title: 'Focus',
            child: _SidebarFocus(store: store),
          ),
        ),
      ],
    );
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE6DDCF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SidebarSummary extends StatelessWidget {
  const _SidebarSummary({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final device = store.deviceSnapshot.value;
    final transfers = store.transferJobs.value;
    final failedCount = transfers
        .where((job) => job.stage == TransferStage.failed)
        .length;
    final activeCount = transfers.where((job) => _isActiveTransfer(job)).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          device?.deviceName ?? 'No device name',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        const SizedBox(height: 6),
        Text(
          device?.mailboxSummary ?? 'Sign in to prepare mailbox state.',
          style: const TextStyle(color: Color(0xFF5C6A64), height: 1.45),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _HeaderStatPill(label: 'Active', value: '$activeCount'),
            _HeaderStatPill(label: 'Failed', value: '$failedCount'),
            _HeaderStatPill(
              label: 'Mailbox',
              value: '${store.inboxJobs.value.length}',
            ),
          ],
        ),
      ],
    );
  }
}

class _SidebarFocus extends StatelessWidget {
  const _SidebarFocus({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final destination = store.destination.value;
    final selectedTransfer = store.selectedTransfer.value;
    final selectedPeer = store.selectedPeerDevice.value;
    final failedCount = store.transferJobs.value
        .where((job) => job.stage == TransferStage.failed)
        .length;
    switch (destination) {
      case AppDestination.send:
        return _FocusMessage(
          title: selectedPeer?.label ?? 'Choose a target device',
          body: selectedPeer == null
              ? 'Add files and folders in batches, then pick one device to receive the whole send set.'
              : selectedPeer.subtitle,
        );
      case AppDestination.inbox:
        return _FocusMessage(
          title: store.autoReceiveEnabled.value
              ? 'Mailbox is visible'
              : 'Mailbox is hidden',
          body: store.autoReceiveEnabled.value
              ? 'Incoming relay jobs can be selected together and moved into Transfers after confirming receive.'
              : 'Enable auto-receive in Settings to bring the Mailbox panel back.',
        );
      case AppDestination.transfers:
        return _FocusMessage(
          title: selectedTransfer?.title ?? 'Transfer detail',
          body:
              selectedTransfer?.subtitle ??
              (failedCount > 0
                  ? '$failedCount failed transfer(s) are waiting for recovery.'
                  : 'Use the grouped queue to inspect active, failed, and completed work.'),
        );
      case AppDestination.settings:
        return _FocusMessage(
          title: 'Device and receive policy',
          body:
              'Settings control download directory, auto-receive visibility, sign-out, and device naming.',
        );
    }
  }
}

class _FocusMessage extends StatelessWidget {
  const _FocusMessage({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: const TextStyle(color: Color(0xFF5C6A64), height: 1.5),
        ),
      ],
    );
  }
}

class _HeaderStatPill extends StatelessWidget {
  const _HeaderStatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5D8C8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8A7865),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _DarkHeroChip extends StatelessWidget {
  const _DarkHeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _eyebrowForTitle(String title) {
  switch (title) {
    case 'Send':
      return 'Relay Outbound';
    case 'Mailbox':
      return 'Relay Intake';
    case 'Transfers':
      return 'Transfer History';
    case 'Settings':
      return 'Workspace Control';
    default:
      return 'QuarkDrop';
  }
}

String _headerDescription(String title, bool autoReceiveEnabled) {
  switch (title) {
    case 'Send':
      return 'Build a send batch, choose a target device, and relay encrypted payloads through Quark.';
    case 'Mailbox':
      return autoReceiveEnabled
          ? 'Review relay jobs waiting in this mailbox and move selected items into local transfers.'
          : 'Mailbox appears only while auto-receive is enabled.';
    case 'Transfers':
      return 'Track active work, recover failures, and clear completed history without mixing the states together.';
    case 'Settings':
      return 'Control device identity, receive policy, storage location, and session state.';
    default:
      return 'Encrypted relay workspace.';
  }
}

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
      final sendStatus = store.sendStatusMessage.value;
      final activeTransferCount = store.transferJobs.value
          .where(_isActiveTransfer)
          .length;
      final fileCount = pendingItems
          .where((item) => item.kind == PendingSendKind.file)
          .length;
      final folderCount = pendingItems.length - fileCount;
      String? selectedPeerLabel;
      rust_api.PeerDevice? selectedPeer;
      for (final peer in peers) {
        if (peer.deviceId == selectedPeerId) {
          selectedPeerLabel = peer.label;
          selectedPeer = peer;
          break;
        }
      }
      return _Panel(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wideLayout = constraints.maxWidth >= 1080;
            final left = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PaneTitle(
                  title: 'Send To Device',
                  subtitle:
                      'Build one encrypted batch from multiple file and folder picks, then deliver it to a selected device.',
                ),
                const SizedBox(height: 18),
                _SendOverviewCard(
                  selectedPeerLabel: selectedPeerLabel,
                  batchCount: pendingItems.length,
                  fileCount: fileCount,
                  folderCount: folderCount,
                  activeTransferCount: activeTransferCount,
                  onOpenTransfers: () =>
                      store.selectDestination(AppDestination.transfers),
                ),
                const SizedBox(height: 16),
                _SendComposerCard(
                  pendingItems: pendingItems,
                  sendInProgress: sendInProgress,
                  selectedPeerLabel: selectedPeerLabel,
                  onAddFiles: store.addFilesToSendQueue,
                  onAddFolder: store.addDirectoryToSendQueue,
                  onClear: store.clearPendingSendItems,
                  onRemoveItem: store.removePendingSendItem,
                  onSend: store.sendPendingSelection,
                ),
                if (sendStatus != null) ...[
                  const SizedBox(height: 14),
                  _InlineStatusCard(
                    tone: _StatusTone.neutral,
                    message: sendStatus,
                  ),
                ],
              ],
            );
            final right = peers.isEmpty
                ? const Center(
                    child: _EmptyPaneMessage(
                      title: 'No peer devices yet',
                      body:
                          'No other device is available yet. Open QuarkDrop on another device and sign in first.',
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PeerSelectionHero(peer: selectedPeer),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F4EC),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE7DED0)),
                          ),
                          child: ListView.separated(
                            itemCount: peers.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final peer = peers[index];
                              final selected = peer.deviceId == selectedPeerId;
                              return InkWell(
                                borderRadius: BorderRadius.circular(22),
                                onTap: () =>
                                    store.selectPeerDevice(peer.deviceId),
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    color: selected
                                        ? const Color(0xFFFEF7EE)
                                        : Colors.white,
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFFE1B48A)
                                          : const Color(0xFFE7DED0),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const _DirectionChip(
                                            direction: TransferDirection.send,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              peer.label,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          if (selected)
                                            const _StatusBadge(
                                              label: 'Selected',
                                              color: Color(0xFFB44A1D),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        peer.subtitle,
                                        style: const TextStyle(height: 1.5),
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: [
                                          _MiniInfo(
                                            label: 'Device ID',
                                            value: peer.deviceId,
                                          ),
                                          if (!selected)
                                            OutlinedButton.icon(
                                              onPressed: () =>
                                                  store.selectPeerDevice(
                                                    peer.deviceId,
                                                  ),
                                              icon: const Icon(
                                                Icons.ads_click_rounded,
                                              ),
                                              label: const Text(
                                                'Choose Device',
                                              ),
                                            )
                                          else
                                            const _StatusBadge(
                                              label: 'Send Target',
                                              color: Color(0xFF1E7A67),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
            if (wideLayout) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: left),
                  const SizedBox(width: 18),
                  Expanded(flex: 6, child: right),
                ],
              );
            }
            return ListView(
              children: [
                left,
                const SizedBox(height: 18),
                SizedBox(height: 540, child: right),
              ],
            );
          },
        ),
      );
    });
  }
}

class _TransfersPane extends StatelessWidget {
  const _TransfersPane({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final jobs = store.transferJobs.value;
      final selectedJob = store.selectedTransfer.value;
      final resumeStatus = store.resumeStatusMessage.value;
      final transferActionStatus = store.transferActionStatusMessage.value;
      final transferActionInProgress = store.transferActionInProgress.value;
      final activeJobs = jobs.where(_isActiveTransfer).toList(growable: false);
      final failedJobs = jobs
          .where((job) => job.stage == TransferStage.failed)
          .toList(growable: false);
      final completedJobs = jobs
          .where((job) => job.stage == TransferStage.completed)
          .toList(growable: false);
      final hasCompletedJobs = jobs.any(
        (job) => job.stage == TransferStage.completed,
      );
      return _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: _PaneTitle(
                    title: 'Transfer Queue',
                    subtitle: 'Current and recent send or receive jobs.',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: transferActionInProgress || !hasCompletedJobs
                      ? null
                      : store.clearCompletedTransfers,
                  icon: const Icon(Icons.cleaning_services_outlined),
                  label: const Text('Clear Completed'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (resumeStatus != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCF8F1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE7DED0)),
                ),
                child: Text(resumeStatus, style: const TextStyle(height: 1.5)),
              ),
              const SizedBox(height: 16),
            ],
            if (transferActionStatus != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F2E9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE7DED0)),
                ),
                child: Text(
                  transferActionStatus,
                  style: const TextStyle(height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: jobs.isEmpty
                  ? const Center(
                      child: _EmptyPaneMessage(
                        title: 'No transfer history yet',
                        body:
                            'Send a file or receive a mailbox job to build the transfer queue.',
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final wideLayout = constraints.maxWidth >= 1080;
                        final queue = _TransferQueueList(
                          store: store,
                          activeJobs: activeJobs,
                          failedJobs: failedJobs,
                          completedJobs: completedJobs,
                        );
                        final detail = _TransferDetailCard(
                          job: selectedJob,
                          transferActionInProgress: transferActionInProgress,
                          resumeInProgress: store.resumeInProgress.value,
                          onResume: selectedJob == null
                              ? null
                              : () => store.resumeTransfer(selectedJob),
                          onDeleteRemote: selectedJob == null
                              ? null
                              : () => store.deleteTransfer(selectedJob),
                        );
                        if (wideLayout) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: SingleChildScrollView(child: queue),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                flex: 4,
                                child: SingleChildScrollView(child: detail),
                              ),
                            ],
                          );
                        }
                        return ListView(
                          children: [detail, const SizedBox(height: 16), queue],
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    });
  }
}

class _TransferQueueList extends StatelessWidget {
  const _TransferQueueList({
    required this.store,
    required this.activeJobs,
    required this.failedJobs,
    required this.completedJobs,
  });

  final AppStore store;
  final List<TransferJob> activeJobs;
  final List<TransferJob> failedJobs;
  final List<TransferJob> completedJobs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TransferSection(
          title: 'In Progress',
          subtitle:
              'Transfers that are still uploading, downloading, or verifying.',
          jobs: activeJobs,
          emptyLabel: 'Nothing is running right now.',
          store: store,
        ),
        const SizedBox(height: 18),
        _TransferSection(
          title: 'Failed',
          subtitle:
              'These jobs stopped and can be resumed or deleted remotely.',
          jobs: failedJobs,
          emptyLabel: 'No failed transfers.',
          store: store,
        ),
        const SizedBox(height: 18),
        _TransferSection(
          title: 'Completed',
          subtitle: 'Finished transfers kept as local history until cleared.',
          jobs: completedJobs,
          emptyLabel: 'No completed transfers yet.',
          store: store,
        ),
      ],
    );
  }
}

class _TransferSection extends StatelessWidget {
  const _TransferSection({
    required this.title,
    required this.subtitle,
    required this.jobs,
    required this.emptyLabel,
    required this.store,
  });

  final String title;
  final String subtitle;
  final List<TransferJob> jobs;
  final String emptyLabel;
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F4EC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7DED0)),
      ),
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
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF5C6A64),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(
                label: '${jobs.length}',
                color: const Color(0xFF6B5B4B),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (jobs.isEmpty)
            Text(emptyLabel, style: const TextStyle(color: Color(0xFF6A756F)))
          else
            Column(
              children: [
                for (var index = 0; index < jobs.length; index++) ...[
                  _TransferListTile(job: jobs[index], store: store),
                  if (index != jobs.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _TransferListTile extends StatelessWidget {
  const _TransferListTile({required this.job, required this.store});

  final TransferJob job;
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final selected = store.selectedTransferId.value == job.id;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => store.selectTransfer(job.id),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: selected ? const Color(0xFFFEF7EE) : Colors.white,
          border: Border.all(
            color: selected ? const Color(0xFFE1B48A) : const Color(0xFFE7DED0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _DirectionChip(direction: job.direction),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusBadge(
                  label: _stageLabel(job.stage),
                  color: _stageColor(job.stage),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(job.subtitle, style: const TextStyle(height: 1.45)),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: job.progress,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _stageColor(job.stage),
                ),
                backgroundColor: const Color(0xFFE8E0D3),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _progressLabel(job),
              style: const TextStyle(color: Color(0xFF5C6A64)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferDetailCard extends StatelessWidget {
  const _TransferDetailCard({
    required this.job,
    required this.transferActionInProgress,
    required this.resumeInProgress,
    required this.onResume,
    required this.onDeleteRemote,
  });

  final TransferJob? job;
  final bool transferActionInProgress;
  final bool resumeInProgress;
  final VoidCallback? onResume;
  final VoidCallback? onDeleteRemote;

  @override
  Widget build(BuildContext context) {
    if (job == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F4EC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE7DED0)),
        ),
        child: const _EmptyPaneMessage(
          title: 'Select a transfer',
          body:
              'Choose a row from the queue to inspect its state and available actions.',
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F4EC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7DED0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PaneTitle(
            title: 'Selected Transfer',
            subtitle: 'Current status, direction, and recovery actions.',
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _DirectionChip(direction: job!.direction),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  job!.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusBadge(
                label: _stageLabel(job!.stage),
                color: _stageColor(job!.stage),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            job!.subtitle,
            style: const TextStyle(height: 1.5, color: Color(0xFF5C6A64)),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: job!.progress,
              valueColor: AlwaysStoppedAnimation<Color>(
                _stageColor(job!.stage),
              ),
              backgroundColor: const Color(0xFFE8E0D3),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _progressLabel(job!),
            style: const TextStyle(fontSize: 15, color: Color(0xFF5C6A64)),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _DetailMetaChip(
                icon: job!.direction == TransferDirection.send
                    ? Icons.north_east_rounded
                    : Icons.south_west_rounded,
                label: job!.direction == TransferDirection.send
                    ? 'Send job'
                    : 'Receive job',
              ),
              _DetailMetaChip(
                icon: Icons.flag_outlined,
                label: _detailStateLabel(job!),
              ),
              _DetailMetaChip(
                icon: Icons.percent_rounded,
                label: '${(job!.progress * 100).round()}%',
              ),
            ],
          ),
          if (job!.stage == TransferStage.failed) ...[
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: resumeInProgress ? null : onResume,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Resume Transfer'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: transferActionInProgress ? null : onDeleteRemote,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete Remote Job'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailMetaChip extends StatelessWidget {
  const _DetailMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE7DED0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6A5C4D)),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _SettingsPane extends StatelessWidget {
  const _SettingsPane({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final device = store.deviceSnapshot.value;
      final lastError = store.lastErrorMessage.value;
      final platformPaths = store.platformPaths;
      final preferredDownloadDir = store.preferredDownloadDir.value;
      final downloadStatus = store.downloadDirectoryStatusMessage.value;
      return _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PaneTitle(
              title: 'Settings',
              subtitle: 'Device, storage, help, and sign-out.',
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  if (device != null) ...[
                    _DeviceSettingsCard(
                      store: store,
                      deviceName: device.deviceName,
                    ),
                    const SizedBox(height: 14),
                    _InfoCard(
                      title: 'Signed In',
                      body:
                          'Current device: ${device.deviceName}\nAccount source: ${device.authSource}',
                      icon: Icons.devices_rounded,
                    ),
                    const SizedBox(height: 14),
                  ],
                  _InfoCard(
                    title: 'App Data',
                    body: 'App data: ${platformPaths.configDir}',
                    icon: Icons.storage_rounded,
                  ),
                  const SizedBox(height: 14),
                  _DownloadDirectoryCard(
                    store: store,
                    currentPath:
                        preferredDownloadDir ??
                        platformPaths.downloadDir ??
                        'Choose a folder before receiving',
                    statusMessage: downloadStatus,
                  ),
                  const SizedBox(height: 14),
                  _AutoReceiveCard(store: store),
                  const SizedBox(height: 14),
                  _InfoCard(
                    title: 'Help',
                    body:
                        '1. Sign in on each device.\n2. Open Send and choose a target device.\n3. Pick a file or folder.\n4. Open Inbox on the receiving device to save it locally.\n5. Use Transfers to resume unfinished jobs.',
                    icon: Icons.help_outline_rounded,
                  ),
                  const SizedBox(height: 14),
                  _SignOutCard(store: store),
                  if (lastError != null) ...[
                    const SizedBox(height: 14),
                    _InfoCard(
                      title: 'Latest Error',
                      body: lastError,
                      icon: Icons.warning_amber_rounded,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE4DBCE)),
      ),
      child: child,
    );
  }
}

class _PaneTitle extends StatelessWidget {
  const _PaneTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: Color(0xFF5C6A64))),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(16),
      ),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _DirectionChip extends StatelessWidget {
  const _DirectionChip({required this.direction});

  final TransferDirection direction;

  @override
  Widget build(BuildContext context) {
    final icon = direction == TransferDirection.send
        ? Icons.north_east_rounded
        : Icons.south_west_rounded;
    final label = direction == TransferDirection.send ? 'Send' : 'Receive';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECE3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _DeviceSettingsCard extends StatefulWidget {
  const _DeviceSettingsCard({required this.store, required this.deviceName});

  final AppStore store;
  final String deviceName;

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
    return Watch((context) {
      final saving = widget.store.deviceNameSaving.value;
      final status = widget.store.deviceNameStatusMessage.value;
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F3EB),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device Name',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose the name other devices see in the send list.',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _editing
                      ? TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          enabled: !saving,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(
                            labelText: 'This device',
                            border: OutlineInputBorder(),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.76),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFDCCFBF)),
                          ),
                          child: Text(
                            _controller.text,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  onPressed: saving
                      ? null
                      : (_editing ? _submit : _startEditing),
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _editing ? Icons.check_rounded : Icons.edit_rounded,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (status != null)
              Text(status, style: const TextStyle(height: 1.4)),
          ],
        ),
      );
    });
  }
}

class _SignOutCard extends StatelessWidget {
  const _SignOutCard({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final busy = store.signOutInProgress.value;
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3EE),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'This removes the current device mailbox from Quark and clears the saved session on this device.',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              onPressed: busy ? null : () => store.signOut(),
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout_rounded),
              label: Text(busy ? 'Signing Out...' : 'Sign Out'),
            ),
          ],
        ),
      );
    });
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
    return Watch((context) {
      final saving = store.downloadDirectorySaving.value;
      final hasCustomDir =
          store.preferredDownloadDir.value?.isNotEmpty ?? false;
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F3EB),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Download Folder',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(currentPath, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
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
                  label: const Text('Choose Folder'),
                ),
                if (hasCustomDir)
                  OutlinedButton.icon(
                    onPressed: saving
                        ? null
                        : () => store.clearPreferredDownloadDirectory(),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Use Default'),
                  ),
              ],
            ),
            if (statusMessage != null) ...[
              const SizedBox(height: 12),
              Text(statusMessage!, style: const TextStyle(height: 1.4)),
            ],
          ],
        ),
      );
    });
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3EB),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(body, style: const TextStyle(height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPaneMessage extends StatelessWidget {
  const _EmptyPaneMessage({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F2E9),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.inbox_outlined, size: 30),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF586961), height: 1.5),
          ),
        ],
      ),
    );
  }
}

String _stageLabel(TransferStage stage) {
  switch (stage) {
    case TransferStage.preparing:
      return 'Preparing';
    case TransferStage.uploading:
      return 'Uploading';
    case TransferStage.uploadingManifest:
      return 'Manifest';
    case TransferStage.uploadingCommit:
      return 'Commit';
    case TransferStage.downloading:
      return 'Downloading';
    case TransferStage.verifying:
      return 'Verifying';
    case TransferStage.cleaningRemote:
      return 'Cleanup';
    case TransferStage.failed:
      return 'Failed';
    case TransferStage.completed:
      return 'Done';
  }
}

bool _isActiveTransfer(TransferJob job) =>
    job.stage != TransferStage.failed && job.stage != TransferStage.completed;

Color _stageColor(TransferStage stage) {
  switch (stage) {
    case TransferStage.failed:
      return const Color(0xFFB42318);
    case TransferStage.completed:
      return const Color(0xFF2F7D32);
    case TransferStage.preparing:
    case TransferStage.uploading:
    case TransferStage.uploadingManifest:
    case TransferStage.uploadingCommit:
    case TransferStage.downloading:
    case TransferStage.verifying:
    case TransferStage.cleaningRemote:
      return const Color(0xFFCA5E24);
  }
}

String _progressLabel(TransferJob job) {
  if (job.stage == TransferStage.failed) {
    return 'Transfer failed and is waiting for recovery.';
  }
  if (job.stage == TransferStage.completed) {
    return 'Transfer completed successfully.';
  }
  return '${(job.progress * 100).round()}% complete';
}

String _detailStateLabel(TransferJob job) {
  if (job.stage == TransferStage.failed) {
    return 'Needs attention';
  }
  if (job.stage == TransferStage.completed) {
    return 'Completed';
  }
  return 'Active';
}

class _AutoReceiveCard extends StatelessWidget {
  final AppStore store;
  const _AutoReceiveCard({required this.store});

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Auto-Receive Files'),
        subtitle: const Text(
          'Automatically download incoming files to your default download directory.',
        ),
        value: enabled,
        onChanged: (val) => store.toggleAutoReceive(val),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _InboxPane extends StatelessWidget {
  final AppStore store;

  const _InboxPane({required this.store});

  @override
  Widget build(BuildContext context) {
    final jobs = store.inboxJobs.watch(context);
    final mailboxStatus = store.mailboxStatusMessage.watch(context);
    final autoReceiveEnabled = store.autoReceiveEnabled.watch(context);
    final selectedJobIds = store.selectedMailboxJobIds.watch(context);
    final receiveInProgress = store.receiveInProgress.watch(context);
    final preferredDownloadDir = store.preferredDownloadDir.watch(context);
    final hasReceiveTarget =
        (preferredDownloadDir?.isNotEmpty ?? false) ||
        (!store.platformPaths.requiresDownloadPicker &&
            (store.platformPaths.downloadDir?.isNotEmpty ?? false));

    final sortedJobs = jobs.toList();
    final selectedJobs = sortedJobs
        .where((job) => selectedJobIds.contains(job.id))
        .toList(growable: false);
    final focusedJob = selectedJobs.isNotEmpty
        ? selectedJobs.first
        : (sortedJobs.isNotEmpty ? sortedJobs.first : null);
    final queuedCount = sortedJobs
        .where((job) => job.status == MailboxJobStatus.queued)
        .length;
    final failedCount = sortedJobs
        .where((job) => job.status == MailboxJobStatus.failed)
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wideLayout = constraints.maxWidth >= 1080;
        final left = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PaneTitle(
              title: 'Mailbox',
              subtitle:
                  'Review relay jobs waiting in cloud storage, choose one or more, then save them locally together.',
            ),
            const SizedBox(height: 18),
            _MailboxOverviewCard(
              autoReceiveEnabled: autoReceiveEnabled,
              mailboxStatus: mailboxStatus,
              hasReceiveTarget: hasReceiveTarget,
              queuedCount: queuedCount,
              failedCount: failedCount,
              selectedCount: selectedJobIds.length,
              receiveInProgress: receiveInProgress,
              onReceiveSelected: store.receiveSelectedMailboxJobs,
              onClearSelection: store.clearMailboxSelection,
              onOpenSettings: () =>
                  store.selectDestination(AppDestination.settings),
              onOpenTransfers: () =>
                  store.selectDestination(AppDestination.transfers),
            ),
            const SizedBox(height: 16),
            if (focusedJob != null)
              _MailboxFocusCard(
                job: focusedJob,
                autoReceiveEnabled: autoReceiveEnabled,
                receiveInProgress: receiveInProgress,
                onRetry: () => store.pickOutputAndReceive(focusedJob),
              ),
          ],
        );
        final right = sortedJobs.isEmpty
            ? const Center(
                child: _EmptyPaneMessage(
                  title: 'No relay jobs in the mailbox',
                  body:
                      'Incoming encrypted jobs will appear here after another device sends them.',
                ),
              )
            : Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F4EC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE7DED0)),
                ),
                child: ListView.separated(
                  itemCount: sortedJobs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final job = sortedJobs[index];
                    return _MailboxJobTile(
                      job: job,
                      selected: selectedJobIds.contains(job.id),
                      autoReceiveEnabled: autoReceiveEnabled,
                      receiveInProgress: receiveInProgress,
                      onToggle: (selected) {
                        store.toggleMailboxJobSelection(job.id, selected);
                      },
                      onReceiveNow: () {
                        store.toggleMailboxJobSelection(job.id, true);
                        store.receiveSelectedMailboxJobs();
                      },
                      onRetry: () => store.pickOutputAndReceive(job),
                    );
                  },
                ),
              );
        if (wideLayout) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: left),
              const SizedBox(width: 18),
              Expanded(flex: 6, child: right),
            ],
          );
        }
        return ListView(
          children: [
            left,
            const SizedBox(height: 18),
            SizedBox(height: 560, child: right),
          ],
        );
      },
    );
  }
}

class _SendOverviewCard extends StatelessWidget {
  const _SendOverviewCard({
    required this.selectedPeerLabel,
    required this.batchCount,
    required this.fileCount,
    required this.folderCount,
    required this.activeTransferCount,
    required this.onOpenTransfers,
  });

  final String? selectedPeerLabel;
  final int batchCount;
  final int fileCount;
  final int folderCount;
  final int activeTransferCount;
  final VoidCallback onOpenTransfers;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFCF6ED), Color(0xFFF3EEE5)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6D8C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedPeerLabel == null
                ? 'Step 1. Choose a device'
                : 'Targeting $selectedPeerLabel',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            selectedPeerLabel == null
                ? 'Start by selecting the receiving device. Then build a batch from repeated file and folder picks.'
                : 'Your current batch will be sent to this device as separate encrypted transfer jobs.',
            style: const TextStyle(color: Color(0xFF5C6A64), height: 1.45),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeaderStatPill(label: 'Batch', value: '$batchCount items'),
              _HeaderStatPill(label: 'Files', value: '$fileCount'),
              _HeaderStatPill(label: 'Folders', value: '$folderCount'),
              _HeaderStatPill(label: 'Active', value: '$activeTransferCount'),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onOpenTransfers,
              icon: const Icon(Icons.sync_alt_rounded),
              label: const Text('Open Transfers'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeerSelectionHero extends StatelessWidget {
  const _PeerSelectionHero({required this.peer});

  final rust_api.PeerDevice? peer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2327), Color(0xFF415058)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            peer == null ? 'Step 2. Pick a receiver' : peer!.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            peer?.subtitle ??
                'Select one device from the list below. The whole send batch will be delivered there.',
            style: const TextStyle(color: Color(0xFFE4D6CA), height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _MailboxOverviewCard extends StatelessWidget {
  const _MailboxOverviewCard({
    required this.autoReceiveEnabled,
    required this.mailboxStatus,
    required this.hasReceiveTarget,
    required this.queuedCount,
    required this.failedCount,
    required this.selectedCount,
    required this.receiveInProgress,
    required this.onReceiveSelected,
    required this.onClearSelection,
    required this.onOpenSettings,
    required this.onOpenTransfers,
  });

  final bool autoReceiveEnabled;
  final String? mailboxStatus;
  final bool hasReceiveTarget;
  final int queuedCount;
  final int failedCount;
  final int selectedCount;
  final bool receiveInProgress;
  final Future<void> Function() onReceiveSelected;
  final VoidCallback onClearSelection;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenTransfers;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF7F1E7), Color(0xFFEEF5EF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4DBCE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            autoReceiveEnabled
                ? 'Mailbox is watching cloud relay jobs.'
                : 'Mailbox is visible, but auto-receive is off.',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          if (mailboxStatus != null) ...[
            const SizedBox(height: 8),
            Text(
              mailboxStatus!,
              style: const TextStyle(color: Color(0xFF5C6A64), height: 1.45),
            ),
          ],
          if (!hasReceiveTarget) ...[
            const SizedBox(height: 12),
            const _InlineStatusCard(
              tone: _StatusTone.warning,
              message:
                  'Choose a download folder in Settings before receiving or using auto-receive on this device.',
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeaderStatPill(label: 'Queued', value: '$queuedCount'),
              _HeaderStatPill(label: 'Failed', value: '$failedCount'),
              _HeaderStatPill(label: 'Selected', value: '$selectedCount'),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: receiveInProgress || !hasReceiveTarget
                    ? null
                    : onReceiveSelected,
                icon: receiveInProgress
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(
                  selectedCount == 0
                      ? 'Receive Selected'
                      : 'Receive $selectedCount',
                ),
              ),
              OutlinedButton(
                onPressed: selectedCount == 0 ? null : onClearSelection,
                child: const Text('Clear Selection'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenTransfers,
                icon: const Icon(Icons.sync_alt_rounded),
                label: const Text('Open Transfers'),
              ),
              if (!hasReceiveTarget)
                OutlinedButton.icon(
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.folder_open_rounded),
                  label: const Text('Set Download Folder'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MailboxFocusCard extends StatelessWidget {
  const _MailboxFocusCard({
    required this.job,
    required this.autoReceiveEnabled,
    required this.receiveInProgress,
    required this.onRetry,
  });

  final InboxJob job;
  final bool autoReceiveEnabled;
  final bool receiveInProgress;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F4EC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7DED0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Focused Relay Job',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  job.rootName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _MailboxJobBadge(job: job),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'From ${job.sender} · ${job.receivedAtLabel} · ${job.sizeLabel}',
            style: const TextStyle(color: Color(0xFF5C6A64), height: 1.45),
          ),
          const SizedBox(height: 10),
          Text(
            job.statusMessage ?? job.summary,
            style: const TextStyle(color: Color(0xFF5C6A64), height: 1.5),
          ),
          if (job.status == MailboxJobStatus.failed) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: receiveInProgress ? null : onRetry,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Retry Receive'),
            ),
          ] else if (job.status == MailboxJobStatus.queued) ...[
            const SizedBox(height: 14),
            _InlineStatusCard(
              tone: autoReceiveEnabled
                  ? _StatusTone.success
                  : _StatusTone.neutral,
              message: autoReceiveEnabled
                  ? 'Auto-receive may pick this job up automatically if a download folder is ready.'
                  : 'Select this job and confirm receive to move it into Transfers.',
            ),
          ],
        ],
      ),
    );
  }
}

class _MailboxJobTile extends StatelessWidget {
  const _MailboxJobTile({
    required this.job,
    required this.selected,
    required this.autoReceiveEnabled,
    required this.receiveInProgress,
    required this.onToggle,
    required this.onReceiveNow,
    required this.onRetry,
  });

  final InboxJob job;
  final bool selected;
  final bool autoReceiveEnabled;
  final bool receiveInProgress;
  final ValueChanged<bool> onToggle;
  final VoidCallback onReceiveNow;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFEF7EE) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? const Color(0xFFE1B48A) : const Color(0xFFE7DED0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: selected,
                onChanged: receiveInProgress
                    ? null
                    : (value) => onToggle(value ?? false),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1ECE3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.inventory_2_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.rootName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'From ${job.sender}',
                      style: const TextStyle(
                        color: Color(0xFF5C6A64),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${job.receivedAtLabel} · ${job.sizeLabel}',
                      style: const TextStyle(
                        color: Color(0xFF7A847E),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _MailboxJobBadge(job: job),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            job.statusMessage ?? job.summary,
            style: const TextStyle(color: Color(0xFF596860), height: 1.45),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (job.status == MailboxJobStatus.queued)
                FilledButton.icon(
                  onPressed: receiveInProgress ? null : onReceiveNow,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(autoReceiveEnabled ? 'Receive Now' : 'Save'),
                ),
              if (job.status == MailboxJobStatus.failed)
                OutlinedButton.icon(
                  onPressed: receiveInProgress ? null : onRetry,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Retry'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineStatusCard extends StatelessWidget {
  const _InlineStatusCard({required this.tone, required this.message});

  final _StatusTone tone;
  final String message;

  @override
  Widget build(BuildContext context) {
    final background = switch (tone) {
      _StatusTone.neutral => const Color(0xFFF7F2E9),
      _StatusTone.success => const Color(0xFFEAF4EF),
      _StatusTone.warning => const Color(0xFFFCF4E7),
    };
    final foreground = switch (tone) {
      _StatusTone.neutral => const Color(0xFF596860),
      _StatusTone.success => const Color(0xFF1E7A67),
      _StatusTone.warning => const Color(0xFF8A5A37),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(message, style: TextStyle(color: foreground, height: 1.45)),
    );
  }
}

enum _StatusTone { neutral, success, warning }

class _MailboxJobBadge extends StatelessWidget {
  const _MailboxJobBadge({required this.job});

  final InboxJob job;

  @override
  Widget build(BuildContext context) {
    switch (job.status) {
      case MailboxJobStatus.queued:
        return const _StatusBadge(label: 'Queued', color: Color(0xFF8A6B2F));
      case MailboxJobStatus.autoReceiving:
        return const _StatusBadge(label: 'Receiving', color: Color(0xFF1E7A67));
      case MailboxJobStatus.failed:
        return const _StatusBadge(label: 'Failed', color: Color(0xFFB44A1D));
    }
  }
}

class _SendComposerCard extends StatelessWidget {
  const _SendComposerCard({
    required this.pendingItems,
    required this.sendInProgress,
    required this.selectedPeerLabel,
    required this.onAddFiles,
    required this.onAddFolder,
    required this.onClear,
    required this.onRemoveItem,
    required this.onSend,
  });

  final List<PendingSendItem> pendingItems;
  final bool sendInProgress;
  final String? selectedPeerLabel;
  final Future<void> Function() onAddFiles;
  final Future<void> Function() onAddFolder;
  final VoidCallback onClear;
  final ValueChanged<String> onRemoveItem;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3EB),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedPeerLabel == null
                ? 'Choose a device below, then build your send batch.'
                : 'Ready to send to $selectedPeerLabel.',
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
                label: const Text('Add Files'),
              ),
              OutlinedButton.icon(
                onPressed: sendInProgress ? null : onAddFolder,
                icon: const Icon(Icons.create_new_folder_rounded),
                label: const Text('Add Folder'),
              ),
              OutlinedButton(
                onPressed: sendInProgress || pendingItems.isEmpty
                    ? null
                    : onClear,
                child: const Text('Clear Batch'),
              ),
              FilledButton.icon(
                onPressed: sendInProgress || pendingItems.isEmpty
                    ? null
                    : onSend,
                icon: sendInProgress
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  pendingItems.isEmpty
                      ? 'Send Batch'
                      : 'Send ${pendingItems.length} Item(s)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (pendingItems.isEmpty)
            const Text(
              'No files or folders added yet.',
              style: TextStyle(color: Color(0xFF596860)),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: pendingItems
                  .map((item) {
                    return InputChip(
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
                    );
                  })
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

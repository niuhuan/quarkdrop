import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quarkdrop/src/configs/launch_at_startup.dart' as startup;
import 'package:quarkdrop/src/l10n/app_locale.dart';
import 'package:quarkdrop/src/l10n/l10n.dart';
import 'package:quarkdrop/src/models/pending_send_item.dart';
import 'package:quarkdrop/src/models/transfer_job.dart';
import 'package:quarkdrop/src/rust/api/app.dart' as rust_api;
import 'package:quarkdrop/src/state/app_store.dart';
import 'package:signals_flutter/signals_flutter.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.store});

  final AppStore store;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final List<void Function()> _disposeEffects = [];

  @override
  void initState() {
    super.initState();
    _watchStatusSignal(widget.store.sendStatusMessage);
    _watchStatusSignal(widget.store.resumeStatusMessage);
    _watchStatusSignal(widget.store.transferActionStatusMessage);
    _watchStatusSignal(widget.store.receiveStatusMessage);
    _watchStatusSignal(widget.store.mailboxStatusMessage);
    _watchStatusSignal(widget.store.deviceNameStatusMessage);
    _watchStatusSignal(widget.store.localeStatusMessage);
  }

  void _watchStatusSignal(Signal<String?> signal) {
    String? prev;
    final dispose = effect(() {
      final msg = signal.value;
      if (msg != null && msg != prev) {
        prev = msg;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Text(msg),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              ),
            );
          // Auto-clear the signal after showing
          Future.delayed(const Duration(seconds: 5), () {
            if (signal.value == msg) {
              signal.value = null;
            }
          });
        });
      } else if (msg == null) {
        prev = null;
      }
    });
    _disposeEffects.add(dispose);
  }

  @override
  void dispose() {
    for (final d in _disposeEffects) {
      d();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final store = widget.store;
      final destination = store.destination.value;
      final destinations = _visibleDestinations(store.autoReceiveEnabled.value);
      return LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 980;
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(desktop ? 18 : 0),
                child: desktop
                    ? _DesktopScaffold(store: store)
                    : _MobileScaffold(store: store),
              ),
            ),
            bottomNavigationBar: desktop
                ? null
                : NavigationBar(
                    height: 72,
                    selectedIndex: _selectedDestinationIndex(
                      destination,
                      destinations,
                    ),
                    onDestinationSelected: (index) {
                      store.selectDestination(destinations[index]);
                    },
                    destinations: destinations
                        .map(
                          (destination) =>
                              _navigationDestinationFor(context, destination),
                        )
                        .toList(growable: false),
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
        Expanded(child: _MainWorkspace(store: store)),
      ],
    );
  }
}

class _MobileScaffold extends StatelessWidget {
  const _MobileScaffold({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return _MainWorkspace(store: store);
  }
}

class _DesktopRail extends StatelessWidget {
  const _DesktopRail({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final l10n = context.l10n;
      final selected = store.destination.value;
      final autoReceiveEnabled = store.autoReceiveEnabled.value;
      final values = _visibleDestinations(autoReceiveEnabled);

      // Fix if selected relies on a hidden destination
      int selectedIndex = values.indexOf(selected);
      if (selectedIndex == -1) {
        selectedIndex = 0; // Fallback
        WidgetsBinding.instance.addPostFrameCallback((_) {
          store.selectDestination(values.first);
        });
      }

      return Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E4E4)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.appTitle,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                itemCount: values.length,
                itemBuilder: (context, index) {
                  final dest = values[index];
                  final isSelected = selectedIndex == index;

                  IconData iconData;
                  IconData selectedIconData;
                  String label;
                  switch (dest) {
                    case AppDestination.send:
                      iconData = Icons.send_outlined;
                      selectedIconData = Icons.send_rounded;
                      label = l10n.navSend;
                      break;
                    case AppDestination.inbox:
                      iconData = Icons.inbox_outlined;
                      selectedIconData = Icons.inbox_rounded;
                      label = l10n.navMailbox;
                      break;
                    case AppDestination.transfers:
                      iconData = Icons.sync_alt_outlined;
                      selectedIconData = Icons.sync_alt_rounded;
                      label = l10n.navTransfers;
                      break;
                    case AppDestination.settings:
                      iconData = Icons.tune_outlined;
                      selectedIconData = Icons.tune_rounded;
                      label = l10n.navSettings;
                      break;
                  }

                  final theme = Theme.of(context);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: () => store.selectDestination(dest),
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.05,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? selectedIconData : iconData,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              label,
                              style: TextStyle(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

List<AppDestination> _visibleDestinations(bool autoReceiveEnabled) {
  return [
    AppDestination.send,
    if (!autoReceiveEnabled) AppDestination.inbox,
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

NavigationDestination _navigationDestinationFor(
  BuildContext context,
  AppDestination destination,
) {
  final l10n = context.l10n;
  switch (destination) {
    case AppDestination.send:
      return NavigationDestination(
        icon: const Icon(Icons.send_outlined),
        selectedIcon: const Icon(Icons.send_rounded),
        label: l10n.navSend,
      );
    case AppDestination.inbox:
      return NavigationDestination(
        icon: const Icon(Icons.inbox_outlined),
        selectedIcon: const Icon(Icons.inbox_rounded),
        label: l10n.navMailbox,
      );
    case AppDestination.transfers:
      return NavigationDestination(
        icon: const Icon(Icons.sync_alt_outlined),
        selectedIcon: const Icon(Icons.sync_alt_rounded),
        label: l10n.navTransfers,
      );
    case AppDestination.settings:
      return NavigationDestination(
        icon: const Icon(Icons.tune_outlined),
        selectedIcon: const Icon(Icons.tune_rounded),
        label: l10n.navSettings,
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
      return _buildPane(destination);
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
                      color: selected ? const Color(0xFFFEF7EE) : Colors.white,
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
                            color: Color(0xFF1E7A67),
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

class _TransfersPane extends StatefulWidget {
  const _TransfersPane({required this.store});

  final AppStore store;

  @override
  State<_TransfersPane> createState() => _TransfersPaneState();
}

class _TransfersPaneState extends State<_TransfersPane>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final store = widget.store;
      final jobs = store.transferJobs.value;
      final selectedJob = store.selectedTransfer.value;
      final transferActionInProgress = store.transferActionInProgress.value;
      final hasCompletedJobs = jobs.any(
        (job) => job.stage == TransferStage.completed,
      );
      final uploadJobs = jobs
          .where((j) => j.direction == TransferDirection.send)
          .toList(growable: false);
      final downloadJobs = jobs
          .where((j) => j.direction == TransferDirection.receive)
          .toList(growable: false);

      Widget buildJobList(List<TransferJob> filtered) {
        if (filtered.isEmpty) {
          return Center(
            child: _EmptyPaneMessage(
              title: context.l10n.noTransfersTitle,
              body: context.l10n.noTransfersBody,
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) =>
              _TransferListTile(job: filtered[i], store: store),
        );
      }

      Widget buildBody() {
        if (jobs.isEmpty) {
          return Center(
            child: _EmptyPaneMessage(
              title: context.l10n.noTransferHistoryTitle,
              body: context.l10n.noTransferHistoryBody,
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final wideLayout = constraints.maxWidth >= 1080;
            final tabs = TabBarView(
              controller: _tabController,
              children: [
                buildJobList(jobs),
                buildJobList(uploadJobs),
                buildJobList(downloadJobs),
              ],
            );
            if (wideLayout) {
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
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: tabs),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 4,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(right: 16),
                      child: detail,
                    ),
                  ),
                ],
              );
            }
            return tabs;
          },
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _PaneTitle(
                    title: context.l10n.transfersTitle,
                    subtitle: context.l10n.transfersSubtitle,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: transferActionInProgress || !hasCompletedJobs
                      ? null
                      : store.clearCompletedTransfers,
                  icon: const Icon(Icons.cleaning_services_outlined),
                  label: Text(context.l10n.actionClearCompleted),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: context.l10n.tabAll(jobs.length)),
                Tab(text: context.l10n.tabUpload(uploadJobs.length)),
                Tab(text: context.l10n.tabDownload(downloadJobs.length)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: buildBody()),
        ],
      );
    });
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusBadge(
                  label: _stageLabel(context, job.stage),
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
              _progressLabel(context, job),
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
    final l10n = context.l10n;
    if (job == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F4EC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE7DED0)),
        ),
        child: _EmptyPaneMessage(
          title: l10n.selectTransferTitle,
          body: l10n.selectTransferBody,
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
          _PaneTitle(
            title: l10n.selectedTransferTitle,
            subtitle: l10n.selectedTransferSubtitle,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _DirectionChip(direction: job!.direction),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  job!.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusBadge(
                label: _stageLabel(context, job!.stage),
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
            _progressLabel(context, job!),
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
                    ? l10n.sendJobLabel
                    : l10n.receiveJobLabel,
              ),
              _DetailMetaChip(
                icon: Icons.flag_outlined,
                label: _detailStateLabel(context, job!),
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
                    label: Text(l10n.actionResumeTransfer),
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
                    label: Text(l10n.actionDeleteRemoteJob),
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
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _PaneTitle(
              title: l10n.settingsTitle,
              subtitle: l10n.settingsSubtitle,
            ),
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
                    authSource: device.authSource,
                  ),
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
                _LanguageCard(store: store, statusMessage: localeStatus),
                const SizedBox(height: 14),
                _AutoReceiveCard(store: store),
                const SizedBox(height: 14),
                _NavigateAfterTransferCard(store: store),
                const SizedBox(height: 14),
                if (Platform.isAndroid || Platform.isIOS) ...[
                  _KeepScreenOnCard(store: store),
                  const SizedBox(height: 14),
                ],
                _PollIntervalCard(store: store),
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

class _DirectionChip extends StatelessWidget {
  const _DirectionChip({required this.direction});

  final TransferDirection direction;

  @override
  Widget build(BuildContext context) {
    final icon = direction == TransferDirection.send
        ? Icons.north_east_rounded
        : Icons.south_west_rounded;
    final l10n = context.l10n;
    final label = direction == TransferDirection.send
        ? l10n.directionSend
        : l10n.directionReceive;
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
  const _DeviceSettingsCard({
    required this.store,
    required this.deviceName,
    required this.authSource,
  });

  final AppStore store;
  final String deviceName;
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
    final newPw = _newController.text;
    final confirm = _confirmController.text;
    if (newPw.isEmpty) {
      setState(() => _error = l10n.errorNewPasswordEmpty);
      return;
    }
    if (newPw != confirm) {
      setState(() => _error = l10n.errorPasswordsDoNotMatch);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.store.changeCloudPassword(_oldController.text, newPw);
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
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
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
                      style: TextStyle(
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
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.cloudPasswordCardSubtitle,
                    style: TextStyle(color: Color(0xFF5C6A64), fontSize: 13),
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
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _newController,
                  obscureText: true,
                  enabled: !_saving,
                  decoration: InputDecoration(
                    labelText: l10n.newPasswordLabel,
                    border: OutlineInputBorder(),
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
                    border: OutlineInputBorder(),
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
    } catch (e) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(context.l10n.genericFailed('$e')),
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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
          } catch (e) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                SnackBar(
                  content: Text(l10n.failedOpenDataFolder('$e')),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                ),
              );
          }
        },
        child: Padding(
          padding: EdgeInsets.all(18),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.openDataFolderSubtitle,
                      style: TextStyle(color: Color(0xFF5C6A64), fontSize: 13),
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
      if (mounted) setState(() => _loading = false);
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.signOutSubtitle,
                      style: TextStyle(color: Color(0xFF5C6A64), fontSize: 13),
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
                  onChanged: (v) => setState(() => _deleteRemote = v ?? true),
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
                      style: TextStyle(fontWeight: FontWeight.w700),
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
                onChanged: (value) {
                  store.setLocalePreference(value);
                },
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

String _stageLabel(BuildContext context, TransferStage stage) {
  final l10n = context.l10n;
  switch (stage) {
    case TransferStage.preparing:
      return l10n.stagePreparing;
    case TransferStage.uploading:
      return l10n.stageUploading;
    case TransferStage.uploadingManifest:
      return l10n.stageManifest;
    case TransferStage.uploadingCommit:
      return l10n.stageCommit;
    case TransferStage.downloading:
      return l10n.stageDownloading;
    case TransferStage.verifying:
      return l10n.stageVerifying;
    case TransferStage.cleaningRemote:
      return l10n.stageCleanup;
    case TransferStage.failed:
      return l10n.stageFailed;
    case TransferStage.completed:
      return l10n.stageDone;
  }
}

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

String _progressLabel(BuildContext context, TransferJob job) {
  final l10n = context.l10n;
  if (job.stage == TransferStage.failed) {
    return l10n.transferFailedWaitingRecovery;
  }
  if (job.stage == TransferStage.completed) {
    return l10n.transferCompletedSuccessfully;
  }
  return l10n.transferPercentComplete((job.progress * 100).round());
}

String _detailStateLabel(BuildContext context, TransferJob job) {
  final l10n = context.l10n;
  if (job.stage == TransferStage.failed) {
    return l10n.transferNeedsAttention;
  }
  if (job.stage == TransferStage.completed) {
    return l10n.transferCompleted;
  }
  return l10n.transferActive;
}

class _PollIntervalCard extends StatefulWidget {
  final AppStore store;
  const _PollIntervalCard({required this.store});

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
                          style: TextStyle(fontWeight: FontWeight.w700),
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
                  onChanged: (v) => widget.store.setPollInterval(v.round()),
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
  final AppStore store;
  const _AutoReceiveCard({required this.store});

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
        onChanged: (val) => store.toggleAutoReceive(val),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _NavigateAfterTransferCard extends StatelessWidget {
  final AppStore store;
  const _NavigateAfterTransferCard({required this.store});

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
        onChanged: (val) => store.toggleNavigateAfterTransfer(val),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _KeepScreenOnCard extends StatelessWidget {
  final AppStore store;
  const _KeepScreenOnCard({required this.store});

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
        onChanged: (val) => store.toggleKeepScreenOnDuringTransfer(val),
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
    final l10n = context.l10n;
    final jobs = store.inboxJobs.watch(context);
    final selectedJobIds = store.selectedMailboxJobIds.watch(context);
    final receiveInProgress = store.receiveInProgress.watch(context);

    final sortedJobs = jobs.toList();
    final selectedCount = selectedJobIds.length;
    final allSelected =
        sortedJobs.isNotEmpty && selectedCount == sortedJobs.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              if (sortedJobs.isNotEmpty)
                Checkbox(
                  value: allSelected,
                  tristate: true,
                  onChanged: receiveInProgress
                      ? null
                      : (value) {
                          if (allSelected) {
                            store.clearMailboxSelection();
                          } else {
                            for (final job in sortedJobs) {
                              store.toggleMailboxJobSelection(job.id, true);
                            }
                          }
                        },
                ),
              Expanded(
                child: Text(
                  selectedCount > 0
                      ? l10n.mailboxSelectedCount(selectedCount)
                      : l10n.mailboxItemsCount(sortedJobs.length),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: receiveInProgress || selectedCount == 0
                    ? null
                    : store.receiveSelectedMailboxJobs,
                icon: receiveInProgress
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_rounded, size: 18),
                label: Text(
                  selectedCount == 0
                      ? l10n.actionReceive
                      : l10n.actionReceiveCount(selectedCount),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: sortedJobs.isEmpty
              ? Center(
                  child: _EmptyPaneMessage(
                    title: l10n.mailboxEmptyTitle,
                    body: l10n.mailboxEmptyBody,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: sortedJobs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final job = sortedJobs[index];
                    final selected = selectedJobIds.contains(job.id);
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: receiveInProgress
                          ? null
                          : () => store.toggleMailboxJobSelection(
                              job.id,
                              !selected,
                            ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFFEF7EE)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFFE1B48A)
                                : const Color(0xFFE7DED0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: selected,
                              onChanged: receiveInProgress
                                  ? null
                                  : (value) => store.toggleMailboxJobSelection(
                                      job.id,
                                      value ?? false,
                                    ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    job.rootName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.mailboxFromSender(
                                      job.sender,
                                      job.sizeLabel,
                                    ),
                                    style: const TextStyle(
                                      color: Color(0xFF7A847E),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
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
        color: const Color(0xFFF8F3EB),
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

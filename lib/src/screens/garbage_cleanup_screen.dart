import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quarkdrop/src/l10n/l10n.dart';
import 'package:quarkdrop/src/rust/api/app.dart' as rust_api;
import 'package:quarkdrop/src/state/app_store.dart';
import 'package:signals_flutter/signals_flutter.dart';

class GarbageCleanupScreen extends StatefulWidget {
  const GarbageCleanupScreen({super.key, required this.store});

  final AppStore store;

  @override
  State<GarbageCleanupScreen> createState() => _GarbageCleanupScreenState();
}

class _GarbageCleanupScreenState extends State<GarbageCleanupScreen> {
  late Future<rust_api.CleanupScanResult> _scanFuture;
  final Set<String> _selectedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _scanFuture = _load();
  }

  Future<rust_api.CleanupScanResult> _load() {
    return rust_api.scanGlobalCleanup();
  }

  Future<void> _reload() async {
    final future = _load();
    setState(() {
      _selectedIds.clear();
      _scanFuture = future;
    });
    await future;
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) {
      return;
    }
    final deletedIds = _selectedIds.toSet();
    widget.store.deviceMaintenanceBusy.value = true;
    widget.store.deviceMaintenanceBusyMessage.value =
        widget.store.l10n.deviceMaintenanceBusyGarbageCleanup;
    try {
      await rust_api.deleteCleanupItems(itemIds: deletedIds.toList());
      final oldResult = await _scanFuture;
      final remaining = oldResult.items
          .where((item) => !deletedIds.contains(item.id))
          .toList(growable: false);
      setState(() {
        _selectedIds.clear();
        _scanFuture = SynchronousFuture(rust_api.CleanupScanResult(
          totalCount: remaining.length,
          totalSizeLabel: oldResult.totalSizeLabel,
          items: remaining,
        ));
      });
    } catch (error) {
      widget.store.lastErrorMessage.value = error.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      widget.store.deviceMaintenanceBusy.value = false;
      widget.store.deviceMaintenanceBusyMessage.value = null;
    }
  }

  Future<void> _confirmAndDelete() async {
    if (_selectedIds.isEmpty) return;
    final l10n = widget.store.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.cleanupDeleteConfirmTitle),
          content: Text(l10n.cleanupDeleteConfirmBody(_selectedIds.length)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.actionCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.cleanupDeleteConfirmTitle),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await _deleteSelected();
    }
  }

  void _selectAll() async {
    try {
      final result = await _scanFuture;
      if (!mounted) return;
      final deletableItems = result.items.where((item) => item.canDelete);
      final allSelected =
          deletableItems.isNotEmpty &&
          deletableItems.every((item) => _selectedIds.contains(item.id));
      setState(() {
        if (allSelected) {
          _selectedIds.clear();
        } else {
          for (final item in deletableItems) {
            _selectedIds.add(item.id);
          }
        }
      });
    } catch (_) {}
  }

  void _toggleSelection(rust_api.CleanupItem item, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(item.id);
      } else {
        _selectedIds.remove(item.id);
      }
    });
  }

  void _toggleCategorySelection(
    List<rust_api.CleanupItem> items,
    bool selected,
  ) {
    setState(() {
      for (final item in items) {
        if (!item.canDelete) continue;
        if (selected) {
          _selectedIds.add(item.id);
        } else {
          _selectedIds.remove(item.id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final l10n = context.l10n;
      final busy = widget.store.deviceMaintenanceBusy.value;
      final busyMessage = widget.store.deviceMaintenanceBusyMessage.value;
      final hasActiveTransferJobs = widget.store.hasActiveTransferJobs.value;

      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.garbageCleanupTitle),
          actions: [
            IconButton(
              onPressed: busy ? null : _reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: l10n.actionSelectAll,
              onPressed: busy ? null : _selectAll,
              icon: const Icon(Icons.select_all_rounded),
            ),
            IconButton(
              onPressed:
                  busy || _selectedIds.isEmpty ? null : _confirmAndDelete,
              color: Theme.of(context).colorScheme.error,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          ],
        ),
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _reload,
              child: FutureBuilder<rust_api.CleanupScanResult>(
                future: _scanFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _ErrorState(
                      message: snapshot.error.toString(),
                      onRetry: _reload,
                    );
                  }
                  final result = snapshot.data!;
                  final items = result.items;
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _HeroCard(
                        count: result.totalCount,
                        sizeLabel: result.totalSizeLabel,
                        body: hasActiveTransferJobs
                            ? l10n.deviceMaintenanceActiveTransferBody
                            : l10n.garbageCleanupHintBody,
                        isWarning: hasActiveTransferJobs,
                      ),
                      const SizedBox(height: 16),
                      _CategoryCard(
                        title: l10n.deviceCleanupCategoryReadyTasks,
                        emptyLabel: l10n.deviceCleanupEmptyPreview,
                        items: items
                            .where(
                              (item) =>
                                  item.category ==
                                  rust_api.CleanupCategory.readyDownloadTask,
                            )
                            .toList(growable: false),
                        selectedIds: _selectedIds,
                        onToggle: _toggleSelection,
                        onToggleAll: _toggleCategorySelection,
                      ),
                      const SizedBox(height: 12),
                      _CategoryCard(
                        title: l10n.deviceCleanupCategoryIncompleteUploads,
                        emptyLabel: l10n.deviceCleanupEmptyPreview,
                        items: items
                            .where(
                              (item) =>
                                  item.category ==
                                  rust_api.CleanupCategory.incompleteUploadTask,
                            )
                            .toList(growable: false),
                        selectedIds: _selectedIds,
                        onToggle: _toggleSelection,
                        onToggleAll: _toggleCategorySelection,
                      ),
                      const SizedBox(height: 12),
                      _CategoryCard(
                        title: l10n.deviceCleanupCategoryBrokenTasks,
                        emptyLabel: l10n.deviceCleanupEmptyPreview,
                        items: items
                            .where(
                              (item) =>
                                  item.category ==
                                  rust_api.CleanupCategory.brokenTask,
                            )
                            .toList(growable: false),
                        selectedIds: _selectedIds,
                        onToggle: _toggleSelection,
                        onToggleAll: _toggleCategorySelection,
                      ),
                      const SizedBox(height: 12),
                      _CategoryCard(
                        title: l10n.deviceCleanupCategoryOtherFiles,
                        emptyLabel: l10n.deviceCleanupEmptyPreview,
                        items: items
                            .where(
                              (item) =>
                                  item.category ==
                                  rust_api.CleanupCategory.otherFile,
                            )
                            .toList(growable: false),
                        selectedIds: _selectedIds,
                        onToggle: _toggleSelection,
                        onToggleAll: _toggleCategorySelection,
                      ),
                    ],
                  );
                },
              ),
            ),
            if (busy)
              _CleanupMask(
                message:
                    busyMessage ?? l10n.deviceMaintenanceBusyGarbageCleanup,
              ),
          ],
        ),
      );
    });
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.count,
    required this.sizeLabel,
    required this.body,
    required this.isWarning,
  });

  final int count;
  final String sizeLabel;
  final String body;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tone = isWarning
        ? const Color(0xFFB26A00)
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tone.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isWarning
                    ? Icons.warning_amber_rounded
                    : Icons.cleaning_services,
                color: tone,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.garbageCleanupTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: tone,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(body, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 12),
          Text(
            context.l10n.cleanupSummaryLabel(count, sizeLabel),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.emptyLabel,
    required this.items,
    required this.selectedIds,
    required this.onToggle,
    required this.onToggleAll,
  });

  final String title;
  final String emptyLabel;
  final List<rust_api.CleanupItem> items;
  final Set<String> selectedIds;
  final void Function(rust_api.CleanupItem item, bool selected) onToggle;
  final void Function(List<rust_api.CleanupItem> items, bool selected) onToggleAll;

  @override
  Widget build(BuildContext context) {
    final deletableItems =
        items.where((item) => item.canDelete).toList(growable: false);
    final selectedCount =
        deletableItems.where((item) => selectedIds.contains(item.id)).length;
    final allSelected =
        deletableItems.isNotEmpty && selectedCount == deletableItems.length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$title (${items.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (deletableItems.isNotEmpty)
                Checkbox(
                  value: allSelected,
                  onChanged: (value) =>
                      onToggleAll(deletableItems, value ?? false),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Text(
              emptyLabel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...items.map(
              (item) => _CleanupSelectionTile(
                item: item,
                selected: selectedIds.contains(item.id),
                onToggle: onToggle,
              ),
            ),
        ],
      ),
    );
  }
}

class _CleanupSelectionTile extends StatelessWidget {
  const _CleanupSelectionTile({
    required this.item,
    required this.selected,
    required this.onToggle,
  });

  final rust_api.CleanupItem item;
  final bool selected;
  final void Function(rust_api.CleanupItem item, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: CheckboxListTile(
          value: selected,
          onChanged: item.canDelete
              ? (value) => onToggle(item, value ?? false)
              : null,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            item.title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '${item.deviceLabel} · ${item.sizeLabel} · ${_formatUpdatedLabel(item.updatedAtLabel)}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          secondary: item.canDelete
              ? null
              : const Icon(Icons.lock_outline, color: Color(0xFFB42318)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }
}

String _formatUpdatedLabel(String value) {
  final match = RegExp(r'(\d{10,})').firstMatch(value);
  if (match == null) {
    return value;
  }
  final raw = match.group(1);
  if (raw == null) {
    return value;
  }
  final timestamp = int.tryParse(raw);
  if (timestamp == null) {
    return raw;
  }
  try {
    final time = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}';
  } catch (_) {
    return raw;
  }
}

class _CleanupMask extends StatelessWidget {
  const _CleanupMask({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xB3000000),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: Text(context.l10n.actionRetry),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

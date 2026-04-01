part of 'home_shell.dart';

class _TransfersPane extends StatefulWidget {
  const _TransfersPane({required this.store});

  final AppStore store;

  @override
  State<_TransfersPane> createState() => _TransfersPaneState();
}

class _TransfersPaneState extends State<_TransfersPane>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      widget.store.refresh();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final store = widget.store;
      final jobs = store.transferJobs.value;
      final transferActionInProgress = store.transferActionInProgress.value;
      final hasCompletedJobs = jobs.any(
        (job) => job.stage == TransferStage.completed,
      );
      final unfinishedJobs = jobs
          .where((job) => job.stage != TransferStage.completed)
          .toList(growable: false);
      final sendingJobs = jobs
          .where(
            (job) =>
                job.direction == TransferDirection.send &&
                job.stage != TransferStage.completed,
          )
          .toList(growable: false);
      final receivingJobs = jobs
          .where(
            (job) =>
                job.direction == TransferDirection.receive &&
                job.stage != TransferStage.completed,
          )
          .toList(growable: false);
      final completedJobs = jobs
          .where((job) => job.stage == TransferStage.completed)
          .toList(growable: false);
      final allJobs = jobs.toList(growable: false);

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
          itemBuilder: (_, index) => _TransferListTile(
            job: filtered[index],
            store: store,
            transferActionInProgress: transferActionInProgress,
          ),
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
        return TabBarView(
          controller: _tabController,
          children: [
            buildJobList(unfinishedJobs),
            buildJobList(sendingJobs),
            buildJobList(receivingJobs),
            buildJobList(completedJobs),
            buildJobList(allJobs),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(child: _PaneTitle(title: context.l10n.transfersTitle)),
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
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: context.l10n.tabUnfinished(unfinishedJobs.length)),
                Tab(
                  text: context.l10n.tabSending(
                    sendingJobs.length,
                  ),
                ),
                Tab(
                  text: context.l10n.tabReceiving(
                    receivingJobs.length,
                  ),
                ),
                Tab(text: context.l10n.tabCompleted(completedJobs.length)),
                Tab(text: context.l10n.tabAll(allJobs.length)),
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
  const _TransferListTile({
    required this.job,
    required this.store,
    required this.transferActionInProgress,
  });

  final TransferJob job;
  final AppStore store;
  final bool transferActionInProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: _TransferTypeIcon(title: job.title),
                      ),
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: SizedBox(width: 10),
                      ),
                      TextSpan(text: job.title),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _StatusBadge(
                label: _stageLabel(context, job.stage),
                color: _stageColor(job.stage),
              ),
              if (job.stage != TransferStage.completed)
                _TransferJobMenuButton(
                  job: job,
                  store: store,
                  enabled: !transferActionInProgress,
                ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: job.progress,
              valueColor: AlwaysStoppedAnimation<Color>(
                _stageColor(job.stage),
              ),
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                job.direction == TransferDirection.send
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _progressLabel(context, job),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (job.sizeLabel.isNotEmpty)
                Text(
                  _sizeSummary(job),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _sizeSummary(TransferJob job) {
    if (job.sizeLabel.isEmpty) {
      return '';
    }
    if (job.stage == TransferStage.completed ||
        job.transferredSizeLabel.isEmpty ||
        job.transferredSizeLabel == job.sizeLabel) {
      return job.sizeLabel;
    }
    return '${job.transferredSizeLabel} / ${job.sizeLabel}';
  }
}

class _TransferJobMenuButton extends StatelessWidget {
  const _TransferJobMenuButton({
    required this.job,
    required this.store,
    required this.enabled,
  });

  final TransferJob job;
  final AppStore store;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<_TransferJobAction>(
      enabled: enabled,
      icon: Icon(
        Icons.more_vert_rounded,
        color: enabled
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
      ),
      padding: EdgeInsets.zero,
      splashRadius: 20,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _TransferJobAction.resume,
          child: ListTile(
            leading: const Icon(Icons.replay_rounded),
            title: Text(l10n.actionResumeTransfer),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _TransferJobAction.delete,
          child: ListTile(
            leading: Icon(
              Icons.delete_outline_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              l10n.actionDeleteRemoteJob,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      onSelected: (action) {
        switch (action) {
          case _TransferJobAction.resume:
            store.resumeTransfer(job);
          case _TransferJobAction.delete:
            store.deleteTransfer(job);
        }
      },
    );
  }
}

enum _TransferJobAction { resume, delete }

class _TransferTypeIcon extends StatelessWidget {
  const _TransferTypeIcon({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconForTitle(context, title);
    return Icon(icon, size: 18, color: color);
  }

  (IconData, Color) _iconForTitle(BuildContext context, String title) {
    final theme = Theme.of(context).colorScheme;
    final normalized = title.trim().toLowerCase();
    final extension = normalized.contains('.')
        ? normalized.split('.').last
        : '';
    if (_matches(extension, const ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'bmp', 'svg'])) {
      return (Icons.image_rounded, theme.tertiary);
    }
    if (_matches(extension, const ['mp4', 'mov', 'mkv', 'avi', 'webm', 'm4v'])) {
      return (Icons.videocam_rounded, const Color(0xFFD9485F));
    }
    if (_matches(extension, const ['mp3', 'wav', 'flac', 'aac', 'm4a', 'ogg'])) {
      return (Icons.audio_file_rounded, const Color(0xFF1D6F6D));
    }
    if (_matches(extension, const ['zip', 'rar', '7z', 'tar', 'gz', 'xz'])) {
      return (Icons.folder_zip_rounded, const Color(0xFF8A5B00));
    }
    if (_matches(extension, const ['pdf'])) {
      return (Icons.picture_as_pdf_rounded, const Color(0xFFB42318));
    }
    if (_matches(extension, const ['doc', 'docx', 'pages', 'txt', 'md', 'rtf'])) {
      return (Icons.description_rounded, theme.primary);
    }
    if (_matches(extension, const ['xls', 'xlsx', 'csv', 'numbers'])) {
      return (Icons.table_chart_rounded, const Color(0xFF2F7D32));
    }
    if (_matches(extension, const ['ppt', 'pptx', 'key'])) {
      return (Icons.slideshow_rounded, const Color(0xFFE56F00));
    }
    if (_matches(extension, const ['apk', 'dmg', 'pkg', 'exe', 'msi'])) {
      return (Icons.inventory_2_rounded, theme.secondary);
    }
    if (extension.isEmpty && !normalized.contains('.')) {
      return (Icons.folder_rounded, const Color(0xFF8A5B00));
    }
    return (Icons.insert_drive_file_rounded, theme.onSurfaceVariant);
  }

  bool _matches(String extension, List<String> candidates) {
    return extension.isNotEmpty && candidates.contains(extension);
  }
}

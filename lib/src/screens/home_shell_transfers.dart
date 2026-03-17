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
    _tabController = TabController(length: 4, vsync: this);
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
      final selectedJob = store.selectedTransfer.value;
      final transferActionInProgress = store.transferActionInProgress.value;
      final hasCompletedJobs = jobs.any(
        (job) => job.stage == TransferStage.completed,
      );
      // Tab filters
      final pendingJobs = jobs
          .where((job) => job.stage != TransferStage.completed)
          .toList(growable: false);
      final sendPendingJobs = jobs
          .where(
            (job) =>
                job.direction == TransferDirection.send &&
                job.stage != TransferStage.completed,
          )
          .toList(growable: false);
      final receiveCompletedJobs = jobs
          .where(
            (job) =>
                job.direction == TransferDirection.receive &&
                job.stage == TransferStage.completed,
          )
          .toList(growable: false);
      final completedJobs = jobs
          .where((job) => job.stage == TransferStage.completed)
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
          itemBuilder: (_, index) =>
              _TransferListTile(job: filtered[index], store: store),
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
                buildJobList(pendingJobs),
                buildJobList(sendPendingJobs),
                buildJobList(receiveCompletedJobs),
                buildJobList(completedJobs),
              ],
            );
            if (!wideLayout) {
              return tabs;
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: tabs),
                const SizedBox(width: 18),
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(right: 16),
                    child: _TransferDetailCard(
                      job: selectedJob,
                      transferActionInProgress: transferActionInProgress,
                      resumeInProgress: store.resumeInProgress.value,
                      onResume: selectedJob == null
                          ? null
                          : () => store.resumeTransfer(selectedJob),
                      onDeleteRemote: selectedJob == null
                          ? null
                          : () => store.deleteTransfer(selectedJob),
                    ),
                  ),
                ),
              ],
            );
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
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: context.l10n.tabPending(pendingJobs.length)),
                Tab(
                  text: context.l10n.tabSendQueuePending(
                    sendPendingJobs.length,
                  ),
                ),
                Tab(
                  text: context.l10n.tabReceiveQueueCompleted(
                    receiveCompletedJobs.length,
                  ),
                ),
                Tab(text: context.l10n.tabCompleted(completedJobs.length)),
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
          color: selected ? Theme.of(context).colorScheme.secondaryContainer : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
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
                    style: TextStyle(
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
            Text(job.subtitle, style: TextStyle(height: 1.45)),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: job.progress,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _stageColor(job.stage),
                ),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _progressLabel(context, job),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
                if (job.sizeLabel.isNotEmpty)
                  Text(
                    job.sizeLabel,
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
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
                  style: TextStyle(
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
            style: TextStyle(height: 1.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _progressLabel(context, job!),
            style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
              if (job!.sizeLabel.isNotEmpty)
                _DetailMetaChip(
                  icon: Icons.data_usage_rounded,
                  label: job!.sizeLabel,
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

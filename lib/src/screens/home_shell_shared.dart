part of 'home_shell.dart';

class _PaneTitle extends StatelessWidget {
  const _PaneTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        if (subtitle != null) const SizedBox(height: 6),
        if (subtitle != null) Text(subtitle!, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
    final label = direction == TransferDirection.send
        ? context.l10n.directionSend
        : context.l10n.directionReceive;
    final icon = direction == TransferDirection.send
        ? Icons.north_east_rounded
        : Icons.south_west_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
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
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5),
            ),
          ],
        ),
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

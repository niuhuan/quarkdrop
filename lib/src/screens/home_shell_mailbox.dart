part of 'home_shell.dart';

class _InboxPane extends StatelessWidget {
  const _InboxPane({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final jobs = store.inboxJobs.watch(context);
    final selectedJobIds = store.selectedMailboxJobIds.watch(context);
    final receiveInProgress = store.receiveInProgress.watch(context);

    final sortedJobs = jobs.toList(growable: false);
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
                      : (_) {
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
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.surface,
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
                            IconButton(
                              tooltip: l10n.actionReject,
                              onPressed: receiveInProgress
                                  ? null
                                  : () => store.rejectInboxJob(job.id),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: Color(0xFF9B3D16),
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

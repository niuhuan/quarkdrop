enum MailboxJobStatus { queued, autoReceiving, failed }

class InboxJob {
  const InboxJob({
    required this.id,
    required this.sender,
    required this.rootName,
    required this.summary,
    required this.sizeLabel,
    required this.receivedAtLabel,
    required this.isReady,
    required this.status,
    this.statusMessage,
  });

  final String id;
  final String sender;
  final String rootName;
  final String summary;
  final String sizeLabel;
  final String receivedAtLabel;
  final bool isReady;
  final MailboxJobStatus status;
  final String? statusMessage;

  InboxJob copyWith({MailboxJobStatus? status, String? statusMessage}) {
    return InboxJob(
      id: id,
      sender: sender,
      rootName: rootName,
      summary: summary,
      sizeLabel: sizeLabel,
      receivedAtLabel: receivedAtLabel,
      isReady: isReady,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

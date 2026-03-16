enum TransferStage {
  preparing,
  uploading,
  uploadingManifest,
  uploadingCommit,
  downloading,
  verifying,
  cleaningRemote,
  failed,
  completed,
}

class TransferJob {
  const TransferJob({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.stage,
    required this.direction,
  });

  final String id;
  final String title;
  final String subtitle;
  final double progress;
  final TransferStage stage;
  final TransferDirection direction;
}

enum TransferDirection { send, receive }

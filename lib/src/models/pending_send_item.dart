enum PendingSendKind { file, directory }

class PendingSendItem {
  const PendingSendItem({
    required this.path,
    required this.name,
    required this.kind,
  });

  final String path;
  final String name;
  final PendingSendKind kind;

  PendingSendItem copyWith({
    String? path,
    String? name,
    PendingSendKind? kind,
  }) {
    return PendingSendItem(
      path: path ?? this.path,
      name: name ?? this.name,
      kind: kind ?? this.kind,
    );
  }
}

part of 'app_store.dart';

extension AppStoreIntents on AppStore {
  void initIntentListeners() {
  }

  void addIncomingSharedFilePaths(List<String> paths) {
    if (paths.isEmpty) return;
    
    final items = <PendingSendItem>[];
    
    // Filter nested paths
    paths.sort((a, b) => a.length.compareTo(b.length));
    final filteredPaths = <String>[];
    for (final p in paths) {
      bool isNested = false;
      for (final selected in filteredPaths) {
        if (p.startsWith(selected + Platform.pathSeparator) || p == selected) {
          isNested = true;
          break;
        }
      }
      if (!isNested) {
        filteredPaths.add(p);
      }
    }

    for (var path in filteredPaths) {
      if (path.isEmpty) continue;
      if (path.startsWith('file://')) {
        path = Uri.parse(path).toFilePath();
      }
      final isDir = FileSystemEntity.isDirectorySync(path);
      final name =
          path.split(Platform.pathSeparator).where((e) => e.isNotEmpty).last;
      items.add(PendingSendItem(
        path: path,
        name: name,
        kind: isDir ? PendingSendKind.directory : PendingSendKind.file,
      ));
    }
    if (items.isNotEmpty) {
      _mergePendingSendItems(items);
      destination.value = AppDestination.send;
    }
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class PlatformPaths {
  const PlatformPaths({
    required this.configDir,
    required this.displayName,
    required this.requiresDownloadPicker,
    this.downloadDir,
  });

  final String configDir;
  final String? downloadDir;
  final String displayName;
  final bool requiresDownloadPicker;
}

class PlatformPathsResolver {
  static const _channel = MethodChannel('quarkdrop/platform_paths');

  static Future<PlatformPaths> resolve() async {
    if (kIsWeb) {
      throw UnsupportedError('QuarkDrop does not support web storage paths.');
    }

    if (Platform.isIOS || Platform.isAndroid || Platform.isMacOS) {
      final raw = await _channel.invokeMapMethod<String, Object?>(
        'getPlatformPaths',
      );
      if (raw == null) {
        throw StateError('Platform path channel returned no data.');
      }
      return PlatformPaths(
        configDir: raw['configDir'] as String,
        downloadDir: raw['downloadDir'] as String?,
        displayName: (raw['displayName'] as String?) ?? 'QuarkDrop',
        requiresDownloadPicker:
            (raw['requiresDownloadPicker'] as bool?) ?? false,
      );
    }

    final configDir = await getApplicationSupportDirectory();
    final downloadsDir = await getDownloadsDirectory();
    return PlatformPaths(
      configDir: configDir.path,
      downloadDir: downloadsDir?.path,
      displayName: 'QuarkDrop',
      requiresDownloadPicker: true,
    );
  }
}

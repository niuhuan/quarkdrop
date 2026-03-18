import 'package:flutter/services.dart';

class IosPickedMedia {
  const IosPickedMedia({required this.path, required this.name});

  final String path;
  final String name;
}

const _mediaPickerChannel = MethodChannel('quarkdrop/media_picker');

Future<List<IosPickedMedia>> pickMediaPreservingNames() async {
  final raw = await _mediaPickerChannel.invokeMethod<List<dynamic>>(
    'pickMediaPreservingNames',
  );
  if (raw == null || raw.isEmpty) {
    return const [];
  }

  return raw
      .map((item) => Map<Object?, Object?>.from(item as Map<Object?, Object?>))
      .map((item) {
        final path = (item['path'] as String?)?.trim() ?? '';
        final name = (item['name'] as String?)?.trim() ?? '';
        if (path.isEmpty || name.isEmpty) {
          throw const FormatException('invalid iOS media picker result');
        }
        return IosPickedMedia(path: path, name: name);
      })
      .toList(growable: false);
}

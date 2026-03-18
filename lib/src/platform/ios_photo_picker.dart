import 'package:flutter/services.dart';

class IosPickedPhoto {
  const IosPickedPhoto({required this.path, required this.name});

  final String path;
  final String name;
}

const _photoPickerChannel = MethodChannel('quarkdrop/photo_picker');

Future<List<IosPickedPhoto>> pickImagesPreservingNames() async {
  final raw = await _photoPickerChannel.invokeMethod<List<dynamic>>(
    'pickImagesPreservingNames',
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
          throw const FormatException('invalid iOS photo picker result');
        }
        return IosPickedPhoto(path: path, name: name);
      })
      .toList(growable: false);
}

// Platform file access for progress export/import (docs/07 §2: share_plus,
// file_picker; web: download / picker). Injectable so tests never open a
// platform sheet.
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

abstract interface class ProgressFiles {
  /// Hands [json] to the share sheet (Android) or downloads it (web).
  Future<void> save(String name, String json);

  /// Lets the user pick a `.json` file; `null` when cancelled.
  Future<String?> pick();
}

class PlatformProgressFiles implements ProgressFiles {
  const PlatformProgressFiles();

  static const _mime = 'application/json';

  @override
  Future<void> save(String name, String json) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(utf8.encode(json), mimeType: _mime, name: name)],
        fileNameOverrides: [name],
      ),
    );
  }

  @override
  Future<String?> pick() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (files.isEmpty) return null;
    return utf8.decode(await files.first.readAsBytes(), allowMalformed: true);
  }
}

final progressFilesProvider = Provider<ProgressFiles>(
  (ref) => const PlatformProgressFiles(),
);

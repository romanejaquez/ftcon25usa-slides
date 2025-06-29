import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart';

/// Loads a Rive file from the assets sub-folder
Uint8List loadFile(String filename) {
  final file = File(
      './${Directory.current.path.endsWith('/test') ? '' : 'test/'}$filename');
  if (!file.existsSync()) {
    throw Exception('Rive file does not exist at path: $filename');
  }
  return file.readAsBytesSync();
}

/// Loads in all the files in the batch_rivs directory ('test/assets/batch_rivs')
List<FileTesterWrapper> batchRiveFilesToTest() {
  final directory = Directory('test/assets/batch_rivs');

  final files = directory.listSync();
  return files
      .map((e) {
        try {
          final file = e as File;
          return FileTesterWrapper(
            file: file,
            fileName: basename(file.path),
          );
          // ignore: avoid_catches_without_on_clauses
        } catch (e, st) {
          debugPrintStack(stackTrace: st);
          throw Exception('Not a Rive file');
        }
      })
      .where((element) => extension(element.fileName) == '.riv')
      .toList();
}

class FileTesterWrapper {
  final File file;
  final String fileName;

  FileTesterWrapper({
    required this.file,
    required this.fileName,
  });
}

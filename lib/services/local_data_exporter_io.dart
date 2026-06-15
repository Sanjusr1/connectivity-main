import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'exported_file.dart';

Future<ExportedFile> exportTextFile({
  required String fileName,
  required String contents,
  required String mimeType,
}) async {
  final directory = await _exportDirectory();
  final file = File('${directory.path}${Platform.pathSeparator}$fileName');
  await file.writeAsString(contents, flush: true);
  return ExportedFile(fileName: fileName, path: file.path);
}

Future<Directory> _exportDirectory() async {
  if (Platform.isAndroid) {
    final externalDirectory = await getExternalStorageDirectory();
    if (externalDirectory != null) {
      return externalDirectory;
    }
  }

  return await getDownloadsDirectory() ??
      await getApplicationDocumentsDirectory();
}

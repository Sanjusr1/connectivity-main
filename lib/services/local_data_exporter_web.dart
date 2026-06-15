// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

import 'exported_file.dart';

Future<ExportedFile> exportTextFile({
  required String fileName,
  required String contents,
  required String mimeType,
}) async {
  final bytes = utf8.encode(contents);
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);

  return ExportedFile(fileName: fileName, downloadStarted: true);
}

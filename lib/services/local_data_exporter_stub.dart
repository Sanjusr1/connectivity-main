import 'exported_file.dart';

Future<ExportedFile> exportTextFile({
  required String fileName,
  required String contents,
  required String mimeType,
}) {
  throw UnsupportedError('File export is not supported on this platform.');
}

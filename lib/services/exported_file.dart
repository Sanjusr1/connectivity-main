class ExportedFile {
  const ExportedFile({
    required this.fileName,
    this.path,
    this.downloadStarted = false,
  });

  final String fileName;
  final String? path;
  final bool downloadStarted;
}

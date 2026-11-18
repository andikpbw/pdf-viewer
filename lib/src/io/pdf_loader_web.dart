import 'package:flutter/services.dart';

/// Throws an [UnsupportedError] on Web because direct file path access is
/// restricted by browser sandboxing; use `PdfViewer.fromBytes` instead.
Future<Uint8List> loadPdfFromFile(String path) {
  throw UnsupportedError(
    'Direct file path access is not available on Flutter Web. '
    'Use PdfViewer.fromBytes or PdfDocument.fromBytes instead.',
  );
}

/// Downloads raw PDF bytes from a remote HTTP/HTTPS [url] on Flutter Web.
Future<Uint8List> loadPdfFromNetwork(
  String url, {
  Map<String, String>? headers,
}) async {
  final Uri uri = Uri.parse(url);
  final ByteData data = await NetworkAssetBundle(uri).load(url);
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

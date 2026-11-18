import 'dart:typed_data';

/// Loads raw PDF bytes from a local file system [path].
Future<Uint8List> loadPdfFromFile(String path) {
  throw UnsupportedError(
    'Loading PDF files from a local file path is not supported on this platform.',
  );
}

/// Downloads raw PDF bytes from a remote HTTP/HTTPS [url].
Future<Uint8List> loadPdfFromNetwork(
  String url, {
  Map<String, String>? headers,
}) {
  throw UnsupportedError(
    'Loading PDF files from a network URL is not supported on this platform.',
  );
}

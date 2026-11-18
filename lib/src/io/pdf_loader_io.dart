import 'dart:io';
import 'dart:typed_data';

/// Loads raw PDF bytes from a local file system [path] using `dart:io`.
Future<Uint8List> loadPdfFromFile(String path) async {
  final File file = File(path);
  if (!await file.exists()) {
    throw FileSystemException('PDF file not found at path', path);
  }
  return file.readAsBytes();
}

/// Downloads raw PDF bytes from a remote HTTP/HTTPS [url] using [HttpClient].
Future<Uint8List> loadPdfFromNetwork(
  String url, {
  Map<String, String>? headers,
}) async {
  final Uri uri = Uri.parse(url);
  final HttpClient client = HttpClient();
  try {
    final HttpClientRequest request = await client.getUrl(uri);
    if (headers != null) {
      headers.forEach(request.headers.set);
    }
    final HttpClientResponse response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Failed to load PDF (HTTP ${response.statusCode})',
        uri: uri,
      );
    }
    final BytesBuilder builder = BytesBuilder(copy: false);
    await for (final List<int> chunk in response) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  } finally {
    client.close(force: true);
  }
}

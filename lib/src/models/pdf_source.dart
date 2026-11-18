import 'package:flutter/services.dart';

import 'pdf_document.dart';

/// Describes an asynchronous or synchronous source for loading a [PdfDocument].
sealed class PdfSource {
  /// Creates a [PdfSource].
  const PdfSource();

  /// Resolves and parses the [PdfDocument] from this source.
  Future<PdfDocument> resolve();
}

/// Loads a [PdfDocument] directly from an already parsed [document] instance.
class PdfDocumentSource extends PdfSource {
  /// Creates a [PdfDocumentSource].
  const PdfDocumentSource(this.document);

  /// The pre-parsed [PdfDocument].
  final PdfDocument document;

  @override
  Future<PdfDocument> resolve() async => document;
}

/// Loads a [PdfDocument] from an in-memory [Uint8List] byte buffer.
class PdfBytesSource extends PdfSource {
  /// Creates a [PdfBytesSource].
  const PdfBytesSource(this.bytes);

  /// Raw PDF file bytes.
  final Uint8List bytes;

  @override
  Future<PdfDocument> resolve() async => PdfDocument.fromBytes(bytes);
}

/// Loads a [PdfDocument] from a Flutter application asset.
class PdfAssetSource extends PdfSource {
  /// Creates a [PdfAssetSource].
  const PdfAssetSource(this.assetPath, {this.bundle});

  /// Path to the PDF asset registered in `pubspec.yaml`.
  final String assetPath;

  /// Optional custom [AssetBundle].
  final AssetBundle? bundle;

  @override
  Future<PdfDocument> resolve() =>
      PdfDocument.fromAsset(assetPath, bundle: bundle);
}

/// Loads a [PdfDocument] from a local file system path.
class PdfFileSource extends PdfSource {
  /// Creates a [PdfFileSource].
  const PdfFileSource(this.filePath);

  /// Local file system path to the PDF document.
  final String filePath;

  @override
  Future<PdfDocument> resolve() => PdfDocument.fromFile(filePath);
}

/// Loads a [PdfDocument] from an HTTP/HTTPS URL.
class PdfNetworkSource extends PdfSource {
  /// Creates a [PdfNetworkSource].
  const PdfNetworkSource(this.url, {this.headers});

  /// Remote HTTP or HTTPS URL of the PDF file.
  final String url;

  /// Optional HTTP request headers (for example, `Authorization`).
  final Map<String, String>? headers;

  @override
  Future<PdfDocument> resolve() =>
      PdfDocument.fromNetwork(url, headers: headers);
}

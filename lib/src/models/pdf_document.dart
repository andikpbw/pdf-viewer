import 'package:flutter/services.dart';

import '../io/pdf_loader.dart';
import '../parser/pdf_parser.dart';
import 'pdf_bookmark.dart';
import 'pdf_metadata.dart';
import 'pdf_page_data.dart';
import 'pdf_search_result.dart';

/// Represents a loaded and parsed PDF document ready for viewing, searching,
/// text extraction, and annotating.
class PdfDocument {
  /// Creates a [PdfDocument] from parsed pages, metadata, and bookmarks.
  const PdfDocument({
    required this.pages,
    this.metadata = const PdfMetadata(),
    this.bookmarks = const <PdfBookmark>[],
    this.rawBytes,
  });

  /// Parses a [PdfDocument] synchronously from raw PDF [bytes].
  factory PdfDocument.fromBytes(Uint8List bytes) {
    return PdfParser.parseBytes(bytes);
  }

  /// Loads and parses a [PdfDocument] from a Flutter asset bundle [assetPath].
  static Future<PdfDocument> fromAsset(
    String assetPath, {
    AssetBundle? bundle,
  }) async {
    final AssetBundle effectiveBundle = bundle ?? rootBundle;
    final ByteData byteData = await effectiveBundle.load(assetPath);
    final Uint8List bytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
    return PdfParser.parseBytes(bytes);
  }

  /// Loads and parses a [PdfDocument] from a local file [filePath].
  static Future<PdfDocument> fromFile(String filePath) async {
    final Uint8List bytes = await loadPdfFromFile(filePath);
    return PdfParser.parseBytes(bytes);
  }

  /// Downloads and parses a [PdfDocument] from an HTTP/HTTPS [url].
  static Future<PdfDocument> fromNetwork(
    String url, {
    Map<String, String>? headers,
  }) async {
    final Uint8List bytes = await loadPdfFromNetwork(url, headers: headers);
    return PdfParser.parseBytes(bytes);
  }

  /// Ordered list of pages in the PDF document.
  final List<PdfPageData> pages;

  /// Document-level metadata extracted from the PDF `/Info` dictionary.
  final PdfMetadata metadata;

  /// Table of contents / bookmarks embedded in or inferred from the document.
  final List<PdfBookmark> bookmarks;

  /// Optional original raw PDF bytes.
  final Uint8List? rawBytes;

  /// Total number of pages in the document.
  int get pageCount => pages.length;

  /// Approximate total word count across all pages in the document.
  int get wordCount {
    final String text = extractText().trim();
    if (text.isEmpty) {
      return 0;
    }
    return text.split(RegExp(r'\s+')).length;
  }

  /// Returns the [PdfPageData] for the 1-based [pageNumber].
  ///
  /// Throws a [RangeError] if [pageNumber] is outside `1..pageCount`.
  PdfPageData getPage(int pageNumber) {
    if (pageNumber < 1 || pageNumber > pages.length) {
      throw RangeError.range(pageNumber, 1, pages.length, 'pageNumber');
    }
    return pages[pageNumber - 1];
  }

  /// Extracts concatenated plain text from the entire document, or from a
  /// single 1-based [pageNumber] when provided.
  String extractText({int? pageNumber}) {
    if (pageNumber != null) {
      if (pageNumber < 1 || pageNumber > pages.length) {
        return '';
      }
      return pages[pageNumber - 1].plainText;
    }
    return pages.map((PdfPageData p) => p.plainText).join('\n\n');
  }

  /// Performs a full-text search across all pages in the document.
  ///
  /// Returns a list of [PdfSearchResult] objects ordered by page number and
  /// position on each page.
  List<PdfSearchResult> searchText(
    String query, {
    bool caseSensitive = false,
  }) {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const <PdfSearchResult>[];
    }
    final String needle = caseSensitive ? trimmed : trimmed.toLowerCase();
    final List<PdfSearchResult> results = <PdfSearchResult>[];

    for (final PdfPageData page in pages) {
      int matchIdxOnPage = 0;
      final double pageWidth = page.width <= 0 ? 595.28 : page.width;
      final double pageHeight = page.height <= 0 ? 841.89 : page.height;

      for (final PdfTextElement element in page.textElements) {
        final String haystack =
            caseSensitive ? element.text : element.text.toLowerCase();
        int startIndex = 0;
        while (true) {
          final int foundIndex = haystack.indexOf(needle, startIndex);
          if (foundIndex == -1) {
            break;
          }
          final int endIndex = foundIndex + needle.length;
          final String matched = element.text.substring(foundIndex, endIndex);

          // Compute proportional horizontal bounds within the text element.
          final int totalChars = element.text.isEmpty ? 1 : element.text.length;
          final double startRatio = foundIndex / totalChars;
          final double widthRatio = needle.length / totalChars;
          final double leftPt =
              element.bounds.left + element.bounds.width * startRatio;
          final double widthPt =
              (element.bounds.width * widthRatio).clamp(8.0, pageWidth);

          final Rect normalizedBounds = Rect.fromLTWH(
            (leftPt / pageWidth).clamp(0.0, 1.0),
            (element.bounds.top / pageHeight).clamp(0.0, 1.0),
            (widthPt / pageWidth).clamp(0.01, 1.0),
            (element.bounds.height / pageHeight).clamp(0.01, 1.0),
          );

          final int snippetStart =
              (foundIndex - 20).clamp(0, element.text.length);
          final int snippetEnd = (endIndex + 20).clamp(0, element.text.length);
          final String snippet =
              element.text.substring(snippetStart, snippetEnd).trim();

          results.add(
            PdfSearchResult(
              pageNumber: page.pageNumber,
              matchIndexOnPage: matchIdxOnPage++,
              matchedText: matched,
              surroundingSnippet: snippet,
              bounds: normalizedBounds,
            ),
          );

          startIndex = foundIndex + (needle.isEmpty ? 1 : needle.length);
        }
      }
    }

    return results;
  }
}

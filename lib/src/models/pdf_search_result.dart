import 'dart:ui';
import 'package:flutter/foundation.dart';

/// Represents a single full-text search match within a PDF document.
@immutable
class PdfSearchResult {
  /// Creates a [PdfSearchResult].
  const PdfSearchResult({
    required this.pageNumber,
    required this.matchIndexOnPage,
    required this.matchedText,
    required this.surroundingSnippet,
    required this.bounds,
  });

  /// The 1-based page number where the match was found.
  final int pageNumber;

  /// The 0-based index of this match among all matches on the same page.
  final int matchIndexOnPage;

  /// The exact substring that matched the search query.
  final String matchedText;

  /// A short contextual text snippet surrounding the match.
  final String surroundingSnippet;

  /// Normalized bounding rectangle (`0.0..1.0` relative to page dimensions)
  /// highlighting where the match is located on the page.
  final Rect bounds;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PdfSearchResult &&
        other.pageNumber == pageNumber &&
        other.matchIndexOnPage == matchIndexOnPage &&
        other.matchedText == matchedText &&
        other.bounds == bounds;
  }

  @override
  int get hashCode => Object.hash(
        pageNumber,
        matchIndexOnPage,
        matchedText,
        bounds,
      );

  @override
  String toString() =>
      'PdfSearchResult(page: $pageNumber, text: "$matchedText", bounds: $bounds)';
}

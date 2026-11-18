import 'package:flutter/foundation.dart';

/// Represents a document outline entry (table of contents item) or user bookmark.
@immutable
class PdfBookmark {
  /// Creates a [PdfBookmark] instance.
  const PdfBookmark({
    required this.id,
    required this.title,
    required this.pageNumber,
    this.children = const <PdfBookmark>[],
    this.isUserBookmark = false,
    this.createdAt,
  });

  /// Creates a [PdfBookmark] from a JSON map.
  factory PdfBookmark.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawChildren =
        (json['children'] as List<dynamic>?) ?? const <dynamic>[];
    return PdfBookmark(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
      isUserBookmark: (json['isUserBookmark'] as bool?) ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      children: rawChildren
          .whereType<Map<String, dynamic>>()
          .map(PdfBookmark.fromJson)
          .toList(growable: false),
    );
  }

  /// Unique identifier for this bookmark.
  final String id;

  /// Display title of the bookmark or section heading.
  final String title;

  /// Target 1-based page number in the document.
  final int pageNumber;

  /// Nested sub-bookmarks under this outline item.
  final List<PdfBookmark> children;

  /// Whether this bookmark was created by the user rather than embedded in the PDF.
  final bool isUserBookmark;

  /// Optional timestamp indicating when the bookmark was created.
  final DateTime? createdAt;

  /// Returns a copy of this [PdfBookmark] with the specified fields updated.
  PdfBookmark copyWith({
    String? id,
    String? title,
    int? pageNumber,
    List<PdfBookmark>? children,
    bool? isUserBookmark,
    DateTime? createdAt,
  }) {
    return PdfBookmark(
      id: id ?? this.id,
      title: title ?? this.title,
      pageNumber: pageNumber ?? this.pageNumber,
      children: children ?? this.children,
      isUserBookmark: isUserBookmark ?? this.isUserBookmark,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Serializes this [PdfBookmark] to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'pageNumber': pageNumber,
      'isUserBookmark': isUserBookmark,
      'createdAt': createdAt?.toIso8601String(),
      'children': children.map((PdfBookmark c) => c.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PdfBookmark &&
        other.id == id &&
        other.title == title &&
        other.pageNumber == pageNumber &&
        other.isUserBookmark == isUserBookmark &&
        listEquals(other.children, children);
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        pageNumber,
        isUserBookmark,
        Object.hashAll(children),
      );
}

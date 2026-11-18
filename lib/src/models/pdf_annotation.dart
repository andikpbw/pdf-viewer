import 'dart:convert';
import 'package:flutter/material.dart';

/// Supported interactive annotation types in `pdf_viewer`.
enum PdfAnnotationType {
  /// A semi-transparent rectangular highlight over a region of a page.
  highlight,

  /// A freehand ink stroke drawn on a page.
  ink,

  /// A sticky note or comment anchored to a specific point on a page.
  stickyNote,

  /// A text label or stamp placed on a page.
  stamp,
}

/// Active interactive tool selected in the annotation toolbar.
enum PdfAnnotationTool {
  /// Default pan, zoom, and text-inspection mode (no drawing).
  none,

  /// Rectangular highlighter tool.
  highlight,

  /// Freehand pen/ink drawing tool.
  ink,

  /// Sticky note placement tool.
  stickyNote,
}

/// Represents a user or document annotation placed on a specific PDF page.
///
/// Coordinates in [rect] and [points] are stored in normalized page space
/// (`0.0` to `1.0` relative to page width and height) so annotations scale
/// accurately across any zoom level or viewport size.
@immutable
class PdfAnnotation {
  /// Creates a [PdfAnnotation].
  const PdfAnnotation({
    required this.id,
    required this.pageNumber,
    required this.type,
    this.color = const Color(0xFFFFEB3B),
    this.opacity = 0.45,
    this.strokeWidth = 3.0,
    this.rect,
    this.points = const <Offset>[],
    this.text,
    this.author,
    required this.createdAt,
  });

  /// Restores a [PdfAnnotation] from a JSON map.
  factory PdfAnnotation.fromJson(Map<String, dynamic> json) {
    final String typeName =
        (json['type'] as String?) ?? PdfAnnotationType.highlight.name;
    final PdfAnnotationType resolvedType = PdfAnnotationType.values.firstWhere(
      (PdfAnnotationType t) => t.name == typeName,
      orElse: () => PdfAnnotationType.highlight,
    );

    Rect? parsedRect;
    if (json['rect'] is Map<String, dynamic>) {
      final Map<String, dynamic> r = json['rect'] as Map<String, dynamic>;
      parsedRect = Rect.fromLTWH(
        (r['left'] as num?)?.toDouble() ?? 0.0,
        (r['top'] as num?)?.toDouble() ?? 0.0,
        (r['width'] as num?)?.toDouble() ?? 0.0,
        (r['height'] as num?)?.toDouble() ?? 0.0,
      );
    }

    final List<Offset> parsedPoints = <Offset>[];
    if (json['points'] is List<dynamic>) {
      for (final dynamic item in json['points'] as List<dynamic>) {
        if (item is Map<String, dynamic>) {
          parsedPoints.add(
            Offset(
              (item['dx'] as num?)?.toDouble() ?? 0.0,
              (item['dy'] as num?)?.toDouble() ?? 0.0,
            ),
          );
        }
      }
    }

    return PdfAnnotation(
      id: json['id'] as String? ?? '',
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
      type: resolvedType,
      color: Color((json['color'] as num?)?.toInt() ?? 0xFFFFEB3B),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.45,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 3.0,
      rect: parsedRect,
      points: parsedPoints,
      text: json['text'] as String?,
      author: json['author'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// Unique identifier for the annotation.
  final String id;

  /// 1-based page number on which this annotation appears.
  final int pageNumber;

  /// The type of annotation.
  final PdfAnnotationType type;

  /// Primary color of the annotation.
  final Color color;

  /// Opacity multiplier (`0.0` to `1.0`).
  final double opacity;

  /// Stroke width in logical pixels (used primarily for [PdfAnnotationType.ink]).
  final double strokeWidth;

  /// Normalized bounding box (`0.0..1.0` relative to page width and height).
  final Rect? rect;

  /// Normalized polyline points (`0.0..1.0`) for freehand ink strokes.
  final List<Offset> points;

  /// Text content for sticky notes or stamps.
  final String? text;

  /// Optional author name associated with the annotation.
  final String? author;

  /// Timestamp when the annotation was created.
  final DateTime createdAt;

  /// Creates a copy of this [PdfAnnotation] with updated fields.
  PdfAnnotation copyWith({
    String? id,
    int? pageNumber,
    PdfAnnotationType? type,
    Color? color,
    double? opacity,
    double? strokeWidth,
    Rect? rect,
    List<Offset>? points,
    String? text,
    String? author,
    DateTime? createdAt,
  }) {
    return PdfAnnotation(
      id: id ?? this.id,
      pageNumber: pageNumber ?? this.pageNumber,
      type: type ?? this.type,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      rect: rect ?? this.rect,
      points: points ?? this.points,
      text: text ?? this.text,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts this [PdfAnnotation] to a JSON-serializable map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'pageNumber': pageNumber,
      'type': type.name,
      'color': color.toARGB32(),
      'opacity': opacity,
      'strokeWidth': strokeWidth,
      if (rect != null)
        'rect': <String, double>{
          'left': rect!.left,
          'top': rect!.top,
          'width': rect!.width,
          'height': rect!.height,
        },
      'points': points
          .map((Offset p) => <String, double>{'dx': p.dx, 'dy': p.dy})
          .toList(),
      'text': text,
      'author': author,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Encodes a list of [PdfAnnotation] objects into a JSON string.
  static String encodeList(List<PdfAnnotation> annotations) {
    return jsonEncode(
      annotations.map((PdfAnnotation a) => a.toJson()).toList(),
    );
  }

  /// Decodes a JSON string into a list of [PdfAnnotation] objects.
  static List<PdfAnnotation> decodeList(String jsonString) {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! List<dynamic>) {
      return const <PdfAnnotation>[];
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(PdfAnnotation.fromJson)
        .toList();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PdfAnnotation &&
        other.id == id &&
        other.pageNumber == pageNumber &&
        other.type == type &&
        other.color == color &&
        other.opacity == opacity &&
        other.strokeWidth == strokeWidth &&
        other.rect == rect &&
        other.text == text &&
        other.author == author;
  }

  @override
  int get hashCode => Object.hash(
        id,
        pageNumber,
        type,
        color,
        opacity,
        strokeWidth,
        rect,
        text,
        author,
      );
}

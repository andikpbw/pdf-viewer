import 'package:flutter/painting.dart';

/// Base class for vector or raster graphical elements on a PDF page.
sealed class PdfGraphicElement {
  /// Creates a [PdfGraphicElement].
  const PdfGraphicElement();
}

/// A positioned text run on a PDF page.
class PdfTextElement extends PdfGraphicElement {
  /// Creates a [PdfTextElement].
  const PdfTextElement({
    required this.text,
    required this.bounds,
    this.fontSize = 12.0,
    this.color = const Color(0xFF111827),
    this.fontFamily,
    this.isBold = false,
    this.isItalic = false,
    this.isMonospace = false,
  });

  /// The text string to render.
  final String text;

  /// Bounding box in PDF page points (origin at top-left of page, in points).
  final Rect bounds;

  /// Font size in PDF points.
  final double fontSize;

  /// Fill color of the text.
  final Color color;

  /// Optional font family name.
  final String? fontFamily;

  /// Whether the font weight is bold.
  final bool isBold;

  /// Whether the font style is italic.
  final bool isItalic;

  /// Whether the font uses a monospace family.
  final bool isMonospace;
}

/// A rectangle primitive (filled, stroked, or both) on a PDF page.
class PdfRectElement extends PdfGraphicElement {
  /// Creates a [PdfRectElement].
  const PdfRectElement({
    required this.rect,
    this.fillColor,
    this.strokeColor,
    this.strokeWidth = 1.0,
    this.cornerRadius = 0.0,
  });

  /// Rectangle coordinates in PDF page points (origin at top-left).
  final Rect rect;

  /// Optional interior fill color.
  final Color? fillColor;

  /// Optional border stroke color.
  final Color? strokeColor;

  /// Border line width in points.
  final double strokeWidth;

  /// Optional corner radius in points.
  final double cornerRadius;
}

/// A line segment primitive on a PDF page.
class PdfLineElement extends PdfGraphicElement {
  /// Creates a [PdfLineElement].
  const PdfLineElement({
    required this.start,
    required this.end,
    this.color = const Color(0xFFCBD5E1),
    this.strokeWidth = 1.0,
  });

  /// Start point in page coordinates (points).
  final Offset start;

  /// End point in page coordinates (points).
  final Offset end;

  /// Stroke color of the line.
  final Color color;

  /// Width of the line in points.
  final double strokeWidth;
}

/// A polygonal or bezier path primitive on a PDF page.
class PdfPathElement extends PdfGraphicElement {
  /// Creates a [PdfPathElement].
  const PdfPathElement({
    required this.points,
    this.fillColor,
    this.strokeColor,
    this.strokeWidth = 1.0,
    this.isClosed = false,
  });

  /// Ordered vertices of the path in page points.
  final List<Offset> points;

  /// Optional fill color.
  final Color? fillColor;

  /// Optional stroke color.
  final Color? strokeColor;

  /// Stroke width in points.
  final double strokeWidth;

  /// Whether the path should be closed before painting.
  final bool isClosed;
}

/// Represents a single parsed page of a PDF document.
class PdfPageData {
  /// Creates a [PdfPageData] instance.
  const PdfPageData({
    required this.pageNumber,
    this.width = 595.28,
    this.height = 841.89,
    this.rotation = 0,
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.elements = const <PdfGraphicElement>[],
    this.customImageProvider,
  });

  /// 1-based page number.
  final int pageNumber;

  /// Page width in PDF points (default is A4 width: `595.28` pt).
  final double width;

  /// Page height in PDF points (default is A4 height: `841.89` pt).
  final double height;

  /// Intrinsic page rotation in degrees (`0`, `90`, `180`, or `270`).
  final int rotation;

  /// Background paper color of the page.
  final Color backgroundColor;

  /// Ordered graphical and text elements parsed from the page's content stream.
  final List<PdfGraphicElement> elements;

  /// Optional pre-rasterized image provider if rendered by an external rasterizer.
  final ImageProvider? customImageProvider;

  /// Aspect ratio (`width / height`), taking 90°/270° rotation into account.
  double get aspectRatio {
    final bool isTransposed = (rotation % 180).abs() == 90;
    final double effectiveWidth = isTransposed ? height : width;
    final double effectiveHeight = isTransposed ? width : height;
    if (effectiveHeight <= 0) {
      return 1.0;
    }
    return effectiveWidth / effectiveHeight;
  }

  /// Extracts all text elements on this page in reading order.
  List<PdfTextElement> get textElements =>
      elements.whereType<PdfTextElement>().toList(growable: false);

  /// Concatenated plain text of all text elements on this page.
  String get plainText =>
      textElements.map((PdfTextElement e) => e.text).join(' ');

  /// Creates a copy of this [PdfPageData] with updated properties.
  PdfPageData copyWith({
    int? pageNumber,
    double? width,
    double? height,
    int? rotation,
    Color? backgroundColor,
    List<PdfGraphicElement>? elements,
    ImageProvider? customImageProvider,
  }) {
    return PdfPageData(
      pageNumber: pageNumber ?? this.pageNumber,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      elements: elements ?? this.elements,
      customImageProvider: customImageProvider ?? this.customImageProvider,
    );
  }
}

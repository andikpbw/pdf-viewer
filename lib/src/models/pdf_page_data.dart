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

/// A single drawing command inside a [PdfPathElement] supporting straight
/// segments, cubic Bezier curves, and closed subpaths.
sealed class PdfPathCommand {
  /// Creates a [PdfPathCommand].
  const PdfPathCommand();
}

/// Moves the path pen to [point] without drawing.
class PdfMoveToCommand extends PdfPathCommand {
  /// Creates a [PdfMoveToCommand].
  const PdfMoveToCommand(this.point);

  /// Target point in PDF page coordinates (origin at top-left).
  final Offset point;
}

/// Draws a straight line segment from the current point to [point].
class PdfLineToCommand extends PdfPathCommand {
  /// Creates a [PdfLineToCommand].
  const PdfLineToCommand(this.point);

  /// Segment destination in PDF page coordinates (origin at top-left).
  final Offset point;
}

/// Draws a cubic Bezier curve using control points [control1], [control2], and
/// destination [end].
class PdfCubicToCommand extends PdfPathCommand {
  /// Creates a [PdfCubicToCommand].
  const PdfCubicToCommand(this.control1, this.control2, this.end);

  /// First cubic control point.
  final Offset control1;

  /// Second cubic control point.
  final Offset control2;

  /// Destination endpoint.
  final Offset end;
}

/// Closes the current subpath back to its initial move-to point.
class PdfClosePathCommand extends PdfPathCommand {
  /// Creates a [PdfClosePathCommand].
  const PdfClosePathCommand();
}

/// A polygonal or cubic Bezier path primitive on a PDF page.
class PdfPathElement extends PdfGraphicElement {
  /// Creates a [PdfPathElement].
  const PdfPathElement({
    this.points = const <Offset>[],
    this.commands = const <PdfPathCommand>[],
    this.fillColor,
    this.strokeColor,
    this.strokeWidth = 1.0,
    this.isClosed = false,
  });

  /// Ordered vertices of a polygonal path in page points.
  final List<Offset> points;

  /// Optional rich vector commands (including cubic Bezier curves and
  /// multi-subpath contours). When non-empty, takes precedence over [points].
  final List<PdfPathCommand> commands;

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

  /// Finds the [PdfTextElement] located at [normalizedPoint] (`0.0..1.0`),
  /// or returns `null` if no text run intersects that location.
  PdfTextElement? hitTestText(Offset normalizedPoint) {
    final double px = normalizedPoint.dx * width;
    final double py = normalizedPoint.dy * height;
    final Offset pagePoint = Offset(px, py);

    for (final PdfTextElement el in textElements) {
      if (el.bounds.inflate(4.0).contains(pagePoint)) {
        return el;
      }
    }
    return null;
  }

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

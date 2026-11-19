import 'package:flutter/widgets.dart';

import '../models/pdf_page_data.dart';
import '../models/pdf_search_result.dart';
import '../theme/pdf_viewer_theme.dart';

/// Renders a single [PdfPageData] using hardware-accelerated Flutter vector
/// canvas primitives, optional search match highlights, and active text
/// selection overlays.
class PdfPageCanvas extends StatelessWidget {
  /// Creates a [PdfPageCanvas].
  const PdfPageCanvas({
    super.key,
    required this.page,
    this.searchResults = const <PdfSearchResult>[],
    this.activeSearchResult,
    this.colorMode = PdfColorMode.normal,
    this.rotationOffset = 0,
    this.searchHighlightColor = const Color(0x66FACC15),
    this.activeSearchHighlightColor = const Color(0xA6F97316),
    this.selectedBounds,
    this.selectionColor = const Color(0x4D3B82F6),
    this.fontFamily,
    this.isThumbnail = false,
  });

  /// The parsed page model to render.
  final PdfPageData page;

  /// Search matches located on this page.
  final List<PdfSearchResult> searchResults;

  /// The currently focused search result (if located on this page).
  final PdfSearchResult? activeSearchResult;

  /// Reading color filter applied to the page surface.
  final PdfColorMode colorMode;

  /// Additional clockwise rotation in degrees (`0`, `90`, `180`, `270`).
  final int rotationOffset;

  /// Fill color for non-active search match highlights.
  final Color searchHighlightColor;

  /// Fill color for the active search match highlight.
  final Color activeSearchHighlightColor;

  /// Optional normalized bounding rectangle (`0.0..1.0`) of selected text.
  final Rect? selectedBounds;

  /// Fill color used to highlight [selectedBounds].
  final Color selectionColor;

  /// Optional default font family for rendered PDF text runs.
  final String? fontFamily;

  /// Whether this canvas is being rendered inside a compact thumbnail preview.
  final bool isThumbnail;

  @override
  Widget build(BuildContext context) {
    final int totalRotation = (page.rotation + rotationOffset) % 360;
    final int quarterTurns = (totalRotation ~/ 90) % 4;
    final String? effectiveFontFamily =
        fontFamily ?? DefaultTextStyle.of(context).style.fontFamily;

    Widget content = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _PdfPageVectorPainter(
            page: page,
            searchResults:
                isThumbnail ? const <PdfSearchResult>[] : searchResults,
            activeSearchResult: isThumbnail ? null : activeSearchResult,
            searchHighlightColor: searchHighlightColor,
            activeSearchHighlightColor: activeSearchHighlightColor,
            selectedBounds: isThumbnail ? null : selectedBounds,
            selectionColor: selectionColor,
            fontFamily: effectiveFontFamily,
          ),
          child: page.customImageProvider != null
              ? Image(
                  image: page.customImageProvider!,
                  fit: BoxFit.fill,
                )
              : const SizedBox.expand(),
        );
      },
    );

    if (quarterTurns != 0) {
      content = RotatedBox(
        quarterTurns: quarterTurns,
        child: content,
      );
    }

    final ColorFilter? filter = colorMode.colorFilter;
    if (filter != null) {
      content = ColorFiltered(
        colorFilter: filter,
        child: content,
      );
    }

    return RepaintBoundary(child: content);
  }
}

class _PdfPageVectorPainter extends CustomPainter {
  _PdfPageVectorPainter({
    required this.page,
    required this.searchResults,
    required this.activeSearchResult,
    required this.searchHighlightColor,
    required this.activeSearchHighlightColor,
    required this.selectedBounds,
    required this.selectionColor,
    required this.fontFamily,
  });

  final PdfPageData page;
  final List<PdfSearchResult> searchResults;
  final PdfSearchResult? activeSearchResult;
  final Color searchHighlightColor;
  final Color activeSearchHighlightColor;
  final Rect? selectedBounds;
  final Color selectionColor;
  final String? fontFamily;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final Paint bgPaint = Paint()
      ..color = page.backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final double pageW = page.width <= 0 ? 595.28 : page.width;
    final double pageH = page.height <= 0 ? 841.89 : page.height;
    final double scaleX = size.width / pageW;
    final double scaleY = size.height / pageH;

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    for (final PdfGraphicElement element in page.elements) {
      if (element is PdfRectElement) {
        _paintRect(canvas, element, scaleX, scaleY);
      } else if (element is PdfLineElement) {
        _paintLine(canvas, element, scaleX, scaleY);
      } else if (element is PdfPathElement) {
        _paintPath(canvas, element, scaleX, scaleY);
      } else if (element is PdfTextElement) {
        _paintText(canvas, element, scaleX, scaleY, size.width);
      }
    }

    // Paint active text selection overlay.
    if (selectedBounds != null) {
      final Rect selRect = Rect.fromLTWH(
        selectedBounds!.left * size.width,
        selectedBounds!.top * size.height,
        selectedBounds!.width * size.width,
        selectedBounds!.height * size.height,
      ).inflate(2.5);
      final RRect rrect = RRect.fromRectAndRadius(
        selRect,
        const Radius.circular(4.0),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = selectionColor
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = selectionColor.withValues(alpha: 0.85)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke,
      );
    }

    // Paint search highlights on top of page content.
    if (searchResults.isNotEmpty) {
      for (final PdfSearchResult match in searchResults) {
        final bool isActive = match == activeSearchResult;
        final Rect highlightRect = Rect.fromLTWH(
          match.bounds.left * size.width,
          match.bounds.top * size.height,
          match.bounds.width * size.width,
          match.bounds.height * size.height,
        ).inflate(2.2);
        final RRect rrect = RRect.fromRectAndRadius(
          highlightRect,
          const Radius.circular(3.5),
        );
        final Paint fillPaint = Paint()
          ..color = isActive ? activeSearchHighlightColor : searchHighlightColor
          ..style = PaintingStyle.fill;
        canvas.drawRRect(rrect, fillPaint);

        if (isActive) {
          final Paint borderPaint = Paint()
            ..color = const Color(0xFFEA580C)
            ..strokeWidth = 1.6
            ..style = PaintingStyle.stroke;
          canvas.drawRRect(rrect, borderPaint);
        }
      }
    }

    canvas.restore();
  }

  void _paintRect(
    Canvas canvas,
    PdfRectElement el,
    double scaleX,
    double scaleY,
  ) {
    final Rect scaledRect = Rect.fromLTWH(
      el.rect.left * scaleX,
      el.rect.top * scaleY,
      el.rect.width * scaleX,
      el.rect.height * scaleY,
    );
    final double radius = el.cornerRadius * ((scaleX + scaleY) * 0.5);

    if (el.fillColor != null) {
      final Paint fillPaint = Paint()
        ..color = el.fillColor!
        ..style = PaintingStyle.fill;
      if (radius > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(scaledRect, Radius.circular(radius)),
          fillPaint,
        );
      } else {
        canvas.drawRect(scaledRect, fillPaint);
      }
    }

    if (el.strokeColor != null && el.strokeWidth > 0) {
      final Paint strokePaint = Paint()
        ..color = el.strokeColor!
        ..strokeWidth = (el.strokeWidth * scaleX).clamp(0.5, 16.0)
        ..style = PaintingStyle.stroke;
      if (radius > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(scaledRect, Radius.circular(radius)),
          strokePaint,
        );
      } else {
        canvas.drawRect(scaledRect, strokePaint);
      }
    }
  }

  void _paintLine(
    Canvas canvas,
    PdfLineElement el,
    double scaleX,
    double scaleY,
  ) {
    final Paint paint = Paint()
      ..color = el.color
      ..strokeWidth = (el.strokeWidth * scaleX).clamp(0.5, 16.0)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(el.start.dx * scaleX, el.start.dy * scaleY),
      Offset(el.end.dx * scaleX, el.end.dy * scaleY),
      paint,
    );
  }

  void _paintPath(
    Canvas canvas,
    PdfPathElement el,
    double scaleX,
    double scaleY,
  ) {
    final Path path = Path();
    if (el.commands.isNotEmpty) {
      for (final PdfPathCommand cmd in el.commands) {
        switch (cmd) {
          case PdfMoveToCommand(:final Offset point):
            path.moveTo(point.dx * scaleX, point.dy * scaleY);
          case PdfLineToCommand(:final Offset point):
            path.lineTo(point.dx * scaleX, point.dy * scaleY);
          case PdfCubicToCommand(
              :final Offset control1,
              :final Offset control2,
              :final Offset end,
            ):
            path.cubicTo(
              control1.dx * scaleX,
              control1.dy * scaleY,
              control2.dx * scaleX,
              control2.dy * scaleY,
              end.dx * scaleX,
              end.dy * scaleY,
            );
          case PdfClosePathCommand():
            path.close();
        }
      }
    } else {
      if (el.points.length < 2) {
        return;
      }
      path.moveTo(el.points.first.dx * scaleX, el.points.first.dy * scaleY);
      for (int i = 1; i < el.points.length; i++) {
        path.lineTo(el.points[i].dx * scaleX, el.points[i].dy * scaleY);
      }
      if (el.isClosed) {
        path.close();
      }
    }

    if (el.fillColor != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = el.fillColor!
          ..style = PaintingStyle.fill,
      );
    }
    if (el.strokeColor != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = el.strokeColor!
          ..strokeWidth = (el.strokeWidth * scaleX).clamp(0.5, 16.0)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _paintText(
    Canvas canvas,
    PdfTextElement el,
    double scaleX,
    double scaleY,
    double canvasWidth,
  ) {
    final double scaledFontSize = (el.fontSize * scaleY).clamp(2.0, 120.0);
    final double left = el.bounds.left * scaleX;
    final double top = el.bounds.top * scaleY;
    final double maxAvailableWidth =
        (canvasWidth - left).clamp(8.0, canvasWidth);

    final TextSpan span = TextSpan(
      text: el.text,
      style: TextStyle(
        color: el.color,
        fontSize: scaledFontSize,
        fontWeight: el.isBold ? FontWeight.w700 : FontWeight.w400,
        fontStyle: el.isItalic ? FontStyle.italic : FontStyle.normal,
        fontFamily: el.isMonospace ? 'RobotoMono' : fontFamily,
        height: 1.15,
      ),
    );

    final TextPainter tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: maxAvailableWidth);

    tp.paint(canvas, Offset(left, top));
    tp.dispose();
  }

  @override
  bool shouldRepaint(covariant _PdfPageVectorPainter oldDelegate) {
    return oldDelegate.page != page ||
        oldDelegate.searchResults != searchResults ||
        oldDelegate.activeSearchResult != activeSearchResult ||
        oldDelegate.searchHighlightColor != searchHighlightColor ||
        oldDelegate.activeSearchHighlightColor != activeSearchHighlightColor ||
        oldDelegate.selectedBounds != selectedBounds ||
        oldDelegate.selectionColor != selectionColor ||
        oldDelegate.fontFamily != fontFamily;
  }
}

import 'dart:math' as math;
import 'package:flutter/widgets.dart';

import '../models/pdf_annotation.dart';
import '../theme/pdf_icons.dart';
import '../theme/pdf_viewer_theme.dart';

/// Interactive overlay widget that renders and records [PdfAnnotation] items
/// (highlights, underlines, strikethroughs, smooth freehand ink, editable
/// sticky notes, and review stamps) on top of a PDF page.
class PdfAnnotationLayer extends StatefulWidget {
  /// Creates a [PdfAnnotationLayer].
  const PdfAnnotationLayer({
    super.key,
    required this.pageNumber,
    required this.annotations,
    this.activeTool = PdfAnnotationTool.none,
    this.activeColor = const Color(0xFFFACC15),
    this.activeStrokeWidth = 3.0,
    this.activeStampText = 'APPROVED',
    this.theme,
    this.onAnnotationCreated,
    this.onAnnotationUpdated,
    this.onAnnotationDeleted,
  });

  /// 1-based page number associated with this annotation layer.
  final int pageNumber;

  /// Existing annotations located on this page.
  final List<PdfAnnotation> annotations;

  /// Currently selected interactive drawing tool.
  final PdfAnnotationTool activeTool;

  /// Active color for newly created annotations.
  final Color activeColor;

  /// Active stroke width for newly created freehand ink strokes.
  final double activeStrokeWidth;

  /// Label text applied when tapping with [PdfAnnotationTool.stamp].
  final String activeStampText;

  /// Optional theme used to style sticky note dialogs consistently.
  final PdfViewerTheme? theme;

  /// Callback invoked when the user finishes creating an annotation.
  final ValueChanged<PdfAnnotation>? onAnnotationCreated;

  /// Callback invoked when the user edits an existing annotation (such as a
  /// sticky note).
  final ValueChanged<PdfAnnotation>? onAnnotationUpdated;

  /// Callback invoked when the user deletes an annotation.
  final ValueChanged<String>? onAnnotationDeleted;

  @override
  State<PdfAnnotationLayer> createState() => _PdfAnnotationLayerState();
}

class _PdfAnnotationLayerState extends State<PdfAnnotationLayer> {
  Offset? _dragStartNormalized;
  Offset? _dragCurrentNormalized;
  final List<Offset> _draftInkPoints = <Offset>[];

  bool get _isRectTool =>
      widget.activeTool == PdfAnnotationTool.highlight ||
      widget.activeTool == PdfAnnotationTool.underline ||
      widget.activeTool == PdfAnnotationTool.strikethrough;

  Offset _normalize(Offset localPosition, Size size) {
    final double nx =
        size.width <= 0 ? 0.0 : (localPosition.dx / size.width).clamp(0.0, 1.0);
    final double ny = size.height <= 0
        ? 0.0
        : (localPosition.dy / size.height).clamp(0.0, 1.0);
    return Offset(nx, ny);
  }

  void _handlePanStart(DragStartDetails details, Size size) {
    final Offset norm = _normalize(details.localPosition, size);
    setState(() {
      if (_isRectTool) {
        _dragStartNormalized = norm;
        _dragCurrentNormalized = norm;
      } else if (widget.activeTool == PdfAnnotationTool.ink) {
        _draftInkPoints
          ..clear()
          ..add(norm);
      }
    });
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    final Offset norm = _normalize(details.localPosition, size);
    setState(() {
      if (_isRectTool) {
        _dragCurrentNormalized = norm;
      } else if (widget.activeTool == PdfAnnotationTool.ink) {
        if (_draftInkPoints.isEmpty ||
            (_draftInkPoints.last - norm).distance > 0.002) {
          _draftInkPoints.add(norm);
        }
      }
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_isRectTool &&
        _dragStartNormalized != null &&
        _dragCurrentNormalized != null) {
      final Rect rect = Rect.fromPoints(
        _dragStartNormalized!,
        _dragCurrentNormalized!,
      );
      final double minHeight =
          widget.activeTool == PdfAnnotationTool.highlight ? 0.008 : 0.002;
      if (rect.width > 0.01 && rect.height >= minHeight) {
        final PdfAnnotationType type = switch (widget.activeTool) {
          PdfAnnotationTool.underline => PdfAnnotationType.underline,
          PdfAnnotationTool.strikethrough => PdfAnnotationType.strikethrough,
          _ => PdfAnnotationType.highlight,
        };
        widget.onAnnotationCreated?.call(
          PdfAnnotation(
            id: '${type.name}_${DateTime.now().microsecondsSinceEpoch}',
            pageNumber: widget.pageNumber,
            type: type,
            color: widget.activeColor,
            opacity: type == PdfAnnotationType.highlight ? 0.36 : 0.92,
            strokeWidth: widget.activeStrokeWidth,
            rect: rect,
            createdAt: DateTime.now(),
          ),
        );
      }
    } else if (widget.activeTool == PdfAnnotationTool.ink &&
        _draftInkPoints.length >= 2) {
      widget.onAnnotationCreated?.call(
        PdfAnnotation(
          id: 'ink_${DateTime.now().microsecondsSinceEpoch}',
          pageNumber: widget.pageNumber,
          type: PdfAnnotationType.ink,
          color: widget.activeColor,
          opacity: 0.92,
          strokeWidth: widget.activeStrokeWidth,
          points: List<Offset>.unmodifiable(_draftInkPoints),
          createdAt: DateTime.now(),
        ),
      );
    }

    setState(() {
      _dragStartNormalized = null;
      _dragCurrentNormalized = null;
      _draftInkPoints.clear();
    });
  }

  Future<void> _handleTapUp(TapUpDetails details, Size size) async {
    final Offset norm = _normalize(details.localPosition, size);
    if (widget.activeTool == PdfAnnotationTool.stamp) {
      widget.onAnnotationCreated?.call(
        PdfAnnotation(
          id: 'stamp_${DateTime.now().microsecondsSinceEpoch}',
          pageNumber: widget.pageNumber,
          type: PdfAnnotationType.stamp,
          color: widget.activeColor,
          opacity: 0.95,
          rect: Rect.fromCenter(center: norm, width: 0.22, height: 0.055),
          text: widget.activeStampText,
          createdAt: DateTime.now(),
        ),
      );
      return;
    }

    if (widget.activeTool != PdfAnnotationTool.stickyNote) {
      return;
    }
    final String? noteText = await _promptStickyNoteText(context);
    if (!mounted) {
      return;
    }
    if (noteText != null && noteText.trim().isNotEmpty) {
      widget.onAnnotationCreated?.call(
        PdfAnnotation(
          id: 'note_${DateTime.now().microsecondsSinceEpoch}',
          pageNumber: widget.pageNumber,
          type: PdfAnnotationType.stickyNote,
          color: widget.activeColor,
          opacity: 1.0,
          rect: Rect.fromCenter(center: norm, width: 0.05, height: 0.05),
          text: noteText.trim(),
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  Future<String?> _promptStickyNoteText(
    BuildContext context, {
    String initialText = '',
    String title = 'Add Sticky Note',
  }) async {
    final PdfViewerTheme effectiveTheme =
        widget.theme ?? PdfViewerTheme.fromContext(context);
    final TextEditingController textController =
        TextEditingController(text: initialText);
    final FocusNode focusNode = FocusNode();

    try {
      return await showPdfModalDialog<String>(
        context: context,
        builder: (BuildContext dialogContext) {
          return Container(
            width: 350,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: effectiveTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: effectiveTheme.surfaceBorderColor),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x45000000),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    PdfIcon(
                      PdfIcons.stickyNote,
                      size: 19,
                      color: effectiveTheme.accentColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: effectiveTheme.toolbarForegroundColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        effectiveTheme.backgroundColor.withValues(alpha: 0.55),
                    border:
                        Border.all(color: effectiveTheme.surfaceBorderColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: EditableText(
                    controller: textController,
                    focusNode: focusNode,
                    autofocus: true,
                    maxLines: 4,
                    style: TextStyle(
                      fontFamily: effectiveTheme.fontFamily ??
                          DefaultTextStyle.of(context).style.fontFamily,
                      fontSize: 14,
                      color: effectiveTheme.toolbarForegroundColor,
                      height: 1.4,
                    ),
                    cursorColor: effectiveTheme.accentColor,
                    backgroundCursorColor:
                        effectiveTheme.secondaryForegroundColor,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: effectiveTheme.secondaryForegroundColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          Navigator.of(dialogContext).pop(textController.text),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: effectiveTheme.accentColor,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Text(
                          'Save Note',
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    } finally {
      textController.dispose();
      focusNode.dispose();
    }
  }

  Future<void> _showStickyNoteDetails(
    BuildContext context,
    PdfAnnotation note,
  ) async {
    final PdfViewerTheme effectiveTheme =
        widget.theme ?? PdfViewerTheme.fromContext(context);
    final bool? shouldEdit = await showPdfModalDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Container(
          width: 350,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: effectiveTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: effectiveTheme.surfaceBorderColor),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x45000000),
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: note.color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: PdfIcon(
                        PdfIcons.stickyNote,
                        size: 16,
                        color: note.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Note on Page ${note.pageNumber}',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: effectiveTheme.toolbarForegroundColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: effectiveTheme.backgroundColor.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: effectiveTheme.surfaceBorderColor),
                ),
                child: Text(
                  note.text ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: effectiveTheme.toolbarForegroundColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (widget.onAnnotationDeleted != null)
                    GestureDetector(
                      onTap: () {
                        widget.onAnnotationDeleted?.call(note.id);
                        Navigator.of(dialogContext).pop(false);
                      },
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (widget.onAnnotationUpdated != null)
                    GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(true),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            color: effectiveTheme.accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.of(dialogContext).pop(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: effectiveTheme.accentColor,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (shouldEdit == true && mounted) {
      final String? updatedText = await _promptStickyNoteText(
        this.context,
        initialText: note.text ?? '',
        title: 'Edit Sticky Note',
      );
      if (updatedText != null && updatedText.trim().isNotEmpty) {
        widget.onAnnotationUpdated?.call(
          note.copyWith(text: updatedText.trim()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        final bool isDrawingEnabled =
            widget.activeTool != PdfAnnotationTool.none;

        final List<PdfAnnotation> stickyNotes = widget.annotations
            .where((PdfAnnotation a) => a.type == PdfAnnotationType.stickyNote)
            .toList(growable: false);

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CustomPaint(
              size: size,
              painter: _AnnotationCanvasPainter(
                annotations: widget.annotations,
                draftRect: (_dragStartNormalized != null &&
                        _dragCurrentNormalized != null)
                    ? Rect.fromPoints(
                        _dragStartNormalized!,
                        _dragCurrentNormalized!,
                      )
                    : null,
                draftTool: widget.activeTool,
                draftInkPoints: _draftInkPoints,
                activeColor: widget.activeColor,
                activeStrokeWidth: widget.activeStrokeWidth,
                fontFamily: widget.theme?.fontFamily ??
                    DefaultTextStyle.of(context).style.fontFamily,
              ),
            ),
            if (isDrawingEnabled)
              MouseRegion(
                cursor: SystemMouseCursors.precise,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (DragStartDetails d) => _handlePanStart(d, size),
                  onPanUpdate: (DragUpdateDetails d) =>
                      _handlePanUpdate(d, size),
                  onPanEnd: _handlePanEnd,
                  onTapUp: (TapUpDetails d) => _handleTapUp(d, size),
                  child: const SizedBox.expand(),
                ),
              ),
            for (final PdfAnnotation note in stickyNotes)
              if (note.rect != null)
                Positioned(
                  left: (note.rect!.center.dx * size.width - 15)
                      .clamp(0.0, math.max(0.0, size.width - 30)),
                  top: (note.rect!.center.dy * size.height - 15)
                      .clamp(0.0, math.max(0.0, size.height - 30)),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _showStickyNoteDetails(context, note),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: note.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFFFFF),
                            width: 2.0,
                          ),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x45000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: PdfIcon(
                            PdfIcons.comment,
                            size: 15,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _AnnotationCanvasPainter extends CustomPainter {
  _AnnotationCanvasPainter({
    required this.annotations,
    required this.draftRect,
    required this.draftTool,
    required this.draftInkPoints,
    required this.activeColor,
    required this.activeStrokeWidth,
    this.fontFamily,
  });

  final List<PdfAnnotation> annotations;
  final Rect? draftRect;
  final PdfAnnotationTool draftTool;
  final List<Offset> draftInkPoints;
  final Color activeColor;
  final double activeStrokeWidth;
  final String? fontFamily;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    for (final PdfAnnotation annotation in annotations) {
      switch (annotation.type) {
        case PdfAnnotationType.highlight:
          if (annotation.rect != null) {
            _paintHighlight(
              canvas,
              size,
              annotation.rect!,
              annotation.color.withValues(alpha: annotation.opacity),
            );
          }
        case PdfAnnotationType.underline:
          if (annotation.rect != null) {
            _paintHorizontalLineMarkup(
              canvas,
              size,
              annotation.rect!,
              annotation.color.withValues(alpha: annotation.opacity),
              annotation.strokeWidth,
              atCenter: false,
            );
          }
        case PdfAnnotationType.strikethrough:
          if (annotation.rect != null) {
            _paintHorizontalLineMarkup(
              canvas,
              size,
              annotation.rect!,
              annotation.color.withValues(alpha: annotation.opacity),
              annotation.strokeWidth,
              atCenter: true,
            );
          }
        case PdfAnnotationType.ink:
          if (annotation.points.length >= 2) {
            _paintSmoothInk(
              canvas,
              size,
              annotation.points,
              annotation.color.withValues(alpha: annotation.opacity),
              annotation.strokeWidth,
            );
          }
        case PdfAnnotationType.stamp:
          if (annotation.rect != null && annotation.text != null) {
            _paintStamp(canvas, size, annotation);
          }
        case PdfAnnotationType.stickyNote:
          break;
      }
    }

    if (draftRect != null) {
      switch (draftTool) {
        case PdfAnnotationTool.underline:
          _paintHorizontalLineMarkup(
            canvas,
            size,
            draftRect!,
            activeColor.withValues(alpha: 0.9),
            activeStrokeWidth,
            atCenter: false,
          );
        case PdfAnnotationTool.strikethrough:
          _paintHorizontalLineMarkup(
            canvas,
            size,
            draftRect!,
            activeColor.withValues(alpha: 0.9),
            activeStrokeWidth,
            atCenter: true,
          );
        default:
          _paintHighlight(
            canvas,
            size,
            draftRect!,
            activeColor.withValues(alpha: 0.36),
          );
      }
    }

    if (draftInkPoints.length >= 2) {
      _paintSmoothInk(
        canvas,
        size,
        draftInkPoints,
        activeColor.withValues(alpha: 0.92),
        activeStrokeWidth,
      );
    }
  }

  void _paintHighlight(
    Canvas canvas,
    Size size,
    Rect normRect,
    Color fillColor,
  ) {
    final Rect scaled = Rect.fromLTWH(
      normRect.left * size.width,
      normRect.top * size.height,
      normRect.width * size.width,
      normRect.height * size.height,
    );
    final Paint paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(scaled, const Radius.circular(4)),
      paint,
    );
  }

  void _paintHorizontalLineMarkup(
    Canvas canvas,
    Size size,
    Rect normRect,
    Color strokeColor,
    double strokeWidth, {
    required bool atCenter,
  }) {
    final double y = atCenter
        ? normRect.center.dy * size.height
        : normRect.bottom * size.height;
    final Paint paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth.clamp(1.5, 6.0)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(normRect.left * size.width, y),
      Offset(normRect.right * size.width, y),
      paint,
    );
  }

  void _paintSmoothInk(
    Canvas canvas,
    Size size,
    List<Offset> normPoints,
    Color strokeColor,
    double strokeWidth,
  ) {
    final List<Offset> pts = normPoints
        .map((Offset p) => Offset(p.dx * size.width, p.dy * size.height))
        .toList(growable: false);

    final Path path = Path()..moveTo(pts.first.dx, pts.first.dy);
    if (pts.length == 2) {
      path.lineTo(pts[1].dx, pts[1].dy);
    } else {
      for (int i = 1; i < pts.length - 1; i++) {
        final Offset mid = Offset(
          (pts[i].dx + pts[i + 1].dx) * 0.5,
          (pts[i].dy + pts[i + 1].dy) * 0.5,
        );
        path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
      }
      path.lineTo(pts.last.dx, pts.last.dy);
    }

    final Paint paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }

  void _paintStamp(Canvas canvas, Size size, PdfAnnotation stamp) {
    final Rect r = stamp.rect!;
    final Offset center = Offset(
      r.center.dx * size.width,
      r.center.dy * size.height,
    );
    final double fontSize = (size.width * 0.026).clamp(10.0, 16.0);
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: stamp.text,
        style: TextStyle(
          fontFamily: fontFamily,
          color: stamp.color,
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
          letterSpacing: 1.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final Rect badgeRect = Rect.fromCenter(
      center: center,
      width: tp.width + 20,
      height: tp.height + 10,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.08);
    canvas.translate(-center.dx, -center.dy);

    final RRect rr = RRect.fromRectAndRadius(
      badgeRect,
      const Radius.circular(6),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..color = stamp.color.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..color = stamp.color
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );
    tp.paint(
      canvas,
      Offset(
        badgeRect.left + (badgeRect.width - tp.width) * 0.5,
        badgeRect.top + (badgeRect.height - tp.height) * 0.5,
      ),
    );
    canvas.restore();
    tp.dispose();
  }

  @override
  bool shouldRepaint(covariant _AnnotationCanvasPainter oldDelegate) {
    return oldDelegate.annotations != annotations ||
        oldDelegate.draftRect != draftRect ||
        oldDelegate.draftTool != draftTool ||
        oldDelegate.draftInkPoints != draftInkPoints ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.activeStrokeWidth != activeStrokeWidth;
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/pdf_annotation.dart';

/// Interactive overlay widget that renders and records [PdfAnnotation] items
/// on top of a PDF page.
class PdfAnnotationLayer extends StatefulWidget {
  /// Creates a [PdfAnnotationLayer].
  const PdfAnnotationLayer({
    super.key,
    required this.pageNumber,
    required this.annotations,
    this.activeTool = PdfAnnotationTool.none,
    this.activeColor = const Color(0xFFFACC15),
    this.activeStrokeWidth = 3.0,
    this.onAnnotationCreated,
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

  /// Callback invoked when the user finishes creating an annotation.
  final ValueChanged<PdfAnnotation>? onAnnotationCreated;

  /// Callback invoked when the user deletes an annotation (for example, from a
  /// sticky note dialog).
  final ValueChanged<String>? onAnnotationDeleted;

  @override
  State<PdfAnnotationLayer> createState() => _PdfAnnotationLayerState();
}

class _PdfAnnotationLayerState extends State<PdfAnnotationLayer> {
  Offset? _dragStartNormalized;
  Offset? _dragCurrentNormalized;
  final List<Offset> _draftInkPoints = <Offset>[];

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
      if (widget.activeTool == PdfAnnotationTool.highlight) {
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
      if (widget.activeTool == PdfAnnotationTool.highlight) {
        _dragCurrentNormalized = norm;
      } else if (widget.activeTool == PdfAnnotationTool.ink) {
        _draftInkPoints.add(norm);
      }
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (widget.activeTool == PdfAnnotationTool.highlight &&
        _dragStartNormalized != null &&
        _dragCurrentNormalized != null) {
      final Rect rect = Rect.fromPoints(
        _dragStartNormalized!,
        _dragCurrentNormalized!,
      );
      if (rect.width > 0.01 && rect.height > 0.008) {
        widget.onAnnotationCreated?.call(
          PdfAnnotation(
            id: 'hl_${DateTime.now().microsecondsSinceEpoch}',
            pageNumber: widget.pageNumber,
            type: PdfAnnotationType.highlight,
            color: widget.activeColor,
            opacity: 0.38,
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
          opacity: 0.90,
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
    if (widget.activeTool != PdfAnnotationTool.stickyNote) {
      return;
    }
    final Offset norm = _normalize(details.localPosition, size);
    final String? noteText = await _promptStickyNoteText(context);
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
  }) async {
    final TextEditingController textController =
        TextEditingController(text: initialText);
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add Sticky Note'),
          content: TextField(
            controller: textController,
            autofocus: true,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Write a comment or note for this page...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(textController.text),
              child: const Text('Save Note'),
            ),
          ],
        );
      },
    );
  }

  void _showStickyNoteDetails(BuildContext context, PdfAnnotation note) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: <Widget>[
              Icon(Icons.sticky_note_2_rounded, color: note.color),
              const SizedBox(width: 8),
              Text('Note on Page ${note.pageNumber}'),
            ],
          ),
          content: Text(note.text ?? ''),
          actions: <Widget>[
            if (widget.onAnnotationDeleted != null)
              TextButton.icon(
                onPressed: () {
                  widget.onAnnotationDeleted?.call(note.id);
                  Navigator.of(dialogContext).pop();
                },
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                label: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
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
                draftHighlightRect: (_dragStartNormalized != null &&
                        _dragCurrentNormalized != null)
                    ? Rect.fromPoints(
                        _dragStartNormalized!,
                        _dragCurrentNormalized!,
                      )
                    : null,
                draftInkPoints: _draftInkPoints,
                activeColor: widget.activeColor,
                activeStrokeWidth: widget.activeStrokeWidth,
              ),
            ),
            if (isDrawingEnabled)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (DragStartDetails d) => _handlePanStart(d, size),
                onPanUpdate: (DragUpdateDetails d) => _handlePanUpdate(d, size),
                onPanEnd: _handlePanEnd,
                onTapUp: (TapUpDetails d) => _handleTapUp(d, size),
                child: const SizedBox.expand(),
              ),
            for (final PdfAnnotation note in stickyNotes)
              if (note.rect != null)
                Positioned(
                  left: (note.rect!.center.dx * size.width - 16)
                      .clamp(0.0, math.max(0.0, size.width - 32)),
                  top: (note.rect!.center.dy * size.height - 16)
                      .clamp(0.0, math.max(0.0, size.height - 32)),
                  child: Tooltip(
                    message: note.text ?? 'Sticky Note',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showStickyNoteDetails(context, note),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: note.color,
                            shape: BoxShape.circle,
                            boxShadow: const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x40000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.comment_rounded,
                            size: 17,
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
    required this.draftHighlightRect,
    required this.draftInkPoints,
    required this.activeColor,
    required this.activeStrokeWidth,
  });

  final List<PdfAnnotation> annotations;
  final Rect? draftHighlightRect;
  final List<Offset> draftInkPoints;
  final Color activeColor;
  final double activeStrokeWidth;

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
        case PdfAnnotationType.ink:
          if (annotation.points.length >= 2) {
            _paintInk(
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
          // Rendered as an interactive widget pin above the canvas.
          break;
      }
    }

    if (draftHighlightRect != null) {
      _paintHighlight(
        canvas,
        size,
        draftHighlightRect!,
        activeColor.withValues(alpha: 0.38),
      );
    }

    if (draftInkPoints.length >= 2) {
      _paintInk(
        canvas,
        size,
        draftInkPoints,
        activeColor.withValues(alpha: 0.90),
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

  void _paintInk(
    Canvas canvas,
    Size size,
    List<Offset> normPoints,
    Color strokeColor,
    double strokeWidth,
  ) {
    final Path path = Path()
      ..moveTo(
        normPoints.first.dx * size.width,
        normPoints.first.dy * size.height,
      );
    for (int i = 1; i < normPoints.length; i++) {
      final Offset p = normPoints[i];
      path.lineTo(p.dx * size.width, p.dy * size.height);
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
    final Offset pos = Offset(r.left * size.width, r.top * size.height);
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: stamp.text,
        style: TextStyle(
          color: stamp.color,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
    tp.dispose();
  }

  @override
  bool shouldRepaint(covariant _AnnotationCanvasPainter oldDelegate) {
    return oldDelegate.annotations != annotations ||
        oldDelegate.draftHighlightRect != draftHighlightRect ||
        oldDelegate.draftInkPoints != draftInkPoints ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.activeStrokeWidth != activeStrokeWidth;
  }
}

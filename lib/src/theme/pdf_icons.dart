import 'dart:math' as math;
import 'package:flutter/widgets.dart';

/// Built-in vector icon constants and pure-`widgets.dart` UI primitives for
/// `pdf_reader` so the library renders crisp icons everywhere with zero
/// external or Material font dependencies.
class PdfIcons {
  const PdfIcons._();

  /// Search magnifying glass icon.
  static const IconData search = IconData(0xe567, fontFamily: 'MaterialIcons');

  /// Up arrow icon.
  static const IconData arrowUp = IconData(0xe316, fontFamily: 'MaterialIcons');

  /// Down arrow icon.
  static const IconData arrowDown =
      IconData(0xe313, fontFamily: 'MaterialIcons');

  /// Left chevron icon.
  static const IconData chevronLeft =
      IconData(0xe15b, fontFamily: 'MaterialIcons');

  /// Right chevron icon.
  static const IconData chevronRight =
      IconData(0xe15c, fontFamily: 'MaterialIcons');

  /// Close (X) icon.
  static const IconData close = IconData(0xe16a, fontFamily: 'MaterialIcons');

  /// Bookmark filled icon.
  static const IconData bookmark =
      IconData(0xe0f8, fontFamily: 'MaterialIcons');

  /// Bookmark outline icon.
  static const IconData bookmarkBorder =
      IconData(0xe0fa, fontFamily: 'MaterialIcons');

  /// Table of contents / outlines icon.
  static const IconData toc = IconData(0xe665, fontFamily: 'MaterialIcons');

  /// Draw / annotate icon.
  static const IconData draw = IconData(0xe1f8, fontFamily: 'MaterialIcons');

  /// Grid / thumbnails icon.
  static const IconData gridView =
      IconData(0xe2f0, fontFamily: 'MaterialIcons');

  /// Layout mode carousel icon.
  static const IconData viewCarousel =
      IconData(0xe6b6, fontFamily: 'MaterialIcons');

  /// Color tonality / reading filter icon.
  static const IconData tonality =
      IconData(0xe671, fontFamily: 'MaterialIcons');

  /// Rotate clockwise icon.
  static const IconData rotateRight =
      IconData(0xe53d, fontFamily: 'MaterialIcons');

  /// Info outline icon.
  static const IconData infoOutline =
      IconData(0xe33c, fontFamily: 'MaterialIcons');

  /// PDF document icon.
  static const IconData pdf = IconData(0xe4ba, fontFamily: 'MaterialIcons');

  /// Sparkle / Humanize AI icon.
  static const IconData sparkle = IconData(0xe0b0, fontFamily: 'MaterialIcons');

  /// Copy to clipboard icon.
  static const IconData copy = IconData(0xe190, fontFamily: 'MaterialIcons');

  /// Pan / hand tool icon.
  static const IconData panTool = IconData(0xe481, fontFamily: 'MaterialIcons');

  /// Highlighter tool icon.
  static const IconData highlight =
      IconData(0xe30c, fontFamily: 'MaterialIcons');

  /// Freehand ink gesture icon.
  static const IconData ink = IconData(0xe2d8, fontFamily: 'MaterialIcons');

  /// Sticky note icon.
  static const IconData stickyNote =
      IconData(0xe609, fontFamily: 'MaterialIcons');

  /// Comment bubble icon.
  static const IconData comment = IconData(0xe17e, fontFamily: 'MaterialIcons');

  /// Undo icon.
  static const IconData undo = IconData(0xe692, fontFamily: 'MaterialIcons');

  /// Redo icon.
  static const IconData redo = IconData(0xe514, fontFamily: 'MaterialIcons');

  /// Delete / clear icon.
  static const IconData delete = IconData(0xe1b9, fontFamily: 'MaterialIcons');

  /// Zoom in (+) icon.
  static const IconData add = IconData(0xe047, fontFamily: 'MaterialIcons');

  /// Zoom out (-) icon.
  static const IconData remove = IconData(0xe516, fontFamily: 'MaterialIcons');

  /// Error outline icon.
  static const IconData errorOutline =
      IconData(0xe237, fontFamily: 'MaterialIcons');

  /// Refresh / retry icon.
  static const IconData refresh = IconData(0xe515, fontFamily: 'MaterialIcons');

  /// Light mode sun icon.
  static const IconData lightMode =
      IconData(0xe3a8, fontFamily: 'MaterialIcons');

  /// Dark mode moon icon.
  static const IconData darkMode =
      IconData(0xe1ad, fontFamily: 'MaterialIcons');

  /// Sidebar panel toggle icon.
  static const IconData sidebar = IconData(0xf001, fontFamily: 'PdfIcons');

  /// More options vertical dots icon.
  static const IconData moreVert = IconData(0xf002, fontFamily: 'PdfIcons');

  /// Fit width icon.
  static const IconData fitWidth = IconData(0xf003, fontFamily: 'PdfIcons');

  /// Fit page icon.
  static const IconData fitPage = IconData(0xf004, fontFamily: 'PdfIcons');

  /// Enter immersive / fullscreen reading mode icon.
  static const IconData fullscreen = IconData(0xf005, fontFamily: 'PdfIcons');

  /// Exit immersive / fullscreen reading mode icon.
  static const IconData fullscreenExit =
      IconData(0xf006, fontFamily: 'PdfIcons');

  /// Underline annotation tool icon.
  static const IconData underline = IconData(0xf007, fontFamily: 'PdfIcons');

  /// Strikethrough annotation tool icon.
  static const IconData strikethrough =
      IconData(0xf008, fontFamily: 'PdfIcons');

  /// Stamp annotation tool icon.
  static const IconData stamp = IconData(0xf009, fontFamily: 'PdfIcons');

  /// Edit / pencil icon.
  static const IconData edit = IconData(0xf00a, fontFamily: 'PdfIcons');

  /// Checkmark icon.
  static const IconData check = IconData(0xf00b, fontFamily: 'PdfIcons');

  /// Double-page book spread layout icon.
  static const IconData doublePage = IconData(0xf00c, fontFamily: 'PdfIcons');

  /// Single page layout icon.
  static const IconData singlePage = IconData(0xf00d, fontFamily: 'PdfIcons');

  /// Vertical continuous scroll layout icon.
  static const IconData scrollVertical =
      IconData(0xf00e, fontFamily: 'PdfIcons');

  /// Horizontal continuous scroll layout icon.
  static const IconData scrollHorizontal =
      IconData(0xf00f, fontFamily: 'PdfIcons');

  /// Annotations list / layers icon.
  static const IconData annotations = IconData(0xf010, fontFamily: 'PdfIcons');
}

/// Renders crisp, modern geometric vector icons directly on Flutter's [Canvas]
/// for all [PdfIcons] glyphs without requiring external icon fonts.
///
/// If an unrecognized external [IconData] is provided, gracefully falls back to
/// Flutter's standard [Icon] widget.
class PdfIcon extends StatelessWidget {
  /// Creates a [PdfIcon].
  const PdfIcon(
    this.icon, {
    super.key,
    this.size = 20.0,
    this.color = const Color(0xFF0F172A),
    this.semanticLabel,
  });

  /// The icon glyph to paint.
  final IconData icon;

  /// Logical width and height of the icon.
  final double size;

  /// Primary stroke/fill color of the icon.
  final Color color;

  /// Optional accessibility label.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_PdfVectorIconPainter.supports(icon)) {
      child = SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _PdfVectorIconPainter(
            codePoint: icon.codePoint,
            color: color,
          ),
        ),
      );
    } else {
      child = Icon(
        icon,
        size: size,
        color: color,
      );
    }

    if (semanticLabel != null && semanticLabel!.isNotEmpty) {
      return Semantics(
        label: semanticLabel,
        child: ExcludeSemantics(child: child),
      );
    }
    return child;
  }
}

class _PdfVectorIconPainter extends CustomPainter {
  const _PdfVectorIconPainter({
    required this.codePoint,
    required this.color,
  });

  final int codePoint;
  final Color color;

  static const Set<int> _supported = <int>{
    0xe567, // search
    0xe316, // arrowUp
    0xe313, // arrowDown
    0xe15b, // chevronLeft
    0xe15c, // chevronRight
    0xe16a, // close
    0xe0f8, // bookmark
    0xe0fa, // bookmarkBorder
    0xe665, // toc
    0xe1f8, // draw
    0xe2f0, // gridView
    0xe6b6, // viewCarousel
    0xe671, // tonality
    0xe53d, // rotateRight
    0xe33c, // infoOutline
    0xe4ba, // pdf
    0xe0b0, // sparkle
    0xe190, // copy
    0xe481, // panTool
    0xe30c, // highlight
    0xe2d8, // ink
    0xe609, // stickyNote
    0xe17e, // comment
    0xe692, // undo
    0xe514, // redo
    0xe1b9, // delete
    0xe047, // add
    0xe516, // remove
    0xe237, // errorOutline
    0xe515, // refresh
    0xe3a8, // lightMode
    0xe1ad, // darkMode
    0xf001, // sidebar
    0xf002, // moreVert
    0xf003, // fitWidth
    0xf004, // fitPage
    0xf005, // fullscreen
    0xf006, // fullscreenExit
    0xf007, // underline
    0xf008, // strikethrough
    0xf009, // stamp
    0xf00a, // edit
    0xf00b, // check
    0xf00c, // doublePage
    0xf00d, // singlePage
    0xf00e, // scrollVertical
    0xf00f, // scrollHorizontal
    0xf010, // annotations
  };

  static bool supports(IconData icon) => _supported.contains(icon.codePoint);

  @override
  void paint(Canvas canvas, Size size) {
    final double s = math.min(size.width, size.height) / 24.0;
    canvas.save();
    canvas.translate(
      (size.width - 24.0 * s) * 0.5,
      (size.height - 24.0 * s) * 0.5,
    );
    canvas.scale(s, s);

    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.85
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (codePoint) {
      case 0xe567: // search
        canvas.drawCircle(const Offset(10.5, 10.5), 6.5, stroke);
        canvas.drawLine(
            const Offset(15.5, 15.5), const Offset(20.5, 20.5), stroke);
      case 0xe316: // arrowUp
        final Path p = Path()
          ..moveTo(6, 15)
          ..lineTo(12, 9)
          ..lineTo(18, 15);
        canvas.drawPath(p, stroke);
      case 0xe313: // arrowDown
        final Path p = Path()
          ..moveTo(6, 9)
          ..lineTo(12, 15)
          ..lineTo(18, 9);
        canvas.drawPath(p, stroke);
      case 0xe15b: // chevronLeft
        final Path p = Path()
          ..moveTo(15, 6)
          ..lineTo(9, 12)
          ..lineTo(15, 18);
        canvas.drawPath(p, stroke);
      case 0xe15c: // chevronRight
        final Path p = Path()
          ..moveTo(9, 6)
          ..lineTo(15, 12)
          ..lineTo(9, 18);
        canvas.drawPath(p, stroke);
      case 0xe16a: // close
        canvas.drawLine(const Offset(6, 6), const Offset(18, 18), stroke);
        canvas.drawLine(const Offset(18, 6), const Offset(6, 18), stroke);
      case 0xe0f8: // bookmark (filled)
        final Path p = Path()
          ..moveTo(6.5, 4)
          ..lineTo(17.5, 4)
          ..quadraticBezierTo(18.5, 4, 18.5, 5.2)
          ..lineTo(18.5, 20.5)
          ..lineTo(12, 16.5)
          ..lineTo(5.5, 20.5)
          ..lineTo(5.5, 5.2)
          ..quadraticBezierTo(5.5, 4, 6.5, 4)
          ..close();
        canvas.drawPath(p, fill);
      case 0xe0fa: // bookmarkBorder
        final Path p = Path()
          ..moveTo(6.5, 4)
          ..lineTo(17.5, 4)
          ..quadraticBezierTo(18.5, 4, 18.5, 5.2)
          ..lineTo(18.5, 20.2)
          ..lineTo(12, 16.2)
          ..lineTo(5.5, 20.2)
          ..lineTo(5.5, 5.2)
          ..quadraticBezierTo(5.5, 4, 6.5, 4)
          ..close();
        canvas.drawPath(p, stroke);
      case 0xe665: // toc
        canvas.drawCircle(const Offset(4.5, 6.5), 1.2, fill);
        canvas.drawCircle(const Offset(4.5, 12.0), 1.2, fill);
        canvas.drawCircle(const Offset(4.5, 17.5), 1.2, fill);
        canvas.drawLine(const Offset(8.5, 6.5), const Offset(20, 6.5), stroke);
        canvas.drawLine(
            const Offset(8.5, 12.0), const Offset(20, 12.0), stroke);
        canvas.drawLine(
            const Offset(8.5, 17.5), const Offset(17, 17.5), stroke);
      case 0xe1f8: // draw / pen
        final Path p = Path()
          ..moveTo(15.5, 4.5)
          ..lineTo(19.5, 8.5)
          ..lineTo(8.5, 19.5)
          ..lineTo(4, 20)
          ..lineTo(4.5, 15.5)
          ..close();
        canvas.drawPath(p, stroke);
        canvas.drawLine(const Offset(13, 7), const Offset(17, 11), stroke);
      case 0xe2f0: // gridView
        for (final Offset o in const <Offset>[
          Offset(4, 4),
          Offset(13.5, 4),
          Offset(4, 13.5),
          Offset(13.5, 13.5),
        ]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(o.dx, o.dy, 6.5, 6.5),
              const Radius.circular(1.6),
            ),
            stroke,
          );
        }
      case 0xe6b6: // viewCarousel
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(7, 4.5, 10, 15),
            const Radius.circular(2),
          ),
          stroke,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(2.5, 7, 2.5, 10),
            const Radius.circular(1),
          ),
          stroke,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(19, 7, 2.5, 10),
            const Radius.circular(1),
          ),
          stroke,
        );
      case 0xe671: // tonality / contrast
        canvas.drawCircle(const Offset(12, 12), 8.2, stroke);
        final Path half = Path()
          ..moveTo(12, 3.8)
          ..arcTo(
            Rect.fromCircle(center: const Offset(12, 12), radius: 8.2),
            -math.pi / 2,
            math.pi,
            false,
          )
          ..close();
        canvas.drawPath(half, fill);
      case 0xe53d: // rotateRight
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(12, 12.5), radius: 7.2),
          -math.pi * 0.45,
          math.pi * 1.65,
          false,
          stroke,
        );
        final Path arrow = Path()
          ..moveTo(14.5, 2.8)
          ..lineTo(18.5, 5.5)
          ..lineTo(14.8, 8.8);
        canvas.drawPath(arrow, stroke);
      case 0xe33c: // infoOutline
        canvas.drawCircle(const Offset(12, 12), 8.5, stroke);
        canvas.drawLine(const Offset(12, 11.2), const Offset(12, 16.2), stroke);
        canvas.drawCircle(const Offset(12, 8.0), 1.15, fill);
      case 0xe4ba: // pdf document
        final Path doc = Path()
          ..moveTo(6, 3.5)
          ..lineTo(14, 3.5)
          ..lineTo(18.5, 8)
          ..lineTo(18.5, 20.5)
          ..lineTo(6, 20.5)
          ..close();
        canvas.drawPath(doc, stroke);
        final Path fold = Path()
          ..moveTo(14, 3.5)
          ..lineTo(14, 8)
          ..lineTo(18.5, 8);
        canvas.drawPath(fold, stroke);
        canvas.drawLine(
            const Offset(9, 12.5), const Offset(15.5, 12.5), stroke);
        canvas.drawLine(const Offset(9, 16.0), const Offset(14, 16.0), stroke);
      case 0xe0b0: // sparkle
        final Path star = Path()
          ..moveTo(12, 3)
          ..quadraticBezierTo(12.6, 11.4, 21, 12)
          ..quadraticBezierTo(12.6, 12.6, 12, 21)
          ..quadraticBezierTo(11.4, 12.6, 3, 12)
          ..quadraticBezierTo(11.4, 11.4, 12, 3)
          ..close();
        canvas.drawPath(star, fill);
      case 0xe190: // copy
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(8.5, 8.5, 11.5, 11.5),
            const Radius.circular(2),
          ),
          stroke,
        );
        final Path back = Path()
          ..moveTo(6.5, 15.5)
          ..lineTo(5.5, 15.5)
          ..quadraticBezierTo(4, 15.5, 4, 14)
          ..lineTo(4, 5.5)
          ..quadraticBezierTo(4, 4, 5.5, 4)
          ..lineTo(14, 4)
          ..quadraticBezierTo(15.5, 4, 15.5, 5.5)
          ..lineTo(15.5, 6.5);
        canvas.drawPath(back, stroke);
      case 0xe481: // panTool / cursor move
        canvas.drawLine(const Offset(12, 4), const Offset(12, 20), stroke);
        canvas.drawLine(const Offset(4, 12), const Offset(20, 12), stroke);
        canvas.drawPath(
          Path()
            ..moveTo(9.5, 6.5)
            ..lineTo(12, 4)
            ..lineTo(14.5, 6.5),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(9.5, 17.5)
            ..lineTo(12, 20)
            ..lineTo(14.5, 17.5),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(6.5, 9.5)
            ..lineTo(4, 12)
            ..lineTo(6.5, 14.5),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(17.5, 9.5)
            ..lineTo(20, 12)
            ..lineTo(17.5, 14.5),
          stroke,
        );
      case 0xe30c: // highlight marker
        final Path marker = Path()
          ..moveTo(9, 13.5)
          ..lineTo(16.5, 6)
          ..lineTo(19.5, 9)
          ..lineTo(12, 16.5)
          ..close();
        canvas.drawPath(marker, stroke);
        canvas.drawLine(const Offset(7, 15.5), const Offset(10, 18.5), stroke);
        canvas.drawLine(const Offset(4.5, 20), const Offset(19.5, 20), stroke);
      case 0xe2d8: // ink squiggle
        final Path wave = Path()
          ..moveTo(4, 16)
          ..cubicTo(7, 7, 10, 7, 12, 12)
          ..cubicTo(14, 17, 17, 17, 20, 8);
        canvas.drawPath(wave, stroke);
      case 0xe609: // stickyNote
        final Path note = Path()
          ..moveTo(4.5, 4.5)
          ..lineTo(19.5, 4.5)
          ..lineTo(19.5, 15)
          ..lineTo(15, 19.5)
          ..lineTo(4.5, 19.5)
          ..close();
        canvas.drawPath(note, stroke);
        final Path corner = Path()
          ..moveTo(15, 19.5)
          ..lineTo(15, 15)
          ..lineTo(19.5, 15);
        canvas.drawPath(corner, stroke);
      case 0xe17e: // comment bubble
        final Path bubble = Path()
          ..moveTo(5, 5)
          ..lineTo(19, 5)
          ..quadraticBezierTo(20, 5, 20, 6.2)
          ..lineTo(20, 15.5)
          ..quadraticBezierTo(20, 16.7, 19, 16.7)
          ..lineTo(9.5, 16.7)
          ..lineTo(5.5, 20)
          ..lineTo(5.5, 16.7)
          ..lineTo(5, 16.7)
          ..quadraticBezierTo(4, 16.7, 4, 15.5)
          ..lineTo(4, 6.2)
          ..quadraticBezierTo(4, 5, 5, 5)
          ..close();
        canvas.drawPath(bubble, stroke);
      case 0xe692: // undo
        final Path p = Path()
          ..moveTo(8, 7)
          ..lineTo(4, 11)
          ..lineTo(8, 15);
        canvas.drawPath(p, stroke);
        final Path arc = Path()
          ..moveTo(4.5, 11)
          ..lineTo(14, 11)
          ..cubicTo(18, 11, 19.5, 13.5, 19.5, 16.5)
          ..cubicTo(19.5, 18.2, 18, 19, 16, 19);
        canvas.drawPath(arc, stroke);
      case 0xe514: // redo
        final Path p = Path()
          ..moveTo(16, 7)
          ..lineTo(20, 11)
          ..lineTo(16, 15);
        canvas.drawPath(p, stroke);
        final Path arc = Path()
          ..moveTo(19.5, 11)
          ..lineTo(10, 11)
          ..cubicTo(6, 11, 4.5, 13.5, 4.5, 16.5)
          ..cubicTo(4.5, 18.2, 6, 19, 8, 19);
        canvas.drawPath(arc, stroke);
      case 0xe1b9: // delete trash
        canvas.drawLine(
            const Offset(4.5, 6.5), const Offset(19.5, 6.5), stroke);
        canvas.drawLine(const Offset(9.5, 4), const Offset(14.5, 4), stroke);
        final Path bin = Path()
          ..moveTo(6.5, 6.5)
          ..lineTo(7.5, 19.5)
          ..quadraticBezierTo(7.7, 20.5, 9, 20.5)
          ..lineTo(15, 20.5)
          ..quadraticBezierTo(16.3, 20.5, 16.5, 19.5)
          ..lineTo(17.5, 6.5);
        canvas.drawPath(bin, stroke);
        canvas.drawLine(const Offset(10, 10.5), const Offset(10, 16.5), stroke);
        canvas.drawLine(const Offset(14, 10.5), const Offset(14, 16.5), stroke);
      case 0xe047: // add (+)
        canvas.drawLine(const Offset(12, 5.5), const Offset(12, 18.5), stroke);
        canvas.drawLine(const Offset(5.5, 12), const Offset(18.5, 12), stroke);
      case 0xe516: // remove (-)
        canvas.drawLine(const Offset(5.5, 12), const Offset(18.5, 12), stroke);
      case 0xe237: // errorOutline
        canvas.drawCircle(const Offset(12, 12), 8.5, stroke);
        canvas.drawLine(const Offset(12, 7.5), const Offset(12, 13.0), stroke);
        canvas.drawCircle(const Offset(12, 16.2), 1.15, fill);
      case 0xe515: // refresh
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(12, 12), radius: 7.5),
          -math.pi * 0.25,
          math.pi * 1.55,
          false,
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(15.5, 4.5)
            ..lineTo(19.2, 6.8)
            ..lineTo(16.2, 10.0),
          stroke,
        );
      case 0xe3a8: // lightMode sun
        canvas.drawCircle(const Offset(12, 12), 4.2, stroke);
        for (int i = 0; i < 8; i++) {
          final double angle = i * math.pi / 4;
          canvas.drawLine(
            Offset(12 + math.cos(angle) * 6.8, 12 + math.sin(angle) * 6.8),
            Offset(12 + math.cos(angle) * 9.2, 12 + math.sin(angle) * 9.2),
            stroke,
          );
        }
      case 0xe1ad: // darkMode moon
        final Path moon = Path()
          ..moveTo(19.2, 14.2)
          ..arcToPoint(
            const Offset(9.8, 4.8),
            radius: const Radius.circular(8.2),
            largeArc: true,
          )
          ..arcToPoint(
            const Offset(19.2, 14.2),
            radius: const Radius.circular(6.6),
            clockwise: false,
          )
          ..close();
        canvas.drawPath(moon, stroke);
      case 0xf001: // sidebar
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3.5, 4.5, 17, 15),
            const Radius.circular(2.5),
          ),
          stroke,
        );
        canvas.drawLine(
            const Offset(9.2, 4.5), const Offset(9.2, 19.5), stroke);
      case 0xf002: // moreVert
        canvas.drawCircle(const Offset(12, 6), 1.5, fill);
        canvas.drawCircle(const Offset(12, 12), 1.5, fill);
        canvas.drawCircle(const Offset(12, 18), 1.5, fill);
      case 0xf003: // fitWidth
        canvas.drawLine(const Offset(4, 6), const Offset(4, 18), stroke);
        canvas.drawLine(const Offset(20, 6), const Offset(20, 18), stroke);
        canvas.drawLine(const Offset(7.5, 12), const Offset(16.5, 12), stroke);
        canvas.drawPath(
          Path()
            ..moveTo(10, 9.5)
            ..lineTo(7.5, 12)
            ..lineTo(10, 14.5),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(14, 9.5)
            ..lineTo(16.5, 12)
            ..lineTo(14, 14.5),
          stroke,
        );
      case 0xf004: // fitPage
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(5.5, 3.5, 13, 17),
            const Radius.circular(2),
          ),
          stroke,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(8.8, 7, 6.4, 10),
            const Radius.circular(1),
          ),
          stroke,
        );
      case 0xf005: // fullscreen
        canvas.drawPath(
          Path()
            ..moveTo(4, 9)
            ..lineTo(4, 4)
            ..lineTo(9, 4),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(15, 4)
            ..lineTo(20, 4)
            ..lineTo(20, 9),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(20, 15)
            ..lineTo(20, 20)
            ..lineTo(15, 20),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(9, 20)
            ..lineTo(4, 20)
            ..lineTo(4, 15),
          stroke,
        );
      case 0xf006: // fullscreenExit
        canvas.drawPath(
          Path()
            ..moveTo(9, 4)
            ..lineTo(9, 9)
            ..lineTo(4, 9),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(15, 4)
            ..lineTo(15, 9)
            ..lineTo(20, 9),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(20, 15)
            ..lineTo(15, 15)
            ..lineTo(15, 20),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(4, 15)
            ..lineTo(9, 15)
            ..lineTo(9, 20),
          stroke,
        );
      case 0xf007: // underline
        final Path u = Path()
          ..moveTo(7, 5)
          ..lineTo(7, 11.5)
          ..arcToPoint(
            const Offset(17, 11.5),
            radius: const Radius.circular(5),
            clockwise: false,
          )
          ..lineTo(17, 5);
        canvas.drawPath(u, stroke);
        canvas.drawLine(const Offset(5, 19.5), const Offset(19, 19.5), stroke);
      case 0xf008: // strikethrough
        canvas.drawLine(const Offset(4.5, 12), const Offset(19.5, 12), stroke);
        final Path sTop = Path()
          ..moveTo(16, 7.5)
          ..cubicTo(15.5, 5, 9, 4.8, 8.5, 8)
          ..cubicTo(8.3, 9.5, 9.8, 10.6, 12, 11.2);
        canvas.drawPath(sTop, stroke);
        final Path sBot = Path()
          ..moveTo(14.5, 13.5)
          ..cubicTo(16.2, 15, 15.5, 18.8, 11.8, 19)
          ..cubicTo(9.2, 19, 7.8, 17.6, 7.6, 16);
        canvas.drawPath(sBot, stroke);
      case 0xf009: // stamp
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(4, 14.5, 16, 4),
            const Radius.circular(1.5),
          ),
          stroke,
        );
        final Path handle = Path()
          ..moveTo(9.5, 14.5)
          ..lineTo(10.2, 10.5)
          ..cubicTo(8, 8.8, 8.5, 4.8, 12, 4.8)
          ..cubicTo(15.5, 4.8, 16, 8.8, 13.8, 10.5)
          ..lineTo(14.5, 14.5);
        canvas.drawPath(handle, stroke);
        canvas.drawLine(const Offset(5, 20.5), const Offset(19, 20.5), stroke);
      case 0xf00a: // edit
        final Path p = Path()
          ..moveTo(14.5, 5.5)
          ..lineTo(18.5, 9.5)
          ..lineTo(8.5, 19.5)
          ..lineTo(4.5, 19.5)
          ..lineTo(4.5, 15.5)
          ..close();
        canvas.drawPath(p, stroke);
      case 0xf00b: // check
        canvas.drawPath(
          Path()
            ..moveTo(5.5, 12.5)
            ..lineTo(10, 17)
            ..lineTo(18.5, 7.5),
          stroke,
        );
      case 0xf00c: // doublePage
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 4.5, 8, 15),
            const Radius.circular(1.5),
          ),
          stroke,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(13, 4.5, 8, 15),
            const Radius.circular(1.5),
          ),
          stroke,
        );
      case 0xf00d: // singlePage
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(6, 3.5, 12, 17),
            const Radius.circular(2),
          ),
          stroke,
        );
      case 0xf00e: // scrollVertical
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(5.5, 3, 13, 7.5),
            const Radius.circular(1.5),
          ),
          stroke,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(5.5, 13.5, 13, 7.5),
            const Radius.circular(1.5),
          ),
          stroke,
        );
      case 0xf00f: // scrollHorizontal
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 5.5, 7.5, 13),
            const Radius.circular(1.5),
          ),
          stroke,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(13.5, 5.5, 7.5, 13),
            const Radius.circular(1.5),
          ),
          stroke,
        );
      case 0xf010: // annotations / layers
        canvas.drawPath(
          Path()
            ..moveTo(12, 4)
            ..lineTo(20, 8.5)
            ..lineTo(12, 13)
            ..lineTo(4, 8.5)
            ..close(),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(4, 12.8)
            ..lineTo(12, 17.3)
            ..lineTo(20, 12.8),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(4, 16.5)
            ..lineTo(12, 21)
            ..lineTo(20, 16.5),
          stroke,
        );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PdfVectorIconPainter oldDelegate) {
    return oldDelegate.codePoint != codePoint || oldDelegate.color != color;
  }
}

/// Lightweight, dependency-free icon button built on `package:flutter/widgets.dart`
/// with smooth hover highlight, active pill feedback, and crisp vector icons.
class PdfIconButton extends StatefulWidget {
  /// Creates a [PdfIconButton].
  const PdfIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color = const Color(0xFF0F172A),
    this.size = 19.0,
    this.padding = const EdgeInsets.all(7.5),
    this.isActive = false,
    this.activeColor,
    this.borderRadius = 9.0,
  });

  /// Icon glyph to display.
  final IconData icon;

  /// Tap callback, or `null` when disabled.
  final VoidCallback? onPressed;

  /// Semantic label / accessibility description for the button.
  final String? tooltip;

  /// Foreground color of the icon.
  final Color color;

  /// Size of the icon in logical pixels.
  final double size;

  /// Touch target padding around the icon.
  final EdgeInsetsGeometry padding;

  /// Whether this button is currently toggled active.
  final bool isActive;

  /// Optional highlight tint used when [isActive] is `true`.
  final Color? activeColor;

  /// Corner radius of the hover/active highlight pill.
  final double borderRadius;

  @override
  State<PdfIconButton> createState() => _PdfIconButtonState();
}

class _PdfIconButtonState extends State<PdfIconButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    final Color tint = widget.activeColor ?? widget.color;
    final Color effectiveColor = enabled
        ? (widget.isActive ? tint : widget.color)
        : widget.color.withValues(alpha: 0.34);

    final Color bgColor;
    if (!enabled) {
      bgColor = const Color(0x00000000);
    } else if (_pressed) {
      bgColor = tint.withValues(alpha: 0.18);
    } else if (widget.isActive) {
      bgColor = tint.withValues(alpha: 0.14);
    } else if (_hovered) {
      bgColor = widget.color.withValues(alpha: 0.08);
    } else {
      bgColor = const Color(0x00000000);
    }

    Widget button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onPressed,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: PdfIcon(
          widget.icon,
          size: widget.size,
          color: effectiveColor,
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      button = Semantics(
        label: widget.tooltip,
        button: true,
        enabled: enabled,
        excludeSemantics: true,
        child: button,
      );
    }

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: button,
    );
  }
}

/// Displays a modal dialog using pure `package:flutter/widgets.dart` primitives
/// with a smooth fade and scale entrance transition.
Future<T?> showPdfModalDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final String? ambientFontFamily =
      DefaultTextStyle.of(context).style.fontFamily;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: const Color(0x88000000),
    transitionDuration: const Duration(milliseconds: 200),
    transitionBuilder: (
      BuildContext ctx,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      final CurvedAnimation curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
    pageBuilder: (
      BuildContext dialogContext,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: DefaultTextStyle(
            style: TextStyle(
              fontFamily: ambientFontFamily,
              color: const Color(0xFF0F172A),
              fontSize: 14,
              decoration: TextDecoration.none,
            ),
            child: builder(dialogContext),
          ),
        ),
      );
    },
  );
}

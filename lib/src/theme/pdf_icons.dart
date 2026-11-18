import 'package:flutter/widgets.dart';

/// Built-in vector icon constants and pure-`widgets.dart` UI primitives for
/// `pdf_reader` so the library does not depend on deprecated Material imports.
class PdfIcons {
  const PdfIcons._();

  /// Search icon.
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

  /// Table of contents icon.
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
  static const IconData refresh = IconData(0xe514, fontFamily: 'MaterialIcons');

  /// Light mode sun icon.
  static const IconData lightMode =
      IconData(0xe3a8, fontFamily: 'MaterialIcons');

  /// Dark mode moon icon.
  static const IconData darkMode =
      IconData(0xe1ad, fontFamily: 'MaterialIcons');
}

/// Lightweight, dependency-free icon button built on `package:flutter/widgets.dart`.
class PdfIconButton extends StatelessWidget {
  /// Creates a [PdfIconButton].
  const PdfIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color = const Color(0xFF0F172A),
    this.size = 20.0,
    this.padding = const EdgeInsets.all(8.0),
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

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    final Color effectiveColor =
        enabled ? color : color.withValues(alpha: 0.35);

    Widget button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Padding(
        padding: padding,
        child: Icon(
          icon,
          size: size,
          color: effectiveColor,
          semanticLabel: tooltip,
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      button = Semantics(
        label: tooltip,
        button: true,
        enabled: enabled,
        excludeSemantics: true,
        child: button,
      );
    }

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: button,
    );
  }
}

/// Displays a modal dialog using pure `package:flutter/widgets.dart` primitives.
Future<T?> showPdfModalDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: const Color(0x88000000),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (
      BuildContext dialogContext,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      return Center(
        child: DefaultTextStyle(
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 14,
            decoration: TextDecoration.none,
          ),
          child: builder(dialogContext),
        ),
      );
    },
  );
}

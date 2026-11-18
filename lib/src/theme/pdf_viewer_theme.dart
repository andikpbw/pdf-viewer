import 'package:flutter/material.dart';

/// Page layout and scrolling modes supported by `PdfViewer`.
enum PdfPageLayoutMode {
  /// Continuous vertical scrolling list of pages.
  continuousVertical,

  /// Continuous horizontal scrolling strip of pages.
  continuousHorizontal,

  /// Single page at a time with swipe/page-flip transitions.
  singlePage,

  /// Side-by-side two-page book spread layout for tablets and desktops.
  doublePage,
}

/// Visual color filters applied to rendered PDF pages for reading comfort.
enum PdfColorMode {
  /// Standard full-color paper appearance.
  normal,

  /// Inverted dark reading filter suitable for low-light environments.
  night,

  /// Warm sepia paper filter for extended reading comfort.
  sepia,

  /// High-contrast monochromatic grayscale filter.
  grayscale;

  /// Returns the hardware-accelerated [ColorFilter] matrix for this mode, or
  /// `null` for [PdfColorMode.normal].
  ColorFilter? get colorFilter {
    switch (this) {
      case PdfColorMode.normal:
        return null;
      case PdfColorMode.night:
        return const ColorFilter.matrix(<double>[
          -0.88,
          0.0,
          0.0,
          0.0,
          240.0,
          0.0,
          -0.88,
          0.0,
          0.0,
          242.0,
          0.0,
          0.0,
          -0.85,
          0.0,
          248.0,
          0.0,
          0.0,
          0.0,
          1.0,
          0.0,
        ]);
      case PdfColorMode.sepia:
        return const ColorFilter.matrix(<double>[
          0.393,
          0.769,
          0.189,
          0.0,
          0.0,
          0.349,
          0.686,
          0.168,
          0.0,
          0.0,
          0.272,
          0.534,
          0.131,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          1.0,
          0.0,
        ]);
      case PdfColorMode.grayscale:
        return const ColorFilter.matrix(<double>[
          0.2126,
          0.7152,
          0.0722,
          0.0,
          0.0,
          0.2126,
          0.7152,
          0.0722,
          0.0,
          0.0,
          0.2126,
          0.7152,
          0.0722,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          1.0,
          0.0,
        ]);
    }
  }

  /// Human-readable label for UI menus.
  String get label {
    switch (this) {
      case PdfColorMode.normal:
        return 'Normal';
      case PdfColorMode.night:
        return 'Night Mode';
      case PdfColorMode.sepia:
        return 'Sepia';
      case PdfColorMode.grayscale:
        return 'Grayscale';
    }
  }
}

/// Visual styling configuration for `PdfViewer` and its companion widgets.
@immutable
class PdfViewerTheme {
  /// Creates a custom [PdfViewerTheme].
  const PdfViewerTheme({
    this.backgroundColor = const Color(0xFFF1F5F9),
    this.toolbarBackgroundColor = const Color(0xF2FFFFFF),
    this.toolbarForegroundColor = const Color(0xFF0F172A),
    this.accentColor = const Color(0xFF2563EB),
    this.pageShadowColor = const Color(0x260F172A),
    this.pageBorderRadius = 6.0,
    this.pageSpacing = 16.0,
    this.searchHighlightColor = const Color(0x66FACC15),
    this.activeSearchHighlightColor = const Color(0x99F97316),
    this.thumbnailBorderColor = const Color(0xFFCBD5E1),
    this.activeThumbnailBorderColor = const Color(0xFF2563EB),
  });

  /// Creates a clean light Material 3 preset [PdfViewerTheme].
  factory PdfViewerTheme.light({Color accentColor = const Color(0xFF2563EB)}) {
    return PdfViewerTheme(
      backgroundColor: const Color(0xFFF1F5F9),
      toolbarBackgroundColor: const Color(0xF5FFFFFF),
      toolbarForegroundColor: const Color(0xFF0F172A),
      accentColor: accentColor,
      pageShadowColor: const Color(0x240F172A),
      thumbnailBorderColor: const Color(0xFFCBD5E1),
      activeThumbnailBorderColor: accentColor,
    );
  }

  /// Creates a sleek dark Material 3 preset [PdfViewerTheme].
  factory PdfViewerTheme.dark({Color accentColor = const Color(0xFF38BDF8)}) {
    return PdfViewerTheme(
      backgroundColor: const Color(0xFF0B1120),
      toolbarBackgroundColor: const Color(0xF21E293B),
      toolbarForegroundColor: const Color(0xFFF8FAFC),
      accentColor: accentColor,
      pageShadowColor: const Color(0x66000000),
      thumbnailBorderColor: const Color(0xFF334155),
      activeThumbnailBorderColor: accentColor,
    );
  }

  /// Resolves an adaptive [PdfViewerTheme] based on the ambient [ThemeData]
  /// brightness in [context].
  factory PdfViewerTheme.fromContext(BuildContext context) {
    final ThemeData materialTheme = Theme.of(context);
    final bool isDark = materialTheme.brightness == Brightness.dark;
    final Color primary = materialTheme.colorScheme.primary;
    return isDark
        ? PdfViewerTheme.dark(accentColor: primary)
        : PdfViewerTheme.light(accentColor: primary);
  }

  /// Canvas backdrop color behind PDF pages.
  final Color backgroundColor;

  /// Surface color of top/bottom toolbars and floating panels.
  final Color toolbarBackgroundColor;

  /// Icon and text color on toolbars.
  final Color toolbarForegroundColor;

  /// Primary accent color for active indicators, sliders, and badges.
  final Color accentColor;

  /// Elevation shadow color cast by each PDF page card.
  final Color pageShadowColor;

  /// Corner radius of rendered PDF page cards in logical pixels.
  final double pageBorderRadius;

  /// Spacing between adjacent pages in continuous scroll modes.
  final double pageSpacing;

  /// Highlight overlay color for non-active search matches.
  final Color searchHighlightColor;

  /// Highlight overlay color for the currently focused search match.
  final Color activeSearchHighlightColor;

  /// Border color of unselected page thumbnails.
  final Color thumbnailBorderColor;

  /// Border color of the currently active page thumbnail.
  final Color activeThumbnailBorderColor;

  /// Returns a copy of this [PdfViewerTheme] with the given fields replaced.
  PdfViewerTheme copyWith({
    Color? backgroundColor,
    Color? toolbarBackgroundColor,
    Color? toolbarForegroundColor,
    Color? accentColor,
    Color? pageShadowColor,
    double? pageBorderRadius,
    double? pageSpacing,
    Color? searchHighlightColor,
    Color? activeSearchHighlightColor,
    Color? thumbnailBorderColor,
    Color? activeThumbnailBorderColor,
  }) {
    return PdfViewerTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      toolbarBackgroundColor:
          toolbarBackgroundColor ?? this.toolbarBackgroundColor,
      toolbarForegroundColor:
          toolbarForegroundColor ?? this.toolbarForegroundColor,
      accentColor: accentColor ?? this.accentColor,
      pageShadowColor: pageShadowColor ?? this.pageShadowColor,
      pageBorderRadius: pageBorderRadius ?? this.pageBorderRadius,
      pageSpacing: pageSpacing ?? this.pageSpacing,
      searchHighlightColor: searchHighlightColor ?? this.searchHighlightColor,
      activeSearchHighlightColor:
          activeSearchHighlightColor ?? this.activeSearchHighlightColor,
      thumbnailBorderColor: thumbnailBorderColor ?? this.thumbnailBorderColor,
      activeThumbnailBorderColor:
          activeThumbnailBorderColor ?? this.activeThumbnailBorderColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PdfViewerTheme &&
        other.backgroundColor == backgroundColor &&
        other.toolbarBackgroundColor == toolbarBackgroundColor &&
        other.toolbarForegroundColor == toolbarForegroundColor &&
        other.accentColor == accentColor &&
        other.pageShadowColor == pageShadowColor &&
        other.pageBorderRadius == pageBorderRadius &&
        other.pageSpacing == pageSpacing &&
        other.searchHighlightColor == searchHighlightColor &&
        other.activeSearchHighlightColor == activeSearchHighlightColor &&
        other.thumbnailBorderColor == thumbnailBorderColor &&
        other.activeThumbnailBorderColor == activeThumbnailBorderColor;
  }

  @override
  int get hashCode => Object.hash(
        backgroundColor,
        toolbarBackgroundColor,
        toolbarForegroundColor,
        accentColor,
        pageShadowColor,
        pageBorderRadius,
        pageSpacing,
        searchHighlightColor,
        activeSearchHighlightColor,
        thumbnailBorderColor,
        activeThumbnailBorderColor,
      );
}

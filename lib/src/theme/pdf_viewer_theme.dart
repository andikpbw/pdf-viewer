import 'package:flutter/widgets.dart';

/// Page layout and scrolling modes supported by `PdfViewer`.
enum PdfPageLayoutMode {
  /// Continuous vertical scrolling list of pages.
  continuousVertical,

  /// Continuous horizontal scrolling strip of pages.
  continuousHorizontal,

  /// Single page at a time with swipe/page-flip transitions.
  singlePage,

  /// Side-by-side two-page book spread layout for tablets and desktops.
  doublePage;

  /// Human-readable short label for UI menus and toolbars.
  String get label {
    switch (this) {
      case PdfPageLayoutMode.continuousVertical:
        return 'Vertical';
      case PdfPageLayoutMode.continuousHorizontal:
        return 'Horizontal';
      case PdfPageLayoutMode.singlePage:
        return 'Single';
      case PdfPageLayoutMode.doublePage:
        return 'Book Spread';
    }
  }
}

/// Page sizing policy inside the viewer viewport.
enum PdfFitMode {
  /// Fits the entire page inside the available viewport height and width.
  fitPage,

  /// Expands the page to fill the full available viewport width.
  fitWidth;

  /// Human-readable label for UI menus.
  String get label {
    switch (this) {
      case PdfFitMode.fitPage:
        return 'Fit Page';
      case PdfFitMode.fitWidth:
        return 'Fit Width';
    }
  }
}

/// Active tab displayed in the adaptive studio sidebar / navigation drawer.
enum PdfSidebarTab {
  /// Miniature live vector page thumbnail previews.
  thumbnails,

  /// Document outlines (table of contents) and user-saved bookmarks.
  bookmarks,

  /// Interactive list of annotations across the document.
  annotations,
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
          -0.86,
          0.0,
          0.0,
          0.0,
          236.0,
          0.0,
          -0.86,
          0.0,
          0.0,
          240.0,
          0.0,
          0.0,
          -0.82,
          0.0,
          246.0,
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

  /// Representative swatch color for reading mode selectors.
  Color get swatchColor {
    switch (this) {
      case PdfColorMode.normal:
        return const Color(0xFFFFFFFF);
      case PdfColorMode.night:
        return const Color(0xFF1E293B);
      case PdfColorMode.sepia:
        return const Color(0xFFF3E5C8);
      case PdfColorMode.grayscale:
        return const Color(0xFF94A3B8);
    }
  }
}

/// Visual styling configuration for `PdfViewer` and its companion widgets.
@immutable
class PdfViewerTheme {
  /// Creates a custom [PdfViewerTheme].
  const PdfViewerTheme({
    this.backgroundColor = const Color(0xFFEEF2F6),
    this.toolbarBackgroundColor = const Color(0xF8FFFFFF),
    this.toolbarForegroundColor = const Color(0xFF0F172A),
    this.accentColor = const Color(0xFF2563EB),
    this.pageShadowColor = const Color(0x220F172A),
    this.pageBorderRadius = 8.0,
    this.pageSpacing = 18.0,
    this.searchHighlightColor = const Color(0x66FACC15),
    this.activeSearchHighlightColor = const Color(0xA6F97316),
    this.thumbnailBorderColor = const Color(0xFFCBD5E1),
    this.activeThumbnailBorderColor = const Color(0xFF2563EB),
    this.surfaceColor = const Color(0xFFFFFFFF),
    this.surfaceBorderColor = const Color(0xFFE2E8F0),
    this.secondaryForegroundColor = const Color(0xFF64748B),
    this.selectionColor = const Color(0x4D3B82F6),
    this.toolbarBorderRadius = 16.0,
    this.fontFamily,
  });

  /// Creates a crisp, modern light studio preset [PdfViewerTheme].
  factory PdfViewerTheme.light({
    Color accentColor = const Color(0xFF2563EB),
    String? fontFamily,
  }) {
    return PdfViewerTheme(
      backgroundColor: const Color(0xFFEEF2F7),
      toolbarBackgroundColor: const Color(0xFAFFFFFF),
      toolbarForegroundColor: const Color(0xFF0F172A),
      accentColor: accentColor,
      pageShadowColor: const Color(0x220F172A),
      pageBorderRadius: 8.0,
      thumbnailBorderColor: const Color(0xFFCBD5E1),
      activeThumbnailBorderColor: accentColor,
      surfaceColor: const Color(0xFFFFFFFF),
      surfaceBorderColor: const Color(0xFFE2E8F0),
      secondaryForegroundColor: const Color(0xFF64748B),
      selectionColor: accentColor.withValues(alpha: 0.28),
      fontFamily: fontFamily,
    );
  }

  /// Creates a sleek dark studio preset [PdfViewerTheme].
  factory PdfViewerTheme.dark({
    Color accentColor = const Color(0xFF38BDF8),
    String? fontFamily,
  }) {
    return PdfViewerTheme(
      backgroundColor: const Color(0xFF090E1A),
      toolbarBackgroundColor: const Color(0xF5111827),
      toolbarForegroundColor: const Color(0xFFF8FAFC),
      accentColor: accentColor,
      pageShadowColor: const Color(0x78000000),
      pageBorderRadius: 8.0,
      thumbnailBorderColor: const Color(0xFF283548),
      activeThumbnailBorderColor: accentColor,
      surfaceColor: const Color(0xFF151E2E),
      surfaceBorderColor: const Color(0xFF243146),
      secondaryForegroundColor: const Color(0xFF94A3B8),
      selectionColor: accentColor.withValues(alpha: 0.30),
      fontFamily: fontFamily,
    );
  }

  /// Creates a warm, book-inspired sepia preset [PdfViewerTheme].
  factory PdfViewerTheme.sepia({
    Color accentColor = const Color(0xFFB45309),
    String? fontFamily,
  }) {
    return PdfViewerTheme(
      backgroundColor: const Color(0xFFEDE3D2),
      toolbarBackgroundColor: const Color(0xFAF7F0E2),
      toolbarForegroundColor: const Color(0xFF3B2A1A),
      accentColor: accentColor,
      pageShadowColor: const Color(0x263B2A1A),
      pageBorderRadius: 8.0,
      thumbnailBorderColor: const Color(0xFFD6C7AE),
      activeThumbnailBorderColor: accentColor,
      surfaceColor: const Color(0xFFFAF4E8),
      surfaceBorderColor: const Color(0xFFDDCFB8),
      secondaryForegroundColor: const Color(0xFF78614A),
      selectionColor: accentColor.withValues(alpha: 0.25),
      fontFamily: fontFamily,
    );
  }

  /// Creates a high-contrast OLED midnight preset [PdfViewerTheme].
  factory PdfViewerTheme.midnight({
    Color accentColor = const Color(0xFF818CF8),
    String? fontFamily,
  }) {
    return PdfViewerTheme(
      backgroundColor: const Color(0xFF05070D),
      toolbarBackgroundColor: const Color(0xF50B0F1A),
      toolbarForegroundColor: const Color(0xFFF1F5F9),
      accentColor: accentColor,
      pageShadowColor: const Color(0x99000000),
      pageBorderRadius: 8.0,
      thumbnailBorderColor: const Color(0xFF1E293B),
      activeThumbnailBorderColor: accentColor,
      surfaceColor: const Color(0xFF0F1524),
      surfaceBorderColor: const Color(0xFF1E293B),
      secondaryForegroundColor: const Color(0xFF94A3B8),
      selectionColor: accentColor.withValues(alpha: 0.32),
      fontFamily: fontFamily,
    );
  }

  /// Resolves an adaptive [PdfViewerTheme] based on the ambient platform
  /// brightness in [context].
  factory PdfViewerTheme.fromContext(BuildContext context) {
    final Brightness brightness =
        MediaQuery.maybePlatformBrightnessOf(context) ?? Brightness.light;
    final bool isDark = brightness == Brightness.dark;
    return isDark ? PdfViewerTheme.dark() : PdfViewerTheme.light();
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

  /// Elevated panel, dialog, and sidebar surface color.
  final Color surfaceColor;

  /// Subtle 1px hairline border color for toolbars, sidebars, and dialogs.
  final Color surfaceBorderColor;

  /// Muted foreground color for captions, subtitles, and secondary metadata.
  final Color secondaryForegroundColor;

  /// Translucent fill color for selected PDF text ranges.
  final Color selectionColor;

  /// Default border radius for floating bars and dialog surfaces.
  final double toolbarBorderRadius;

  /// Optional font family applied to viewer UI chrome and rendered PDF text.
  final String? fontFamily;

  /// Whether this theme uses a dark background palette.
  bool get isDark => backgroundColor.computeLuminance() < 0.3;

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
    Color? surfaceColor,
    Color? surfaceBorderColor,
    Color? secondaryForegroundColor,
    Color? selectionColor,
    double? toolbarBorderRadius,
    String? fontFamily,
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
      surfaceColor: surfaceColor ?? this.surfaceColor,
      surfaceBorderColor: surfaceBorderColor ?? this.surfaceBorderColor,
      secondaryForegroundColor:
          secondaryForegroundColor ?? this.secondaryForegroundColor,
      selectionColor: selectionColor ?? this.selectionColor,
      toolbarBorderRadius: toolbarBorderRadius ?? this.toolbarBorderRadius,
      fontFamily: fontFamily ?? this.fontFamily,
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
        other.activeThumbnailBorderColor == activeThumbnailBorderColor &&
        other.surfaceColor == surfaceColor &&
        other.surfaceBorderColor == surfaceBorderColor &&
        other.secondaryForegroundColor == secondaryForegroundColor &&
        other.selectionColor == selectionColor &&
        other.toolbarBorderRadius == toolbarBorderRadius &&
        other.fontFamily == fontFamily;
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
        surfaceColor,
        surfaceBorderColor,
        secondaryForegroundColor,
        selectionColor,
        toolbarBorderRadius,
        fontFamily,
      );
}

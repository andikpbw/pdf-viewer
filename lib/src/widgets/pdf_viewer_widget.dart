import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../controller/pdf_viewer_controller.dart';
import '../models/pdf_annotation.dart';
import '../models/pdf_bookmark.dart';
import '../models/pdf_document.dart';
import '../models/pdf_page_data.dart';
import '../models/pdf_source.dart';
import '../theme/pdf_icons.dart';
import '../theme/pdf_viewer_theme.dart';
import 'pdf_annotation_layer.dart';
import 'pdf_page_canvas.dart';
import 'pdf_search_bar.dart';
import 'pdf_thumbnail_bar.dart';
import 'pdf_toolbar.dart';

/// Signature for building a custom loading state widget in [PdfViewer].
typedef PdfLoadingWidgetBuilder = Widget Function(BuildContext context);

/// Signature for building a custom error state widget in [PdfViewer].
typedef PdfErrorWidgetBuilder = Widget Function(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
);

/// A modern, adaptive, cross-platform PDF studio viewer widget for Flutter,
/// proudly supported by [Humanize AI](https://humanize.id).
///
/// Features:
/// * Pure-Flutter vector rendering across Android, iOS, Web, macOS, Windows, and Linux.
/// * True continuous vertical & horizontal scrolling, single-page, and double-page book spread modes.
/// * Docked multi-tab Studio Sidebar on desktop (Pages, Outlines, Markup) & slide-over drawer on mobile.
/// * Full-text search with case matching, live counters, and bounding-box highlighting.
/// * Tap-to-select PDF text with instant Copy and Highlight actions.
/// * Interactive annotations (highlighter, underline, strikethrough, Bezier-smoothed ink, editable sticky notes, review stamps) with undo/redo.
/// * Keyboard shortcuts, Ctrl/Cmd wheel zoom, Fit-Page/Fit-Width, immersive focus mode, and reading color filters.
class PdfViewer extends StatefulWidget {
  /// Creates a [PdfViewer] from any [PdfSource].
  const PdfViewer({
    super.key,
    required this.source,
    this.controller,
    this.theme,
    this.title,
    this.showTopToolbar = true,
    this.showBottomScrubber = true,
    this.showSupportBadge = false,
    this.enableDoubleTapZoom = true,
    this.doubleTapZoomScale = 2.0,
    this.enableTextSelection = true,
    this.enableKeyboardShortcuts = true,
    this.onDocumentLoaded,
    this.onPageChanged,
    this.onLoadError,
    this.onAnnotationAdded,
    this.loadingBuilder,
    this.errorBuilder,
    this.leadingToolbarActions = const <Widget>[],
    this.trailingToolbarActions = const <Widget>[],
  });

  /// Creates a [PdfViewer] from an already parsed [PdfDocument].
  factory PdfViewer.fromDocument(
    PdfDocument document, {
    Key? key,
    PdfViewerController? controller,
    PdfViewerTheme? theme,
    String? title,
    bool showTopToolbar = true,
    bool showBottomScrubber = true,
    bool showSupportBadge = false,
    bool enableDoubleTapZoom = true,
    double doubleTapZoomScale = 2.0,
    bool enableTextSelection = true,
    bool enableKeyboardShortcuts = true,
    ValueChanged<PdfDocument>? onDocumentLoaded,
    ValueChanged<int>? onPageChanged,
    ValueChanged<Object>? onLoadError,
    ValueChanged<PdfAnnotation>? onAnnotationAdded,
    PdfLoadingWidgetBuilder? loadingBuilder,
    PdfErrorWidgetBuilder? errorBuilder,
    List<Widget> leadingToolbarActions = const <Widget>[],
    List<Widget> trailingToolbarActions = const <Widget>[],
  }) {
    return PdfViewer(
      key: key,
      source: PdfDocumentSource(document),
      controller: controller,
      theme: theme,
      title: title,
      showTopToolbar: showTopToolbar,
      showBottomScrubber: showBottomScrubber,
      showSupportBadge: showSupportBadge,
      enableDoubleTapZoom: enableDoubleTapZoom,
      doubleTapZoomScale: doubleTapZoomScale,
      enableTextSelection: enableTextSelection,
      enableKeyboardShortcuts: enableKeyboardShortcuts,
      onDocumentLoaded: onDocumentLoaded,
      onPageChanged: onPageChanged,
      onLoadError: onLoadError,
      onAnnotationAdded: onAnnotationAdded,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
      leadingToolbarActions: leadingToolbarActions,
      trailingToolbarActions: trailingToolbarActions,
    );
  }

  /// Creates a [PdfViewer] from raw PDF [bytes].
  factory PdfViewer.fromBytes(
    Uint8List bytes, {
    Key? key,
    PdfViewerController? controller,
    PdfViewerTheme? theme,
    String? title,
    bool showTopToolbar = true,
    bool showBottomScrubber = true,
    bool showSupportBadge = false,
    bool enableDoubleTapZoom = true,
    double doubleTapZoomScale = 2.0,
    bool enableTextSelection = true,
    bool enableKeyboardShortcuts = true,
    ValueChanged<PdfDocument>? onDocumentLoaded,
    ValueChanged<int>? onPageChanged,
    ValueChanged<Object>? onLoadError,
    ValueChanged<PdfAnnotation>? onAnnotationAdded,
    PdfLoadingWidgetBuilder? loadingBuilder,
    PdfErrorWidgetBuilder? errorBuilder,
    List<Widget> leadingToolbarActions = const <Widget>[],
    List<Widget> trailingToolbarActions = const <Widget>[],
  }) {
    return PdfViewer(
      key: key,
      source: PdfBytesSource(bytes),
      controller: controller,
      theme: theme,
      title: title,
      showTopToolbar: showTopToolbar,
      showBottomScrubber: showBottomScrubber,
      showSupportBadge: showSupportBadge,
      enableDoubleTapZoom: enableDoubleTapZoom,
      doubleTapZoomScale: doubleTapZoomScale,
      enableTextSelection: enableTextSelection,
      enableKeyboardShortcuts: enableKeyboardShortcuts,
      onDocumentLoaded: onDocumentLoaded,
      onPageChanged: onPageChanged,
      onLoadError: onLoadError,
      onAnnotationAdded: onAnnotationAdded,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
      leadingToolbarActions: leadingToolbarActions,
      trailingToolbarActions: trailingToolbarActions,
    );
  }

  /// Creates a [PdfViewer] from a Flutter application asset [assetPath].
  factory PdfViewer.fromAsset(
    String assetPath, {
    Key? key,
    AssetBundle? bundle,
    PdfViewerController? controller,
    PdfViewerTheme? theme,
    String? title,
    bool showTopToolbar = true,
    bool showBottomScrubber = true,
    bool showSupportBadge = false,
    bool enableDoubleTapZoom = true,
    double doubleTapZoomScale = 2.0,
    bool enableTextSelection = true,
    bool enableKeyboardShortcuts = true,
    ValueChanged<PdfDocument>? onDocumentLoaded,
    ValueChanged<int>? onPageChanged,
    ValueChanged<Object>? onLoadError,
    ValueChanged<PdfAnnotation>? onAnnotationAdded,
    PdfLoadingWidgetBuilder? loadingBuilder,
    PdfErrorWidgetBuilder? errorBuilder,
    List<Widget> leadingToolbarActions = const <Widget>[],
    List<Widget> trailingToolbarActions = const <Widget>[],
  }) {
    return PdfViewer(
      key: key,
      source: PdfAssetSource(assetPath, bundle: bundle),
      controller: controller,
      theme: theme,
      title: title,
      showTopToolbar: showTopToolbar,
      showBottomScrubber: showBottomScrubber,
      showSupportBadge: showSupportBadge,
      enableDoubleTapZoom: enableDoubleTapZoom,
      doubleTapZoomScale: doubleTapZoomScale,
      enableTextSelection: enableTextSelection,
      enableKeyboardShortcuts: enableKeyboardShortcuts,
      onDocumentLoaded: onDocumentLoaded,
      onPageChanged: onPageChanged,
      onLoadError: onLoadError,
      onAnnotationAdded: onAnnotationAdded,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
      leadingToolbarActions: leadingToolbarActions,
      trailingToolbarActions: trailingToolbarActions,
    );
  }

  /// Creates a [PdfViewer] from a local file system [filePath].
  factory PdfViewer.fromFile(
    String filePath, {
    Key? key,
    PdfViewerController? controller,
    PdfViewerTheme? theme,
    String? title,
    bool showTopToolbar = true,
    bool showBottomScrubber = true,
    bool showSupportBadge = false,
    bool enableDoubleTapZoom = true,
    double doubleTapZoomScale = 2.0,
    bool enableTextSelection = true,
    bool enableKeyboardShortcuts = true,
    ValueChanged<PdfDocument>? onDocumentLoaded,
    ValueChanged<int>? onPageChanged,
    ValueChanged<Object>? onLoadError,
    ValueChanged<PdfAnnotation>? onAnnotationAdded,
    PdfLoadingWidgetBuilder? loadingBuilder,
    PdfErrorWidgetBuilder? errorBuilder,
    List<Widget> leadingToolbarActions = const <Widget>[],
    List<Widget> trailingToolbarActions = const <Widget>[],
  }) {
    return PdfViewer(
      key: key,
      source: PdfFileSource(filePath),
      controller: controller,
      theme: theme,
      title: title,
      showTopToolbar: showTopToolbar,
      showBottomScrubber: showBottomScrubber,
      showSupportBadge: showSupportBadge,
      enableDoubleTapZoom: enableDoubleTapZoom,
      doubleTapZoomScale: doubleTapZoomScale,
      enableTextSelection: enableTextSelection,
      enableKeyboardShortcuts: enableKeyboardShortcuts,
      onDocumentLoaded: onDocumentLoaded,
      onPageChanged: onPageChanged,
      onLoadError: onLoadError,
      onAnnotationAdded: onAnnotationAdded,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
      leadingToolbarActions: leadingToolbarActions,
      trailingToolbarActions: trailingToolbarActions,
    );
  }

  /// Creates a [PdfViewer] from an HTTP/HTTPS [url].
  factory PdfViewer.fromNetwork(
    String url, {
    Key? key,
    Map<String, String>? headers,
    PdfViewerController? controller,
    PdfViewerTheme? theme,
    String? title,
    bool showTopToolbar = true,
    bool showBottomScrubber = true,
    bool showSupportBadge = false,
    bool enableDoubleTapZoom = true,
    double doubleTapZoomScale = 2.0,
    bool enableTextSelection = true,
    bool enableKeyboardShortcuts = true,
    ValueChanged<PdfDocument>? onDocumentLoaded,
    ValueChanged<int>? onPageChanged,
    ValueChanged<Object>? onLoadError,
    ValueChanged<PdfAnnotation>? onAnnotationAdded,
    PdfLoadingWidgetBuilder? loadingBuilder,
    PdfErrorWidgetBuilder? errorBuilder,
    List<Widget> leadingToolbarActions = const <Widget>[],
    List<Widget> trailingToolbarActions = const <Widget>[],
  }) {
    return PdfViewer(
      key: key,
      source: PdfNetworkSource(url, headers: headers),
      controller: controller,
      theme: theme,
      title: title,
      showTopToolbar: showTopToolbar,
      showBottomScrubber: showBottomScrubber,
      showSupportBadge: showSupportBadge,
      enableDoubleTapZoom: enableDoubleTapZoom,
      doubleTapZoomScale: doubleTapZoomScale,
      enableTextSelection: enableTextSelection,
      enableKeyboardShortcuts: enableKeyboardShortcuts,
      onDocumentLoaded: onDocumentLoaded,
      onPageChanged: onPageChanged,
      onLoadError: onLoadError,
      onAnnotationAdded: onAnnotationAdded,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
      leadingToolbarActions: leadingToolbarActions,
      trailingToolbarActions: trailingToolbarActions,
    );
  }

  /// Source from which the [PdfDocument] is loaded.
  final PdfSource source;

  /// Optional external controller for driving and observing viewer state.
  final PdfViewerController? controller;

  /// Optional theme customization. Defaults to `PdfViewerTheme.fromContext(context)`.
  final PdfViewerTheme? theme;

  /// Optional title override displayed in the top toolbar.
  final String? title;

  /// Whether to render the adaptive top toolbar.
  final bool showTopToolbar;

  /// Whether to render the floating bottom page scrubber and zoom bar.
  final bool showBottomScrubber;

  /// Whether to display a compact "Supported by Humanize AI" badge in the corner.
  final bool showSupportBadge;

  /// Whether double-tapping a page toggles between `1.0x` and [doubleTapZoomScale].
  final bool enableDoubleTapZoom;

  /// Target zoom multiplier when double-tapping a page.
  final double doubleTapZoomScale;

  /// Whether tapping text runs selects text for copying or instant highlighting.
  final bool enableTextSelection;

  /// Whether desktop keyboard shortcuts (search, zoom, arrows, undo/redo) are active.
  final bool enableKeyboardShortcuts;

  /// Callback invoked when the [PdfDocument] finishes loading.
  final ValueChanged<PdfDocument>? onDocumentLoaded;

  /// Callback invoked whenever the active 1-based page number changes.
  final ValueChanged<int>? onPageChanged;

  /// Callback invoked if loading or parsing the PDF fails.
  final ValueChanged<Object>? onLoadError;

  /// Callback invoked when the user creates a new [PdfAnnotation].
  final ValueChanged<PdfAnnotation>? onAnnotationAdded;

  /// Optional builder for the loading state.
  final PdfLoadingWidgetBuilder? loadingBuilder;

  /// Optional builder for the error state.
  final PdfErrorWidgetBuilder? errorBuilder;

  /// Extra widgets placed at the start of the top toolbar.
  final List<Widget> leadingToolbarActions;

  /// Extra widgets placed at the end of the top toolbar.
  final List<Widget> trailingToolbarActions;

  @override
  State<PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> {
  late PdfViewerController _controller;
  bool _ownsController = false;

  PdfDocument? _document;
  Object? _loadError;
  StackTrace? _loadStackTrace;
  bool _isLoading = true;

  int _lastSyncedPage = 1;
  int _lastNavigationRevision = 0;
  double _lastSyncedZoom = 1.0;
  PdfPageLayoutMode _lastLayoutMode = PdfPageLayoutMode.continuousVertical;
  double _lastContinuousItemExtent = 600.0;
  bool _isProgrammaticScrolling = false;

  PageController? _pageController;
  final ScrollController _continuousScrollController = ScrollController();
  final TransformationController _transformController =
      TransformationController();
  final FocusNode _keyboardFocusNode = FocusNode(debugLabel: 'PdfViewerFocus');

  @override
  void initState() {
    super.initState();
    _initController();
    unawaited(_loadDocument());
  }

  void _initController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = PdfViewerController();
      _ownsController = true;
    }
    _lastSyncedPage = _controller.currentPage;
    _lastNavigationRevision = _controller.navigationRevision;
    _lastSyncedZoom = _controller.zoomLevel;
    _lastLayoutMode = _controller.layoutMode;
    _recreatePageController();
    _controller.addListener(_onControllerChanged);
  }

  void _recreatePageController() {
    _pageController?.dispose();
    final int initialIdx =
        _controller.layoutMode == PdfPageLayoutMode.doublePage
            ? ((_controller.currentPage - 1) ~/ 2)
            : (_controller.currentPage - 1);
    _pageController = PageController(initialPage: math.max(0, initialIdx));
  }

  @override
  void didUpdateWidget(covariant PdfViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_onControllerChanged);
      if (_ownsController) {
        _controller.dispose();
      }
      _initController();
      if (_document != null) {
        _controller.attachDocument(_document!);
      }
    }
    if (oldWidget.source != widget.source) {
      unawaited(_loadDocument());
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    _pageController?.dispose();
    _continuousScrollController.dispose();
    _transformController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      _loadStackTrace = null;
    });
    try {
      final PdfDocument doc = await widget.source.resolve();
      if (!mounted) {
        return;
      }
      _document = doc;
      _controller.attachDocument(doc);
      setState(() {
        _isLoading = false;
      });
      widget.onDocumentLoaded?.call(doc);
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError = error;
        _loadStackTrace = stackTrace;
      });
      widget.onLoadError?.call(error);
    }
  }

  bool get _isContinuousMode =>
      _controller.layoutMode == PdfPageLayoutMode.continuousVertical ||
      _controller.layoutMode == PdfPageLayoutMode.continuousHorizontal;

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    if (_controller.layoutMode != _lastLayoutMode) {
      _lastLayoutMode = _controller.layoutMode;
      _recreatePageController();
      if (_isContinuousMode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollContinuousToPage(_controller.currentPage, animate: false);
        });
      }
    }

    final bool pageChanged = _controller.currentPage != _lastSyncedPage;
    final bool explicitNav =
        _controller.navigationRevision != _lastNavigationRevision;

    if (pageChanged) {
      _lastSyncedPage = _controller.currentPage;
      widget.onPageChanged?.call(_controller.currentPage);
    }

    if (explicitNav) {
      _lastNavigationRevision = _controller.navigationRevision;
      final int targetPage = _controller.currentPage;
      if (_isContinuousMode) {
        _scrollContinuousToPage(targetPage, animate: true);
      } else if (_pageController != null && _pageController!.hasClients) {
        final int targetIdx =
            _controller.layoutMode == PdfPageLayoutMode.doublePage
                ? ((targetPage - 1) ~/ 2)
                : (targetPage - 1);
        final int currentIdx = _pageController!.page?.round() ?? 0;
        if (currentIdx != targetIdx) {
          _pageController!.jumpToPage(math.max(0, targetIdx));
        }
      }
    }

    if ((_controller.zoomLevel - _lastSyncedZoom).abs() > 0.005) {
      _lastSyncedZoom = _controller.zoomLevel;
      final Matrix4 matrix = Matrix4.identity()
        ..scaleByDouble(
          _lastSyncedZoom,
          _lastSyncedZoom,
          1.0,
          1.0,
        );
      _transformController.value = matrix;
    }

    setState(() {});
  }

  void _scrollContinuousToPage(int pageNumber, {required bool animate}) {
    if (!_continuousScrollController.hasClients ||
        _lastContinuousItemExtent <= 1) {
      return;
    }
    final double maxExtent =
        _continuousScrollController.position.maxScrollExtent;
    final double targetOffset =
        ((pageNumber - 1) * _lastContinuousItemExtent).clamp(0.0, maxExtent);
    if ((targetOffset - _continuousScrollController.offset).abs() < 2.0) {
      return;
    }
    _isProgrammaticScrolling = true;
    if (animate) {
      unawaited(
        _continuousScrollController
            .animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        )
            .whenComplete(() {
          _isProgrammaticScrolling = false;
        }),
      );
    } else {
      _continuousScrollController.jumpTo(targetOffset);
      _isProgrammaticScrolling = false;
    }
  }

  void _handleDoubleTap() {
    if (!widget.enableDoubleTapZoom) {
      return;
    }
    if ((_controller.zoomLevel - 1.0).abs() < 0.05) {
      _controller.setZoom(widget.doubleTapZoomScale);
    } else {
      _controller.resetZoom();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!widget.enableKeyboardShortcuts || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    // Don't hijack typing when an EditableText has primary focus.
    final FocusNode? primary = FocusManager.instance.primaryFocus;
    final bool isTyping = primary != null &&
        primary != _keyboardFocusNode &&
        _controller.isSearchVisible;

    final bool hasModifier = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final bool hasShift = HardwareKeyboard.instance.isShiftPressed;
    final LogicalKeyboardKey key = event.logicalKey;

    if (hasModifier && key == LogicalKeyboardKey.keyF) {
      _controller.toggleSearchVisibility(true);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      if (_controller.isSearchVisible) {
        _controller.toggleSearchVisibility(false);
        return KeyEventResult.handled;
      }
      if (_controller.hasTextSelection) {
        _controller.clearTextSelection();
        return KeyEventResult.handled;
      }
      if (_controller.activeAnnotationTool != PdfAnnotationTool.none) {
        _controller.setAnnotationTool(PdfAnnotationTool.none);
        return KeyEventResult.handled;
      }
      if (_controller.isImmersiveMode) {
        _controller.toggleImmersiveMode(false);
        return KeyEventResult.handled;
      }
      if (_controller.isSidebarOpen) {
        _controller.toggleSidebar(false);
        return KeyEventResult.handled;
      }
    }
    if (hasModifier &&
        (key == LogicalKeyboardKey.equal ||
            key == LogicalKeyboardKey.add ||
            key == LogicalKeyboardKey.numpadAdd)) {
      _controller.zoomIn();
      return KeyEventResult.handled;
    }
    if (hasModifier &&
        (key == LogicalKeyboardKey.minus ||
            key == LogicalKeyboardKey.numpadSubtract)) {
      _controller.zoomOut();
      return KeyEventResult.handled;
    }
    if (hasModifier && key == LogicalKeyboardKey.digit0) {
      _controller.resetZoom();
      return KeyEventResult.handled;
    }
    if (hasModifier && key == LogicalKeyboardKey.keyZ) {
      if (hasShift) {
        _controller.redoAnnotation();
      } else {
        _controller.undoAnnotation();
      }
      return KeyEventResult.handled;
    }

    if (isTyping) {
      return KeyEventResult.ignored;
    }

    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.pageDown) {
      _controller.nextPage();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.pageUp) {
      _controller.previousPage();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      _controller.firstPage();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      _controller.lastPage();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyR && !hasModifier) {
      _controller.rotateClockwise();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final bool hasModifier = HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;
      if (hasModifier) {
        if (event.scrollDelta.dy < 0) {
          _controller.zoomIn(0.15);
        } else if (event.scrollDelta.dy > 0) {
          _controller.zoomOut(0.15);
        }
      }
    }
  }

  void _handlePageTapForTextSelection(
    TapUpDetails details,
    PdfPageData page,
    Size renderedSize,
  ) {
    if (!widget.enableTextSelection ||
        _controller.activeAnnotationTool != PdfAnnotationTool.none) {
      return;
    }
    if (renderedSize.width <= 0 || renderedSize.height <= 0) {
      return;
    }
    final Offset norm = Offset(
      (details.localPosition.dx / renderedSize.width).clamp(0.0, 1.0),
      (details.localPosition.dy / renderedSize.height).clamp(0.0, 1.0),
    );
    final PdfTextElement? hit = page.hitTestText(norm);
    if (hit == null) {
      _controller.clearTextSelection();
      return;
    }
    final double pageW = page.width <= 0 ? 595.28 : page.width;
    final double pageH = page.height <= 0 ? 841.89 : page.height;
    final Rect normRect = Rect.fromLTWH(
      (hit.bounds.left / pageW).clamp(0.0, 1.0),
      (hit.bounds.top / pageH).clamp(0.0, 1.0),
      (hit.bounds.width / pageW).clamp(0.02, 1.0),
      (hit.bounds.height / pageH).clamp(0.012, 1.0),
    );
    _controller.selectText(
      text: hit.text,
      pageNumber: page.pageNumber,
      bounds: normRect,
    );
  }

  @override
  Widget build(BuildContext context) {
    final PdfViewerTheme effectiveTheme =
        widget.theme ?? PdfViewerTheme.fromContext(context);
    final String? effectiveFontFamily = effectiveTheme.fontFamily ??
        DefaultTextStyle.of(context).style.fontFamily;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: DefaultTextStyle(
        style: TextStyle(
          fontFamily: effectiveFontFamily,
          color: effectiveTheme.toolbarForegroundColor,
          fontSize: 14,
          decoration: TextDecoration.none,
        ),
        child: Focus(
          focusNode: _keyboardFocusNode,
          onKeyEvent: _handleKeyEvent,
          child: Listener(
            onPointerSignal: _handlePointerSignal,
            child: _buildBody(context, effectiveTheme),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PdfViewerTheme effectiveTheme) {
    if (_isLoading) {
      if (widget.loadingBuilder != null) {
        return widget.loadingBuilder!(context);
      }
      return ColoredBox(
        color: effectiveTheme.backgroundColor,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _PureLoadingSpinner(color: effectiveTheme.accentColor),
              const SizedBox(height: 14),
              Text(
                'Loading PDF Document...',
                style: TextStyle(
                  color: effectiveTheme.toolbarForegroundColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_loadError != null || _document == null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(
          context,
          _loadError ?? StateError('Unknown PDF load error'),
          _loadStackTrace,
        );
      }
      return ColoredBox(
        color: effectiveTheme.backgroundColor,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: effectiveTheme.surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: effectiveTheme.surfaceBorderColor),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const PdfIcon(
                    PdfIcons.errorOutline,
                    size: 44,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load PDF document',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: effectiveTheme.toolbarForegroundColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$_loadError',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: effectiveTheme.secondaryForegroundColor,
                    ),
                  ),
                  const SizedBox(height: 18),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _loadDocument,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: effectiveTheme.accentColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Retry',
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final PdfDocument doc = _document!;
    final bool showChrome = !_controller.isImmersiveMode;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints outerConstraints) {
        final bool useDockedSidebar = outerConstraints.maxWidth >= 860;
        final bool sidebarOpen = _controller.isSidebarOpen;

        return ColoredBox(
          color: effectiveTheme.backgroundColor,
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  if (widget.showTopToolbar && showChrome)
                    PdfTopToolbar(
                      controller: _controller,
                      theme: effectiveTheme,
                      title: widget.title,
                      leadingActions: widget.leadingToolbarActions,
                      trailingActions: widget.trailingToolbarActions,
                      onOpenBookmarksDrawer: _controller.toggleSidebar,
                    ),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        if (useDockedSidebar && sidebarOpen && showChrome)
                          SizedBox(
                            width: 256,
                            child: _StudioNavigationPanel(
                              document: doc,
                              controller: _controller,
                              theme: effectiveTheme,
                              isDocked: true,
                              onClose: () => _controller.toggleSidebar(false),
                            ),
                          ),
                        Expanded(
                          child: Stack(
                            children: <Widget>[
                              Positioned.fill(
                                child: GestureDetector(
                                  onDoubleTap: _handleDoubleTap,
                                  child: InteractiveViewer(
                                    transformationController:
                                        _transformController,
                                    minScale: _controller.minZoom,
                                    maxScale: _controller.maxZoom,
                                    panEnabled:
                                        _controller.activeAnnotationTool ==
                                            PdfAnnotationTool.none,
                                    scaleEnabled:
                                        _controller.activeAnnotationTool ==
                                            PdfAnnotationTool.none,
                                    onInteractionEnd:
                                        (ScaleEndDetails details) {
                                      final double currentScale =
                                          _transformController.value
                                              .getMaxScaleOnAxis();
                                      _lastSyncedZoom = currentScale;
                                      _controller.setZoom(currentScale);
                                    },
                                    child: _buildViewportLayout(
                                      doc,
                                      effectiveTheme,
                                    ),
                                  ),
                                ),
                              ),
                              if (_controller.isSearchVisible && showChrome)
                                Positioned(
                                  top: 12,
                                  left: 16,
                                  right: 16,
                                  child: Center(
                                    child: PdfSearchBar(
                                      controller: _controller,
                                      theme: effectiveTheme,
                                    ),
                                  ),
                                ),
                              if (_controller.isAnnotationToolbarVisible &&
                                  showChrome)
                                Positioned(
                                  top: _controller.isSearchVisible ? 70 : 12,
                                  left: 16,
                                  right: 16,
                                  child: Center(
                                    child: PdfAnnotationToolbar(
                                      controller: _controller,
                                      theme: effectiveTheme,
                                    ),
                                  ),
                                ),
                              if (_controller.hasTextSelection && showChrome)
                                Positioned(
                                  top: _controller.isSearchVisible ||
                                          _controller.isAnnotationToolbarVisible
                                      ? 72
                                      : 14,
                                  left: 16,
                                  right: 16,
                                  child: Center(
                                    child: _TextSelectionActionBar(
                                      controller: _controller,
                                      theme: effectiveTheme,
                                      onHighlightCreated:
                                          widget.onAnnotationAdded,
                                    ),
                                  ),
                                ),
                              if (widget.showSupportBadge &&
                                  showChrome &&
                                  outerConstraints.maxWidth >= 560)
                                Positioned(
                                  bottom: widget.showBottomScrubber ? 68 : 14,
                                  right: 14,
                                  child: _SupportPill(theme: effectiveTheme),
                                ),
                              if (widget.showBottomScrubber && showChrome)
                                Positioned(
                                  bottom: 14,
                                  left: 14,
                                  right: 14,
                                  child: Center(
                                    child: PdfBottomScrubber(
                                      controller: _controller,
                                      theme: effectiveTheme,
                                    ),
                                  ),
                                ),
                              if (!showChrome)
                                Positioned(
                                  top: 14,
                                  right: 14,
                                  child: SafeArea(
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: () =>
                                            _controller.toggleImmersiveMode(
                                          false,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: effectiveTheme
                                                .toolbarBackgroundColor,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: effectiveTheme
                                                  .surfaceBorderColor,
                                            ),
                                            boxShadow: const <BoxShadow>[
                                              BoxShadow(
                                                color: Color(0x30000000),
                                                blurRadius: 12,
                                                offset: Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              PdfIcon(
                                                PdfIcons.fullscreenExit,
                                                size: 16,
                                                color:
                                                    effectiveTheme.accentColor,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Exit Focus',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: effectiveTheme
                                                      .toolbarForegroundColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_controller.isThumbnailBarVisible && showChrome)
                    PdfThumbnailBar(
                      document: doc,
                      controller: _controller,
                      theme: effectiveTheme,
                    ),
                ],
              ),
              if (!useDockedSidebar && sidebarOpen && showChrome) ...<Widget>[
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => _controller.toggleSidebar(false),
                    child: const ColoredBox(color: Color(0x66000000)),
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  width: math.min(300.0, outerConstraints.maxWidth * 0.84),
                  child: _StudioNavigationPanel(
                    document: doc,
                    controller: _controller,
                    theme: effectiveTheme,
                    isDocked: false,
                    onClose: () => _controller.toggleSidebar(false),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildViewportLayout(PdfDocument doc, PdfViewerTheme theme) {
    switch (_controller.layoutMode) {
      case PdfPageLayoutMode.continuousVertical:
        return _buildContinuousList(doc, theme, Axis.vertical);
      case PdfPageLayoutMode.continuousHorizontal:
        return _buildContinuousList(doc, theme, Axis.horizontal);
      case PdfPageLayoutMode.singlePage:
        return _buildSinglePageView(doc, theme);
      case PdfPageLayoutMode.doublePage:
        return _buildDoublePageView(doc, theme);
    }
  }

  Size _computePageCardSize(
    PdfPageData page,
    Size availableSpace,
    PdfViewerTheme theme,
  ) {
    final bool isTransposed =
        ((page.rotation + _controller.rotationAngle) % 180).abs() == 90;
    final double rawW = isTransposed ? page.height : page.width;
    final double rawH = isTransposed ? page.width : page.height;
    final double aspect = rawH <= 0 ? 0.707 : rawW / rawH;

    final double maxW = math.max(120.0, availableSpace.width - 36);
    final double maxH = math.max(160.0, availableSpace.height - 92);

    if (_controller.fitMode == PdfFitMode.fitWidth &&
        _controller.layoutMode == PdfPageLayoutMode.continuousVertical) {
      final double cardW = maxW;
      final double cardH = cardW / aspect;
      return Size(cardW, cardH);
    }

    double cardW = maxW;
    double cardH = cardW / aspect;
    if (cardH > maxH) {
      cardH = maxH;
      cardW = cardH * aspect;
    }
    return Size(cardW, cardH);
  }

  Widget _buildContinuousList(
    PdfDocument doc,
    PdfViewerTheme theme,
    Axis scrollDirection,
  ) {
    final bool isVertical = scrollDirection == Axis.vertical;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size sampleSize = doc.pages.isEmpty
            ? const Size(420, 594)
            : _computePageCardSize(
                doc.pages.first,
                constraints.biggest,
                theme,
              );
        final double spacing = theme.pageSpacing;
        final double uniformExtent =
            (isVertical ? sampleSize.height : sampleSize.width) + spacing;
        _lastContinuousItemExtent = uniformExtent;

        final bool hasUniformPageSizes = doc.pages.length <= 1 ||
            doc.pages.every(
              (PdfPageData p) =>
                  (p.width - doc.pages.first.width).abs() < 1.0 &&
                  (p.height - doc.pages.first.height).abs() < 1.0 &&
                  p.rotation == doc.pages.first.rotation,
            );

        return NotificationListener<ScrollUpdateNotification>(
          onNotification: (ScrollUpdateNotification notification) {
            if (_isProgrammaticScrolling ||
                _lastContinuousItemExtent <= 1 ||
                doc.pageCount <= 1) {
              return false;
            }
            final double offset = notification.metrics.pixels;
            final int estimatedPage =
                (offset / _lastContinuousItemExtent).round() + 1;
            final int clamped = estimatedPage.clamp(1, doc.pageCount);
            if (clamped != _controller.currentPage) {
              _lastSyncedPage = clamped;
              _controller.syncCurrentPage(clamped);
              widget.onPageChanged?.call(clamped);
            }
            return false;
          },
          child: ListView.builder(
            controller: _continuousScrollController,
            scrollDirection: scrollDirection,
            itemExtent: hasUniformPageSizes ? uniformExtent : null,
            padding: EdgeInsets.only(
              top: isVertical ? spacing : spacing * 0.75,
              bottom: isVertical ? spacing + 72 : spacing * 0.75,
              left: spacing,
              right: spacing,
            ),
            itemCount: doc.pageCount,
            itemBuilder: (BuildContext context, int index) {
              final PdfPageData page = doc.pages[index];
              final Size cardSize = _computePageCardSize(
                page,
                constraints.biggest,
                theme,
              );
              return Padding(
                padding: EdgeInsets.only(
                  bottom: isVertical ? spacing : 0,
                  right: isVertical ? 0 : spacing,
                ),
                child: Center(
                  child: _buildPageCard(page, cardSize, theme),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSinglePageView(PdfDocument doc, PdfViewerTheme theme) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return PageView.builder(
          controller: _pageController,
          itemCount: doc.pageCount,
          onPageChanged: (int idx) {
            _lastSyncedPage = idx + 1;
            _controller.syncCurrentPage(idx + 1);
            widget.onPageChanged?.call(idx + 1);
          },
          itemBuilder: (BuildContext context, int index) {
            final PdfPageData page = doc.pages[index];
            final Size cardSize = _computePageCardSize(
              page,
              constraints.biggest,
              theme,
            );
            return Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  theme.pageSpacing,
                  theme.pageSpacing * 0.75,
                  theme.pageSpacing,
                  theme.pageSpacing + 56,
                ),
                child: _buildPageCard(page, cardSize, theme),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDoublePageView(PdfDocument doc, PdfViewerTheme theme) {
    final int spreadCount = (doc.pageCount + 1) ~/ 2;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size halfSpace = Size(
          (constraints.maxWidth - theme.pageSpacing * 3) / 2,
          constraints.maxHeight,
        );
        return PageView.builder(
          controller: _pageController,
          itemCount: spreadCount,
          onPageChanged: (int spreadIdx) {
            final int firstPage = spreadIdx * 2 + 1;
            _lastSyncedPage = firstPage;
            _controller.syncCurrentPage(firstPage);
            widget.onPageChanged?.call(firstPage);
          },
          itemBuilder: (BuildContext context, int spreadIdx) {
            final int leftIdx = spreadIdx * 2;
            final int rightIdx = leftIdx + 1;
            final PdfPageData leftPage = doc.pages[leftIdx];
            final PdfPageData? rightPage =
                rightIdx < doc.pageCount ? doc.pages[rightIdx] : null;
            final Size leftSize = _computePageCardSize(
              leftPage,
              halfSpace,
              theme,
            );
            final Size? rightSize = rightPage != null
                ? _computePageCardSize(rightPage, halfSpace, theme)
                : null;

            return Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  theme.pageSpacing,
                  theme.pageSpacing * 0.75,
                  theme.pageSpacing,
                  theme.pageSpacing + 56,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Flexible(
                      child: _buildPageCard(leftPage, leftSize, theme),
                    ),
                    if (rightPage != null && rightSize != null) ...<Widget>[
                      SizedBox(width: theme.pageSpacing * 0.7),
                      Flexible(
                        child: _buildPageCard(rightPage, rightSize, theme),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPageCard(
    PdfPageData page,
    Size cardSize,
    PdfViewerTheme theme,
  ) {
    final Rect? selectedBounds = _controller.selectedTextPage == page.pageNumber
        ? _controller.selectedTextBounds
        : null;

    return Container(
      width: cardSize.width,
      height: cardSize.height,
      decoration: BoxDecoration(
        color: page.backgroundColor,
        borderRadius: BorderRadius.circular(theme.pageBorderRadius),
        border: Border.all(
          color: theme.surfaceBorderColor.withValues(alpha: 0.7),
          width: 0.8,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.pageShadowColor,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(theme.pageBorderRadius),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (TapUpDetails d) =>
              _handlePageTapForTextSelection(d, page, cardSize),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              PdfPageCanvas(
                page: page,
                searchResults:
                    _controller.searchResultsForPage(page.pageNumber),
                activeSearchResult: _controller.activeSearchResult,
                colorMode: _controller.colorMode,
                rotationOffset: _controller.rotationAngle,
                searchHighlightColor: theme.searchHighlightColor,
                activeSearchHighlightColor: theme.activeSearchHighlightColor,
                selectedBounds: selectedBounds,
                selectionColor: theme.selectionColor,
                fontFamily: theme.fontFamily,
              ),
              PdfAnnotationLayer(
                pageNumber: page.pageNumber,
                annotations: _controller.annotationsForPage(page.pageNumber),
                activeTool: _controller.activeAnnotationTool,
                activeColor: _controller.activeAnnotationColor,
                activeStrokeWidth: _controller.activeStrokeWidth,
                activeStampText: _controller.activeStampText,
                theme: theme,
                onAnnotationCreated: (PdfAnnotation annotation) {
                  _controller.addAnnotation(annotation);
                  widget.onAnnotationAdded?.call(annotation);
                },
                onAnnotationUpdated: _controller.updateAnnotation,
                onAnnotationDeleted: _controller.removeAnnotation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextSelectionActionBar extends StatelessWidget {
  const _TextSelectionActionBar({
    required this.controller,
    required this.theme,
    this.onHighlightCreated,
  });

  final PdfViewerController controller;
  final PdfViewerTheme theme;
  final ValueChanged<PdfAnnotation>? onHighlightCreated;

  @override
  Widget build(BuildContext context) {
    final String text = controller.selectedText ?? '';
    final int? page = controller.selectedTextPage;
    final Rect? bounds = controller.selectedTextBounds;
    if (text.isEmpty || page == null || bounds == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.surfaceBorderColor),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              '"$text"',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: theme.secondaryForegroundColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: text));
                controller.clearTextSelection();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    PdfIcon(
                      PdfIcons.copy,
                      size: 14,
                      color: theme.accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Copy',
                      style: TextStyle(
                        fontSize: 11.8,
                        fontWeight: FontWeight.w700,
                        color: theme.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                final PdfAnnotation ann = PdfAnnotation(
                  id: 'sel_hl_${DateTime.now().microsecondsSinceEpoch}',
                  pageNumber: page,
                  type: PdfAnnotationType.highlight,
                  color: controller.activeAnnotationColor,
                  opacity: 0.38,
                  rect: bounds,
                  text: text,
                  createdAt: DateTime.now(),
                );
                controller.addAnnotation(ann);
                onHighlightCreated?.call(ann);
                controller.clearTextSelection();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0x33FACC15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const PdfIcon(
                      PdfIcons.highlight,
                      size: 14,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Highlight',
                      style: TextStyle(
                        fontSize: 11.8,
                        fontWeight: FontWeight.w700,
                        color: theme.toolbarForegroundColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          PdfIconButton(
            tooltip: 'Clear Selection',
            icon: PdfIcons.close,
            size: 15,
            padding: const EdgeInsets.all(4),
            color: theme.secondaryForegroundColor,
            onPressed: controller.clearTextSelection,
          ),
        ],
      ),
    );
  }
}

class _StudioNavigationPanel extends StatelessWidget {
  const _StudioNavigationPanel({
    required this.document,
    required this.controller,
    required this.theme,
    required this.isDocked,
    required this.onClose,
  });

  final PdfDocument document;
  final PdfViewerController controller;
  final PdfViewerTheme theme;
  final bool isDocked;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, _) {
        final PdfSidebarTab activeTab = controller.activeSidebarTab;
        final List<PdfBookmark> bookmarks = controller.allBookmarks;
        final List<PdfAnnotation> annotations = controller.annotations;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            border: Border(
              right: BorderSide(color: theme.surfaceBorderColor),
            ),
            boxShadow: isDocked
                ? const <BoxShadow>[]
                : const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x45000000),
                      blurRadius: 24,
                      offset: Offset(6, 0),
                    ),
                  ],
          ),
          child: SafeArea(
            top: !isDocked,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 10),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: theme.backgroundColor.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: <Widget>[
                              _SidebarTabButton(
                                label: 'Pages',
                                isSelected:
                                    activeTab == PdfSidebarTab.thumbnails,
                                theme: theme,
                                onTap: () => controller
                                    .setSidebarTab(PdfSidebarTab.thumbnails),
                              ),
                              _SidebarTabButton(
                                label: 'Outline',
                                isSelected:
                                    activeTab == PdfSidebarTab.bookmarks,
                                theme: theme,
                                onTap: () => controller
                                    .setSidebarTab(PdfSidebarTab.bookmarks),
                              ),
                              _SidebarTabButton(
                                label: annotations.isEmpty
                                    ? 'Notes'
                                    : 'Notes (${annotations.length})',
                                isSelected:
                                    activeTab == PdfSidebarTab.annotations,
                                theme: theme,
                                onTap: () => controller
                                    .setSidebarTab(PdfSidebarTab.annotations),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!isDocked) ...<Widget>[
                        const SizedBox(width: 4),
                        PdfIconButton(
                          tooltip: 'Close Sidebar',
                          icon: PdfIcons.close,
                          size: 17,
                          padding: const EdgeInsets.all(6),
                          color: theme.secondaryForegroundColor,
                          onPressed: onClose,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(height: 1, color: theme.surfaceBorderColor),
                Expanded(
                  child: switch (activeTab) {
                    PdfSidebarTab.thumbnails => PdfThumbnailBar(
                        document: document,
                        controller: controller,
                        theme: theme,
                        axis: Axis.vertical,
                      ),
                    PdfSidebarTab.bookmarks => _BookmarksList(
                        bookmarks: bookmarks,
                        controller: controller,
                        theme: theme,
                        closeOnTap: !isDocked,
                        onClose: onClose,
                      ),
                    PdfSidebarTab.annotations => _AnnotationsList(
                        annotations: annotations,
                        controller: controller,
                        theme: theme,
                        closeOnTap: !isDocked,
                        onClose: onClose,
                      ),
                  },
                ),
                Container(height: 1, color: theme.surfaceBorderColor),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      PdfIcon(
                        PdfIcons.sparkle,
                        size: 13,
                        color: theme.accentColor,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Humanize AI • humanize.id',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.secondaryForegroundColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SidebarTabButton extends StatelessWidget {
  const _SidebarTabButton({
    required this.label,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final PdfViewerTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? theme.surfaceColor : const Color(0x00000000),
              borderRadius: BorderRadius.circular(7),
              boxShadow: isSelected
                  ? const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.2,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? theme.accentColor
                    : theme.secondaryForegroundColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BookmarksList extends StatelessWidget {
  const _BookmarksList({
    required this.bookmarks,
    required this.controller,
    required this.theme,
    required this.closeOnTap,
    required this.onClose,
  });

  final List<PdfBookmark> bookmarks;
  final PdfViewerController controller;
  final PdfViewerTheme theme;
  final bool closeOnTap;
  final VoidCallback onClose;

  List<({PdfBookmark item, int depth})> _flatten(
    List<PdfBookmark> list,
    int depth,
  ) {
    final List<({PdfBookmark item, int depth})> out =
        <({PdfBookmark item, int depth})>[];
    for (final PdfBookmark bm in list) {
      out.add((item: bm, depth: depth));
      if (bm.children.isNotEmpty) {
        out.addAll(_flatten(bm.children, depth + 1));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final List<({PdfBookmark item, int depth})> flat = _flatten(bookmarks, 0);
    if (flat.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No outlines or bookmarks yet.\nBookmark any page from the top toolbar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.secondaryForegroundColor,
              fontSize: 12.8,
              height: 1.45,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: flat.length,
      itemBuilder: (BuildContext context, int index) {
        final PdfBookmark item = flat[index].item;
        final int depth = flat[index].depth;
        final bool isCurrent = item.pageNumber == controller.currentPage;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              controller.jumpToPage(item.pageNumber);
              if (closeOnTap) {
                onClose();
              }
            },
            child: Container(
              margin: EdgeInsets.fromLTRB(
                10.0 + depth * 12.0,
                2,
                10,
                2,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: isCurrent
                    ? theme.accentColor.withValues(alpha: 0.12)
                    : const Color(0x00000000),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                children: <Widget>[
                  PdfIcon(
                    item.isUserBookmark ? PdfIcons.bookmark : PdfIcons.toc,
                    color: isCurrent
                        ? theme.accentColor
                        : theme.secondaryForegroundColor,
                    size: 16,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isCurrent
                            ? theme.accentColor
                            : theme.toolbarForegroundColor,
                        fontSize: 12.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: theme.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'p.${item.pageNumber}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: theme.accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnnotationsList extends StatelessWidget {
  const _AnnotationsList({
    required this.annotations,
    required this.controller,
    required this.theme,
    required this.closeOnTap,
    required this.onClose,
  });

  final List<PdfAnnotation> annotations;
  final PdfViewerController controller;
  final PdfViewerTheme theme;
  final bool closeOnTap;
  final VoidCallback onClose;

  String _typeLabel(PdfAnnotationType type) {
    switch (type) {
      case PdfAnnotationType.highlight:
        return 'Highlight';
      case PdfAnnotationType.underline:
        return 'Underline';
      case PdfAnnotationType.strikethrough:
        return 'Strikethrough';
      case PdfAnnotationType.ink:
        return 'Freehand Ink';
      case PdfAnnotationType.stickyNote:
        return 'Sticky Note';
      case PdfAnnotationType.stamp:
        return 'Review Stamp';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (annotations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No annotations yet.\nUse the Markup toolbar to highlight, sketch, or pin sticky notes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.secondaryForegroundColor,
              fontSize: 12.8,
              height: 1.45,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: annotations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (BuildContext context, int index) {
        final PdfAnnotation ann = annotations[index];
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              controller.jumpToAnnotation(ann);
              if (closeOnTap) {
                onClose();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.backgroundColor.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.surfaceBorderColor),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 10,
                    height: 28,
                    decoration: BoxDecoration(
                      color: ann.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                _typeLabel(ann.type),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w700,
                                  color: theme.toolbarForegroundColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'p.${ann.pageNumber}',
                              style: TextStyle(
                                fontSize: 10.8,
                                fontWeight: FontWeight.w600,
                                color: theme.accentColor,
                              ),
                            ),
                          ],
                        ),
                        if (ann.text != null &&
                            ann.text!.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 3),
                          Text(
                            ann.text!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: theme.secondaryForegroundColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PdfIconButton(
                    tooltip: 'Delete Annotation',
                    icon: PdfIcons.delete,
                    size: 15,
                    padding: const EdgeInsets.all(5),
                    color: theme.secondaryForegroundColor,
                    onPressed: () => controller.removeAnnotation(ann.id),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PureLoadingSpinner extends StatefulWidget {
  const _PureLoadingSpinner({required this.color});

  final Color color;

  @override
  State<_PureLoadingSpinner> createState() => _PureLoadingSpinnerState();
}

class _PureLoadingSpinnerState extends State<_PureLoadingSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (BuildContext context, _) {
        return Transform.rotate(
          angle: _animController.value * 2 * math.pi,
          child: SizedBox(
            width: 34,
            height: 34,
            child: CustomPaint(
              painter: _SpinnerArcPainter(color: widget.color),
            ),
          ),
        );
      },
    );
  }
}

class _SpinnerArcPainter extends CustomPainter {
  const _SpinnerArcPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = (Offset.zero & size).deflate(3);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..strokeWidth = 3.2
        ..style = PaintingStyle.stroke,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 1.15,
      false,
      Paint()
        ..color = color
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _SpinnerArcPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SupportPill extends StatelessWidget {
  const _SupportPill({required this.theme});

  final PdfViewerTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
      decoration: BoxDecoration(
        color: theme.toolbarBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.surfaceBorderColor),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          PdfIcon(
            PdfIcons.sparkle,
            size: 13,
            color: theme.accentColor,
          ),
          const SizedBox(width: 5),
          Text(
            'Humanize AI • humanize.id',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.toolbarForegroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

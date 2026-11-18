import 'dart:async';
import 'dart:math' as math;
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

/// A modern, adaptive, cross-platform PDF viewer widget for Flutter, proudly
/// supported by [Humanize AI](https://humanize.id).
///
/// Features:
/// * Pure-Flutter vector rendering across Android, iOS, Web, macOS, Windows, and Linux.
/// * Continuous vertical, continuous horizontal, single-page, and double-page spread modes.
/// * Full-text search with live match highlighting and navigation.
/// * Interactive annotations (highlighter, freehand ink, sticky notes) with undo/redo.
/// * Live vector page thumbnails, outline & user bookmark drawer, and reading color filters.
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
  bool _isBookmarksDrawerOpen = false;

  int _lastSyncedPage = 1;
  double _lastSyncedZoom = 1.0;
  PageController? _pageController;
  final TransformationController _transformController =
      TransformationController();

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
    _lastSyncedZoom = _controller.zoomLevel;
    _pageController = PageController(initialPage: _controller.currentPage - 1);
    _controller.addListener(_onControllerChanged);
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
    _transformController.dispose();
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

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }
    if (_controller.currentPage != _lastSyncedPage) {
      final int targetPage = _controller.currentPage;
      _lastSyncedPage = targetPage;
      widget.onPageChanged?.call(targetPage);

      if (_pageController != null && _pageController!.hasClients) {
        final int targetIdx =
            _controller.layoutMode == PdfPageLayoutMode.doublePage
                ? ((targetPage - 1) ~/ 2)
                : (targetPage - 1);
        final int currentIdx = _pageController!.page?.round() ?? 0;
        if (currentIdx != targetIdx) {
          _pageController!.jumpToPage(targetIdx);
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

  @override
  Widget build(BuildContext context) {
    final PdfViewerTheme effectiveTheme =
        widget.theme ?? PdfViewerTheme.fromContext(context);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: DefaultTextStyle(
        style: TextStyle(
          color: effectiveTheme.toolbarForegroundColor,
          fontSize: 14,
          decoration: TextDecoration.none,
        ),
        child: _buildBody(context, effectiveTheme),
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
          child: Text(
            'Loading PDF Document...',
            style: TextStyle(
              color: effectiveTheme.toolbarForegroundColor,
              fontWeight: FontWeight.w500,
            ),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  PdfIcons.errorOutline,
                  size: 48,
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
                    color: effectiveTheme.toolbarForegroundColor
                        .withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _loadDocument,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: effectiveTheme.accentColor,
                      borderRadius: BorderRadius.circular(8),
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
              ],
            ),
          ),
        ),
      );
    }

    final PdfDocument doc = _document!;

    return ColoredBox(
      color: effectiveTheme.backgroundColor,
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              if (widget.showTopToolbar)
                PdfTopToolbar(
                  controller: _controller,
                  theme: effectiveTheme,
                  title: widget.title,
                  leadingActions: widget.leadingToolbarActions,
                  trailingActions: widget.trailingToolbarActions,
                  onOpenBookmarksDrawer: () {
                    setState(() {
                      _isBookmarksDrawerOpen = !_isBookmarksDrawerOpen;
                    });
                  },
                ),
              Expanded(
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: GestureDetector(
                        onDoubleTap: _handleDoubleTap,
                        child: InteractiveViewer(
                          transformationController: _transformController,
                          minScale: _controller.minZoom,
                          maxScale: _controller.maxZoom,
                          panEnabled: _controller.activeAnnotationTool ==
                              PdfAnnotationTool.none,
                          scaleEnabled: _controller.activeAnnotationTool ==
                              PdfAnnotationTool.none,
                          onInteractionEnd: (ScaleEndDetails details) {
                            final double currentScale =
                                _transformController.value.getMaxScaleOnAxis();
                            _lastSyncedZoom = currentScale;
                            _controller.setZoom(currentScale);
                          },
                          child: _buildViewportLayout(doc, effectiveTheme),
                        ),
                      ),
                    ),
                    if (_controller.isSearchVisible)
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
                    if (_controller.isAnnotationToolbarVisible)
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
                    if (widget.showSupportBadge)
                      Positioned(
                        bottom: widget.showBottomScrubber ? 68 : 14,
                        right: 14,
                        child: _SupportPill(theme: effectiveTheme),
                      ),
                    if (widget.showBottomScrubber)
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
                  ],
                ),
              ),
              if (_controller.isThumbnailBarVisible)
                PdfThumbnailBar(
                  document: doc,
                  controller: _controller,
                  theme: effectiveTheme,
                ),
            ],
          ),
          if (_isBookmarksDrawerOpen) ...<Widget>[
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isBookmarksDrawerOpen = false;
                  });
                },
                child: const ColoredBox(color: Color(0x66000000)),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: 300,
              child: _BookmarksDrawer(
                controller: _controller,
                theme: effectiveTheme,
                onClose: () {
                  setState(() {
                    _isBookmarksDrawerOpen = false;
                  });
                },
              ),
            ),
          ],
        ],
      ),
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

  Widget _buildContinuousList(
    PdfDocument doc,
    PdfViewerTheme theme,
    Axis scrollDirection,
  ) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return PageView.builder(
          controller: _pageController,
          scrollDirection: scrollDirection,
          padEnds: false,
          itemCount: doc.pageCount,
          onPageChanged: (int idx) {
            _lastSyncedPage = idx + 1;
            _controller.jumpToPage(idx + 1);
            widget.onPageChanged?.call(idx + 1);
          },
          itemBuilder: (BuildContext context, int index) {
            final PdfPageData page = doc.pages[index];
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: theme.pageSpacing,
                  vertical: theme.pageSpacing * 0.75,
                ),
                child: _buildPageCard(page, constraints.biggest, theme),
              ),
            );
          },
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
            _controller.jumpToPage(idx + 1);
            widget.onPageChanged?.call(idx + 1);
          },
          itemBuilder: (BuildContext context, int index) {
            final PdfPageData page = doc.pages[index];
            return Center(
              child: Padding(
                padding: EdgeInsets.all(theme.pageSpacing),
                child: _buildPageCard(page, constraints.biggest, theme),
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
        final Size halfSize = Size(
          (constraints.maxWidth - theme.pageSpacing * 3) / 2,
          constraints.maxHeight,
        );
        return PageView.builder(
          controller: _pageController,
          itemCount: spreadCount,
          onPageChanged: (int spreadIdx) {
            final int firstPage = spreadIdx * 2 + 1;
            _lastSyncedPage = firstPage;
            _controller.jumpToPage(firstPage);
            widget.onPageChanged?.call(firstPage);
          },
          itemBuilder: (BuildContext context, int spreadIdx) {
            final int leftIdx = spreadIdx * 2;
            final int rightIdx = leftIdx + 1;
            final PdfPageData leftPage = doc.pages[leftIdx];
            final PdfPageData? rightPage =
                rightIdx < doc.pageCount ? doc.pages[rightIdx] : null;

            return Center(
              child: Padding(
                padding: EdgeInsets.all(theme.pageSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Flexible(
                      child: _buildPageCard(leftPage, halfSize, theme),
                    ),
                    if (rightPage != null) ...<Widget>[
                      SizedBox(width: theme.pageSpacing * 0.6),
                      Flexible(
                        child: _buildPageCard(rightPage, halfSize, theme),
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
    Size availableSpace,
    PdfViewerTheme theme,
  ) {
    final bool isTransposed =
        ((page.rotation + _controller.rotationAngle) % 180).abs() == 90;
    final double rawW = isTransposed ? page.height : page.width;
    final double rawH = isTransposed ? page.width : page.height;
    final double aspect = rawH <= 0 ? 0.707 : rawW / rawH;

    final double maxW = math.max(120.0, availableSpace.width - 32);
    final double maxH = math.max(160.0, availableSpace.height - 88);

    double cardW = maxW;
    double cardH = cardW / aspect;
    if (cardH > maxH) {
      cardH = maxH;
      cardW = cardH * aspect;
    }

    return Container(
      width: cardW,
      height: cardH,
      decoration: BoxDecoration(
        color: page.backgroundColor,
        borderRadius: BorderRadius.circular(theme.pageBorderRadius),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.pageShadowColor,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(theme.pageBorderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            PdfPageCanvas(
              page: page,
              searchResults: _controller.searchResultsForPage(page.pageNumber),
              activeSearchResult: _controller.activeSearchResult,
              colorMode: _controller.colorMode,
              rotationOffset: _controller.rotationAngle,
              searchHighlightColor: theme.searchHighlightColor,
              activeSearchHighlightColor: theme.activeSearchHighlightColor,
            ),
            PdfAnnotationLayer(
              pageNumber: page.pageNumber,
              annotations: _controller.annotationsForPage(page.pageNumber),
              activeTool: _controller.activeAnnotationTool,
              activeColor: _controller.activeAnnotationColor,
              activeStrokeWidth: _controller.activeStrokeWidth,
              onAnnotationCreated: (PdfAnnotation annotation) {
                _controller.addAnnotation(annotation);
                widget.onAnnotationAdded?.call(annotation);
              },
              onAnnotationDeleted: _controller.removeAnnotation,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarksDrawer extends StatelessWidget {
  const _BookmarksDrawer({
    required this.controller,
    required this.theme,
    required this.onClose,
  });

  final PdfViewerController controller;
  final PdfViewerTheme theme;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final List<PdfBookmark> bookmarks = controller.allBookmarks;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.toolbarBackgroundColor,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 16,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
              child: Row(
                children: <Widget>[
                  Icon(PdfIcons.bookmark, color: theme.accentColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Outlines & Bookmarks',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.toolbarForegroundColor,
                      ),
                    ),
                  ),
                  PdfIconButton(
                    tooltip: 'Close Bookmarks',
                    icon: PdfIcons.close,
                    color: theme.toolbarForegroundColor,
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              color: theme.toolbarForegroundColor.withValues(alpha: 0.12),
            ),
            Expanded(
              child: bookmarks.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No bookmarks yet.\nTap the bookmark icon in the top toolbar to save any page.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.toolbarForegroundColor
                                .withValues(alpha: 0.65),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: bookmarks.length,
                      itemBuilder: (BuildContext context, int index) {
                        final PdfBookmark item = bookmarks[index];
                        final bool isCurrent =
                            item.pageNumber == controller.currentPage;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            controller.jumpToPage(item.pageNumber);
                            onClose();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  item.isUserBookmark
                                      ? PdfIcons.bookmark
                                      : PdfIcons.toc,
                                  color: isCurrent
                                      ? theme.accentColor
                                      : theme.toolbarForegroundColor
                                          .withValues(alpha: 0.7),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: TextStyle(
                                      fontWeight: isCurrent
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isCurrent
                                          ? theme.accentColor
                                          : theme.toolbarForegroundColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.accentColor
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'p. ${item.pageNumber}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: theme.accentColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              height: 1,
              color: theme.toolbarForegroundColor.withValues(alpha: 0.12),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    PdfIcons.sparkle,
                    size: 14,
                    color: theme.accentColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Supported by Humanize AI (humanize.id)',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color:
                          theme.toolbarForegroundColor.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportPill extends StatelessWidget {
  const _SupportPill({required this.theme});

  final PdfViewerTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.toolbarBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
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

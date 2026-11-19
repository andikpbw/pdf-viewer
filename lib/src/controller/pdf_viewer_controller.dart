import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../models/pdf_annotation.dart';
import '../models/pdf_bookmark.dart';
import '../models/pdf_document.dart';
import '../models/pdf_search_result.dart';
import '../theme/pdf_viewer_theme.dart';

/// Reactive controller for programmatically inspecting and driving a
/// `PdfViewer` widget.
///
/// Manages page navigation, zoom level, fit mode, rotation, layout mode,
/// reading color filters, full-text search, text selection, adaptive studio
/// sidebar tabs, immersive mode, user bookmarks, and interactive annotations
/// with undo/redo history.
class PdfViewerController extends ChangeNotifier {
  /// Creates a [PdfViewerController].
  PdfViewerController({
    int initialPage = 1,
    double initialZoom = 1.0,
    this.minZoom = 0.5,
    this.maxZoom = 4.0,
    PdfPageLayoutMode initialLayoutMode = PdfPageLayoutMode.continuousVertical,
    PdfColorMode initialColorMode = PdfColorMode.normal,
    PdfFitMode initialFitMode = PdfFitMode.fitPage,
    bool initialSidebarOpen = false,
  })  : _currentPage = initialPage < 1 ? 1 : initialPage,
        _zoomLevel = initialZoom.clamp(minZoom, maxZoom),
        _layoutMode = initialLayoutMode,
        _colorMode = initialColorMode,
        _fitMode = initialFitMode,
        _isSidebarOpen = initialSidebarOpen;

  /// Minimum allowed zoom multiplier.
  final double minZoom;

  /// Maximum allowed zoom multiplier.
  final double maxZoom;

  PdfDocument? _document;
  int _currentPage;
  int _navigationRevision = 0;
  double _zoomLevel;
  int _rotationAngle = 0;
  PdfPageLayoutMode _layoutMode;
  PdfColorMode _colorMode;
  PdfFitMode _fitMode;
  bool _isImmersiveMode = false;

  // Sidebar & drawer state
  bool _isSidebarOpen;
  PdfSidebarTab _activeSidebarTab = PdfSidebarTab.thumbnails;

  // Search state
  bool _isSearchVisible = false;
  bool _caseSensitiveSearch = false;
  String _searchQuery = '';
  List<PdfSearchResult> _searchResults = const <PdfSearchResult>[];
  int _activeSearchResultIndex = -1;

  // Text selection state
  String? _selectedText;
  int? _selectedTextPage;
  Rect? _selectedTextBounds;

  // Annotation state
  bool _isAnnotationToolbarVisible = false;
  PdfAnnotationTool _activeAnnotationTool = PdfAnnotationTool.none;
  Color _activeAnnotationColor = const Color(0xFFFACC15);
  double _activeStrokeWidth = 3.0;
  String _activeStampText = 'APPROVED';
  final List<PdfAnnotation> _annotations = <PdfAnnotation>[];
  final List<List<PdfAnnotation>> _undoStack = <List<PdfAnnotation>>[];
  final List<List<PdfAnnotation>> _redoStack = <List<PdfAnnotation>>[];

  // Bookmarks & thumbnails state
  bool _isThumbnailBarVisible = false;
  final List<PdfBookmark> _userBookmarks = <PdfBookmark>[];

  /// The currently attached [PdfDocument], or `null` if not yet loaded.
  PdfDocument? get document => _document;

  /// Total number of pages in the attached document, or `0` if none.
  int get pageCount => _document?.pageCount ?? 0;

  /// Current 1-based page number.
  int get currentPage => _currentPage;

  /// Monotonically increasing counter incremented on explicit programmatic
  /// page navigation (as opposed to passive scroll tracking).
  int get navigationRevision => _navigationRevision;

  /// Whether there is a page after [currentPage].
  bool get hasNextPage => pageCount > 0 && _currentPage < pageCount;

  /// Whether there is a page before [currentPage].
  bool get hasPreviousPage => _currentPage > 1;

  /// Current zoom multiplier (`1.0` = 100%).
  double get zoomLevel => _zoomLevel;

  /// Document-wide clockwise rotation offset in degrees (`0`, `90`, `180`, `270`).
  int get rotationAngle => _rotationAngle;

  /// Current page layout mode.
  PdfPageLayoutMode get layoutMode => _layoutMode;

  /// Active reading color filter mode.
  PdfColorMode get colorMode => _colorMode;

  /// Active page fit policy (`fitPage` or `fitWidth`).
  PdfFitMode get fitMode => _fitMode;

  /// Whether distraction-free immersive reading mode is enabled.
  bool get isImmersiveMode => _isImmersiveMode;

  /// Whether the adaptive sidebar / navigation drawer is open.
  bool get isSidebarOpen => _isSidebarOpen;

  /// Active tab in the sidebar / navigation drawer.
  PdfSidebarTab get activeSidebarTab => _activeSidebarTab;

  /// Whether the interactive search bar is currently visible.
  bool get isSearchVisible => _isSearchVisible;

  /// Whether full-text search matches letter casing.
  bool get caseSensitiveSearch => _caseSensitiveSearch;

  /// Current full-text search query string.
  String get searchQuery => _searchQuery;

  /// All matches found for [searchQuery].
  List<PdfSearchResult> get searchResults =>
      List<PdfSearchResult>.unmodifiable(_searchResults);

  /// 0-based index of the currently focused search match, or `-1` if none.
  int get activeSearchResultIndex => _activeSearchResultIndex;

  /// The currently focused [PdfSearchResult], or `null` if none.
  PdfSearchResult? get activeSearchResult {
    if (_activeSearchResultIndex < 0 ||
        _activeSearchResultIndex >= _searchResults.length) {
      return null;
    }
    return _searchResults[_activeSearchResultIndex];
  }

  /// Currently selected text string on the page, or `null` if none.
  String? get selectedText => _selectedText;

  /// 1-based page number containing [selectedText], or `null` if none.
  int? get selectedTextPage => _selectedTextPage;

  /// Normalized bounding rect (`0.0..1.0`) of [selectedText], or `null`.
  Rect? get selectedTextBounds => _selectedTextBounds;

  /// Whether a text selection is currently active.
  bool get hasTextSelection =>
      _selectedText != null &&
      _selectedText!.isNotEmpty &&
      _selectedTextPage != null &&
      _selectedTextBounds != null;

  /// Whether the annotation toolbar is currently visible.
  bool get isAnnotationToolbarVisible => _isAnnotationToolbarVisible;

  /// Currently selected annotation drawing tool.
  PdfAnnotationTool get activeAnnotationTool => _activeAnnotationTool;

  /// Currently selected color for new annotations.
  Color get activeAnnotationColor => _activeAnnotationColor;

  /// Currently selected stroke width for new ink annotations.
  double get activeStrokeWidth => _activeStrokeWidth;

  /// Currently selected stamp text used when placing review stamps.
  String get activeStampText => _activeStampText;

  /// Unmodifiable list of all annotations in the document.
  List<PdfAnnotation> get annotations =>
      List<PdfAnnotation>.unmodifiable(_annotations);

  /// Whether an annotation action can be undone.
  bool get canUndoAnnotation => _undoStack.isNotEmpty;

  /// Whether an undone annotation action can be redone.
  bool get canRedoAnnotation => _redoStack.isNotEmpty;

  /// Whether the bottom thumbnail strip is visible.
  bool get isThumbnailBarVisible => _isThumbnailBarVisible;

  /// User-created bookmarks for the current document.
  List<PdfBookmark> get userBookmarks =>
      List<PdfBookmark>.unmodifiable(_userBookmarks);

  /// Combined list of embedded document bookmarks and [userBookmarks].
  List<PdfBookmark> get allBookmarks {
    final List<PdfBookmark> docBookmarks =
        _document?.bookmarks ?? const <PdfBookmark>[];
    return <PdfBookmark>[...docBookmarks, ..._userBookmarks];
  }

  /// Attaches a loaded [PdfDocument] to this controller.
  void attachDocument(PdfDocument document) {
    _document = document;
    if (_currentPage > document.pageCount && document.pageCount > 0) {
      _currentPage = document.pageCount;
    } else if (_currentPage < 1) {
      _currentPage = 1;
    }
    if (_searchQuery.isNotEmpty) {
      _searchResults = document.searchText(
        _searchQuery,
        caseSensitive: _caseSensitiveSearch,
      );
      _activeSearchResultIndex = _searchResults.isEmpty ? -1 : 0;
    }
    notifyListeners();
  }

  /// Extracts concatenated plain text from the entire attached document.
  String extractAllText() => _document?.extractText() ?? '';

  /// Extracts concatenated plain text from the 1-based [pageNumber].
  String extractPageText(int pageNumber) =>
      _document?.extractText(pageNumber: pageNumber) ?? '';

  /// Jumps directly to the 1-based [pageNumber].
  void jumpToPage(int pageNumber) {
    final int maxPage = pageCount > 0 ? pageCount : pageNumber;
    final int target = pageNumber.clamp(1, maxPage < 1 ? 1 : maxPage);
    if (target == _currentPage) {
      return;
    }
    _currentPage = target;
    _navigationRevision++;
    notifyListeners();
  }

  /// Updates [currentPage] from passive scroll-position observation without
  /// triggering a programmatic scroll jump back.
  void syncCurrentPage(int pageNumber) {
    final int maxPage = pageCount > 0 ? pageCount : pageNumber;
    final int target = pageNumber.clamp(1, maxPage < 1 ? 1 : maxPage);
    if (target == _currentPage) {
      return;
    }
    _currentPage = target;
    notifyListeners();
  }

  /// Navigates to the next page (or next spread in double-page mode).
  void nextPage() {
    if (!hasNextPage) {
      return;
    }
    final int step = _layoutMode == PdfPageLayoutMode.doublePage ? 2 : 1;
    jumpToPage(_currentPage + step);
  }

  /// Navigates to the previous page (or previous spread in double-page mode).
  void previousPage() {
    if (!hasPreviousPage) {
      return;
    }
    final int step = _layoutMode == PdfPageLayoutMode.doublePage ? 2 : 1;
    jumpToPage(_currentPage - step);
  }

  /// Navigates to the first page (`1`).
  void firstPage() => jumpToPage(1);

  /// Navigates to the last page of the document.
  void lastPage() {
    if (pageCount > 0) {
      jumpToPage(pageCount);
    }
  }

  /// Sets the zoom multiplier, clamped between [minZoom] and [maxZoom].
  void setZoom(double zoom) {
    final double clamped = zoom.clamp(minZoom, maxZoom);
    if ((clamped - _zoomLevel).abs() < 0.001) {
      return;
    }
    _zoomLevel = clamped;
    notifyListeners();
  }

  /// Increases the zoom level by [step] (default `0.25`).
  void zoomIn([double step = 0.25]) => setZoom(_zoomLevel + step);

  /// Decreases the zoom level by [step] (default `0.25`).
  void zoomOut([double step = 0.25]) => setZoom(_zoomLevel - step);

  /// Resets the zoom level to `1.0` (100%).
  void resetZoom() => setZoom(1.0);

  /// Sets the viewport [PdfFitMode].
  void setFitMode(PdfFitMode mode) {
    if (_fitMode == mode) {
      return;
    }
    _fitMode = mode;
    notifyListeners();
  }

  /// Toggles between [PdfFitMode.fitPage] and [PdfFitMode.fitWidth].
  void toggleFitMode() {
    setFitMode(
      _fitMode == PdfFitMode.fitPage ? PdfFitMode.fitWidth : PdfFitMode.fitPage,
    );
  }

  /// Resets zoom to 100%, rotation to 0°, and fit mode to [PdfFitMode.fitPage].
  void resetView() {
    _zoomLevel = 1.0;
    _rotationAngle = 0;
    _fitMode = PdfFitMode.fitPage;
    notifyListeners();
  }

  /// Rotates the document 90° clockwise.
  void rotateClockwise() {
    _rotationAngle = (_rotationAngle + 90) % 360;
    notifyListeners();
  }

  /// Rotates the document 90° counter-clockwise.
  void rotateCounterClockwise() {
    _rotationAngle = (_rotationAngle + 270) % 360;
    notifyListeners();
  }

  /// Resets document rotation to `0°`.
  void resetRotation() {
    if (_rotationAngle == 0) {
      return;
    }
    _rotationAngle = 0;
    notifyListeners();
  }

  /// Updates the active [PdfPageLayoutMode].
  void setLayoutMode(PdfPageLayoutMode mode) {
    if (_layoutMode == mode) {
      return;
    }
    _layoutMode = mode;
    _navigationRevision++;
    notifyListeners();
  }

  /// Updates the active [PdfColorMode] reading filter.
  void setColorMode(PdfColorMode mode) {
    if (_colorMode == mode) {
      return;
    }
    _colorMode = mode;
    notifyListeners();
  }

  /// Toggles distraction-free immersive reading mode.
  void toggleImmersiveMode([bool? enabled]) {
    final bool next = enabled ?? !_isImmersiveMode;
    if (_isImmersiveMode == next) {
      return;
    }
    _isImmersiveMode = next;
    notifyListeners();
  }

  /// Opens or closes the adaptive sidebar / navigation drawer.
  void toggleSidebar([bool? open]) {
    final bool next = open ?? !_isSidebarOpen;
    if (_isSidebarOpen == next) {
      return;
    }
    _isSidebarOpen = next;
    notifyListeners();
  }

  /// Selects the active [PdfSidebarTab] and optionally opens the sidebar.
  void setSidebarTab(PdfSidebarTab tab, {bool openIfClosed = false}) {
    final bool changedTab = _activeSidebarTab != tab;
    final bool changedOpen = openIfClosed && !_isSidebarOpen;
    if (!changedTab && !changedOpen) {
      return;
    }
    _activeSidebarTab = tab;
    if (openIfClosed) {
      _isSidebarOpen = true;
    }
    notifyListeners();
  }

  /// Shows or hides the search bar.
  void toggleSearchVisibility([bool? visible]) {
    final bool next = visible ?? !_isSearchVisible;
    if (_isSearchVisible == next) {
      return;
    }
    _isSearchVisible = next;
    if (!_isSearchVisible) {
      clearSearch();
    } else {
      notifyListeners();
    }
  }

  /// Toggles case sensitivity for full-text search and re-runs active search.
  void toggleCaseSensitiveSearch([bool? enabled]) {
    final bool next = enabled ?? !_caseSensitiveSearch;
    if (_caseSensitiveSearch == next) {
      return;
    }
    _caseSensitiveSearch = next;
    if (_searchQuery.isNotEmpty) {
      search(_searchQuery, caseSensitive: _caseSensitiveSearch);
    } else {
      notifyListeners();
    }
  }

  /// Executes a full-text search across the attached document for [query].
  void search(String query, {bool? caseSensitive}) {
    _searchQuery = query;
    if (caseSensitive != null) {
      _caseSensitiveSearch = caseSensitive;
    }
    if (_document == null || query.trim().isEmpty) {
      _searchResults = const <PdfSearchResult>[];
      _activeSearchResultIndex = -1;
      notifyListeners();
      return;
    }
    _searchResults = _document!.searchText(
      query,
      caseSensitive: _caseSensitiveSearch,
    );
    if (_searchResults.isNotEmpty) {
      _activeSearchResultIndex = 0;
      _currentPage = _searchResults.first.pageNumber;
      _navigationRevision++;
    } else {
      _activeSearchResultIndex = -1;
    }
    notifyListeners();
  }

  /// Advances focus to the next search match and navigates to its page.
  void nextSearchResult() {
    if (_searchResults.isEmpty) {
      return;
    }
    _activeSearchResultIndex =
        (_activeSearchResultIndex + 1) % _searchResults.length;
    _currentPage = _searchResults[_activeSearchResultIndex].pageNumber;
    _navigationRevision++;
    notifyListeners();
  }

  /// Moves focus to the previous search match and navigates to its page.
  void previousSearchResult() {
    if (_searchResults.isEmpty) {
      return;
    }
    _activeSearchResultIndex =
        (_activeSearchResultIndex - 1 + _searchResults.length) %
            _searchResults.length;
    _currentPage = _searchResults[_activeSearchResultIndex].pageNumber;
    _navigationRevision++;
    notifyListeners();
  }

  /// Clears the active search query and all highlighted matches.
  void clearSearch() {
    if (_searchQuery.isEmpty && _searchResults.isEmpty) {
      notifyListeners();
      return;
    }
    _searchQuery = '';
    _searchResults = const <PdfSearchResult>[];
    _activeSearchResultIndex = -1;
    notifyListeners();
  }

  /// Returns all search results located on the 1-based [pageNumber].
  List<PdfSearchResult> searchResultsForPage(int pageNumber) {
    if (_searchResults.isEmpty) {
      return const <PdfSearchResult>[];
    }
    return _searchResults
        .where((PdfSearchResult r) => r.pageNumber == pageNumber)
        .toList(growable: false);
  }

  /// Sets the currently selected text span on [pageNumber] with normalized
  /// [bounds] (`0.0..1.0`).
  void selectText({
    required String text,
    required int pageNumber,
    required Rect bounds,
  }) {
    _selectedText = text;
    _selectedTextPage = pageNumber;
    _selectedTextBounds = bounds;
    notifyListeners();
  }

  /// Clears any active text selection highlight.
  void clearTextSelection() {
    if (!hasTextSelection) {
      return;
    }
    _selectedText = null;
    _selectedTextPage = null;
    _selectedTextBounds = null;
    notifyListeners();
  }

  /// Shows or hides the interactive annotation toolbar.
  void toggleAnnotationToolbar([bool? visible]) {
    final bool next = visible ?? !_isAnnotationToolbarVisible;
    if (_isAnnotationToolbarVisible == next) {
      return;
    }
    _isAnnotationToolbarVisible = next;
    if (!_isAnnotationToolbarVisible) {
      _activeAnnotationTool = PdfAnnotationTool.none;
    } else if (_activeAnnotationTool == PdfAnnotationTool.none) {
      _activeAnnotationTool = PdfAnnotationTool.highlight;
    }
    clearTextSelection();
    notifyListeners();
  }

  /// Sets the active [PdfAnnotationTool].
  void setAnnotationTool(PdfAnnotationTool tool) {
    if (_activeAnnotationTool == tool) {
      return;
    }
    _activeAnnotationTool = tool;
    if (tool != PdfAnnotationTool.none) {
      _isAnnotationToolbarVisible = true;
      clearTextSelection();
    }
    notifyListeners();
  }

  /// Sets the color used for subsequent annotations.
  void setAnnotationColor(Color color) {
    if (_activeAnnotationColor == color) {
      return;
    }
    _activeAnnotationColor = color;
    notifyListeners();
  }

  /// Sets the stroke width used for subsequent freehand ink annotations.
  void setAnnotationStrokeWidth(double width) {
    final double clamped = width.clamp(1.0, 24.0);
    if ((clamped - _activeStrokeWidth).abs() < 0.01) {
      return;
    }
    _activeStrokeWidth = clamped;
    notifyListeners();
  }

  /// Sets the label text used when placing review stamp annotations.
  void setActiveStampText(String label) {
    final String cleaned = label.trim().toUpperCase();
    if (cleaned.isEmpty || cleaned == _activeStampText) {
      return;
    }
    _activeStampText = cleaned;
    notifyListeners();
  }

  /// Returns all annotations located on the 1-based [pageNumber].
  List<PdfAnnotation> annotationsForPage(int pageNumber) {
    return _annotations
        .where((PdfAnnotation a) => a.pageNumber == pageNumber)
        .toList(growable: false);
  }

  void _pushUndoSnapshot() {
    _undoStack.add(List<PdfAnnotation>.from(_annotations));
    _redoStack.clear();
  }

  /// Adds a new [annotation] to the document and records an undo snapshot.
  void addAnnotation(PdfAnnotation annotation) {
    _pushUndoSnapshot();
    _annotations.add(annotation);
    notifyListeners();
  }

  /// Replaces an existing annotation matching [updated]'s [PdfAnnotation.id]
  /// and records an undo snapshot.
  void updateAnnotation(PdfAnnotation updated) {
    final int idx =
        _annotations.indexWhere((PdfAnnotation a) => a.id == updated.id);
    if (idx == -1) {
      return;
    }
    _pushUndoSnapshot();
    _annotations[idx] = updated;
    notifyListeners();
  }

  /// Navigates directly to the page containing [annotation].
  void jumpToAnnotation(PdfAnnotation annotation) {
    jumpToPage(annotation.pageNumber);
  }

  /// Removes the annotation with the matching [id].
  void removeAnnotation(String id) {
    final int idx = _annotations.indexWhere((PdfAnnotation a) => a.id == id);
    if (idx == -1) {
      return;
    }
    _pushUndoSnapshot();
    _annotations.removeAt(idx);
    notifyListeners();
  }

  /// Clears all annotations, or only those on [pageNumber] if specified.
  void clearAnnotations({int? pageNumber}) {
    if (_annotations.isEmpty) {
      return;
    }
    _pushUndoSnapshot();
    if (pageNumber == null) {
      _annotations.clear();
    } else {
      _annotations.removeWhere((PdfAnnotation a) => a.pageNumber == pageNumber);
    }
    notifyListeners();
  }

  /// Undoes the most recent annotation modification.
  void undoAnnotation() {
    if (_undoStack.isEmpty) {
      return;
    }
    _redoStack.add(List<PdfAnnotation>.from(_annotations));
    final List<PdfAnnotation> previous = _undoStack.removeLast();
    _annotations
      ..clear()
      ..addAll(previous);
    notifyListeners();
  }

  /// Redoes the most recently undone annotation modification.
  void redoAnnotation() {
    if (_redoStack.isEmpty) {
      return;
    }
    _undoStack.add(List<PdfAnnotation>.from(_annotations));
    final List<PdfAnnotation> next = _redoStack.removeLast();
    _annotations
      ..clear()
      ..addAll(next);
    notifyListeners();
  }

  /// Serializes all current annotations to a JSON string.
  String exportAnnotationsJson() => PdfAnnotation.encodeList(_annotations);

  /// Imports annotations from a serialized [jsonString].
  void importAnnotationsJson(String jsonString, {bool replaceExisting = true}) {
    final List<PdfAnnotation> decoded = PdfAnnotation.decodeList(jsonString);
    _pushUndoSnapshot();
    if (replaceExisting) {
      _annotations.clear();
    }
    _annotations.addAll(decoded);
    notifyListeners();
  }

  /// Toggles visibility of the bottom page thumbnail strip.
  void toggleThumbnailBar([bool? visible]) {
    final bool next = visible ?? !_isThumbnailBarVisible;
    if (_isThumbnailBarVisible == next) {
      return;
    }
    _isThumbnailBarVisible = next;
    notifyListeners();
  }

  /// Returns `true` if a user bookmark exists for [pageNumber].
  bool isPageBookmarked(int pageNumber) {
    return _userBookmarks.any((PdfBookmark b) => b.pageNumber == pageNumber);
  }

  /// Toggles a user bookmark on [pageNumber] (defaults to [currentPage]).
  void toggleBookmark({int? pageNumber, String? title}) {
    final int targetPage = pageNumber ?? _currentPage;
    final int existingIndex = _userBookmarks
        .indexWhere((PdfBookmark b) => b.pageNumber == targetPage);
    if (existingIndex != -1) {
      _userBookmarks.removeAt(existingIndex);
    } else {
      _userBookmarks.add(
        PdfBookmark(
          id: 'user_bm_${DateTime.now().microsecondsSinceEpoch}',
          title: title ?? 'Page $targetPage',
          pageNumber: targetPage,
          isUserBookmark: true,
          createdAt: DateTime.now(),
        ),
      );
    }
    notifyListeners();
  }
}

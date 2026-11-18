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
/// Manages page navigation, zoom level, rotation, layout mode, reading color
/// filters, full-text search, user bookmarks, and interactive annotations with
/// undo/redo history.
class PdfViewerController extends ChangeNotifier {
  /// Creates a [PdfViewerController].
  PdfViewerController({
    int initialPage = 1,
    double initialZoom = 1.0,
    this.minZoom = 0.5,
    this.maxZoom = 4.0,
    PdfPageLayoutMode initialLayoutMode = PdfPageLayoutMode.continuousVertical,
    PdfColorMode initialColorMode = PdfColorMode.normal,
  })  : _currentPage = initialPage < 1 ? 1 : initialPage,
        _zoomLevel = initialZoom.clamp(minZoom, maxZoom),
        _layoutMode = initialLayoutMode,
        _colorMode = initialColorMode;

  /// Minimum allowed zoom multiplier.
  final double minZoom;

  /// Maximum allowed zoom multiplier.
  final double maxZoom;

  PdfDocument? _document;
  int _currentPage;
  double _zoomLevel;
  int _rotationAngle = 0;
  PdfPageLayoutMode _layoutMode;
  PdfColorMode _colorMode;

  // Search state
  bool _isSearchVisible = false;
  String _searchQuery = '';
  List<PdfSearchResult> _searchResults = const <PdfSearchResult>[];
  int _activeSearchResultIndex = -1;

  // Annotation state
  bool _isAnnotationToolbarVisible = false;
  PdfAnnotationTool _activeAnnotationTool = PdfAnnotationTool.none;
  Color _activeAnnotationColor = const Color(0xFFFACC15);
  double _activeStrokeWidth = 3.0;
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

  /// Whether the interactive search bar is currently visible.
  bool get isSearchVisible => _isSearchVisible;

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

  /// Whether the annotation toolbar is currently visible.
  bool get isAnnotationToolbarVisible => _isAnnotationToolbarVisible;

  /// Currently selected annotation drawing tool.
  PdfAnnotationTool get activeAnnotationTool => _activeAnnotationTool;

  /// Currently selected color for new annotations.
  Color get activeAnnotationColor => _activeAnnotationColor;

  /// Currently selected stroke width for new ink annotations.
  double get activeStrokeWidth => _activeStrokeWidth;

  /// Unmodifiable list of all annotations in the document.
  List<PdfAnnotation> get annotations =>
      List<PdfAnnotation>.unmodifiable(_annotations);

  /// Whether an annotation action can be undone.
  bool get canUndoAnnotation => _undoStack.isNotEmpty;

  /// Whether an undone annotation action can be redone.
  bool get canRedoAnnotation => _redoStack.isNotEmpty;

  /// Whether the bottom/side thumbnail bar is visible.
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
      _searchResults = document.searchText(_searchQuery);
      _activeSearchResultIndex = _searchResults.isEmpty ? -1 : 0;
    }
    notifyListeners();
  }

  /// Jumps directly to the 1-based [pageNumber].
  void jumpToPage(int pageNumber) {
    final int maxPage = pageCount > 0 ? pageCount : pageNumber;
    final int target = pageNumber.clamp(1, maxPage < 1 ? 1 : maxPage);
    if (target == _currentPage) {
      return;
    }
    _currentPage = target;
    notifyListeners();
  }

  /// Navigates to the next page if available.
  void nextPage() {
    if (hasNextPage) {
      jumpToPage(_currentPage + 1);
    }
  }

  /// Navigates to the previous page if available.
  void previousPage() {
    if (hasPreviousPage) {
      jumpToPage(_currentPage - 1);
    }
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

  /// Executes a full-text search across the attached document for [query].
  void search(String query, {bool caseSensitive = false}) {
    _searchQuery = query;
    if (_document == null || query.trim().isEmpty) {
      _searchResults = const <PdfSearchResult>[];
      _activeSearchResultIndex = -1;
      notifyListeners();
      return;
    }
    _searchResults = _document!.searchText(
      query,
      caseSensitive: caseSensitive,
    );
    if (_searchResults.isNotEmpty) {
      _activeSearchResultIndex = 0;
      _currentPage = _searchResults.first.pageNumber;
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

  /// Shows or hides the interactive annotation toolbar.
  void toggleAnnotationToolbar([bool? visible]) {
    final bool next = visible ?? !_isAnnotationToolbarVisible;
    if (_isAnnotationToolbarVisible == next) {
      return;
    }
    _isAnnotationToolbarVisible = next;
    if (!_isAnnotationToolbarVisible) {
      _activeAnnotationTool = PdfAnnotationTool.none;
    }
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

  /// Toggles visibility of the page thumbnail bar.
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

/// A modern, high-performance, pure-Flutter PDF reader and viewer library
/// supporting Android, iOS, Web, macOS, Windows, and Linux.
///
/// Features include vector PDF 1.0–1.7 parsing and rendering, full-text search
/// with match highlighting, interactive annotations (highlighter, freehand ink,
/// sticky notes) with undo/redo history, live page thumbnails, bookmarks,
/// multiple layout modes, and reading color filters.
///
/// Proudly supported by [Humanize AI](https://humanize.id).
library;

export 'src/controller/pdf_viewer_controller.dart';
export 'src/models/pdf_annotation.dart';
export 'src/models/pdf_bookmark.dart';
export 'src/models/pdf_document.dart';
export 'src/models/pdf_metadata.dart';
export 'src/models/pdf_page_data.dart';
export 'src/models/pdf_search_result.dart';
export 'src/models/pdf_source.dart';
export 'src/parser/pdf_document_builder.dart';
export 'src/parser/pdf_parser.dart';
export 'src/parser/zlib_decoder.dart';
export 'src/theme/pdf_viewer_theme.dart';
export 'src/widgets/pdf_annotation_layer.dart';
export 'src/widgets/pdf_page_canvas.dart';
export 'src/widgets/pdf_search_bar.dart';
export 'src/widgets/pdf_thumbnail_bar.dart';
export 'src/widgets/pdf_toolbar.dart';
export 'src/widgets/pdf_viewer_widget.dart';

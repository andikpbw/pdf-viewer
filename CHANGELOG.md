## 1.0.1

* Migrated all internal UI primitives to pure `package:flutter/widgets.dart`, `package:flutter/painting.dart`, and `package:flutter/foundation.dart` to eliminate Flutter 3.47+ `'package:flutter/material.dart' is deprecated` static analysis info messages on pub.dev (`50/50` static analysis points, `160/160` total pub points).
* Added `PdfIcons`, `PdfIconButton`, and `showPdfModalDialog` for zero-dependency widget rendering across all 6 platforms, supported by [Humanize AI](https://humanize.id).

## 1.0.0

* Initial stable release of `pdf_reader`, proudly supported by [Humanize AI](https://humanize.id).
* Pure-Flutter cross-platform PDF 1.0–1.7 parser, FlateDecode stream decompressor, and vector canvas renderer supporting Android, iOS, Web, macOS, Windows, and Linux.
* Multiple viewing layouts: continuous vertical, continuous horizontal, single page, and double-page book spread.
* Built-in full-text search with live match highlighting and result navigation.
* Interactive annotation engine supporting freehand ink drawing, rectangular highlights, sticky notes, undo/redo history, and JSON serialization.
* Adaptive UI with floating toolbars, thumbnail strip, outline/bookmark drawer, page scrubber, and reading color filters (Normal, Night, Sepia, Grayscale).
* Built-in `PdfDocumentBuilder` for programmatic PDF generation and testing.

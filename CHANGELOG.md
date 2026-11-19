## 1.1.0

* **Adaptive Desktop Studio & Mobile UI**:
  * Docked multi-tab left Studio Sidebar (`Pages`, `Outline`, `Notes`) on wide screens (`>= 860px`) and slide-over navigation drawer on mobile.
  * Overflow-free adaptive top toolbar with full Studio controls on desktop and a sleek `Reader Controls` quick-options sheet on compact phones.
  * Built-in pure-Canvas geometric vector icon engine (`PdfIcon`) for all `PdfIcons` glyphs — zero external font dependencies and zero missing-glyph boxes on any platform.
  * Added 2 new built-in UI theme presets (`PdfViewerTheme.sepia()` and `PdfViewerTheme.midnight()`) alongside refined `.light()` and `.dark()`, plus optional `fontFamily` inheritance across UI chrome, inputs, and PDF canvas text.
* **True Continuous Scrolling & Navigation Ergonomics**:
  * Upgraded `continuousVertical` and `continuousHorizontal` layouts to true `ListView.builder` continuous scrolling with `itemExtent` optimization and passive scroll-to-page sync.
  * Added `PdfFitMode` (`fitPage`, `fitWidth`), distraction-free **Immersive Focus Mode**, desktop keyboard shortcuts (`Cmd/Ctrl+F`, arrows, `PageUp`/`PageDown`, `Home`/`End`, `Cmd/Ctrl + +/-/0`, `Cmd/Ctrl+Z`, `R`, `Esc`), and `Ctrl/Cmd` + scroll-wheel zoom.
  * Implemented value equality (`==` / `hashCode`) on all `PdfSource` subclasses so theme toggles and parent rebuilds never reload the PDF or reset scroll position.
* **Upgraded PDF 1.0–1.7 Parser & Builder**:
  * Canonical `/Catalog` → `/Pages` → recursive `/Kids` page ordering with inherited `/MediaBox`, `/CropBox`, `/Rotate`, and `/Resources`.
  * Added `/ToUnicode` CMap decoding (`beginbfchar` / `beginbfrange`), `/ASCIIHexDecode`, `/ASCII85Decode`, chained `/Filter` arrays, PNG predictor reversal, Form XObject (`/Do`) recursion, cubic Bezier vector paths (`c`, `v`, `y`, `h`), full 2D affine CTM (`cm`), and nested `/Outlines` tree parsing.
  * Added `PdfDocument.extractText()` and `PdfDocument.wordCount`, plus `addMetricCards`, `addBulletList`, `addCodeBlock`, and proportional `columnWeights` in `PdfDocumentBuilder`.
* **Richer Annotations & Interactive Text Selection**:
  * Tap any PDF text run to select, copy to clipboard, or highlight in one click.
  * Added `underline`, `strikethrough`, and styled review `stamp` tools (`APPROVED`, `REVIEWED`, `IMPORTANT`, `DRAFT`), quadratic Bezier freehand ink smoothing, stroke-width picker, case-sensitive search (`Aa`), and theme-aware sticky note editing.

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

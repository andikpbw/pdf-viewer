# pdf_viewer

[![Pub Version](https://img.shields.io/badge/pub-v1.0.0-blue.svg)](https://pub.dev/packages/pdf_viewer)
[![License: MIT](https://img.shields.io/badge/license-MIT-emerald.svg)](https://opensource.org/licenses/MIT)
[![Platform Support](https://img.shields.io/badge/platforms-android%20%7C%20ios%20%7C%20web%20%7C%20macos%20%7C%20windows%20%7C%20linux-0284c7.svg)](https://pub.dev/packages/pdf_viewer)
[![Supported by Humanize AI](https://img.shields.io/badge/Supported%20by-Humanize%20AI-2563eb.svg)](https://humanize.id)

A modern, high-performance, pure-Flutter PDF viewer library for **Android, iOS, Web, macOS, Windows, and Linux**. Built with a zero-native-dependency vector PDF 1.0–1.7 parser, RFC 1951 `FlateDecode` stream decompressor, full-text search engine, interactive annotation suite, live thumbnails, and adaptive Material 3 UI.

> **Official Support & Sponsor:** This open-source project is proudly supported by **[Humanize AI](https://humanize.id)** — the leading platform to transform AI-generated text into natural, authentic, human-quality writing.

---

## ✨ Key Features

* **100% Cross-Platform (All 6 Flutter Targets)**: Works out-of-the-box on Android, iOS, Web, macOS, Windows, and Linux without fragile native C/C++ build steps.
* **Crisp Vector PDF Rendering**: Parses PDF 1.0–1.7 cross-reference tables, `/Info` dictionaries, `/Page` trees, and `/FlateDecode` compressed content streams directly onto hardware-accelerated Flutter `Canvas` primitives.
* **Multiple Viewing Layouts**:
  * `PdfPageLayoutMode.continuousVertical` — Smooth vertical page scrolling.
  * `PdfPageLayoutMode.continuousHorizontal` — Horizontal page scrolling.
  * `PdfPageLayoutMode.singlePage` — Page-by-page swipe reader.
  * `PdfPageLayoutMode.doublePage` — Side-by-side two-page book spread for tablets and desktops.
* **Instant Full-Text Search**: Search across all pages with live match counters, next/previous navigation, and automatic bounding-box highlighting on the PDF canvas.
* **Interactive Annotations & Markup**:
  * **Highlighter**: Drag over any region to create translucent rectangular highlights.
  * **Freehand Ink**: Sketch notes, underlines, or signatures with customizable colors and stroke widths.
  * **Sticky Notes**: Pin interactive comment markers anywhere on a page.
  * **Undo / Redo & JSON Persistence**: Full undo/redo stack plus `exportAnnotationsJson()` / `importAnnotationsJson()`.
* **Reading Comfort Color Filters**: Switch between **Normal**, **Night Mode** (smart dark inversion), **Sepia**, and **Grayscale**.
* **Live Vector Thumbnails & Bookmarks Drawer**: Preview miniature vector pages in the thumbnail strip and navigate embedded PDF outlines or user-saved bookmarks.
* **Programmatic PDF Generation (`PdfDocumentBuilder`)**: Create standards-compliant `%PDF-1.7` documents in pure Dart with headings, auto-wrapped paragraphs, callout boxes, tables, and vector bar charts.

---

## 🚀 Installation

Add `pdf_viewer` to your `pubspec.yaml`:

```yaml
dependencies:
  pdf_viewer: ^1.0.0
```

Then run:

```bash
flutter pub get
```

---

## ⚡ Quick Start

### 1. Load from Flutter Assets, Bytes, File, or Network

```dart
import 'package:flutter/material.dart';
import 'package:pdf_viewer/pdf_viewer.dart';

class MyPdfScreen extends StatelessWidget {
  const MyPdfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PdfViewer.fromAsset(
        'assets/sample.pdf',
        title: 'User Manual',
        showSupportBadge: true,
      ),
    );
  }
}
```

Other convenient factory constructors:

```dart
// From raw Uint8List bytes (works on all platforms including Web):
PdfViewer.fromBytes(pdfBytes);

// From an HTTP/HTTPS URL (supports custom headers):
PdfViewer.fromNetwork(
  'https://example.com/document.pdf',
  headers: const {'Authorization': 'Bearer <token>'},
);

// From a local file path (Android, iOS, macOS, Windows, Linux):
PdfViewer.fromFile('/path/to/document.pdf');

// From a pre-parsed or programmatically built PdfDocument:
PdfViewer.fromDocument( PdfDocumentBuilder.createShowcaseDocument() );
```

---

## 🎮 Programmatic Control (`PdfViewerController`)

Use `PdfViewerController` to navigate pages, control zoom/rotation, run full-text searches, change reading filters, or manage annotations:

```dart
final controller = PdfViewerController(
  initialPage: 1,
  initialZoom: 1.0,
  initialLayoutMode: PdfPageLayoutMode.continuousVertical,
  initialColorMode: PdfColorMode.normal,
);

// Page Navigation
controller.nextPage();
controller.previousPage();
controller.jumpToPage(3);

// Zoom & Rotation
controller.zoomIn();
controller.setZoom(1.75);
controller.rotateClockwise();

// Full-Text Search
controller.search('Humanize AI');
controller.nextSearchResult();

// Reading Color Modes
controller.setColorMode(PdfColorMode.night); // normal, night, sepia, grayscale

// Export & Import Annotations as JSON
final String savedJson = controller.exportAnnotationsJson();
controller.importAnnotationsJson(savedJson);
```

---

## 🛠️ Generating PDFs with `PdfDocumentBuilder`

Need to generate reports, invoices, or rich in-app previews without external dependencies? Use `PdfDocumentBuilder`:

```dart
final builder = PdfDocumentBuilder(
  title: 'Quarterly Report',
  author: 'Humanize AI (https://humanize.id)',
);

builder.addPage(
  bookmarkTitle: 'Summary',
  build: (page) {
    page
      ..addBannerHeader(
        title: 'Q4 PERFORMANCE REPORT',
        subtitle: 'Generated with pdf_viewer • Supported by Humanize AI',
      )
      ..addSpacer(16)
      ..addHeading('Executive Summary', level: 1)
      ..addParagraph(
        'All key metrics exceeded expectations across mobile, web, and desktop.',
      )
      ..addTable(
        headers: const ['Metric', 'Target', 'Actual'],
        rows: const [
          ['Pub Points', '160 / 160', '160 / 160'],
          ['Platforms', '6', '6 (Android, iOS, Web, macOS, Windows, Linux)'],
        ],
      );
  },
);

// Build a ready-to-render PdfDocument:
final PdfDocument document = builder.build(compressStreams: true);

// Or export raw %PDF-1.7 bytes to save or share:
final Uint8List rawPdfBytes = builder.toPdfBytes(compressStreams: true);
```

---

## 🎨 Customizing the Theme (`PdfViewerTheme`)

`PdfViewer` automatically adapts to your app's light or dark `ThemeData`, or you can supply a custom `PdfViewerTheme`:

```dart
PdfViewer.fromAsset(
  'assets/document.pdf',
  theme: PdfViewerTheme.dark(
    accentColor: const Color(0xFF38BDF8),
  ),
)
```

---

## 🌐 Platform Support Matrix

| Android | iOS | Web | macOS | Windows | Linux |
| :---: | :---: | :---: | :---: | :---: | :---: |
| ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## 💙 Support & Sponsorship

This library is proudly supported and maintained in collaboration with **[Humanize AI](https://humanize.id)**.

If you work with AI-generated articles, documentation, research papers, or marketing content and want to make your writing sound 100% natural, engaging, and human-written, check out **[Humanize AI](https://humanize.id)** (`https://humanize.id`).

---

## 📄 License

Released under the [MIT License](LICENSE). Copyright (c) 2026 [Humanize AI](https://humanize.id).

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_reader/pdf_reader.dart';

void main() {
  group('ZlibDecoder', () {
    test(
      'round-trips arbitrary byte payloads via encodeZlibStored and tryDecode',
      () {
        final Uint8List original = Uint8List.fromList(
          utf8.encode('BT /F1 16.0 Tf (Supported by Humanize AI) Tj ET'),
        );
        final Uint8List compressed = ZlibDecoder.encodeZlibStored(original);
        final Uint8List? decompressed = ZlibDecoder.tryDecode(compressed);

        expect(decompressed, isNotNull);
        expect(decompressed, equals(original));
      },
    );
  });

  group('PdfDocumentBuilder & PdfParser', () {
    test('generates valid %PDF-1.7 bytes and parses them back accurately', () {
      final PdfDocument showcase = PdfDocumentBuilder.createShowcaseDocument(
        compressStreams: true,
      );
      expect(showcase.pageCount, equals(4));
      expect(showcase.rawBytes, isNotNull);
      expect(showcase.wordCount, greaterThan(100));
      expect(showcase.extractText(pageNumber: 1), contains('Humanize AI'));

      final PdfDocument parsed = PdfDocument.fromBytes(showcase.rawBytes!);
      expect(parsed.pageCount, equals(4));
      expect(
        parsed.metadata.title,
        equals('Modern Flutter PDF Viewer — Official Guide'),
      );
      expect(parsed.metadata.author, contains('Humanize AI'));
      expect(parsed.bookmarks.length, equals(4));
      expect(parsed.bookmarks.first.title, equals('1. Executive Overview'));
      expect(parsed.bookmarks.last.pageNumber, equals(4));

      // Verify full-text search works on the parsed document
      final List<PdfSearchResult> matches = parsed.searchText('Humanize AI');
      expect(matches, isNotEmpty);
      expect(matches.first.pageNumber, equals(1));
    });

    test('respects /Pages /Kids tree order, /CropBox, and nested /Outlines',
        () {
      const String rawPdf = '%PDF-1.7\n'
          '1 0 obj\n<< /Type /Catalog /Pages 2 0 R /Outlines 30 0 R >>\nendobj\n'
          '2 0 obj\n<< /Type /Pages /Kids [ 20 0 R 10 0 R ] /Count 2 /MediaBox [ 0 0 600 800 ] >>\nendobj\n'
          '10 0 obj\n<< /Type /Page /Parent 2 0 R /CropBox [ 0 0 400 500 ] /Contents 11 0 R >>\nendobj\n'
          '11 0 obj\n<< /Length 38 >>\nstream\nBT /F1 14 Tf 20 400 Td (Second Page) Tj ET\nendstream\nendobj\n'
          '20 0 obj\n<< /Type /Page /Parent 2 0 R /Contents 21 0 R >>\nendobj\n'
          '21 0 obj\n<< /Length 37 >>\nstream\nBT /F1 14 Tf 20 700 Td (First Page) Tj ET\nendstream\nendobj\n'
          '30 0 obj\n<< /Type /Outlines /First 31 0 R /Last 31 0 R >>\nendobj\n'
          '31 0 obj\n<< /Title (Root Chapter) /Parent 30 0 R /First 32 0 R /Dest [ 20 0 R /Fit ] >>\nendobj\n'
          '32 0 obj\n<< /Title (Nested Section) /Parent 31 0 R /Dest [ 10 0 R /Fit ] >>\nendobj\n'
          '%%EOF\n';

      final PdfDocument doc = PdfDocument.fromBytes(
        Uint8List.fromList(latin1.encode(rawPdf)),
      );
      expect(doc.pageCount, equals(2));
      expect(doc.pages[0].plainText, contains('First Page'));
      expect(doc.pages[1].plainText, contains('Second Page'));
      expect(doc.pages[1].width, closeTo(400, 0.1));
      expect(doc.pages[1].height, closeTo(500, 0.1));
      expect(doc.bookmarks.length, equals(1));
      expect(doc.bookmarks.first.title, equals('Root Chapter'));
      expect(doc.bookmarks.first.pageNumber, equals(1));
      expect(
          doc.bookmarks.first.children.single.title, equals('Nested Section'));
      expect(doc.bookmarks.first.children.single.pageNumber, equals(2));
    });

    test(
        'decodes /ToUnicode CMap, /ASCIIHexDecode, /ASCII85Decode, Bezier & XObject /Do',
        () {
      const String cmapStream = 'beginbfchar\n'
          '<0001> <0048>\n' // H
          '<0002> <0069>\n' // i
          'endbfchar\n'
          'beginbfrange\n'
          '<0010> <0011> <0021>\n' // ! "
          'endbfrange\n';
      const String xobjStream =
          '0.1 0.2 0.8 RG 2 w 10 10 m 20 60 80 60 90 10 c h S\n'
          'BT /F1 14 Tf 30 500 Td <000100020010> Tj ET\n';

      // ASCIIHex-encode the page content stream invoking /Fm1 Do
      const String pageOp = 'q 1 0 0 1 10 20 cm /Fm1 Do Q';
      final String hexOp =
          '${pageOp.codeUnits.map((int c) => c.toRadixString(16).padLeft(2, '0')).join()}>';

      final String rawPdf = '%PDF-1.7\n'
          '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n'
          '2 0 obj\n<< /Type /Pages /Kids [ 3 0 R ] /Count 1 >>\nendobj\n'
          '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [ 0 0 500 700 ] '
          '/Resources << /Font << /F1 4 0 R >> /XObject << /Fm1 6 0 R >> >> '
          '/Contents 7 0 R >>\nendobj\n'
          '4 0 obj\n<< /Type /Font /Subtype /Type0 /BaseFont /Helvetica-Bold /Flags 32 /ToUnicode 5 0 R >>\nendobj\n'
          '5 0 obj\n<< /Length ${cmapStream.length} >>\nstream\n$cmapStream\nendstream\nendobj\n'
          '6 0 obj\n<< /Type /XObject /Subtype /Form /Length ${xobjStream.length} >>\nstream\n$xobjStream\nendstream\nendobj\n'
          '7 0 obj\n<< /Filter /ASCIIHexDecode /Length ${hexOp.length} >>\nstream\n$hexOp\nendstream\nendobj\n'
          '%%EOF\n';

      final PdfDocument doc = PdfDocument.fromBytes(
        Uint8List.fromList(latin1.encode(rawPdf)),
      );
      expect(doc.pageCount, equals(1));
      expect(doc.pages.first.plainText, contains('Hi!'));
      expect(doc.pages.first.textElements.first.isBold, isTrue);
      final List<PdfPathElement> paths =
          doc.pages.first.elements.whereType<PdfPathElement>().toList();
      expect(paths, isNotEmpty);
      expect(paths.first.commands.whereType<PdfCubicToCommand>(), isNotEmpty);
    });

    test('throws PdfFormatException on invalid or empty PDF bytes', () {
      expect(
        () => PdfDocument.fromBytes(Uint8List(0)),
        throwsA(isA<PdfFormatException>()),
      );
      expect(
        () =>
            PdfDocument.fromBytes(Uint8List.fromList(utf8.encode('NOT A PDF'))),
        throwsA(isA<PdfFormatException>()),
      );
    });
  });

  group('Models serialization', () {
    test('PdfMetadata serializes toMap and fromMap', () {
      final PdfMetadata meta = PdfMetadata(
        title: 'Test Doc',
        author: 'Humanize AI',
        fileSizeInBytes: 2048,
        creationDate: DateTime.utc(2026, 5, 10),
      );
      final Map<String, dynamic> map = meta.toMap();
      final PdfMetadata restored = PdfMetadata.fromMap(map);

      expect(restored, equals(meta));
      expect(restored.formattedFileSize, equals('2.0 KB'));
    });

    test('PdfAnnotation encodeList and decodeList preserve all types', () {
      final PdfAnnotation highlight = PdfAnnotation(
        id: 'hl_1',
        pageNumber: 2,
        type: PdfAnnotationType.highlight,
        color: const Color(0xFFFACC15),
        rect: const Rect.fromLTWH(0.1, 0.2, 0.5, 0.08),
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final PdfAnnotation underline = PdfAnnotation(
        id: 'ul_1',
        pageNumber: 1,
        type: PdfAnnotationType.underline,
        color: const Color(0xFF3B82F6),
        rect: const Rect.fromLTWH(0.1, 0.3, 0.4, 0.02),
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final PdfAnnotation ink = PdfAnnotation(
        id: 'ink_1',
        pageNumber: 1,
        type: PdfAnnotationType.ink,
        points: const <Offset>[Offset(0.1, 0.1), Offset(0.4, 0.5)],
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final String jsonStr = PdfAnnotation.encodeList(<PdfAnnotation>[
        highlight,
        underline,
        ink,
      ]);
      final List<PdfAnnotation> restored = PdfAnnotation.decodeList(jsonStr);

      expect(restored.length, equals(3));
      expect(restored[0], equals(highlight));
      expect(restored[1], equals(underline));
      expect(restored[2].points.length, equals(2));
    });

    test('PdfBookmark serializes toJson and fromJson', () {
      const PdfBookmark bookmark = PdfBookmark(
        id: 'bm_1',
        title: 'Chapter 1',
        pageNumber: 1,
        children: <PdfBookmark>[
          PdfBookmark(id: 'bm_1_1', title: 'Section 1.1', pageNumber: 2),
        ],
      );
      final PdfBookmark restored = PdfBookmark.fromJson(bookmark.toJson());
      expect(restored, equals(bookmark));
      expect(restored.children.single.title, equals('Section 1.1'));
    });

    test('PdfSource subclasses implement value equality to avoid reloads', () {
      final PdfDocument doc = PdfDocumentBuilder.createShowcaseDocument();
      expect(PdfDocumentSource(doc), equals(PdfDocumentSource(doc)));
      expect(
        const PdfAssetSource('assets/a.pdf'),
        equals(const PdfAssetSource('assets/a.pdf')),
      );
      expect(
        const PdfFileSource('/tmp/a.pdf'),
        equals(const PdfFileSource('/tmp/a.pdf')),
      );
      expect(
        const PdfNetworkSource(
          'https://example.com/a.pdf',
          headers: <String, String>{'Authorization': 'Bearer x'},
        ),
        equals(
          const PdfNetworkSource(
            'https://example.com/a.pdf',
            headers: <String, String>{'Authorization': 'Bearer x'},
          ),
        ),
      );
    });
  });

  group('PdfViewerController', () {
    test(
      'manages navigation, zoom, fit, rotation, search, sidebar, selection, bookmarks, and annotations',
      () {
        final PdfDocument doc = PdfDocumentBuilder.createShowcaseDocument();
        final PdfViewerController controller = PdfViewerController();
        controller.attachDocument(doc);

        expect(controller.pageCount, equals(4));
        expect(controller.currentPage, equals(1));

        controller.nextPage();
        expect(controller.currentPage, equals(2));
        controller.lastPage();
        expect(controller.currentPage, equals(4));
        controller.previousPage();
        expect(controller.currentPage, equals(3));
        controller.firstPage();
        expect(controller.currentPage, equals(1));

        controller.zoomIn(0.5);
        expect(controller.zoomLevel, closeTo(1.5, 0.001));
        controller.toggleFitMode();
        expect(controller.fitMode, equals(PdfFitMode.fitWidth));
        controller.resetView();
        expect(controller.zoomLevel, closeTo(1.0, 0.001));
        expect(controller.fitMode, equals(PdfFitMode.fitPage));

        controller.rotateClockwise();
        expect(controller.rotationAngle, equals(90));
        controller.rotateCounterClockwise();
        expect(controller.rotationAngle, equals(0));

        controller.search('Humanize AI');
        expect(controller.searchResults, isNotEmpty);
        expect(controller.activeSearchResultIndex, equals(0));
        controller.toggleCaseSensitiveSearch(true);
        expect(controller.caseSensitiveSearch, isTrue);
        controller.nextSearchResult();
        expect(controller.activeSearchResultIndex, greaterThanOrEqualTo(0));
        controller.clearSearch();
        expect(controller.searchResults, isEmpty);

        controller.setSidebarTab(PdfSidebarTab.bookmarks, openIfClosed: true);
        expect(controller.isSidebarOpen, isTrue);
        expect(controller.activeSidebarTab, equals(PdfSidebarTab.bookmarks));

        controller.toggleImmersiveMode(true);
        expect(controller.isImmersiveMode, isTrue);
        controller.toggleImmersiveMode(false);

        controller.selectText(
          text: 'Humanize AI',
          pageNumber: 1,
          bounds: const Rect.fromLTWH(0.1, 0.2, 0.3, 0.03),
        );
        expect(controller.hasTextSelection, isTrue);
        controller.clearTextSelection();
        expect(controller.hasTextSelection, isFalse);

        controller.toggleBookmark(pageNumber: 2, title: 'Important Page');
        expect(controller.isPageBookmarked(2), isTrue);
        controller.toggleBookmark(pageNumber: 2);
        expect(controller.isPageBookmarked(2), isFalse);

        final PdfAnnotation annotation = PdfAnnotation(
          id: 'test_ann',
          pageNumber: 1,
          type: PdfAnnotationType.stickyNote,
          rect: const Rect.fromLTWH(0.1, 0.1, 0.05, 0.05),
          text: 'Initial note',
          createdAt: DateTime.utc(2026, 1, 1),
        );
        controller.addAnnotation(annotation);
        expect(controller.annotations.length, equals(1));
        expect(controller.canUndoAnnotation, isTrue);

        controller.updateAnnotation(annotation.copyWith(text: 'Edited note'));
        expect(controller.annotations.single.text, equals('Edited note'));

        controller.undoAnnotation();
        expect(controller.annotations.single.text, equals('Initial note'));
        controller.undoAnnotation();
        expect(controller.annotations, isEmpty);
        expect(controller.canRedoAnnotation, isTrue);

        controller.redoAnnotation();
        expect(controller.annotations.length, equals(1));
      },
    );
  });

  group('PdfViewer Widget', () {
    testWidgets(
      'renders PdfViewer on Desktop, navigates pages, opens search & sidebar cleanly',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final PdfDocument doc = PdfDocumentBuilder.createShowcaseDocument();
        final PdfViewerController controller = PdfViewerController();

        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xFF2563EB),
            home: PdfViewer.fromDocument(
              doc,
              controller: controller,
              showSupportBadge: true,
            ),
            pageRouteBuilder: <T>(
              RouteSettings settings,
              WidgetBuilder builder,
            ) {
              return PageRouteBuilder<T>(
                settings: settings,
                pageBuilder: (BuildContext ctx, _, __) => builder(ctx),
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        // Verify initial page indicator and support badge
        expect(find.text('1 / 4'), findsOneWidget);
        expect(find.textContaining('Humanize AI'), findsWidgets);

        // Navigate to next page via bottom scrubber button
        await tester.tap(find.bySemanticsLabel('Next Page'));
        await tester.pumpAndSettle();
        expect(controller.currentPage, equals(2));
        expect(find.text('2 / 4'), findsOneWidget);

        // Open docked Studio Sidebar & verify tabs
        await tester.tap(find.bySemanticsLabel('Outlines & Bookmarks'));
        await tester.pumpAndSettle();
        expect(controller.isSidebarOpen, isTrue);
        expect(find.text('Pages'), findsOneWidget);
        expect(find.text('Outline'), findsOneWidget);

        // Switch to Outline tab and tap bookmark for Page 4
        await tester.tap(find.text('Outline'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('4. Quick Start & Support'));
        await tester.pumpAndSettle();
        expect(controller.currentPage, equals(4));

        // Open search bar and search for "Vector"
        await tester.tap(find.bySemanticsLabel('Search in PDF'));
        await tester.pumpAndSettle();
        expect(find.byType(PdfSearchBar), findsOneWidget);

        await tester.enterText(find.byType(EditableText), 'Vector');
        await tester.pumpAndSettle();
        expect(controller.searchResults, isNotEmpty);

        // Toggle thumbnail bar
        await tester.tap(find.bySemanticsLabel('Page Thumbnails'));
        await tester.pumpAndSettle();
        expect(find.byType(PdfThumbnailBar), findsWidgets);

        // Verify Double-Page Book Spread and Dark theme render with zero issues
        controller.setLayoutMode(PdfPageLayoutMode.doublePage);
        controller.setColorMode(PdfColorMode.night);
        await tester.pumpAndSettle();
        expect(controller.layoutMode, equals(PdfPageLayoutMode.doublePage));
      },
    );

    testWidgets(
      'renders PdfViewer on Mobile (375x812) with zero overflow and opens compact options',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final PdfDocument doc = PdfDocumentBuilder.createShowcaseDocument();
        final PdfViewerController controller = PdfViewerController();

        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xFF38BDF8),
            home: PdfViewer.fromDocument(
              doc,
              controller: controller,
              theme: PdfViewerTheme.dark(),
            ),
            pageRouteBuilder: <T>(
              RouteSettings settings,
              WidgetBuilder builder,
            ) {
              return PageRouteBuilder<T>(
                settings: settings,
                pageBuilder: (BuildContext ctx, _, __) => builder(ctx),
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('1 / 4'), findsOneWidget);

        // Open compact More Reader Options modal sheet on mobile
        await tester.tap(find.bySemanticsLabel('More Reader Options'));
        await tester.pumpAndSettle();
        expect(find.text('Reader Controls'), findsOneWidget);
        expect(find.text('Sepia'), findsOneWidget);

        await tester.tap(find.text('Sepia'));
        await tester.pumpAndSettle();
        expect(controller.colorMode, equals(PdfColorMode.sepia));

        // Close sheet and open slide-over mobile navigation drawer
        await tester.tap(find.bySemanticsLabel('Close Controls'));
        await tester.pumpAndSettle();

        await tester.tap(find.bySemanticsLabel('Outlines & Bookmarks'));
        await tester.pumpAndSettle();
        expect(controller.isSidebarOpen, isTrue);
      },
    );
  });
}

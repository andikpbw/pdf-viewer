import 'dart:convert';
import 'dart:typed_data';
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

      final PdfDocument parsed = PdfDocument.fromBytes(showcase.rawBytes!);
      expect(parsed.pageCount, equals(4));
      expect(
        parsed.metadata.title,
        equals('Modern Flutter PDF Viewer — Official Guide'),
      );
      expect(parsed.metadata.author, contains('Humanize AI'));
      expect(parsed.bookmarks, isNotEmpty);

      // Verify full-text search works on the parsed document
      final List<PdfSearchResult> matches = parsed.searchText('Humanize AI');
      expect(matches, isNotEmpty);
      expect(matches.first.pageNumber, equals(1));
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

    test('PdfAnnotation encodeList and decodeList preserve properties', () {
      final PdfAnnotation highlight = PdfAnnotation(
        id: 'hl_1',
        pageNumber: 2,
        type: PdfAnnotationType.highlight,
        color: const Color(0xFFFACC15),
        rect: const Rect.fromLTWH(0.1, 0.2, 0.5, 0.08),
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
        ink,
      ]);
      final List<PdfAnnotation> restored = PdfAnnotation.decodeList(jsonStr);

      expect(restored.length, equals(2));
      expect(restored[0], equals(highlight));
      expect(restored[1].points.length, equals(2));
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
  });

  group('PdfViewerController', () {
    test(
      'manages navigation, zoom, rotation, search, bookmarks, and annotations',
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
        controller.resetZoom();
        expect(controller.zoomLevel, closeTo(1.0, 0.001));

        controller.rotateClockwise();
        expect(controller.rotationAngle, equals(90));
        controller.rotateCounterClockwise();
        expect(controller.rotationAngle, equals(0));

        controller.search('Humanize AI');
        expect(controller.searchResults, isNotEmpty);
        expect(controller.activeSearchResultIndex, equals(0));
        controller.nextSearchResult();
        expect(controller.activeSearchResultIndex, greaterThanOrEqualTo(0));
        controller.clearSearch();
        expect(controller.searchResults, isEmpty);

        controller.toggleBookmark(pageNumber: 2, title: 'Important Page');
        expect(controller.isPageBookmarked(2), isTrue);
        controller.toggleBookmark(pageNumber: 2);
        expect(controller.isPageBookmarked(2), isFalse);

        final PdfAnnotation annotation = PdfAnnotation(
          id: 'test_ann',
          pageNumber: 1,
          type: PdfAnnotationType.highlight,
          rect: const Rect.fromLTWH(0.1, 0.1, 0.3, 0.05),
          createdAt: DateTime.utc(2026, 1, 1),
        );
        controller.addAnnotation(annotation);
        expect(controller.annotations.length, equals(1));
        expect(controller.canUndoAnnotation, isTrue);

        controller.undoAnnotation();
        expect(controller.annotations, isEmpty);
        expect(controller.canRedoAnnotation, isTrue);

        controller.redoAnnotation();
        expect(controller.annotations.length, equals(1));
      },
    );
  });

  group('PdfViewer Widget', () {
    testWidgets('renders PdfViewer, navigates pages, and opens search bar', (
      WidgetTester tester,
    ) async {
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
          pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
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
      expect(find.byType(PdfThumbnailBar), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:pdf_viewer/pdf_viewer.dart';

void main() {
  runApp(const PdfViewerShowcaseApp());
}

/// Interactive showcase app for the `pdf_viewer` library, proudly supported by
/// [Humanize AI](https://humanize.id).
class PdfViewerShowcaseApp extends StatefulWidget {
  /// Creates a [PdfViewerShowcaseApp].
  const PdfViewerShowcaseApp({super.key});

  @override
  State<PdfViewerShowcaseApp> createState() => _PdfViewerShowcaseAppState();
}

class _PdfViewerShowcaseAppState extends State<PdfViewerShowcaseApp> {
  bool _isDarkTheme = false;
  late final PdfViewerController _controller;
  late final PdfDocument _showcaseDocument;

  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController(
      initialLayoutMode: PdfPageLayoutMode.continuousVertical,
    );
    _showcaseDocument = PdfDocumentBuilder.createShowcaseDocument(
      compressStreams: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'pdf_viewer — Supported by Humanize AI',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2563EB),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF38BDF8),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: PdfViewer.fromDocument(
        _showcaseDocument,
        controller: _controller,
        showSupportBadge: true,
        theme: _isDarkTheme ? PdfViewerTheme.dark() : PdfViewerTheme.light(),
        trailingToolbarActions: <Widget>[
          IconButton(
            tooltip: _isDarkTheme ? 'Switch to Light UI' : 'Switch to Dark UI',
            onPressed: () {
              setState(() {
                _isDarkTheme = !_isDarkTheme;
              });
            },
            icon: Icon(
              _isDarkTheme ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

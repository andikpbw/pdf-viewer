import 'package:flutter/widgets.dart';
import 'package:pdf_reader/pdf_reader.dart';

void main() {
  runApp(const PdfViewerShowcaseApp());
}

/// Interactive showcase app for the `pdf_reader` library, proudly supported by
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
    final PdfViewerTheme activeTheme =
        _isDarkTheme ? PdfViewerTheme.dark() : PdfViewerTheme.light();

    return WidgetsApp(
      title: 'pdf_reader — Supported by Humanize AI',
      color: const Color(0xFF2563EB),
      debugShowCheckedModeBanner: false,
      home: PdfViewer.fromDocument(
        _showcaseDocument,
        controller: _controller,
        showSupportBadge: true,
        theme: activeTheme,
        trailingToolbarActions: <Widget>[
          PdfIconButton(
            tooltip: _isDarkTheme ? 'Switch to Light UI' : 'Switch to Dark UI',
            icon: _isDarkTheme ? PdfIcons.lightMode : PdfIcons.darkMode,
            color: activeTheme.toolbarForegroundColor,
            onPressed: () {
              setState(() {
                _isDarkTheme = !_isDarkTheme;
              });
            },
          ),
        ],
      ),
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
        return PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (BuildContext ctx, _, __) => builder(ctx),
        );
      },
    );
  }
}

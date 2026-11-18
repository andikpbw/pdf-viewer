import 'package:flutter/widgets.dart';

import '../controller/pdf_viewer_controller.dart';
import '../theme/pdf_icons.dart';
import '../theme/pdf_viewer_theme.dart';

/// Floating full-text search bar connected to a [PdfViewerController].
class PdfSearchBar extends StatefulWidget {
  /// Creates a [PdfSearchBar].
  const PdfSearchBar({
    super.key,
    required this.controller,
    required this.theme,
  });

  /// The controller managing search queries and match navigation.
  final PdfViewerController controller;

  /// Visual styling configuration.
  final PdfViewerTheme theme;

  @override
  State<PdfSearchBar> createState() => _PdfSearchBarState();
}

class _PdfSearchBarState extends State<PdfSearchBar> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController =
        TextEditingController(text: widget.controller.searchQuery);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, _) {
        final int total = widget.controller.searchResults.length;
        final int currentIdx = widget.controller.activeSearchResultIndex;
        final String counterLabel = total == 0
            ? (_textController.text.trim().isEmpty ? '' : '0/0')
            : '${currentIdx + 1}/$total';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          constraints: const BoxConstraints(maxWidth: 460),
          decoration: BoxDecoration(
            color: widget.theme.toolbarBackgroundColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x29000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Icon(
                PdfIcons.search,
                size: 20,
                color: widget.theme.accentColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: <Widget>[
                    if (_textController.text.isEmpty)
                      IgnorePointer(
                        child: Text(
                          'Find in document...',
                          style: TextStyle(
                            color: widget.theme.toolbarForegroundColor
                                .withValues(alpha: 0.55),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    EditableText(
                      controller: _textController,
                      focusNode: _focusNode,
                      autofocus: true,
                      style: TextStyle(
                        color: widget.theme.toolbarForegroundColor,
                        fontSize: 14,
                      ),
                      cursorColor: widget.theme.accentColor,
                      backgroundCursorColor: const Color(0xFF94A3B8),
                      onChanged: (String value) {
                        setState(() {});
                        widget.controller.search(value);
                      },
                      onSubmitted: (String value) {
                        if (widget.controller.searchResults.isNotEmpty) {
                          widget.controller.nextSearchResult();
                        } else {
                          widget.controller.search(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              if (counterLabel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    counterLabel,
                    style: TextStyle(
                      color: widget.theme.toolbarForegroundColor
                          .withValues(alpha: 0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              PdfIconButton(
                tooltip: 'Previous Match',
                icon: PdfIcons.arrowUp,
                color: widget.theme.toolbarForegroundColor,
                onPressed:
                    total > 0 ? widget.controller.previousSearchResult : null,
              ),
              PdfIconButton(
                tooltip: 'Next Match',
                icon: PdfIcons.arrowDown,
                color: widget.theme.toolbarForegroundColor,
                onPressed:
                    total > 0 ? widget.controller.nextSearchResult : null,
              ),
              PdfIconButton(
                tooltip: 'Close Search',
                icon: PdfIcons.close,
                size: 19,
                color: widget.theme.toolbarForegroundColor,
                onPressed: () {
                  _textController.clear();
                  widget.controller.toggleSearchVisibility(false);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

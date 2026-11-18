import 'package:flutter/material.dart';

import '../controller/pdf_viewer_controller.dart';
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

  @override
  void initState() {
    super.initState();
    _textController =
        TextEditingController(text: widget.controller.searchQuery);
  }

  @override
  void dispose() {
    _textController.dispose();
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

        return Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(14),
          color: widget.theme.toolbarBackgroundColor,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            constraints: const BoxConstraints(maxWidth: 460),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: widget.theme.accentColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    autofocus: true,
                    style: TextStyle(
                      color: widget.theme.toolbarForegroundColor,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Find in document...',
                      hintStyle: TextStyle(
                        color: widget.theme.toolbarForegroundColor
                            .withValues(alpha: 0.55),
                        fontSize: 14,
                      ),
                      isDense: true,
                      border: InputBorder.none,
                    ),
                    onChanged: (String value) {
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
                IconButton(
                  tooltip: 'Previous Match',
                  visualDensity: VisualDensity.compact,
                  onPressed:
                      total > 0 ? widget.controller.previousSearchResult : null,
                  icon: Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: widget.theme.toolbarForegroundColor,
                  ),
                ),
                IconButton(
                  tooltip: 'Next Match',
                  visualDensity: VisualDensity.compact,
                  onPressed:
                      total > 0 ? widget.controller.nextSearchResult : null,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: widget.theme.toolbarForegroundColor,
                  ),
                ),
                IconButton(
                  tooltip: 'Close Search',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    _textController.clear();
                    widget.controller.toggleSearchVisibility(false);
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    size: 19,
                    color: widget.theme.toolbarForegroundColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

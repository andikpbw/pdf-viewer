import 'package:flutter/widgets.dart';

import '../controller/pdf_viewer_controller.dart';
import '../theme/pdf_icons.dart';
import '../theme/pdf_viewer_theme.dart';

/// Floating full-text search bar connected to a [PdfViewerController].
///
/// Features live match counters, case-sensitivity toggling (`Aa`), keyboard
/// submit navigation, and theme-aware styling.
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
    widget.controller.addListener(_syncQueryFromController);
  }

  @override
  void didUpdateWidget(covariant PdfSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncQueryFromController);
      widget.controller.addListener(_syncQueryFromController);
      _syncQueryFromController();
    }
  }

  void _syncQueryFromController() {
    final String externalQuery = widget.controller.searchQuery;
    if (_textController.text != externalQuery) {
      _textController.value = TextEditingValue(
        text: externalQuery,
        selection: TextSelection.collapsed(offset: externalQuery.length),
      );
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncQueryFromController);
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
        final bool hasQuery = _textController.text.trim().isNotEmpty;
        final String counterLabel = !hasQuery
            ? ''
            : (total == 0 ? '0 / 0' : '${currentIdx + 1} / $total');

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: widget.theme.toolbarBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.theme.surfaceBorderColor),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x28000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              PdfIcon(
                PdfIcons.search,
                size: 18,
                color: widget.theme.accentColor,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: <Widget>[
                    if (_textController.text.isEmpty)
                      IgnorePointer(
                        child: Text(
                          'Find in document...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: widget.theme.secondaryForegroundColor
                                .withValues(alpha: 0.8),
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    EditableText(
                      controller: _textController,
                      focusNode: _focusNode,
                      autofocus: true,
                      style: TextStyle(
                        fontFamily: widget.theme.fontFamily ??
                            DefaultTextStyle.of(context).style.fontFamily,
                        color: widget.theme.toolbarForegroundColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                      cursorColor: widget.theme.accentColor,
                      backgroundCursorColor:
                          widget.theme.secondaryForegroundColor,
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
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: total > 0
                        ? widget.theme.accentColor.withValues(alpha: 0.14)
                        : const Color(0x22EF4444),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    counterLabel,
                    style: TextStyle(
                      color: total > 0
                          ? widget.theme.accentColor
                          : const Color(0xFFEF4444),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: widget.controller.toggleCaseSensitiveSearch,
                  child: Semantics(
                    label: 'Toggle Case Sensitive Search',
                    button: true,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.controller.caseSensitiveSearch
                            ? widget.theme.accentColor.withValues(alpha: 0.16)
                            : const Color(0x00000000),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: widget.controller.caseSensitiveSearch
                              ? widget.theme.accentColor
                              : const Color(0x00000000),
                        ),
                      ),
                      child: Text(
                        'Aa',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: widget.controller.caseSensitiveSearch
                              ? widget.theme.accentColor
                              : widget.theme.secondaryForegroundColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              PdfIconButton(
                tooltip: 'Previous Match',
                icon: PdfIcons.arrowUp,
                size: 17,
                padding: const EdgeInsets.all(6),
                color: widget.theme.toolbarForegroundColor,
                onPressed:
                    total > 0 ? widget.controller.previousSearchResult : null,
              ),
              PdfIconButton(
                tooltip: 'Next Match',
                icon: PdfIcons.arrowDown,
                size: 17,
                padding: const EdgeInsets.all(6),
                color: widget.theme.toolbarForegroundColor,
                onPressed:
                    total > 0 ? widget.controller.nextSearchResult : null,
              ),
              PdfIconButton(
                tooltip: 'Close Search',
                icon: PdfIcons.close,
                size: 17,
                padding: const EdgeInsets.all(6),
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

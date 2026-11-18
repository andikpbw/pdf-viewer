import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controller/pdf_viewer_controller.dart';
import '../models/pdf_annotation.dart';
import '../models/pdf_document.dart';
import '../models/pdf_metadata.dart';
import '../theme/pdf_viewer_theme.dart';

/// Adaptive top toolbar for `PdfViewer` providing access to search, layout
/// switching, color filters, rotation, bookmarks, annotations, and metadata.
class PdfTopToolbar extends StatelessWidget {
  /// Creates a [PdfTopToolbar].
  const PdfTopToolbar({
    super.key,
    required this.controller,
    required this.theme,
    this.title,
    this.onOpenBookmarksDrawer,
    this.leadingActions = const <Widget>[],
    this.trailingActions = const <Widget>[],
  });

  /// Controller driving the viewer state.
  final PdfViewerController controller;

  /// Visual theme configuration.
  final PdfViewerTheme theme;

  /// Optional override title displayed in the toolbar.
  final String? title;

  /// Callback invoked when the user taps the table of contents / bookmarks icon.
  final VoidCallback? onOpenBookmarksDrawer;

  /// Custom widgets inserted before the title.
  final List<Widget> leadingActions;

  /// Custom widgets appended at the end of the toolbar.
  final List<Widget> trailingActions;

  void _showMetadataDialog(BuildContext context) {
    final PdfDocument? doc = controller.document;
    final PdfMetadata meta = doc?.metadata ?? const PdfMetadata();

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: <Widget>[
              Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF2563EB)),
              SizedBox(width: 10),
              Expanded(child: Text('Document Information')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _InfoRow(label: 'Title', value: meta.title ?? 'Untitled'),
                _InfoRow(label: 'Author', value: meta.author ?? 'Unknown'),
                _InfoRow(label: 'Subject', value: meta.subject ?? '—'),
                _InfoRow(label: 'Keywords', value: meta.keywords ?? '—'),
                _InfoRow(
                  label: 'PDF Version',
                  value: 'PDF ${meta.version}',
                ),
                _InfoRow(
                  label: 'Pages',
                  value: '${controller.pageCount}',
                ),
                _InfoRow(
                  label: 'File Size',
                  value: meta.formattedFileSize,
                ),
                _InfoRow(
                  label: 'Encrypted',
                  value: meta.isEncrypted ? 'Yes' : 'No',
                ),
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Supported by Humanize AI',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'https://humanize.id',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy https://humanize.id',
                        icon: const Icon(
                          Icons.copy_rounded,
                          size: 17,
                          color: Color(0xFF2563EB),
                        ),
                        onPressed: () {
                          Clipboard.setData(
                            const ClipboardData(text: 'https://humanize.id'),
                          );
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Copied Humanize AI link (https://humanize.id)',
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, _) {
        final String resolvedTitle =
            title ?? controller.document?.metadata.title ?? 'PDF Document';
        final bool isBookmarked =
            controller.isPageBookmarked(controller.currentPage);

        return Material(
          elevation: 2,
          color: theme.toolbarBackgroundColor,
          child: SafeArea(
            bottom: false,
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: <Widget>[
                  ...leadingActions,
                  if (onOpenBookmarksDrawer != null)
                    IconButton(
                      tooltip: 'Outlines & Bookmarks',
                      onPressed: onOpenBookmarksDrawer,
                      icon: Icon(
                        Icons.toc_rounded,
                        color: theme.toolbarForegroundColor,
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        resolvedTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.toolbarForegroundColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Search in PDF',
                    onPressed: controller.toggleSearchVisibility,
                    icon: Icon(
                      Icons.search_rounded,
                      color: controller.isSearchVisible
                          ? theme.accentColor
                          : theme.toolbarForegroundColor,
                    ),
                  ),
                  IconButton(
                    tooltip: isBookmarked
                        ? 'Remove Bookmark'
                        : 'Bookmark Current Page',
                    onPressed: controller.toggleBookmark,
                    icon: Icon(
                      isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: isBookmarked
                          ? theme.accentColor
                          : theme.toolbarForegroundColor,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Annotate & Markup',
                    onPressed: controller.toggleAnnotationToolbar,
                    icon: Icon(
                      Icons.draw_rounded,
                      color: controller.isAnnotationToolbarVisible
                          ? theme.accentColor
                          : theme.toolbarForegroundColor,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Page Thumbnails',
                    onPressed: controller.toggleThumbnailBar,
                    icon: Icon(
                      Icons.grid_view_rounded,
                      color: controller.isThumbnailBarVisible
                          ? theme.accentColor
                          : theme.toolbarForegroundColor,
                    ),
                  ),
                  PopupMenuButton<PdfPageLayoutMode>(
                    tooltip: 'Page Layout Mode',
                    icon: Icon(
                      Icons.view_carousel_outlined,
                      color: theme.toolbarForegroundColor,
                    ),
                    initialValue: controller.layoutMode,
                    onSelected: controller.setLayoutMode,
                    itemBuilder: (BuildContext context) =>
                        const <PopupMenuEntry<PdfPageLayoutMode>>[
                      PopupMenuItem<PdfPageLayoutMode>(
                        value: PdfPageLayoutMode.continuousVertical,
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.swap_vert_rounded),
                          title: Text('Continuous Vertical'),
                        ),
                      ),
                      PopupMenuItem<PdfPageLayoutMode>(
                        value: PdfPageLayoutMode.continuousHorizontal,
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.swap_horiz_rounded),
                          title: Text('Continuous Horizontal'),
                        ),
                      ),
                      PopupMenuItem<PdfPageLayoutMode>(
                        value: PdfPageLayoutMode.singlePage,
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.insert_drive_file_outlined),
                          title: Text('Single Page'),
                        ),
                      ),
                      PopupMenuItem<PdfPageLayoutMode>(
                        value: PdfPageLayoutMode.doublePage,
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.menu_book_rounded),
                          title: Text('Double Page Spread'),
                        ),
                      ),
                    ],
                  ),
                  PopupMenuButton<PdfColorMode>(
                    tooltip: 'Reading Color Mode',
                    icon: Icon(
                      Icons.tonality_rounded,
                      color: controller.colorMode != PdfColorMode.normal
                          ? theme.accentColor
                          : theme.toolbarForegroundColor,
                    ),
                    initialValue: controller.colorMode,
                    onSelected: controller.setColorMode,
                    itemBuilder: (BuildContext context) => PdfColorMode.values
                        .map(
                          (PdfColorMode mode) => PopupMenuItem<PdfColorMode>(
                            value: mode,
                            child: Text(mode.label),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  IconButton(
                    tooltip: 'Rotate 90° Clockwise',
                    onPressed: controller.rotateClockwise,
                    icon: Icon(
                      Icons.rotate_right_rounded,
                      color: theme.toolbarForegroundColor,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Document Info & Humanize AI Support',
                    onPressed: () => _showMetadataDialog(context),
                    icon: Icon(
                      Icons.info_outline_rounded,
                      color: theme.toolbarForegroundColor,
                    ),
                  ),
                  ...trailingActions,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive secondary bar for choosing annotation tools, colors, and
/// undo/redo operations.
class PdfAnnotationToolbar extends StatelessWidget {
  /// Creates a [PdfAnnotationToolbar].
  const PdfAnnotationToolbar({
    super.key,
    required this.controller,
    required this.theme,
  });

  /// Controller managing annotation state.
  final PdfViewerController controller;

  /// Visual theme configuration.
  final PdfViewerTheme theme;

  static const List<Color> _palette = <Color>[
    Color(0xFFFACC15),
    Color(0xFFEF4444),
    Color(0xFF22C55E),
    Color(0xFF3B82F6),
    Color(0xFFA855F7),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, _) {
        final PdfAnnotationTool activeTool = controller.activeAnnotationTool;

        return Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(14),
          color: theme.toolbarBackgroundColor,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _ToolChip(
                  icon: Icons.pan_tool_alt_rounded,
                  label: 'Pan',
                  isSelected: activeTool == PdfAnnotationTool.none,
                  accentColor: theme.accentColor,
                  foregroundColor: theme.toolbarForegroundColor,
                  onTap: () =>
                      controller.setAnnotationTool(PdfAnnotationTool.none),
                ),
                const SizedBox(width: 6),
                _ToolChip(
                  icon: Icons.highlight_rounded,
                  label: 'Highlight',
                  isSelected: activeTool == PdfAnnotationTool.highlight,
                  accentColor: theme.accentColor,
                  foregroundColor: theme.toolbarForegroundColor,
                  onTap: () =>
                      controller.setAnnotationTool(PdfAnnotationTool.highlight),
                ),
                const SizedBox(width: 6),
                _ToolChip(
                  icon: Icons.gesture_rounded,
                  label: 'Ink',
                  isSelected: activeTool == PdfAnnotationTool.ink,
                  accentColor: theme.accentColor,
                  foregroundColor: theme.toolbarForegroundColor,
                  onTap: () =>
                      controller.setAnnotationTool(PdfAnnotationTool.ink),
                ),
                const SizedBox(width: 6),
                _ToolChip(
                  icon: Icons.sticky_note_2_outlined,
                  label: 'Note',
                  isSelected: activeTool == PdfAnnotationTool.stickyNote,
                  accentColor: theme.accentColor,
                  foregroundColor: theme.toolbarForegroundColor,
                  onTap: () => controller
                      .setAnnotationTool(PdfAnnotationTool.stickyNote),
                ),
                const SizedBox(width: 12),
                for (final Color swatch in _palette)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => controller.setAnnotationColor(swatch),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: swatch,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: controller.activeAnnotationColor == swatch
                                ? theme.toolbarForegroundColor
                                : Colors.transparent,
                            width: 2.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Undo Annotation',
                  visualDensity: VisualDensity.compact,
                  onPressed: controller.canUndoAnnotation
                      ? controller.undoAnnotation
                      : null,
                  icon: Icon(
                    Icons.undo_rounded,
                    size: 19,
                    color: theme.toolbarForegroundColor,
                  ),
                ),
                IconButton(
                  tooltip: 'Redo Annotation',
                  visualDensity: VisualDensity.compact,
                  onPressed: controller.canRedoAnnotation
                      ? controller.redoAnnotation
                      : null,
                  icon: Icon(
                    Icons.redo_rounded,
                    size: 19,
                    color: theme.toolbarForegroundColor,
                  ),
                ),
                IconButton(
                  tooltip: 'Clear Page Annotations',
                  visualDensity: VisualDensity.compact,
                  onPressed: controller.annotations.isNotEmpty
                      ? () => controller.clearAnnotations(
                            pageNumber: controller.currentPage,
                          )
                      : null,
                  icon: Icon(
                    Icons.delete_sweep_outlined,
                    size: 19,
                    color: theme.toolbarForegroundColor,
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

class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final Color accentColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 17,
              color: isSelected ? accentColor : foregroundColor,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? accentColor : foregroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating bottom navigation and zoom scrubber bar for `PdfViewer`.
class PdfBottomScrubber extends StatelessWidget {
  /// Creates a [PdfBottomScrubber].
  const PdfBottomScrubber({
    super.key,
    required this.controller,
    required this.theme,
  });

  /// Controller driving page navigation and zoom.
  final PdfViewerController controller;

  /// Visual theme configuration.
  final PdfViewerTheme theme;

  Future<void> _showJumpToPageDialog(BuildContext context) async {
    final TextEditingController inputController = TextEditingController(
      text: '${controller.currentPage}',
    );
    final int? target = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Go to Page'),
          content: TextField(
            controller: inputController,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Page number (1 - ${controller.pageCount})',
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (String v) {
              Navigator.of(dialogContext).pop(int.tryParse(v));
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext)
                  .pop(int.tryParse(inputController.text)),
              child: const Text('Go'),
            ),
          ],
        );
      },
    );
    if (target != null) {
      controller.jumpToPage(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, _) {
        final int totalPages = controller.pageCount;
        final int current = controller.currentPage;
        final int zoomPercent = (controller.zoomLevel * 100).round();

        return Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(28),
          color: theme.toolbarBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  tooltip: 'Previous Page',
                  visualDensity: VisualDensity.compact,
                  onPressed: controller.hasPreviousPage
                      ? controller.previousPage
                      : null,
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    color: theme.toolbarForegroundColor,
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: totalPages > 1
                      ? () => _showJumpToPageDialog(context)
                      : null,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      '$current / $totalPages',
                      style: TextStyle(
                        color: theme.toolbarForegroundColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                if (totalPages > 1)
                  SizedBox(
                    width: 110,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                      ),
                      child: Slider(
                        min: 1.0,
                        max: totalPages.toDouble(),
                        divisions: totalPages > 1 ? totalPages - 1 : 1,
                        value: current.clamp(1, totalPages).toDouble(),
                        activeColor: theme.accentColor,
                        onChanged: (double value) {
                          controller.jumpToPage(value.round());
                        },
                      ),
                    ),
                  ),
                IconButton(
                  tooltip: 'Next Page',
                  visualDensity: VisualDensity.compact,
                  onPressed:
                      controller.hasNextPage ? controller.nextPage : null,
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: theme.toolbarForegroundColor,
                  ),
                ),
                Container(
                  width: 1,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: theme.toolbarForegroundColor.withValues(alpha: 0.18),
                ),
                IconButton(
                  tooltip: 'Zoom Out',
                  visualDensity: VisualDensity.compact,
                  onPressed: controller.zoomLevel > controller.minZoom
                      ? controller.zoomOut
                      : null,
                  icon: Icon(
                    Icons.remove_rounded,
                    size: 18,
                    color: theme.toolbarForegroundColor,
                  ),
                ),
                GestureDetector(
                  onTap: controller.resetZoom,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '$zoomPercent%',
                      style: TextStyle(
                        color: theme.toolbarForegroundColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Zoom In',
                  visualDensity: VisualDensity.compact,
                  onPressed: controller.zoomLevel < controller.maxZoom
                      ? controller.zoomIn
                      : null,
                  icon: Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: theme.toolbarForegroundColor,
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

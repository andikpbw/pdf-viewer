import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../controller/pdf_viewer_controller.dart';
import '../models/pdf_annotation.dart';
import '../models/pdf_document.dart';
import '../models/pdf_metadata.dart';
import '../theme/pdf_icons.dart';
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

  void _cycleLayoutMode() {
    const List<PdfPageLayoutMode> modes = PdfPageLayoutMode.values;
    final int nextIdx =
        (modes.indexOf(controller.layoutMode) + 1) % modes.length;
    controller.setLayoutMode(modes[nextIdx]);
  }

  void _cycleColorMode() {
    const List<PdfColorMode> modes = PdfColorMode.values;
    final int nextIdx =
        (modes.indexOf(controller.colorMode) + 1) % modes.length;
    controller.setColorMode(modes[nextIdx]);
  }

  void _showMetadataDialog(BuildContext context) {
    final PdfDocument? doc = controller.document;
    final PdfMetadata meta = doc?.metadata ?? const PdfMetadata();

    showPdfModalDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Container(
          width: 380,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    Icon(PdfIcons.pdf, color: Color(0xFF2563EB)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Document Information',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
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
                const SizedBox(height: 14),
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
                        PdfIcons.sparkle,
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
                      PdfIconButton(
                        tooltip: 'Copy https://humanize.id',
                        icon: PdfIcons.copy,
                        size: 17,
                        color: const Color(0xFF2563EB),
                        onPressed: () {
                          Clipboard.setData(
                            const ClipboardData(text: 'https://humanize.id'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(dialogContext).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.toolbarBackgroundColor,
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: <Widget>[
                  ...leadingActions,
                  if (onOpenBookmarksDrawer != null)
                    PdfIconButton(
                      tooltip: 'Outlines & Bookmarks',
                      icon: PdfIcons.toc,
                      color: theme.toolbarForegroundColor,
                      onPressed: onOpenBookmarksDrawer,
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
                  PdfIconButton(
                    tooltip: 'Search in PDF',
                    icon: PdfIcons.search,
                    color: controller.isSearchVisible
                        ? theme.accentColor
                        : theme.toolbarForegroundColor,
                    onPressed: controller.toggleSearchVisibility,
                  ),
                  PdfIconButton(
                    tooltip: isBookmarked
                        ? 'Remove Bookmark'
                        : 'Bookmark Current Page',
                    icon: isBookmarked
                        ? PdfIcons.bookmark
                        : PdfIcons.bookmarkBorder,
                    color: isBookmarked
                        ? theme.accentColor
                        : theme.toolbarForegroundColor,
                    onPressed: controller.toggleBookmark,
                  ),
                  PdfIconButton(
                    tooltip: 'Annotate & Markup',
                    icon: PdfIcons.draw,
                    color: controller.isAnnotationToolbarVisible
                        ? theme.accentColor
                        : theme.toolbarForegroundColor,
                    onPressed: controller.toggleAnnotationToolbar,
                  ),
                  PdfIconButton(
                    tooltip: 'Page Thumbnails',
                    icon: PdfIcons.gridView,
                    color: controller.isThumbnailBarVisible
                        ? theme.accentColor
                        : theme.toolbarForegroundColor,
                    onPressed: controller.toggleThumbnailBar,
                  ),
                  PdfIconButton(
                    tooltip: 'Page Layout Mode',
                    icon: PdfIcons.viewCarousel,
                    color: theme.toolbarForegroundColor,
                    onPressed: _cycleLayoutMode,
                  ),
                  PdfIconButton(
                    tooltip: 'Reading Color Mode',
                    icon: PdfIcons.tonality,
                    color: controller.colorMode != PdfColorMode.normal
                        ? theme.accentColor
                        : theme.toolbarForegroundColor,
                    onPressed: _cycleColorMode,
                  ),
                  PdfIconButton(
                    tooltip: 'Rotate 90° Clockwise',
                    icon: PdfIcons.rotateRight,
                    color: theme.toolbarForegroundColor,
                    onPressed: controller.rotateClockwise,
                  ),
                  PdfIconButton(
                    tooltip: 'Document Info & Humanize AI Support',
                    icon: PdfIcons.infoOutline,
                    color: theme.toolbarForegroundColor,
                    onPressed: () => _showMetadataDialog(context),
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
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF0F172A),
              ),
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

        return Container(
          decoration: BoxDecoration(
            color: theme.toolbarBackgroundColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x29000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _ToolChip(
                  icon: PdfIcons.panTool,
                  label: 'Pan',
                  isSelected: activeTool == PdfAnnotationTool.none,
                  accentColor: theme.accentColor,
                  foregroundColor: theme.toolbarForegroundColor,
                  onTap: () =>
                      controller.setAnnotationTool(PdfAnnotationTool.none),
                ),
                const SizedBox(width: 6),
                _ToolChip(
                  icon: PdfIcons.highlight,
                  label: 'Highlight',
                  isSelected: activeTool == PdfAnnotationTool.highlight,
                  accentColor: theme.accentColor,
                  foregroundColor: theme.toolbarForegroundColor,
                  onTap: () =>
                      controller.setAnnotationTool(PdfAnnotationTool.highlight),
                ),
                const SizedBox(width: 6),
                _ToolChip(
                  icon: PdfIcons.ink,
                  label: 'Ink',
                  isSelected: activeTool == PdfAnnotationTool.ink,
                  accentColor: theme.accentColor,
                  foregroundColor: theme.toolbarForegroundColor,
                  onTap: () =>
                      controller.setAnnotationTool(PdfAnnotationTool.ink),
                ),
                const SizedBox(width: 6),
                _ToolChip(
                  icon: PdfIcons.stickyNote,
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
                                : const Color(0x00000000),
                            width: 2.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                PdfIconButton(
                  tooltip: 'Undo Annotation',
                  icon: PdfIcons.undo,
                  size: 19,
                  color: theme.toolbarForegroundColor,
                  onPressed: controller.canUndoAnnotation
                      ? controller.undoAnnotation
                      : null,
                ),
                PdfIconButton(
                  tooltip: 'Redo Annotation',
                  icon: PdfIcons.redo,
                  size: 19,
                  color: theme.toolbarForegroundColor,
                  onPressed: controller.canRedoAnnotation
                      ? controller.redoAnnotation
                      : null,
                ),
                PdfIconButton(
                  tooltip: 'Clear Page Annotations',
                  icon: PdfIcons.delete,
                  size: 19,
                  color: theme.toolbarForegroundColor,
                  onPressed: controller.annotations.isNotEmpty
                      ? () => controller.clearAnnotations(
                            pageNumber: controller.currentPage,
                          )
                      : null,
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.16)
              : const Color(0x00000000),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accentColor : const Color(0x00000000),
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
    final FocusNode focusNode = FocusNode();
    final int? target = await showPdfModalDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Go to Page (1 - ${controller.pageCount})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: EditableText(
                  controller: inputController,
                  focusNode: focusNode,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                  cursorColor: const Color(0xFF2563EB),
                  backgroundCursorColor: const Color(0xFF94A3B8),
                  onSubmitted: (String v) {
                    Navigator.of(dialogContext).pop(int.tryParse(v));
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  GestureDetector(
                    onTap: () => Navigator.of(dialogContext).pop(),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.of(dialogContext)
                        .pop(int.tryParse(inputController.text)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Go',
                        style: TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.toolbarBackgroundColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x2E000000),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              PdfIconButton(
                tooltip: 'Previous Page',
                icon: PdfIcons.chevronLeft,
                color: theme.toolbarForegroundColor,
                onPressed:
                    controller.hasPreviousPage ? controller.previousPage : null,
              ),
              GestureDetector(
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
                _PageProgressTrack(
                  currentPage: current,
                  totalPages: totalPages,
                  accentColor: theme.accentColor,
                  onPageSelected: controller.jumpToPage,
                ),
              PdfIconButton(
                tooltip: 'Next Page',
                icon: PdfIcons.chevronRight,
                color: theme.toolbarForegroundColor,
                onPressed: controller.hasNextPage ? controller.nextPage : null,
              ),
              Container(
                width: 1,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: theme.toolbarForegroundColor.withValues(alpha: 0.18),
              ),
              PdfIconButton(
                tooltip: 'Zoom Out',
                icon: PdfIcons.remove,
                size: 18,
                color: theme.toolbarForegroundColor,
                onPressed: controller.zoomLevel > controller.minZoom
                    ? controller.zoomOut
                    : null,
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
              PdfIconButton(
                tooltip: 'Zoom In',
                icon: PdfIcons.add,
                size: 18,
                color: theme.toolbarForegroundColor,
                onPressed: controller.zoomLevel < controller.maxZoom
                    ? controller.zoomIn
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PageProgressTrack extends StatelessWidget {
  const _PageProgressTrack({
    required this.currentPage,
    required this.totalPages,
    required this.accentColor,
    required this.onPageSelected,
  });

  final int currentPage;
  final int totalPages;
  final Color accentColor;
  final ValueChanged<int> onPageSelected;

  void _updateFromDx(double dx, double width) {
    if (width <= 0 || totalPages <= 1) {
      return;
    }
    final double ratio = (dx / width).clamp(0.0, 1.0);
    final int targetPage = 1 + (ratio * (totalPages - 1)).round();
    onPageSelected(targetPage);
  }

  @override
  Widget build(BuildContext context) {
    const double trackWidth = 100.0;
    final double progress =
        totalPages <= 1 ? 1.0 : (currentPage - 1) / (totalPages - 1);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (TapDownDetails d) =>
          _updateFromDx(d.localPosition.dx, trackWidth),
      onHorizontalDragUpdate: (DragUpdateDetails d) =>
          _updateFromDx(d.localPosition.dx, trackWidth),
      child: SizedBox(
        width: trackWidth,
        height: 24,
        child: Center(
          child: Stack(
            alignment: Alignment.centerLeft,
            children: <Widget>[
              Container(
                width: trackWidth,
                height: 4,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: trackWidth * progress.clamp(0.0, 1.0),
                height: 4,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

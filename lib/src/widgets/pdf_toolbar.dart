import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../controller/pdf_viewer_controller.dart';
import '../models/pdf_annotation.dart';
import '../models/pdf_document.dart';
import '../models/pdf_metadata.dart';
import '../theme/pdf_icons.dart';
import '../theme/pdf_viewer_theme.dart';

/// Adaptive top toolbar for `PdfViewer` providing access to sidebar/outlines,
/// search, layout switching, reading color filters, fit mode, rotation,
/// bookmarks, annotations, immersive mode, and document metadata.
///
/// Automatically adapts between a full Desktop Studio bar (`width >= 760`) and
/// a compact overflow-free Mobile bar (`width < 760`) with a rich quick-options
/// modal sheet.
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

  /// Callback invoked when the user taps the sidebar / table of contents icon.
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

  IconData _layoutIcon(PdfPageLayoutMode mode) {
    switch (mode) {
      case PdfPageLayoutMode.continuousVertical:
        return PdfIcons.scrollVertical;
      case PdfPageLayoutMode.continuousHorizontal:
        return PdfIcons.scrollHorizontal;
      case PdfPageLayoutMode.singlePage:
        return PdfIcons.singlePage;
      case PdfPageLayoutMode.doublePage:
        return PdfIcons.doublePage;
    }
  }

  void _showCompactOptionsSheet(BuildContext context) {
    showPdfModalDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return ListenableBuilder(
          listenable: controller,
          builder: (BuildContext ctx, _) {
            final bool isBookmarked =
                controller.isPageBookmarked(controller.currentPage);
            return Container(
              width: 340,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.surfaceBorderColor),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x45000000),
                    blurRadius: 28,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        PdfIcon(
                          PdfIcons.pdf,
                          size: 18,
                          color: theme.accentColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reader Controls',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: theme.toolbarForegroundColor,
                            ),
                          ),
                        ),
                        PdfIconButton(
                          tooltip: 'Close Controls',
                          icon: PdfIcons.close,
                          size: 17,
                          padding: const EdgeInsets.all(6),
                          color: theme.secondaryForegroundColor,
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'LAYOUT MODE',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: theme.secondaryForegroundColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        for (final PdfPageLayoutMode mode
                            in PdfPageLayoutMode.values)
                          _SelectablePill(
                            icon: _layoutIcon(mode),
                            label: mode.label,
                            isSelected: controller.layoutMode == mode,
                            theme: theme,
                            onTap: () => controller.setLayoutMode(mode),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'READING FILTER',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: theme.secondaryForegroundColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        for (final PdfColorMode mode in PdfColorMode.values)
                          _ColorModeChip(
                            mode: mode,
                            isSelected: controller.colorMode == mode,
                            theme: theme,
                            onTap: () => controller.setColorMode(mode),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'QUICK ACTIONS',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: theme.secondaryForegroundColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        _SelectablePill(
                          icon: isBookmarked
                              ? PdfIcons.bookmark
                              : PdfIcons.bookmarkBorder,
                          label: isBookmarked ? 'Bookmarked' : 'Bookmark',
                          isSelected: isBookmarked,
                          theme: theme,
                          onTap: controller.toggleBookmark,
                        ),
                        _SelectablePill(
                          icon: PdfIcons.gridView,
                          label: 'Thumbnails',
                          isSelected: controller.isThumbnailBarVisible,
                          theme: theme,
                          onTap: () {
                            controller.toggleThumbnailBar();
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                        _SelectablePill(
                          icon: controller.fitMode == PdfFitMode.fitWidth
                              ? PdfIcons.fitWidth
                              : PdfIcons.fitPage,
                          label: controller.fitMode.label,
                          isSelected: controller.fitMode == PdfFitMode.fitWidth,
                          theme: theme,
                          onTap: controller.toggleFitMode,
                        ),
                        _SelectablePill(
                          icon: PdfIcons.rotateRight,
                          label: 'Rotate 90°',
                          isSelected: controller.rotationAngle != 0,
                          theme: theme,
                          onTap: controller.rotateClockwise,
                        ),
                        _SelectablePill(
                          icon: PdfIcons.fullscreen,
                          label: 'Focus Mode',
                          isSelected: controller.isImmersiveMode,
                          theme: theme,
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            controller.toggleImmersiveMode(true);
                          },
                        ),
                        _SelectablePill(
                          icon: PdfIcons.infoOutline,
                          label: 'Doc Info',
                          isSelected: false,
                          theme: theme,
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            _showMetadataDialog(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMetadataDialog(BuildContext context) {
    final PdfDocument? doc = controller.document;
    final PdfMetadata meta = doc?.metadata ?? const PdfMetadata();

    showPdfModalDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Container(
          width: 390,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.surfaceBorderColor),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x45000000),
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: theme.accentColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: PdfIcon(
                          PdfIcons.pdf,
                          size: 19,
                          color: theme.accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Document Information',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: theme.toolbarForegroundColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _InfoRow(
                  label: 'Title',
                  value: meta.title ?? 'Untitled',
                  theme: theme,
                ),
                _InfoRow(
                  label: 'Author',
                  value: meta.author ?? 'Unknown',
                  theme: theme,
                ),
                _InfoRow(
                  label: 'Subject',
                  value: meta.subject ?? '—',
                  theme: theme,
                ),
                _InfoRow(
                  label: 'PDF Version',
                  value: 'PDF ${meta.version}',
                  theme: theme,
                ),
                _InfoRow(
                  label: 'Pages',
                  value: '${controller.pageCount}',
                  theme: theme,
                ),
                _InfoRow(
                  label: 'Words',
                  value: '${doc?.wordCount ?? 0}',
                  theme: theme,
                ),
                _InfoRow(
                  label: 'File Size',
                  value: meta.formattedFileSize,
                  theme: theme,
                ),
                _InfoRow(
                  label: 'Encrypted',
                  value: meta.isEncrypted ? 'Yes' : 'No',
                  theme: theme,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.accentColor.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      PdfIcon(
                        PdfIcons.sparkle,
                        color: theme.accentColor,
                        size: 19,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Supported by Humanize AI',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: theme.toolbarForegroundColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'https://humanize.id',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PdfIconButton(
                        tooltip: 'Copy https://humanize.id',
                        icon: PdfIcons.copy,
                        size: 16,
                        color: theme.accentColor,
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
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: theme.accentColor,
                          borderRadius: BorderRadius.circular(9),
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
        final String metaLine = controller.pageCount > 0
            ? 'Page ${controller.currentPage} of ${controller.pageCount}'
                '${controller.document != null ? '  •  PDF ${controller.document!.metadata.version}' : ''}'
            : 'Ready';

        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isCompact = constraints.maxWidth < 760;
            final bool showPillLabels = constraints.maxWidth >= 960;

            return DecoratedBox(
              decoration: BoxDecoration(
                color: theme.toolbarBackgroundColor,
                border: Border(
                  bottom: BorderSide(color: theme.surfaceBorderColor),
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Container(
                  height: 56,
                  padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12),
                  child: Row(
                    children: <Widget>[
                      ...leadingActions,
                      if (onOpenBookmarksDrawer != null)
                        PdfIconButton(
                          tooltip: 'Outlines & Bookmarks',
                          icon: isCompact ? PdfIcons.toc : PdfIcons.sidebar,
                          isActive: controller.isSidebarOpen,
                          activeColor: theme.accentColor,
                          color: theme.toolbarForegroundColor,
                          onPressed: onOpenBookmarksDrawer,
                        ),
                      if (!isCompact) ...<Widget>[
                        const SizedBox(width: 6),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: theme.accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: PdfIcon(
                              PdfIcons.pdf,
                              size: 16,
                              color: theme.accentColor,
                            ),
                          ),
                        ),
                      ],
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                resolvedTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.toolbarForegroundColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: isCompact ? 13.5 : 14.2,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                metaLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.secondaryForegroundColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      PdfIconButton(
                        tooltip: 'Search in PDF',
                        icon: PdfIcons.search,
                        isActive: controller.isSearchVisible,
                        activeColor: theme.accentColor,
                        color: theme.toolbarForegroundColor,
                        onPressed: controller.toggleSearchVisibility,
                      ),
                      if (!isCompact) ...<Widget>[
                        PdfIconButton(
                          tooltip: isBookmarked
                              ? 'Remove Bookmark'
                              : 'Bookmark Current Page',
                          icon: isBookmarked
                              ? PdfIcons.bookmark
                              : PdfIcons.bookmarkBorder,
                          isActive: isBookmarked,
                          activeColor: theme.accentColor,
                          color: theme.toolbarForegroundColor,
                          onPressed: controller.toggleBookmark,
                        ),
                        PdfIconButton(
                          tooltip: 'Annotate & Markup',
                          icon: PdfIcons.draw,
                          isActive: controller.isAnnotationToolbarVisible,
                          activeColor: theme.accentColor,
                          color: theme.toolbarForegroundColor,
                          onPressed: controller.toggleAnnotationToolbar,
                        ),
                        PdfIconButton(
                          tooltip: 'Page Thumbnails',
                          icon: PdfIcons.gridView,
                          isActive: controller.isThumbnailBarVisible,
                          activeColor: theme.accentColor,
                          color: theme.toolbarForegroundColor,
                          onPressed: controller.toggleThumbnailBar,
                        ),
                        _ToolbarDivider(color: theme.surfaceBorderColor),
                        if (showPillLabels)
                          _ToolbarModePill(
                            tooltip: 'Page Layout Mode',
                            icon: _layoutIcon(controller.layoutMode),
                            label: controller.layoutMode.label,
                            isHighlighted: controller.layoutMode !=
                                PdfPageLayoutMode.continuousVertical,
                            theme: theme,
                            onTap: _cycleLayoutMode,
                          )
                        else
                          PdfIconButton(
                            tooltip: 'Page Layout Mode',
                            icon: _layoutIcon(controller.layoutMode),
                            isActive: controller.layoutMode !=
                                PdfPageLayoutMode.continuousVertical,
                            activeColor: theme.accentColor,
                            color: theme.toolbarForegroundColor,
                            onPressed: _cycleLayoutMode,
                          ),
                        const SizedBox(width: 4),
                        if (showPillLabels)
                          _ToolbarModePill(
                            tooltip: 'Reading Color Mode',
                            icon: PdfIcons.tonality,
                            label: controller.colorMode.label,
                            swatchColor: controller.colorMode.swatchColor,
                            isHighlighted:
                                controller.colorMode != PdfColorMode.normal,
                            theme: theme,
                            onTap: _cycleColorMode,
                          )
                        else
                          PdfIconButton(
                            tooltip: 'Reading Color Mode',
                            icon: PdfIcons.tonality,
                            isActive:
                                controller.colorMode != PdfColorMode.normal,
                            activeColor: theme.accentColor,
                            color: theme.toolbarForegroundColor,
                            onPressed: _cycleColorMode,
                          ),
                        _ToolbarDivider(color: theme.surfaceBorderColor),
                        PdfIconButton(
                          tooltip: controller.fitMode == PdfFitMode.fitWidth
                              ? 'Switch to Fit Page'
                              : 'Switch to Fit Width',
                          icon: controller.fitMode == PdfFitMode.fitWidth
                              ? PdfIcons.fitWidth
                              : PdfIcons.fitPage,
                          isActive: controller.fitMode == PdfFitMode.fitWidth,
                          activeColor: theme.accentColor,
                          color: theme.toolbarForegroundColor,
                          onPressed: controller.toggleFitMode,
                        ),
                        PdfIconButton(
                          tooltip: 'Rotate 90° Clockwise',
                          icon: PdfIcons.rotateRight,
                          isActive: controller.rotationAngle != 0,
                          activeColor: theme.accentColor,
                          color: theme.toolbarForegroundColor,
                          onPressed: controller.rotateClockwise,
                        ),
                        PdfIconButton(
                          tooltip: 'Immersive Focus Mode',
                          icon: PdfIcons.fullscreen,
                          color: theme.toolbarForegroundColor,
                          onPressed: () => controller.toggleImmersiveMode(true),
                        ),
                        PdfIconButton(
                          tooltip: 'Document Info & Humanize AI Support',
                          icon: PdfIcons.infoOutline,
                          color: theme.toolbarForegroundColor,
                          onPressed: () => _showMetadataDialog(context),
                        ),
                      ] else ...<Widget>[
                        PdfIconButton(
                          tooltip: 'Annotate & Markup',
                          icon: PdfIcons.draw,
                          isActive: controller.isAnnotationToolbarVisible,
                          activeColor: theme.accentColor,
                          color: theme.toolbarForegroundColor,
                          onPressed: controller.toggleAnnotationToolbar,
                        ),
                        PdfIconButton(
                          tooltip: 'More Reader Options',
                          icon: PdfIcons.moreVert,
                          color: theme.toolbarForegroundColor,
                          onPressed: () => _showCompactOptionsSheet(context),
                        ),
                      ],
                      ...trailingActions,
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      color: color,
    );
  }
}

class _ToolbarModePill extends StatelessWidget {
  const _ToolbarModePill({
    required this.tooltip,
    required this.icon,
    required this.label,
    required this.isHighlighted,
    required this.theme,
    required this.onTap,
    this.swatchColor,
  });

  final String tooltip;
  final IconData icon;
  final String label;
  final bool isHighlighted;
  final PdfViewerTheme theme;
  final VoidCallback onTap;
  final Color? swatchColor;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Semantics(
        label: tooltip,
        button: true,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5.5),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? theme.accentColor.withValues(alpha: 0.14)
                  : theme.backgroundColor.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: isHighlighted
                    ? theme.accentColor.withValues(alpha: 0.45)
                    : theme.surfaceBorderColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (swatchColor != null)
                  Container(
                    width: 11,
                    height: 11,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: swatchColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.toolbarForegroundColor
                            .withValues(alpha: 0.35),
                      ),
                    ),
                  )
                else ...<Widget>[
                  PdfIcon(
                    icon,
                    size: 15,
                    color: isHighlighted
                        ? theme.accentColor
                        : theme.toolbarForegroundColor,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.8,
                    fontWeight: FontWeight.w600,
                    color: isHighlighted
                        ? theme.accentColor
                        : theme.toolbarForegroundColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectablePill extends StatelessWidget {
  const _SelectablePill({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final PdfViewerTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.accentColor.withValues(alpha: 0.16)
                : theme.backgroundColor.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? theme.accentColor : theme.surfaceBorderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              PdfIcon(
                icon,
                size: 15,
                color: isSelected
                    ? theme.accentColor
                    : theme.toolbarForegroundColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? theme.accentColor
                      : theme.toolbarForegroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorModeChip extends StatelessWidget {
  const _ColorModeChip({
    required this.mode,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  final PdfColorMode mode;
  final bool isSelected;
  final PdfViewerTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.accentColor.withValues(alpha: 0.16)
                : theme.backgroundColor.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? theme.accentColor : theme.surfaceBorderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: mode.swatchColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.toolbarForegroundColor.withValues(alpha: 0.35),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                mode.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? theme.accentColor
                      : theme.toolbarForegroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final String value;
  final PdfViewerTheme theme;

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
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12.8,
                color: theme.secondaryForegroundColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.8,
                fontWeight: FontWeight.w500,
                color: theme.toolbarForegroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive secondary bar for choosing annotation tools, colors, stroke
/// widths, stamp presets, and undo/redo operations.
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
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFFA855F7),
    Color(0xFF0F172A),
  ];

  static const List<double> _strokeWidths = <double>[2.0, 4.0, 7.0];

  static const List<String> _stampPresets = <String>[
    'APPROVED',
    'REVIEWED',
    'IMPORTANT',
    'DRAFT',
  ];

  void _cycleStampLabel() {
    final int idx = _stampPresets.indexOf(controller.activeStampText);
    final int next = (idx + 1) % _stampPresets.length;
    controller.setActiveStampText(_stampPresets[next]);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, _) {
        final PdfAnnotationTool activeTool = controller.activeAnnotationTool;
        final bool showStrokePicker = activeTool == PdfAnnotationTool.ink ||
            activeTool == PdfAnnotationTool.underline ||
            activeTool == PdfAnnotationTool.strikethrough;

        return Container(
          decoration: BoxDecoration(
            color: theme.toolbarBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.surfaceBorderColor),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x28000000),
                blurRadius: 18,
                offset: Offset(0, 6),
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
                const SizedBox(width: 4),
                _ToolChip(
                  icon: PdfIcons.highlight,
                  label: 'Highlight',
                  isSelected: activeTool == PdfAnnotationTool.highlight,
                  accentColor: theme.accentColor,
                  foregroundColor: theme.toolbarForegroundColor,
                  onTap: () =>
                      controller.setAnnotationTool(PdfAnnotationTool.highlight),
                ),
                const SizedBox(width: 4),
                _ToolChip(
                  icon: PdfIcons.underline,
                  label: 'Underline',
                  isSelected: activeTool == PdfAnnotationTool.underline,
                  accentColor: theme.accentColor,
                  foregroundColor: theme.toolbarForegroundColor,
                  onTap: () =>
                      controller.setAnnotationTool(PdfAnnotationTool.underline),
                ),
                const SizedBox(width: 4),
                _ToolChip(
                  icon: PdfIcons.ink,
                  label: 'Ink',
                  isSelected: activeTool == PdfAnnotationTool.ink,
                  accentColor: theme.accentColor,
                  foregroundColor: theme.toolbarForegroundColor,
                  onTap: () =>
                      controller.setAnnotationTool(PdfAnnotationTool.ink),
                ),
                const SizedBox(width: 4),
                _ToolChip(
                  icon: PdfIcons.stickyNote,
                  label: 'Note',
                  isSelected: activeTool == PdfAnnotationTool.stickyNote,
                  accentColor: theme.accentColor,
                  foregroundColor: theme.toolbarForegroundColor,
                  onTap: () => controller
                      .setAnnotationTool(PdfAnnotationTool.stickyNote),
                ),
                const SizedBox(width: 4),
                _ToolChip(
                  icon: PdfIcons.stamp,
                  label: 'Stamp',
                  isSelected: activeTool == PdfAnnotationTool.stamp,
                  accentColor: theme.accentColor,
                  foregroundColor: theme.toolbarForegroundColor,
                  onTap: () =>
                      controller.setAnnotationTool(PdfAnnotationTool.stamp),
                ),
                if (activeTool == PdfAnnotationTool.stamp) ...<Widget>[
                  const SizedBox(width: 6),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _cycleStampLabel,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: controller.activeAnnotationColor
                              .withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: controller.activeAnnotationColor,
                          ),
                        ),
                        child: Text(
                          controller.activeStampText,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: controller.activeAnnotationColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                _ToolbarDivider(color: theme.surfaceBorderColor),
                for (final Color swatch in _palette)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => controller.setAnnotationColor(swatch),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          width: 21,
                          height: 21,
                          decoration: BoxDecoration(
                            color: swatch,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: controller.activeAnnotationColor == swatch
                                  ? theme.toolbarForegroundColor
                                  : theme.surfaceBorderColor,
                              width: controller.activeAnnotationColor == swatch
                                  ? 2.4
                                  : 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (showStrokePicker) ...<Widget>[
                  _ToolbarDivider(color: theme.surfaceBorderColor),
                  for (final double w in _strokeWidths)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => controller.setAnnotationStrokeWidth(w),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: (controller.activeStrokeWidth - w).abs() <
                                      0.6
                                  ? theme.accentColor.withValues(alpha: 0.16)
                                  : const Color(0x00000000),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 4 + w,
                                height: 4 + w,
                                decoration: BoxDecoration(
                                  color: theme.toolbarForegroundColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
                _ToolbarDivider(color: theme.surfaceBorderColor),
                PdfIconButton(
                  tooltip: 'Undo Annotation',
                  icon: PdfIcons.undo,
                  size: 17,
                  padding: const EdgeInsets.all(6),
                  color: theme.toolbarForegroundColor,
                  onPressed: controller.canUndoAnnotation
                      ? controller.undoAnnotation
                      : null,
                ),
                PdfIconButton(
                  tooltip: 'Redo Annotation',
                  icon: PdfIcons.redo,
                  size: 17,
                  padding: const EdgeInsets.all(6),
                  color: theme.toolbarForegroundColor,
                  onPressed: controller.canRedoAnnotation
                      ? controller.redoAnnotation
                      : null,
                ),
                PdfIconButton(
                  tooltip: 'Clear Page Annotations',
                  icon: PdfIcons.delete,
                  size: 17,
                  padding: const EdgeInsets.all(6),
                  color: theme.toolbarForegroundColor,
                  onPressed: controller.annotations.isNotEmpty
                      ? () => controller.clearAnnotations(
                            pageNumber: controller.currentPage,
                          )
                      : null,
                ),
                PdfIconButton(
                  tooltip: 'Close Annotation Bar',
                  icon: PdfIcons.close,
                  size: 17,
                  padding: const EdgeInsets.all(6),
                  color: theme.secondaryForegroundColor,
                  onPressed: () => controller.toggleAnnotationToolbar(false),
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 5.5),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.16)
                : const Color(0x00000000),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.6)
                  : const Color(0x00000000),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              PdfIcon(
                icon,
                size: 15,
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
      ),
    );
  }
}

/// Floating bottom navigation and zoom scrubber capsule for `PdfViewer`.
///
/// Automatically scales its interactive progress slider to avoid overflow on
/// narrow smartphone viewports while offering full studio zoom & page jumping
/// on desktop.
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

    try {
      final int? target = await showPdfModalDialog<int>(
        context: context,
        builder: (BuildContext dialogContext) {
          return Container(
            width: 310,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.surfaceBorderColor),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x45000000),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Go to Page (1 – ${controller.pageCount})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.toolbarForegroundColor,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor.withValues(alpha: 0.55),
                    border: Border.all(color: theme.surfaceBorderColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: EditableText(
                    controller: inputController,
                    focusNode: focusNode,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontFamily: theme.fontFamily ??
                          DefaultTextStyle.of(context).style.fontFamily,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: theme.toolbarForegroundColor,
                    ),
                    cursorColor: theme.accentColor,
                    backgroundCursorColor: theme.secondaryForegroundColor,
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: theme.secondaryForegroundColor,
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
                          horizontal: 18,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: theme.accentColor,
                          borderRadius: BorderRadius.circular(9),
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
    } finally {
      inputController.dispose();
      focusNode.dispose();
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

        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isVeryCompact = constraints.maxWidth < 370;
            final double trackWidth = isVeryCompact
                ? 56.0
                : (constraints.maxWidth < 520 ? 78.0 : 112.0);

            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: isVeryCompact ? 6 : 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: theme.toolbarBackgroundColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.surfaceBorderColor),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x2C000000),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  PdfIconButton(
                    tooltip: 'Previous Page',
                    icon: PdfIcons.chevronLeft,
                    size: 18,
                    padding: EdgeInsets.all(isVeryCompact ? 5 : 6.5),
                    color: theme.toolbarForegroundColor,
                    onPressed: controller.hasPreviousPage
                        ? controller.previousPage
                        : null,
                  ),
                  MouseRegion(
                    cursor: totalPages > 1
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    child: GestureDetector(
                      onTap: totalPages > 1
                          ? () => _showJumpToPageDialog(context)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4.5,
                        ),
                        decoration: BoxDecoration(
                          color: theme.backgroundColor.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '$current / $totalPages',
                          style: TextStyle(
                            color: theme.toolbarForegroundColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (totalPages > 1) ...<Widget>[
                    SizedBox(width: isVeryCompact ? 6 : 10),
                    _PageProgressTrack(
                      width: trackWidth,
                      currentPage: current,
                      totalPages: totalPages,
                      accentColor: theme.accentColor,
                      onPageSelected: controller.jumpToPage,
                    ),
                    SizedBox(width: isVeryCompact ? 2 : 4),
                  ],
                  PdfIconButton(
                    tooltip: 'Next Page',
                    icon: PdfIcons.chevronRight,
                    size: 18,
                    padding: EdgeInsets.all(isVeryCompact ? 5 : 6.5),
                    color: theme.toolbarForegroundColor,
                    onPressed:
                        controller.hasNextPage ? controller.nextPage : null,
                  ),
                  Container(
                    width: 1,
                    height: 18,
                    margin: EdgeInsets.symmetric(
                      horizontal: isVeryCompact ? 3 : 5,
                    ),
                    color: theme.surfaceBorderColor,
                  ),
                  PdfIconButton(
                    tooltip: 'Zoom Out',
                    icon: PdfIcons.remove,
                    size: 16,
                    padding: EdgeInsets.all(isVeryCompact ? 5 : 6),
                    color: theme.toolbarForegroundColor,
                    onPressed: controller.zoomLevel > controller.minZoom
                        ? controller.zoomOut
                        : null,
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: controller.resetZoom,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Text(
                          '$zoomPercent%',
                          style: TextStyle(
                            color: theme.toolbarForegroundColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                  PdfIconButton(
                    tooltip: 'Zoom In',
                    icon: PdfIcons.add,
                    size: 16,
                    padding: EdgeInsets.all(isVeryCompact ? 5 : 6),
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
      },
    );
  }
}

class _PageProgressTrack extends StatelessWidget {
  const _PageProgressTrack({
    required this.width,
    required this.currentPage,
    required this.totalPages,
    required this.accentColor,
    required this.onPageSelected,
  });

  final double width;
  final int currentPage;
  final int totalPages;
  final Color accentColor;
  final ValueChanged<int> onPageSelected;

  void _updateFromDx(double dx) {
    if (width <= 0 || totalPages <= 1) {
      return;
    }
    final double ratio = (dx / width).clamp(0.0, 1.0);
    final int targetPage = 1 + (ratio * (totalPages - 1)).round();
    onPageSelected(targetPage);
  }

  @override
  Widget build(BuildContext context) {
    final double progress =
        (totalPages <= 1 ? 1.0 : (currentPage - 1) / (totalPages - 1))
            .clamp(0.0, 1.0);
    const double thumbSize = 12.0;
    final double thumbLeft =
        ((width - thumbSize) * progress).clamp(0.0, width - thumbSize);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (TapDownDetails d) => _updateFromDx(d.localPosition.dx),
        onHorizontalDragUpdate: (DragUpdateDetails d) =>
            _updateFromDx(d.localPosition.dx),
        child: SizedBox(
          width: width,
          height: 24,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: <Widget>[
              Container(
                width: width,
                height: 4,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: width * progress,
                height: 4,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 140),
                left: thumbLeft,
                child: Container(
                  width: thumbSize,
                  height: thumbSize,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFFFFF),
                      width: 2.0,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.45),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

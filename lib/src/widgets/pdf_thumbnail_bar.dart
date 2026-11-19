import 'package:flutter/widgets.dart';

import '../controller/pdf_viewer_controller.dart';
import '../models/pdf_document.dart';
import '../models/pdf_page_data.dart';
import '../theme/pdf_viewer_theme.dart';
import 'pdf_page_canvas.dart';

/// Interactive thumbnail strip rendering miniature vector previews of all pages
/// in a [PdfDocument], with active page framing, bookmark indicators, and
/// annotation badges.
class PdfThumbnailBar extends StatelessWidget {
  /// Creates a [PdfThumbnailBar].
  const PdfThumbnailBar({
    super.key,
    required this.document,
    required this.controller,
    required this.theme,
    this.axis = Axis.horizontal,
  });

  /// The loaded PDF document whose pages are previewed.
  final PdfDocument document;

  /// Controller used to highlight and select pages.
  final PdfViewerController controller;

  /// Theme styling configuration.
  final PdfViewerTheme theme;

  /// Scroll direction of the thumbnail strip (default is [Axis.horizontal]).
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, _) {
        final int activePage = controller.currentPage;
        final bool isHorizontal = axis == Axis.horizontal;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.toolbarBackgroundColor,
            border: Border(
              top: isHorizontal
                  ? BorderSide(color: theme.surfaceBorderColor)
                  : BorderSide.none,
            ),
            boxShadow: isHorizontal
                ? const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 10,
                      offset: Offset(0, -3),
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: SizedBox(
            height: isHorizontal ? 124 : null,
            width: isHorizontal ? null : 210,
            child: ListView.separated(
              scrollDirection: axis,
              padding: EdgeInsets.symmetric(
                horizontal: isHorizontal ? 16 : 18,
                vertical: isHorizontal ? 11 : 14,
              ),
              itemCount: document.pageCount,
              separatorBuilder: (_, __) => SizedBox(
                width: isHorizontal ? 14 : 0,
                height: isHorizontal ? 0 : 16,
              ),
              itemBuilder: (BuildContext context, int index) {
                final PdfPageData page = document.pages[index];
                final bool isSelected = page.pageNumber == activePage;
                final bool isBookmarked =
                    controller.isPageBookmarked(page.pageNumber);
                final int annotationCount =
                    controller.annotationsForPage(page.pageNumber).length;

                final double thumbHeight = isHorizontal ? 76.0 : 146.0;
                final double thumbWidth = (thumbHeight * page.aspectRatio)
                    .clamp(48.0, isHorizontal ? 104.0 : 164.0);

                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => controller.jumpToPage(page.pageNumber),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Stack(
                          clipBehavior: Clip.none,
                          children: <Widget>[
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: thumbWidth,
                              height: thumbHeight,
                              decoration: BoxDecoration(
                                color: page.backgroundColor,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.activeThumbnailBorderColor
                                      : theme.thumbnailBorderColor,
                                  width: isSelected ? 2.4 : 1.0,
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: isSelected
                                        ? theme.accentColor
                                            .withValues(alpha: 0.22)
                                        : theme.pageShadowColor,
                                    blurRadius: isSelected ? 10 : 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: PdfPageCanvas(
                                  page: page,
                                  colorMode: controller.colorMode,
                                  rotationOffset: controller.rotationAngle,
                                  fontFamily: theme.fontFamily,
                                  isThumbnail: true,
                                ),
                              ),
                            ),
                            if (isBookmarked || annotationCount > 0)
                              Positioned(
                                top: 5,
                                right: 5,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    if (annotationCount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4.5,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF59E0B),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '$annotationCount',
                                          style: const TextStyle(
                                            color: Color(0xFF0F172A),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    if (isBookmarked) ...<Widget>[
                                      if (annotationCount > 0)
                                        const SizedBox(width: 3),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: theme.accentColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFFFFFFFF),
                                            width: 1.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.accentColor
                                : const Color(0x00000000),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isHorizontal
                                ? '${page.pageNumber}'
                                : 'Page ${page.pageNumber}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFFFFFFFF)
                                  : theme.secondaryForegroundColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

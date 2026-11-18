import 'package:flutter/material.dart';

import '../controller/pdf_viewer_controller.dart';
import '../models/pdf_document.dart';
import '../models/pdf_page_data.dart';
import '../theme/pdf_viewer_theme.dart';
import 'pdf_page_canvas.dart';

/// Interactive thumbnail strip rendering miniature vector previews of all pages
/// in a [PdfDocument].
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

        return Material(
          elevation: 6,
          color: theme.toolbarBackgroundColor,
          child: SizedBox(
            height: axis == Axis.horizontal ? 116 : null,
            width: axis == Axis.vertical ? 128 : null,
            child: ListView.separated(
              scrollDirection: axis,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              itemCount: document.pageCount,
              separatorBuilder: (_, __) => SizedBox(
                width: axis == Axis.horizontal ? 12 : 0,
                height: axis == Axis.vertical ? 12 : 0,
              ),
              itemBuilder: (BuildContext context, int index) {
                final PdfPageData page = document.pages[index];
                final bool isSelected = page.pageNumber == activePage;
                const double thumbHeight = 72.0;
                final double thumbWidth =
                    (thumbHeight * page.aspectRatio).clamp(44.0, 96.0);

                return GestureDetector(
                  onTap: () => controller.jumpToPage(page.pageNumber),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: thumbWidth,
                        height: thumbHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: isSelected
                                ? theme.activeThumbnailBorderColor
                                : theme.thumbnailBorderColor,
                            width: isSelected ? 2.4 : 1.0,
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: theme.pageShadowColor,
                              blurRadius: isSelected ? 6 : 2,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3.5),
                          child: PdfPageCanvas(
                            page: page,
                            colorMode: controller.colorMode,
                            rotationOffset: controller.rotationAngle,
                            isThumbnail: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${page.pageNumber}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? theme.accentColor
                              : theme.toolbarForegroundColor
                                  .withValues(alpha: 0.75),
                        ),
                      ),
                    ],
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

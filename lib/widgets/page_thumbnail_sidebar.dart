import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../theme/app_theme.dart';
import '../providers/editor_provider.dart';

/// Sidebar showing page thumbnails for quick navigation.
class PageThumbnailSidebar extends StatelessWidget {
  final EditorProvider provider;
  final PdfDocument? document;

  const PageThumbnailSidebar({
    super.key,
    required this.provider,
    this.document,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final state = provider.state;
        if (!state.isSidebarOpen) return const SizedBox.shrink();

        return AnimatedContainer(
          duration: AppTheme.animNormal,
          width: 180,
          decoration: BoxDecoration(
            gradient: AppTheme.sidebarGradient,
            border: Border(
              right: BorderSide(
                color: AppTheme.textMuted.withValues(alpha: 0.15),
              ),
            ),
            boxShadow: AppTheme.elevation2,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.textMuted.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.layers_rounded,
                      size: 16,
                      color: AppTheme.accent,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Pages',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${state.totalPages}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Thumbnails list
              Expanded(
                child: state.filePath == null
                    ? const Center(
                        child: Text(
                          'No file open',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.spacingSm),
                        itemCount: state.totalPages,
                        itemBuilder: (context, index) {
                          final isActive = index == state.currentPage;
                          final hasAnnotations =
                              state.getPageAnnotations(index).isNotEmpty;
                          return GestureDetector(
                            onTap: () => provider.setCurrentPage(index),
                            child: AnimatedContainer(
                              duration: AppTheme.animFast,
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppTheme.primary.withValues(alpha: 0.15)
                                    : AppTheme.surfaceCard.withValues(alpha: 0.5),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusMd),
                                border: Border.all(
                                  color: isActive
                                      ? AppTheme.primary
                                      : Colors.transparent,
                                  width: isActive ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Thumbnail placeholder
                                  AspectRatio(
                                    aspectRatio: 0.707, // A4 ratio
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: document != null &&
                                              index < document!.pages.length
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: PdfPageView(
                                                document: document!,
                                                pageNumber: index + 1,
                                                alignment: Alignment.center,
                                              ),
                                            )
                                          : Center(
                                              child: Icon(
                                                Icons.description_rounded,
                                                color: Colors.grey[400],
                                                size: 32,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      if (hasAnnotations)
                                        Container(
                                          width: 6,
                                          height: 6,
                                          margin:
                                              const EdgeInsets.only(right: 4),
                                          decoration: const BoxDecoration(
                                            color: AppTheme.accent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      Text(
                                        'Page ${index + 1}',
                                        style: TextStyle(
                                          color: isActive
                                              ? AppTheme.textPrimary
                                              : AppTheme.textSecondary,
                                          fontSize: 11,
                                          fontWeight: isActive
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

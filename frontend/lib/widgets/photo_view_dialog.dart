import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/photo_model.dart';
import '../theme/app_colors.dart';

class PhotoViewDialog extends StatelessWidget {
  final PhotoModel photo;
  final Future<void> Function()? onDelete;

  const PhotoViewDialog({
    super.key,
    required this.photo,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required PhotoModel photo,
    Future<void> Function()? onDelete,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => PhotoViewDialog(photo: photo, onDelete: onDelete),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 32,
        vertical: isMobile ? 16 : 32,
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 900,
            maxHeight: size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: AppColors.charcoal, // #2B2F2C
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF3F4541))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStageColor(photo.stage).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _getStageColor(photo.stage)),
                      ),
                      child: Text(
                        photo.stageTitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getStageColor(photo.stage),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        photo.caption.isNotEmpty ? photo.caption : 'Photo Detail',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary),
                        tooltip: 'Delete Photo',
                        onPressed: () => _confirmDelete(context),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Image Viewer (Pinch / Zoomable)
              Flexible(
                child: Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Image.network(
                      photo.url,
                      fit: BoxFit.contain,
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        final percent = progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                            : null;
                        return Center(
                           child: CircularProgressIndicator(value: percent),
                        );
                      },
                      errorBuilder: (ctx, err, stack) => Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.broken_image, size: 48, color: Colors.white38),
                            const SizedBox(height: 12),
                            Text(
                              'Unable to load image:\n${photo.url}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Footer with metadata
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFF3F4541))),
                ),
                child: Row(
                  children: [
                    if (photo.createdAt != null) ...[
                      const Icon(Icons.access_time, size: 14, color: Colors.white60),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(photo.createdAt!),
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (photo.uploadedByName != null && photo.uploadedByName!.isNotEmpty) ...[
                      const Icon(Icons.person_outline, size: 14, color: Colors.white60),
                      const SizedBox(width: 6),
                      Text(
                        'By ${photo.uploadedByName}',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                    const Spacer(),
                    const Text(
                      'Pinch / Scroll to Zoom',
                      style: TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          'Delete Photo?',
          style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to permanently remove this photo documentation?',
          style: GoogleFonts.inter(color: AppColors.textBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.charcoal,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx); // Close confirmation
              Navigator.pop(context); // Close viewer
              if (onDelete != null) {
                await onDelete!();
              }
            },
            child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Color _getStageColor(String stage) {
    switch (stage) {
      case 'CHECKIN_INSPECTION':
        return AppColors.statusCheckedIn;
      case 'FAULT_EVIDENCE':
        return AppColors.statusPendingApproval;
      case 'REPAIR_COMPLETED':
        return AppColors.statusWorkCompleted;
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $hour:$minute';
  }
}

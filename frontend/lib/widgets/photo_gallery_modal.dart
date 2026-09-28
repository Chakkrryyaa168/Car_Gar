import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/photo_model.dart';
import '../theme/app_colors.dart';
import 'photo_view_dialog.dart';

class PhotoGalleryModal extends StatelessWidget {
  final List<PhotoModel> photos;
  final Future<void> Function(PhotoModel photo)? onDeletePhoto;

  const PhotoGalleryModal({
    super.key,
    required this.photos,
    this.onDeletePhoto,
  });

  static void show(
    BuildContext context,
    List<PhotoModel> photos, {
    Future<void> Function(PhotoModel photo)? onDeletePhoto,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PhotoGalleryModal(
        photos: photos,
        onDeletePhoto: onDeletePhoto,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkinPhotos = photos.where((p) => p.stage == 'CHECKIN_INSPECTION').toList();
    final faultPhotos = photos.where((p) => p.stage == 'FAULT_EVIDENCE').toList();
    final completedPhotos = photos.where((p) => p.stage == 'REPAIR_COMPLETED').toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface, // #FFFFFF
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppColors.border),
          left: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated, // #FDF6F5
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Vehicle Photo Documentation',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: photos.isEmpty
                ? Center(
                    child: Text(
                      'No photos attached to this ticket yet.',
                      style: GoogleFonts.inter(color: AppColors.textSecondary),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildStageSection(
                        title: '1. Check-In Inspection Walkaround',
                        icon: Icons.car_crash_outlined,
                        color: AppColors.primary,
                        photos: checkinPhotos,
                      ),
                      const SizedBox(height: 16),
                      _buildStageSection(
                        title: '2. Diagnosed Fault Evidence',
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.primary,
                        photos: faultPhotos,
                      ),
                      const SizedBox(height: 16),
                      _buildStageSection(
                        title: '3. Post-Repair Completion Verification',
                        icon: Icons.task_alt_rounded,
                        color: AppColors.primary,
                        photos: completedPhotos,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<PhotoModel> photos,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated, // #FDF6F5
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border), // #E8DAD8
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '${photos.length} photos',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (photos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No photos recorded in this stage.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                return InkWell(
                  onTap: () {
                    PhotoViewDialog.show(
                      context,
                      photo: photo,
                      onDelete: onDeletePhoto != null ? () => onDeletePhoto!(photo) : null,
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          photo.url,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: AppColors.surfaceMuted,
                            child: const Icon(Icons.broken_image, color: AppColors.textSecondary),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            color: AppColors.primary.withValues(alpha: 0.8),
                            child: Text(
                              photo.caption.isNotEmpty ? photo.caption : photo.stageTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: AppColors.background,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

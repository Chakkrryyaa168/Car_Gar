import 'package:flutter/material.dart';
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
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.photo_library_outlined, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Vehicle Photo Documentation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: photos.isEmpty
                ? const Center(
                    child: Text(
                      'No photos attached to this ticket yet.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildStageSection(
                        title: '1. Check-In Inspection Walkaround',
                        icon: Icons.car_crash_outlined,
                        color: AppColors.statusCheckedIn,
                        photos: checkinPhotos,
                      ),
                      const SizedBox(height: 16),
                      _buildStageSection(
                        title: '2. Diagnosed Fault Evidence',
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.statusPendingApproval,
                        photos: faultPhotos,
                      ),
                      const SizedBox(height: 16),
                      _buildStageSection(
                        title: '3. Post-Repair Completion Verification',
                        icon: Icons.task_alt_rounded,
                        color: AppColors.statusWorkCompleted,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${photos.length} photos',
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (photos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No photos recorded in this stage.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
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
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            color: Colors.black.withValues(alpha: 0.65),
                            child: Text(
                              photo.caption.isNotEmpty ? photo.caption : photo.stageTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
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

class PhotoModel {
  final String id;
  final String ticketId;
  final String? ticketItemId;
  final String stage; // CHECKIN_INSPECTION, FAULT_EVIDENCE, REPAIR_COMPLETED
  final String url;
  final String caption;
  final String? uploadedByName;
  final DateTime? createdAt;

  PhotoModel({
    required this.id,
    required this.ticketId,
    this.ticketItemId,
    required this.stage,
    required this.url,
    required this.caption,
    this.uploadedByName,
    this.createdAt,
  });

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    String rawUrl = json['url'] ?? '';
    if (rawUrl.startsWith('/')) {
      rawUrl = 'http://127.0.0.1:8000$rawUrl';
    }
    return PhotoModel(
      id: json['id'] ?? '',
      ticketId: json['ticket'] ?? '',
      ticketItemId: json['ticket_item'],
      stage: json['stage'] ?? 'CHECKIN_INSPECTION',
      url: rawUrl,
      caption: json['caption'] ?? '',
      uploadedByName: json['uploaded_by_name'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  String get stageTitle {
    switch (stage) {
      case 'CHECKIN_INSPECTION':
        return 'Check-in Walkaround';
      case 'FAULT_EVIDENCE':
        return 'Diagnosed Fault Evidence';
      case 'REPAIR_COMPLETED':
        return 'Post-Repair Completion';
      default:
        return stage;
    }
  }
}

import 'json_helpers.dart';

class TicketItemModel {
  final String id;
  final String ticketId;
  final String? assignedMechanic;
  final String? assignedMechanicName;
  final String? inventoryItem;
  final String? inventoryItemName;
  final String type; // LABOR or PART
  final String description;
  final double unitPrice;
  final double quantity;
  final double totalPrice;
  String approvalStatus; // PENDING, APPROVED, REJECTED
  bool isCompleted;
  final String mechanicNotes;

  TicketItemModel({
    required this.id,
    required this.ticketId,
    this.assignedMechanic,
    this.assignedMechanicName,
    this.inventoryItem,
    this.inventoryItemName,
    required this.type,
    required this.description,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    required this.approvalStatus,
    required this.isCompleted,
    required this.mechanicNotes,
  });

  factory TicketItemModel.fromJson(Map<String, dynamic> json) {
    return TicketItemModel(
      id: json['id'] ?? '',
      ticketId: json['ticket'] ?? '',
      assignedMechanic: json['assigned_mechanic'],
      assignedMechanicName: json['assigned_mechanic_name'],
      inventoryItem: json['inventory_item'],
      inventoryItemName: json['inventory_item_name'],
      type: json['type'] ?? 'PART',
      description: json['description'] ?? '',
      unitPrice: parseDouble(json['unit_price']),
      quantity: parseDouble(json['quantity'], 1.0),
      totalPrice: parseDouble(json['total_price']),
      approvalStatus: json['approval_status'] ?? 'PENDING',
      isCompleted: json['is_completed'] ?? false,
      mechanicNotes: json['mechanic_notes'] ?? '',
    );
  }

  bool get isApproved => approvalStatus == 'APPROVED';
  bool get isPending => approvalStatus == 'PENDING';
  bool get isRejected => approvalStatus == 'REJECTED';
}

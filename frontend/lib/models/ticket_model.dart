import 'vehicle_model.dart';
import 'user_model.dart';
import 'ticket_item_model.dart';
import 'photo_model.dart';
import 'invoice_model.dart';
import 'json_helpers.dart';

class TicketStatusLogModel {
  final String id;
  final String? changedByName;
  final String fromStatus;
  final String toStatus;
  final String remarks;
  final DateTime? createdAt;

  TicketStatusLogModel({
    required this.id,
    this.changedByName,
    required this.fromStatus,
    required this.toStatus,
    required this.remarks,
    this.createdAt,
  });

  factory TicketStatusLogModel.fromJson(Map<String, dynamic> json) {
    return TicketStatusLogModel(
      id: json['id'] ?? '',
      changedByName: json['changed_by_name'],
      fromStatus: json['from_status'] ?? '',
      toStatus: json['to_status'] ?? '',
      remarks: json['remarks'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}

class TicketModel {
  final String id;
  final String ticketNumber;
  final String? vehicleInfo;
  final VehicleModel? vehicle;
  final UserModel? customer;
  final UserModel? leadMechanic;
  final String? customerName;
  final String? customerPhone;
  final String? leadMechanicName;
  final String? receptionistName;
  String currentStatus;
  final int mileageIn;
  final int fuelLevelPercent;
  final String notes;
  List<TicketItemModel> items;
  List<PhotoModel> photos;
  List<TicketStatusLogModel> statusLogs;
  InvoiceModel? invoice;
  final int totalItemsCount;
  final int approvedItemsCount;
  final int completedItemsCount;
  final double totalEstimatedAmount;
  final DateTime? createdAt;

  TicketModel({
    required this.id,
    required this.ticketNumber,
    this.vehicleInfo,
    this.vehicle,
    this.customer,
    this.leadMechanic,
    this.customerName,
    this.customerPhone,
    this.leadMechanicName,
    this.receptionistName,
    required this.currentStatus,
    required this.mileageIn,
    required this.fuelLevelPercent,
    required this.notes,
    required this.items,
    required this.photos,
    required this.statusLogs,
    this.invoice,
    required this.totalItemsCount,
    required this.approvedItemsCount,
    required this.completedItemsCount,
    required this.totalEstimatedAmount,
    this.createdAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    // Parse nested or flat items
    List<TicketItemModel> itemsList = [];
    if (json['items'] is List) {
      itemsList = (json['items'] as List).map((i) => TicketItemModel.fromJson(i)).toList();
    }

    List<PhotoModel> photosList = [];
    if (json['photos'] is List) {
      photosList = (json['photos'] as List).map((p) => PhotoModel.fromJson(p)).toList();
    }

    List<TicketStatusLogModel> logsList = [];
    if (json['status_logs'] is List) {
      logsList = (json['status_logs'] as List).map((l) => TicketStatusLogModel.fromJson(l)).toList();
    }

    InvoiceModel? invoiceObj;
    if (json['invoice'] != null && json['invoice'] is Map<String, dynamic>) {
      invoiceObj = InvoiceModel.fromJson(json['invoice']);
    }

    VehicleModel? vehicleObj;
    if (json['vehicle'] != null && json['vehicle'] is Map<String, dynamic>) {
      vehicleObj = VehicleModel.fromJson(json['vehicle']);
    }

    UserModel? customerObj;
    if (json['customer'] != null && json['customer'] is Map<String, dynamic>) {
      customerObj = UserModel.fromJson(json['customer']);
    }

    UserModel? mechanicObj;
    if (json['lead_mechanic'] != null && json['lead_mechanic'] is Map<String, dynamic>) {
      mechanicObj = UserModel.fromJson(json['lead_mechanic']);
    }

    return TicketModel(
      id: json['id'] ?? '',
      ticketNumber: json['ticket_number'] ?? '',
      vehicleInfo: json['vehicle_info'] ?? (vehicleObj != null ? vehicleObj.displayName : 'Vehicle'),
      vehicle: vehicleObj,
      customer: customerObj,
      leadMechanic: mechanicObj,
      customerName: json['customer_name'] ?? customerObj?.fullName,
      customerPhone: json['customer_phone'] ?? customerObj?.phoneNumber,
      leadMechanicName: json['lead_mechanic_name'] ?? mechanicObj?.fullName,
      receptionistName: json['receptionist_name'],
      currentStatus: json['current_status'] ?? 'CHECKED_IN',
      mileageIn: parseInt(json['mileage_in'], 0),
      fuelLevelPercent: parseInt(json['fuel_level_percent'], 50),
      notes: json['notes'] ?? '',
      items: itemsList,
      photos: photosList,
      statusLogs: logsList,
      invoice: invoiceObj,
      totalItemsCount: parseInt(json['total_items_count'], itemsList.length),
      approvedItemsCount: parseInt(json['approved_items_count'], itemsList.where((i) => i.isApproved).length),
      completedItemsCount: parseInt(json['completed_items_count'], itemsList.where((i) => i.isCompleted).length),
      totalEstimatedAmount: parseDouble(json['total_estimated_amount']),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  // Helper flags
  bool get isPendingApproval => currentStatus == 'PENDING_CUSTOMER_APPROVAL';
  bool get isInProgress => currentStatus == 'APPROVED_IN_PROGRESS';
  bool get isReadyForPickup => currentStatus == 'READY_FOR_PICKUP';
  bool get isPaidAndClosed => currentStatus == 'PAID_AND_CLOSED';
  bool get isWorkCompleted => currentStatus == 'WORK_COMPLETED';
}

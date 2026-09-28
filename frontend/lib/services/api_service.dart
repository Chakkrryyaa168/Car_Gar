import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/ticket_model.dart';
import '../models/ticket_item_model.dart';
import '../models/inventory_model.dart';
import '../models/vehicle_model.dart';
import '../models/invoice_model.dart';

class ApiService {
  static const String _defaultBaseUrl = 'http://127.0.0.1:8000/api';
  String baseUrl;
  String? authToken;

  ApiService({this.baseUrl = _defaultBaseUrl, this.authToken});

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  dynamic _safeJsonDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  String _extractError(http.Response response, String fallback) {
    final parsed = _safeJsonDecode(response.body);
    if (parsed is Map) {
      final msg = parsed['error'] ?? parsed['detail'] ?? parsed['message'];
      if (msg != null && msg.toString().isNotEmpty) {
        return msg.toString();
      }
    }
    if (response.statusCode >= 500) {
      return 'Server error (${response.statusCode}). Please check backend service.';
    }
    if (response.statusCode == 404) {
      return 'Endpoint not found (404).';
    }
    return '$fallback (${response.statusCode})';
  }

  // -------------------------------------------------------------
  // Auth & Demo Switching
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> demoLogin(String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/demo-login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'role': role}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      authToken = data['access'];
      return {
        'token': data['access'],
        'user': UserModel.fromJson(data['user']),
      };
    } else {
      throw Exception(_extractError(response, 'Demo login failed'));
    }
  }

  Future<Map<String, dynamic>> login(String usernameOrEmail, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': usernameOrEmail,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      authToken = data['access'];
      return {
        'token': data['access'],
        'user': UserModel.fromJson(data['user']),
      };
    } else {
      throw Exception(_extractError(response, 'Login failed'));
    }
  }

  Future<Map<String, dynamic>> firebaseLogin({
    required String idToken,
    String role = 'CUSTOMER',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/firebase-login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_token': idToken,
        'role': role,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      authToken = data['access'];
      return {
        'token': data['access'],
        'refresh': data['refresh'],
        'user': UserModel.fromJson(data['user']),
        'firebase_uid': data['firebase_uid'],
      };
    } else {
      throw Exception(_extractError(response, 'Firebase authentication failed'));
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    String? avatarUrl,
    String? licensePlate,
    String? make,
    String? model,
    int? year,
    String? color,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'avatar_url': avatarUrl,
        'license_plate': licensePlate,
        'make': make,
        'model': model,
        'year': year,
        'color': color,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      authToken = data['access'];
      return {
        'token': data['access'],
        'user': UserModel.fromJson(data['user']),
      };
    } else {
      throw Exception(_extractError(response, 'Registration failed'));
    }
  }

  Future<UserModel> fetchCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile/'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data);
    } else {
      throw Exception(_extractError(response, 'Failed to fetch user profile'));
    }
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/auth/profile/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      final updatedData = jsonDecode(response.body);
      return UserModel.fromJson(updatedData);
    } else {
      throw Exception(_extractError(response, 'Failed to update profile'));
    }
  }

  // -------------------------------------------------------------
  // Tickets
  // -------------------------------------------------------------
  Future<List<TicketModel>> fetchTickets({String? status, String? search}) async {
    final queryParams = <String, String>{};
    if (status != null && status.isNotEmpty && status != 'ALL') {
      queryParams['status'] = status;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final baseUri = Uri.parse('$baseUrl/tickets/');
    final uri = queryParams.isNotEmpty
        ? baseUri.replace(queryParameters: queryParams)
        : baseUri;

    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List results = decoded is Map && decoded.containsKey('results')
          ? decoded['results']
          : (decoded as List);
      return results.map((t) => TicketModel.fromJson(t)).toList();
    } else {
      throw Exception('Failed to fetch tickets: ${response.statusCode}');
    }
  }

  Future<TicketModel> fetchTicketDetail(String ticketId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tickets/$ticketId/'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return TicketModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch ticket detail: ${response.statusCode}');
    }
  }

  Future<TicketModel> changeTicketStatus(String ticketId, String newStatus, {String remarks = ''}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tickets/$ticketId/change_status/'),
      headers: _headers,
      body: jsonEncode({
        'status': newStatus,
        'remarks': remarks,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return TicketModel.fromJson(data['ticket']);
    } else {
      throw Exception('Failed to change status: ${response.body}');
    }
  }

  Future<TicketModel> batchApproveItems(String ticketId, List<Map<String, String>> approvals) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tickets/$ticketId/batch_approve_items/'),
      headers: _headers,
      body: jsonEncode({'approvals': approvals}),
    );
    if (response.statusCode == 200) {
      return TicketModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to batch approve items: ${response.body}');
    }
  }

  Future<TicketModel> createTicket({
    required String vehicleId,
    required String customerId,
    required int mileageIn,
    required int fuelLevelPercent,
    required String notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tickets/'),
      headers: _headers,
      body: jsonEncode({
        'vehicle': vehicleId,
        'customer': customerId,
        'mileage_in': mileageIn,
        'fuel_level_percent': fuelLevelPercent,
        'notes': notes,
      }),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return TicketModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create ticket: ${response.body}');
    }
  }

  // -------------------------------------------------------------
  // Ticket Items & Mechanic Actions
  // -------------------------------------------------------------
  Future<TicketItemModel> addTicketItem({
    required String ticketId,
    required String type, // 'PART' or 'LABOR'
    required String description,
    required double unitPrice,
    required double quantity,
    String? inventoryItemId,
    String mechanicNotes = '',
  }) async {
    final payload = {
      'ticket': ticketId,
      'type': type,
      'description': description,
      'unit_price': unitPrice.toStringAsFixed(2),
      'quantity': quantity.toStringAsFixed(2),
      'mechanic_notes': mechanicNotes,
      if (inventoryItemId != null && inventoryItemId.isNotEmpty)
        'inventory_item': inventoryItemId,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/ticket-items/'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return TicketItemModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add item: ${response.body}');
    }
  }

  Future<void> completeTicketItem(String itemId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ticket-items/$itemId/complete/'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception(_extractError(response, 'Failed to complete item'));
    }
  }

  Future<void> deleteTicketItem(String itemId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/ticket-items/$itemId/'),
      headers: _headers,
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(_extractError(response, 'Failed to delete item'));
    }
  }

  // -------------------------------------------------------------
  // Photos
  // -------------------------------------------------------------
  Future<void> uploadPhoto({
    required String ticketId,
    required String stage,
    required String url,
    String caption = '',
    String? ticketItemId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/photos/'),
      headers: _headers,
      body: jsonEncode({
        'ticket': ticketId,
        'stage': stage,
        'url': url,
        'caption': caption,
        if (ticketItemId != null && ticketItemId.isNotEmpty)
          'ticket_item': ticketItemId,
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(_extractError(response, 'Failed to upload photo'));
    }
  }

  Future<void> uploadPhotoFile({
    required String ticketId,
    required String stage,
    required List<int> fileBytes,
    required String fileName,
    String caption = '',
    String? ticketItemId,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/photos/'),
    );
    if (authToken != null && authToken!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $authToken';
    }
    request.fields['ticket'] = ticketId;
    request.fields['stage'] = stage;
    request.fields['caption'] = caption;
    if (ticketItemId != null && ticketItemId.isNotEmpty) {
      request.fields['ticket_item'] = ticketItemId;
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(_extractError(response, 'Failed to upload photo'));
    }
  }

  Future<String> uploadImageFile({
    required List<int> fileBytes,
    required String fileName,
    String folder = 'car_gar/uploads',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload/'),
    );
    if (authToken != null && authToken!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $authToken';
    }
    request.fields['folder'] = folder;
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_extractError(response, 'Failed to upload image'));
    }
    final data = jsonDecode(response.body);
    return data['url'] as String;
  }

  Future<void> deletePhoto(String photoId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/photos/$photoId/'),
      headers: _headers,
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(_extractError(response, 'Failed to delete photo'));
    }
  }

  // -------------------------------------------------------------
  // Vehicles
  // -------------------------------------------------------------
  Future<List<VehicleModel>> fetchVehicles({String? search}) async {
    String url = '$baseUrl/vehicles/';
    if (search != null && search.trim().isNotEmpty) {
      url += '?search=${Uri.encodeComponent(search.trim())}';
    }
    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List results = decoded is Map && decoded.containsKey('results')
          ? decoded['results']
          : (decoded as List);
      return results.map((v) => VehicleModel.fromJson(v)).toList();
    } else {
      throw Exception('Failed to fetch vehicles: ${response.statusCode}');
    }
  }

  // -------------------------------------------------------------
  // Customer Quick Lookup (by Customer ID, Phone, or Plate)
  // -------------------------------------------------------------
  Future<List<Map<String, dynamic>>> lookupCustomer(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    final response = await http.get(
      Uri.parse('$baseUrl/customers/lookup/?q=${Uri.encodeComponent(trimmed)}'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List results = decoded['results'] ?? [];
      return results.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<VehicleModel> createVehicle({
    required String licensePlate,
    required String vin,
    required String make,
    required String model,
    required int year,
    required String color,
    String? ownerId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/vehicles/'),
      headers: _headers,
      body: jsonEncode({
        'license_plate': licensePlate,
        'vin': vin,
        'make': make,
        'model': model,
        'year': year,
        'color': color,
        'owner': ?ownerId,
      }),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return VehicleModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to register vehicle: ${response.body}');
    }
  }

  // -------------------------------------------------------------
  // Inventory
  // -------------------------------------------------------------
  Future<List<InventoryModel>> fetchInventory() async {
    final response = await http.get(Uri.parse('$baseUrl/inventory/'), headers: _headers);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List results = decoded is Map && decoded.containsKey('results')
          ? decoded['results']
          : (decoded as List);
      return results.map((i) => InventoryModel.fromJson(i)).toList();
    } else {
      throw Exception('Failed to fetch inventory: ${response.statusCode}');
    }
  }

  Future<void> restockInventory(String itemId, int quantity) async {
    final response = await http.post(
      Uri.parse('$baseUrl/inventory/$itemId/restock/'),
      headers: _headers,
      body: jsonEncode({'quantity': quantity}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to restock item: ${response.body}');
    }
  }

  // -------------------------------------------------------------
  // Invoices & Payments
  // -------------------------------------------------------------
  Future<InvoiceModel> recordPayment({
    required String invoiceId,
    required double amount,
    required String method,
    String reference = '',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/invoices/$invoiceId/record_payment/'),
      headers: _headers,
      body: jsonEncode({
        'amount_paid': amount.toStringAsFixed(2),
        'method': method,
        'transaction_reference': reference,
      }),
    );
    if (response.statusCode == 200) {
      return InvoiceModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to record payment: ${response.body}');
    }
  }

  // -------------------------------------------------------------
  // Dashboard Metrics
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> fetchDashboardStats() async {
    final response = await http.get(Uri.parse('$baseUrl/dashboard/stats/'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch stats: ${response.statusCode}');
    }
  }

  // -------------------------------------------------------------
  // Staff Administration (Admin)
  // -------------------------------------------------------------
  Future<List<UserModel>> fetchStaffUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/staff/'), headers: _headers);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List results = decoded is Map && decoded.containsKey('results')
          ? decoded['results']
          : (decoded as List);
      return results.map((u) => UserModel.fromJson(u)).toList();
    } else {
      throw Exception('Failed to fetch staff: ${response.statusCode}');
    }
  }

  Future<UserModel> createStaffUser({
    required String email,
    required String fullName,
    required String role,
    required String phoneNumber,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/staff/'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'full_name': fullName,
        'role': role,
        'phone_number': phoneNumber,
        'password': password,
      }),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create staff: ${response.body}');
    }
  }

  Future<UserModel> toggleStaffActive(String staffId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/staff/$staffId/toggle_active/'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to toggle staff status: ${response.body}');
    }
  }

  // -------------------------------------------------------------
  // Audit Logs (Admin)
  // -------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchAuditLogs() async {
    final response = await http.get(Uri.parse('$baseUrl/audit-logs/'), headers: _headers);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List results = decoded is Map && decoded.containsKey('results')
          ? decoded['results']
          : (decoded as List);
      return results.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch audit logs: ${response.statusCode}');
    }
  }
}

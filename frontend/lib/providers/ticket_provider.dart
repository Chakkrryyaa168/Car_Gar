import 'dart:async';
import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class TicketProvider extends ChangeNotifier {
  final ApiService apiService;
  final WebSocketService wsService;

  List<TicketModel> _tickets = [];
  TicketModel? _selectedTicket;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _wsSubscription;

  TicketProvider({required this.apiService, required this.wsService}) {
    _initWsListener();
  }

  List<TicketModel> get tickets => _tickets;
  TicketModel? get selectedTicket => _selectedTicket;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _initWsListener() {
    _wsSubscription = wsService.stream.listen((event) {
      final ticketId = event['ticket_id'];
      if (ticketId != null) {
        // Refresh the selected ticket if it's currently open
        if (_selectedTicket != null && _selectedTicket!.id == ticketId) {
          fetchTicketDetail(ticketId, showLoading: false);
        }
        // Also refresh list
        fetchTickets(showLoading: false);
      }
    });
  }

  void listenToTicket(String ticketId) {
    wsService.connect(ticketId: ticketId);
  }

  void listenToGlobal() {
    wsService.connect();
  }

  Future<void> fetchTickets({String? status, bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _tickets = await apiService.fetchTickets(status: status);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> fetchTicketDetail(String ticketId, {bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _selectedTicket = await apiService.fetchTicketDetail(ticketId);
      listenToTicket(ticketId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> batchApproveItems(String ticketId, List<Map<String, String>> approvals) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedTicket = await apiService.batchApproveItems(ticketId, approvals);
      await fetchTickets(showLoading: false);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeItem(String itemId, String ticketId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await apiService.completeTicketItem(itemId);
      await fetchTicketDetail(ticketId, showLoading: false);
      await fetchTickets(showLoading: false);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changeTicketStatus(String ticketId, String newStatus, {String remarks = ''}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedTicket = await apiService.changeTicketStatus(ticketId, newStatus, remarks: remarks);
      await fetchTickets(showLoading: false);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addDiagnosisItem({
    required String ticketId,
    required String type,
    required String description,
    required double unitPrice,
    required double quantity,
    String? inventoryItemId,
    String mechanicNotes = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await apiService.addTicketItem(
        ticketId: ticketId,
        type: type,
        description: description,
        unitPrice: unitPrice,
        quantity: quantity,
        inventoryItemId: inventoryItemId,
        mechanicNotes: mechanicNotes,
      );
      await fetchTicketDetail(ticketId, showLoading: false);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteDiagnosisItem(String itemId, String ticketId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await apiService.deleteTicketItem(itemId);
      await fetchTicketDetail(ticketId, showLoading: false);
      await fetchTickets(showLoading: false);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadPhoto({
    required String ticketId,
    required String stage,
    required String url,
    String caption = '',
    String? ticketItemId,
  }) async {
    try {
      await apiService.uploadPhoto(
        ticketId: ticketId,
        stage: stage,
        url: url,
        caption: caption,
        ticketItemId: ticketItemId,
      );
      await fetchTicketDetail(ticketId, showLoading: false);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
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
    _isLoading = true;
    notifyListeners();

    try {
      await apiService.uploadPhotoFile(
        ticketId: ticketId,
        stage: stage,
        fileBytes: fileBytes,
        fileName: fileName,
        caption: caption,
        ticketItemId: ticketItemId,
      );
      await fetchTicketDetail(ticketId, showLoading: false);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePhoto(String photoId, String ticketId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await apiService.deletePhoto(photoId);
      await fetchTicketDetail(ticketId, showLoading: false);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> recordPayment({
    required String invoiceId,
    required String ticketId,
    required double amount,
    required String method,
    String reference = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await apiService.recordPayment(
        invoiceId: invoiceId,
        amount: amount,
        method: method,
        reference: reference,
      );
      await fetchTicketDetail(ticketId, showLoading: false);
      await fetchTickets(showLoading: false);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }
}

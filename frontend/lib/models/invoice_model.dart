import 'json_helpers.dart';

class PaymentModel {
  final String id;
  final double amountPaid;
  final String method;
  final String transactionReference;
  final String? receivedByName;
  final DateTime? createdAt;

  PaymentModel({
    required this.id,
    required this.amountPaid,
    required this.method,
    required this.transactionReference,
    this.receivedByName,
    this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? '',
      amountPaid: parseDouble(json['amount_paid']),
      method: json['method'] ?? 'CASH',
      transactionReference: json['transaction_reference'] ?? '',
      receivedByName: json['received_by_name'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}

class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final String? ticketNumber;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final double amountPaid;
  final double balanceDue;
  final String status;
  final List<PaymentModel> payments;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    this.ticketNumber,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.amountPaid,
    required this.balanceDue,
    required this.status,
    required this.payments,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    var rawPayments = json['payments'] as List? ?? [];
    List<PaymentModel> paymentsList = rawPayments.map((p) => PaymentModel.fromJson(p)).toList();

    return InvoiceModel(
      id: json['id'] ?? '',
      invoiceNumber: json['invoice_number'] ?? '',
      ticketNumber: json['ticket_number'],
      subtotal: parseDouble(json['subtotal']),
      taxAmount: parseDouble(json['tax_amount']),
      discountAmount: parseDouble(json['discount_amount']),
      totalAmount: parseDouble(json['total_amount']),
      amountPaid: parseDouble(json['amount_paid']),
      balanceDue: parseDouble(json['balance_due']),
      status: json['status'] ?? 'DRAFT',
      payments: paymentsList,
    );
  }

  bool get isPaid => status == 'PAID';
}

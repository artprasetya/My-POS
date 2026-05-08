import 'package:equatable/equatable.dart';

class Transaction extends Equatable {
  final String id;
  final String transactionNumber;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final String? cashierId;
  final String? cashierName;
  final String? notes;
  final List<TransactionItem> items;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.transactionNumber,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    this.cashierId,
    this.cashierName,
    this.notes,
    this.items = const [],
    required this.createdAt,
  });

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: (json['id'] ?? '').toString(),
      transactionNumber: (json['transaction_number'] ?? 'N/A').toString(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      paymentMethod: (json['payment_method'] ?? 'cash').toString(),
      paymentStatus: (json['payment_status'] ?? 'completed').toString(),
      cashierId: json['cashier_id']?.toString(),
      cashierName: json['profiles'] != null
          ? (json['profiles'] as Map<String, dynamic>)['full_name']?.toString()
          : json['cashier_name']?.toString(),
      notes: json['notes']?.toString(),
      items: json['transaction_items'] != null
          ? (json['transaction_items'] as List)
              .map((e) => TransactionItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_number': transactionNumber,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'total': total,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'cashier_id': cashierId,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [
        id,
        transactionNumber,
        subtotal,
        discountAmount,
        taxAmount,
        total,
        paymentMethod,
        paymentStatus,
        createdAt,
      ];
}

class TransactionItem extends Equatable {
  final String id;
  final String transactionId;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final DateTime createdAt;

  const TransactionItem({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.createdAt,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: (json['id'] ?? '').toString(),
      transactionId: (json['transaction_id'] ?? '').toString(),
      productId: (json['product_id'] ?? '').toString(),
      productName: (json['product_name'] ?? 'Unknown').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
  }

  @override
  List<Object?> get props =>
      [id, transactionId, productId, quantity, unitPrice];
}

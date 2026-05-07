import 'package:equatable/equatable.dart';

class InventoryLog extends Equatable {
  final String id;
  final String productId;
  final String? productName;
  final String type; // 'in' or 'out'
  final int quantity;
  final String? notes;
  final DateTime createdAt;

  const InventoryLog({
    required this.id,
    required this.productId,
    this.productName,
    required this.type,
    required this.quantity,
    this.notes,
    required this.createdAt,
  });

  bool get isStockIn => type == 'in';
  bool get isStockOut => type == 'out';

  factory InventoryLog.fromJson(Map<String, dynamic> json) {
    return InventoryLog(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: json['products'] != null
          ? (json['products'] as Map<String, dynamic>)['name'] as String?
          : json['product_name'] as String?,
      type: json['type'] as String,
      quantity: json['quantity'] as int,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'type': type,
      'quantity': quantity,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [id, productId, type, quantity, createdAt];
}

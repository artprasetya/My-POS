import 'package:equatable/equatable.dart';

class CartItem extends Equatable {
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final String? imageUrl;
  final double discount;
  final String? selectedPriceName;
  final int stockMultiplier;

  const CartItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
    this.discount = 0,
    this.selectedPriceName,
    this.stockMultiplier = 1,
  });

  double get subtotal => unitPrice * quantity;
  double get discountAmount => subtotal * (discount / 100);
  double get total => subtotal - discountAmount;

  CartItem copyWith({
    String? productId,
    String? productName,
    double? unitPrice,
    int? quantity,
    String? imageUrl,
    double? discount,
    String? selectedPriceName,
    int? stockMultiplier,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      discount: discount ?? this.discount,
      selectedPriceName: selectedPriceName ?? this.selectedPriceName,
      stockMultiplier: stockMultiplier ?? this.stockMultiplier,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'subtotal': total,
      'selected_price_name': selectedPriceName,
      'stock_multiplier': stockMultiplier,
    };
  }

  @override
  List<Object?> get props => [
        productId,
        productName,
        unitPrice,
        quantity,
        discount,
        selectedPriceName,
        stockMultiplier,
      ];
}

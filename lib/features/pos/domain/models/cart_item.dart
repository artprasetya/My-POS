import 'package:equatable/equatable.dart';
enum DiscountType { percentage, amount }

class CartItem extends Equatable {
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final String? imageUrl;
  final double discountValue;
  final DiscountType discountType;
  final String? selectedPriceName;
  final int stockMultiplier;

  const CartItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
    this.discountValue = 0,
    this.discountType = DiscountType.percentage,
    this.selectedPriceName,
    this.stockMultiplier = 1,
  });

  double get subtotal => unitPrice * quantity;
  double get discountAmount {
    if (discountType == DiscountType.percentage) {
      return subtotal * (discountValue / 100);
    } else {
      return discountValue;
    }
  }

  double get total => subtotal - discountAmount;

  CartItem copyWith({
    String? productId,
    String? productName,
    double? unitPrice,
    int? quantity,
    String? imageUrl,
    double? discountValue,
    DiscountType? discountType,
    String? selectedPriceName,
    int? stockMultiplier,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      discountValue: discountValue ?? this.discountValue,
      discountType: discountType ?? this.discountType,
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
      'discount_value': discountValue,
      'discount_type': discountType.name,
    };
  }

  @override
  List<Object?> get props => [
        productId,
        productName,
        unitPrice,
        quantity,
        discountValue,
        discountType,
        selectedPriceName,
        stockMultiplier,
      ];
}

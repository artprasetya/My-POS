import 'package:equatable/equatable.dart';

class ProductPriceTier extends Equatable {
  final String name;
  final double price;
  final int multiplier; // Unit conversion (e.g. 1 Dus = 24 pcs, multiplier is 24)

  const ProductPriceTier({
    required this.name,
    required this.price,
    this.multiplier = 1,
  });

  factory ProductPriceTier.fromJson(Map<String, dynamic> json) {
    return ProductPriceTier(
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      multiplier: json['multiplier'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'multiplier': multiplier,
    };
  }

  @override
  List<Object?> get props => [name, price, multiplier];
}

class Product extends Equatable {
  final String id;
  final String name;
  final String? sku;
  final String? barcode;
  final String? categoryId;
  final String? categoryName;
  final double price;
  final double? costPrice;
  final int stock;
  final String? imageUrl;
  final String? description;
  final bool isActive;
  final List<ProductPriceTier>? customPrices;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.name,
    this.sku,
    this.barcode,
    this.categoryId,
    this.categoryName,
    required this.price,
    this.costPrice,
    required this.stock,
    this.imageUrl,
    this.description,
    this.isActive = true,
    this.customPrices,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => stock <= 10;
  bool get isOutOfStock => stock <= 0;
  double get profit => costPrice != null ? price - costPrice! : 0;

  factory Product.fromJson(Map<String, dynamic> json) {
    List<ProductPriceTier>? parsedCustomPrices;
    if (json['custom_prices'] != null) {
      if (json['custom_prices'] is List) {
        parsedCustomPrices = (json['custom_prices'] as List)
            .map((e) => ProductPriceTier.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      categoryId: json['category_id'] as String?,
      categoryName: json['categories'] != null
          ? (json['categories'] as Map<String, dynamic>)['name'] as String?
          : json['category_name'] as String?,
      price: (json['price'] as num).toDouble(),
      costPrice: json['cost_price'] != null
          ? (json['cost_price'] as num).toDouble()
          : null,
      stock: json['stock'] as int? ?? 0,
      imageUrl: json['image_url'] as String?,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      customPrices: parsedCustomPrices,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'category_id': categoryId,
      'price': price,
      'cost_price': costPrice,
      'stock': stock,
      'image_url': imageUrl,
      'description': description,
      'is_active': isActive,
      'custom_prices': customPrices?.map((e) => e.toJson()).toList(),
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? sku,
    String? barcode,
    String? categoryId,
    String? categoryName,
    double? price,
    double? costPrice,
    int? stock,
    String? imageUrl,
    String? description,
    bool? isActive,
    List<ProductPriceTier>? customPrices,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      customPrices: customPrices ?? this.customPrices,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, name, sku, barcode, categoryId, price,
        costPrice, stock, imageUrl, description, isActive, customPrices,
      ];
}

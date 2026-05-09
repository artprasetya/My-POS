import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pos/features/pos/domain/models/cart_item.dart';
import 'package:my_pos/features/products/domain/models/product.dart';

// ─── Events ───
abstract class CartEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CartItemAdded extends CartEvent {
  final Product product;
  CartItemAdded(this.product);

  @override
  List<Object?> get props => [product];
}

class CartItemRemoved extends CartEvent {
  final String productId;
  CartItemRemoved(this.productId);

  @override
  List<Object?> get props => [productId];
}

class CartBarcodeScanned extends CartEvent {
  final String barcode;
  final List<Product> availableProducts;
  CartBarcodeScanned(this.barcode, this.availableProducts);

  @override
  List<Object?> get props => [barcode, availableProducts];
}

class CartUpdateQuantity extends CartEvent {
  final String productId;
  final int quantity;
  CartUpdateQuantity(this.productId, this.quantity);

  @override
  List<Object?> get props => [productId, quantity];
}

class CartUpdatePriceTier extends CartEvent {
  final String productId;
  final String? priceName;
  final double unitPrice;
  final int multiplier;

  CartUpdatePriceTier(this.productId, this.priceName, this.unitPrice, this.multiplier);

  @override
  List<Object?> get props => [productId, priceName, unitPrice, multiplier];
}

class CartUpdateDiscount extends CartEvent {
  final String productId;
  final double discount;
  CartUpdateDiscount(this.productId, this.discount);

  @override
  List<Object?> get props => [productId, discount];
}

class CartSetGlobalDiscount extends CartEvent {
  final double discount;
  CartSetGlobalDiscount(this.discount);

  @override
  List<Object?> get props => [discount];
}

class CartCleared extends CartEvent {}

// ─── State ───
class CartState extends Equatable {
  final List<CartItem> items;
  final double globalDiscount; // percentage
  final double taxRate;

  const CartState({
    this.items = const [],
    this.globalDiscount = 0,
    this.taxRate = 0.0,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get globalDiscountAmount => subtotal * (globalDiscount / 100);
  double get afterDiscount => subtotal - globalDiscountAmount;
  double get taxAmount => 0.0;
  double get total => afterDiscount;
  double get totalAmount => total; // Alias for UI consistency
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    List<CartItem>? items,
    double? globalDiscount,
    double? taxRate,
  }) {
    return CartState(
      items: items ?? this.items,
      globalDiscount: globalDiscount ?? this.globalDiscount,
      taxRate: taxRate ?? this.taxRate,
    );
  }

  @override
  List<Object?> get props => [items, globalDiscount, taxRate];
}

// ─── Bloc ───
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<CartItemAdded>(_onAddItem);
    on<CartItemRemoved>(_onRemoveItem);
    on<CartUpdateQuantity>(_onUpdateQuantity);
    on<CartUpdatePriceTier>(_onUpdatePriceTier);
    on<CartUpdateDiscount>(_onUpdateDiscount);
    on<CartSetGlobalDiscount>(_onSetGlobalDiscount);
    on<CartBarcodeScanned>(_onBarcodeScanned);
    on<CartCleared>(_onClear);
  }

  void _onAddItem(CartItemAdded event, Emitter<CartState> emit) {
    final items = List<CartItem>.from(state.items);
    final existingIndex =
        items.indexWhere((item) => item.productId == event.product.id);

    if (existingIndex >= 0) {
      final existing = items[existingIndex];
      items[existingIndex] = existing.copyWith(
        quantity: existing.quantity + 1,
      );
    } else {
      items.add(CartItem(
        productId: event.product.id,
        productName: event.product.name,
        unitPrice: event.product.price,
        quantity: 1,
        imageUrl: event.product.imageUrl,
      ));
    }

    emit(state.copyWith(items: items));
  }

  void _onRemoveItem(CartItemRemoved event, Emitter<CartState> emit) {
    final items = state.items
        .where((item) => item.productId != event.productId)
        .toList();
    emit(state.copyWith(items: items));
  }

  void _onUpdateQuantity(CartUpdateQuantity event, Emitter<CartState> emit) {
    if (event.quantity <= 0) {
      add(CartItemRemoved(event.productId));
      return;
    }

    final items = state.items.map((item) {
      if (item.productId == event.productId) {
        return item.copyWith(quantity: event.quantity);
      }
      return item;
    }).toList();

    emit(state.copyWith(items: items));
  }

  void _onUpdatePriceTier(CartUpdatePriceTier event, Emitter<CartState> emit) {
    final items = state.items.map((item) {
      if (item.productId == event.productId) {
        return item.copyWith(
          selectedPriceName: event.priceName,
          unitPrice: event.unitPrice,
          stockMultiplier: event.multiplier,
        );
      }
      return item;
    }).toList();
    emit(state.copyWith(items: items));
  }

  void _onUpdateDiscount(CartUpdateDiscount event, Emitter<CartState> emit) {
    final items = state.items.map((item) {
      if (item.productId == event.productId) {
        return item.copyWith(discount: event.discount);
      }
      return item;
    }).toList();

    emit(state.copyWith(items: items));
  }

  void _onSetGlobalDiscount(
      CartSetGlobalDiscount event, Emitter<CartState> emit) {
    emit(state.copyWith(globalDiscount: event.discount));
  }

  void _onBarcodeScanned(CartBarcodeScanned event, Emitter<CartState> emit) {
    try {
      final product = event.availableProducts.firstWhere(
        (p) => p.barcode == event.barcode,
      );
      add(CartItemAdded(product));
    } catch (_) {
      // Product not found
    }
  }

  void _onClear(CartCleared event, Emitter<CartState> emit) {
    emit(const CartState());
  }
}

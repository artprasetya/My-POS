import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pos/features/pos/domain/models/cart_item.dart';
import 'package:my_pos/features/products/domain/models/product.dart';

// ─── Events ───
abstract class CartEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CartAddItem extends CartEvent {
  final Product product;
  CartAddItem(this.product);

  @override
  List<Object?> get props => [product];
}

class CartRemoveItem extends CartEvent {
  final String productId;
  CartRemoveItem(this.productId);

  @override
  List<Object?> get props => [productId];
}

class CartUpdateQuantity extends CartEvent {
  final String productId;
  final int quantity;
  CartUpdateQuantity(this.productId, this.quantity);

  @override
  List<Object?> get props => [productId, quantity];
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

class CartClear extends CartEvent {}

// ─── State ───
class CartState extends Equatable {
  final List<CartItem> items;
  final double globalDiscount; // percentage
  final double taxRate;

  const CartState({
    this.items = const [],
    this.globalDiscount = 0,
    this.taxRate = 0.11,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get globalDiscountAmount => subtotal * (globalDiscount / 100);
  double get afterDiscount => subtotal - globalDiscountAmount;
  double get taxAmount => afterDiscount * taxRate;
  double get total => afterDiscount + taxAmount;
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
    on<CartAddItem>(_onAddItem);
    on<CartRemoveItem>(_onRemoveItem);
    on<CartUpdateQuantity>(_onUpdateQuantity);
    on<CartUpdateDiscount>(_onUpdateDiscount);
    on<CartSetGlobalDiscount>(_onSetGlobalDiscount);
    on<CartClear>(_onClear);
  }

  void _onAddItem(CartAddItem event, Emitter<CartState> emit) {
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

  void _onRemoveItem(CartRemoveItem event, Emitter<CartState> emit) {
    final items = state.items
        .where((item) => item.productId != event.productId)
        .toList();
    emit(state.copyWith(items: items));
  }

  void _onUpdateQuantity(CartUpdateQuantity event, Emitter<CartState> emit) {
    if (event.quantity <= 0) {
      add(CartRemoveItem(event.productId));
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

  void _onClear(CartClear event, Emitter<CartState> emit) {
    emit(const CartState());
  }
}

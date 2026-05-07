import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pos/features/products/data/repositories/product_repository.dart';
import 'package:my_pos/features/products/domain/models/category.dart';
import 'package:my_pos/features/products/domain/models/product.dart';

// ─── Events ───
abstract class ProductEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductsLoadRequested extends ProductEvent {
  final String? categoryId;
  final String? search;

  ProductsLoadRequested({this.categoryId, this.search});

  @override
  List<Object?> get props => [categoryId, search];
}

class ProductCreateRequested extends ProductEvent {
  final Product product;
  ProductCreateRequested(this.product);

  @override
  List<Object?> get props => [product];
}

class ProductUpdateRequested extends ProductEvent {
  final Product product;
  ProductUpdateRequested(this.product);

  @override
  List<Object?> get props => [product];
}

class ProductDeleteRequested extends ProductEvent {
  final String productId;
  ProductDeleteRequested(this.productId);

  @override
  List<Object?> get props => [productId];
}

class CategoriesLoadRequested extends ProductEvent {}

// ─── States ───
abstract class ProductState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductsLoaded extends ProductState {
  final List<Product> products;
  final List<Category> categories;
  final String? selectedCategoryId;
  final String? searchQuery;

  ProductsLoaded({
    required this.products,
    this.categories = const [],
    this.selectedCategoryId,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [products, categories, selectedCategoryId, searchQuery];
}

class ProductError extends ProductState {
  final String message;
  ProductError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProductActionSuccess extends ProductState {
  final String message;
  ProductActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Bloc ───
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _repository;
  List<Category> _cachedCategories = [];

  ProductBloc({required ProductRepository repository})
      : _repository = repository,
        super(ProductInitial()) {
    on<ProductsLoadRequested>(_onLoadProducts);
    on<ProductCreateRequested>(_onCreateProduct);
    on<ProductUpdateRequested>(_onUpdateProduct);
    on<ProductDeleteRequested>(_onDeleteProduct);
    on<CategoriesLoadRequested>(_onLoadCategories);
  }

  Future<void> _onLoadProducts(
    ProductsLoadRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    try {
      final products = await _repository.getProducts(
        categoryId: event.categoryId,
        search: event.search,
        activeOnly: false,
      );
      if (_cachedCategories.isEmpty) {
        _cachedCategories = await _repository.getCategories();
      }
      emit(ProductsLoaded(
        products: products,
        categories: _cachedCategories,
        selectedCategoryId: event.categoryId,
        searchQuery: event.search,
      ));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onCreateProduct(
    ProductCreateRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      await _repository.createProduct(event.product);
      emit(ProductActionSuccess('Product created successfully'));
      add(ProductsLoadRequested());
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onUpdateProduct(
    ProductUpdateRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      await _repository.updateProduct(event.product);
      emit(ProductActionSuccess('Product updated successfully'));
      add(ProductsLoadRequested());
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onDeleteProduct(
    ProductDeleteRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      await _repository.deleteProduct(event.productId);
      emit(ProductActionSuccess('Product deleted successfully'));
      add(ProductsLoadRequested());
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onLoadCategories(
    CategoriesLoadRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      _cachedCategories = await _repository.getCategories();
      // Reload products with updated categories
      add(ProductsLoadRequested());
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }
}

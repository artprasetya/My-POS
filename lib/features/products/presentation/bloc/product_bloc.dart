import 'dart:typed_data';
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

class ProductLoadProductsRequested extends ProductEvent {
  final String? categoryId;
  final String? search;
  ProductLoadProductsRequested({this.categoryId, this.search});
  @override
  List<Object?> get props => [categoryId, search];
}

class ProductCreateRequested extends ProductEvent {
  final Product product;
  final Uint8List? imageBytes;
  final String? imageName;

  ProductCreateRequested(this.product, {this.imageBytes, this.imageName});

  @override
  List<Object?> get props => [product, imageBytes, imageName];
}

class ProductUpdateRequested extends ProductEvent {
  final Product product;
  final Uint8List? imageBytes;
  final String? imageName;

  ProductUpdateRequested(this.product, {this.imageBytes, this.imageName});

  @override
  List<Object?> get props => [product, imageBytes, imageName];
}

class ProductDeleteRequested extends ProductEvent {
  final String productId;
  ProductDeleteRequested(this.productId);
  @override
  List<Object?> get props => [productId];
}

class ProductLoadCategoriesRequested extends ProductEvent {}

class ProductCreateCategoryRequested extends ProductEvent {
  final Category category;
  ProductCreateCategoryRequested(this.category);
  @override
  List<Object?> get props => [category];
}

class ProductUpdateCategoryRequested extends ProductEvent {
  final Category category;
  ProductUpdateCategoryRequested(this.category);
  @override
  List<Object?> get props => [category];
}

class ProductDeleteCategoryRequested extends ProductEvent {
  final String categoryId;
  ProductDeleteCategoryRequested(this.categoryId);
  @override
  List<Object?> get props => [categoryId];
}

// ─── States ───
class ProductState extends Equatable {
  final List<Product> products;
  final List<Category> categories;
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final String? selectedCategoryId;
  final String? searchQuery;

  const ProductState({
    this.products = const [],
    this.categories = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.selectedCategoryId,
    this.searchQuery,
  });

  ProductState copyWith({
    List<Product>? products,
    List<Category>? categories,
    bool? isLoading,
    String? error,
    String? successMessage,
    String? selectedCategoryId,
    String? searchQuery,
  }) {
    return ProductState(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Don't persist error
      successMessage: successMessage, // Don't persist success message
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        products,
        categories,
        isLoading,
        error,
        successMessage,
        selectedCategoryId,
        searchQuery,
      ];
}

// ─── Bloc ───
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _repository;

  ProductBloc({required ProductRepository repository})
      : _repository = repository,
        super(const ProductState()) {
    on<ProductLoadProductsRequested>(_onLoadProducts);
    on<ProductCreateRequested>(_onCreateProduct);
    on<ProductUpdateRequested>(_onUpdateProduct);
    on<ProductDeleteRequested>(_onDeleteProduct);
    on<ProductLoadCategoriesRequested>(_onLoadCategories);
    on<ProductCreateCategoryRequested>(_onCreateCategory);
    on<ProductUpdateCategoryRequested>(_onUpdateCategory);
    on<ProductDeleteCategoryRequested>(_onDeleteCategory);
  }

  Future<void> _onLoadProducts(
    ProductLoadProductsRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final products = await _repository.getProducts(
        categoryId: event.categoryId,
        search: event.search,
        activeOnly: false,
      );
      
      // If categories are empty, load them too
      List<Category> categories = state.categories;
      if (categories.isEmpty) {
        categories = await _repository.getCategories();
      }

      emit(state.copyWith(
        isLoading: false,
        products: products,
        categories: categories,
        selectedCategoryId: event.categoryId,
        searchQuery: event.search,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onCreateProduct(
    ProductCreateRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      String? imageUrl = event.product.imageUrl;
      if (event.imageBytes != null && event.imageName != null) {
        imageUrl = await _repository.uploadProductImage(
          event.imageName!,
          event.imageBytes!,
        );
      }

      final product = event.product.copyWith(imageUrl: imageUrl);
      await _repository.createProduct(product);
      
      emit(state.copyWith(successMessage: 'Product created successfully'));
      add(ProductLoadProductsRequested(
        categoryId: state.selectedCategoryId,
        search: state.searchQuery,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onUpdateProduct(
    ProductUpdateRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      String? imageUrl = event.product.imageUrl;
      if (event.imageBytes != null && event.imageName != null) {
        imageUrl = await _repository.uploadProductImage(
          event.imageName!,
          event.imageBytes!,
        );
      }

      final product = event.product.copyWith(imageUrl: imageUrl);
      await _repository.updateProduct(product);
      
      emit(state.copyWith(successMessage: 'Product updated successfully'));
      add(ProductLoadProductsRequested(
        categoryId: state.selectedCategoryId,
        search: state.searchQuery,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onDeleteProduct(
    ProductDeleteRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.deleteProduct(event.productId);
      emit(state.copyWith(successMessage: 'Product deleted successfully'));
      add(ProductLoadProductsRequested(
        categoryId: state.selectedCategoryId,
        search: state.searchQuery,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadCategories(
    ProductLoadCategoriesRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final categories = await _repository.getCategories();
      emit(state.copyWith(isLoading: false, categories: categories));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onCreateCategory(
    ProductCreateCategoryRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.createCategory(event.category);
      emit(state.copyWith(successMessage: 'Category created successfully'));
      add(ProductLoadCategoriesRequested());
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onUpdateCategory(
    ProductUpdateCategoryRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.updateCategory(event.category);
      emit(state.copyWith(successMessage: 'Category updated successfully'));
      add(ProductLoadCategoriesRequested());
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onDeleteCategory(
    ProductDeleteCategoryRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.deleteCategory(event.categoryId);
      emit(state.copyWith(successMessage: 'Category deleted successfully'));
      add(ProductLoadCategoriesRequested());
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}

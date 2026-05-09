import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_pos/features/products/domain/models/category.dart';
import 'package:my_pos/features/products/domain/models/product.dart';
import 'package:my_pos/services/supabase_service.dart';

class ProductRepository {
  // ─── Products ───

  Future<List<Product>> getProducts({
    String? categoryId,
    String? search,
    bool? activeOnly,
  }) async {
    var query = SupabaseService.table('products').select('*, categories(name)');

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (search != null && search.isNotEmpty) {
      query = query.ilike('name', '%$search%');
    }
    if (activeOnly == true) {
      query = query.eq('is_active', true);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final data = await SupabaseService.table('products')
          .select('*, categories(name)')
          .eq('barcode', barcode)
          .maybeSingle();

      if (data == null) return null;
      return Product.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<Product> getProduct(String id) async {
    final data = await SupabaseService.table('products')
        .select('*, categories(name)')
        .eq('id', id)
        .maybeSingle();

    if (data == null) {
      throw Exception('Product not found');
    }
    return Product.fromJson(data);
  }

  Future<Product> createProduct(Product product) async {
    final response = await SupabaseService.table('products')
        .insert(product.toJson())
        .select('*, categories(name)');

    final data = response as List;
    if (data.isEmpty) {
      throw Exception('Failed to create product (0 rows returned)');
    }
    return Product.fromJson(data.first);
  }

  Future<Product> updateProduct(Product product) async {
    final payload = product.toJson();
    final response = await SupabaseService.table('products')
        .update(payload)
        .eq('id', product.id)
        .select();

    final data = response as List;
    if (data.isEmpty) {
      debugPrint(
          '===> Update failed (0 rows). ID: ${product.id}. Payload: $payload');
      throw Exception(
          'Update failed (0 rows). ID: ${product.id}. Payload: $payload');
    }
    
    // Fetch categories manually to keep it compatible
    final catResponse = await SupabaseService.table('categories')
        .select('name')
        .eq('id', product.categoryId!)
        .maybeSingle();
        
    if (catResponse != null) {
      data.first['categories'] = {'name': catResponse['name']};
    }

    return Product.fromJson(data.first);
  }

  Future<void> deleteProduct(String id) async {
    await SupabaseService.table('products').delete().eq('id', id);
  }

  Future<void> updateStock(String productId, int newStock) async {
    await SupabaseService.table('products')
        .update({'stock': newStock}).eq('id', productId);
  }

  // ─── Product Image ───

  Future<String> uploadProductImage(String fileName, Uint8List bytes) async {
    final path = 'products/$fileName';
    await SupabaseService.storage.from('product-images').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return SupabaseService.storage.from('product-images').getPublicUrl(path);
  }

  // ─── Categories ───

  Future<List<Category>> getCategories() async {
    final data = await SupabaseService.table('categories')
        .select()
        .order('name', ascending: true);
    return (data as List).map((e) => Category.fromJson(e)).toList();
  }

  Future<Category> createCategory(Category category) async {
    final data = await SupabaseService.table('categories')
        .insert(category.toJson())
        .select()
        .maybeSingle();

    if (data == null) {
      throw Exception('Failed to create category');
    }
    return Category.fromJson(data);
  }

  Future<Category> updateCategory(Category category) async {
    final data = await SupabaseService.table('categories')
        .update(category.toJson())
        .eq('id', category.id)
        .select()
        .maybeSingle();

    if (data == null) {
      throw Exception('Category not found');
    }
    return Category.fromJson(data);
  }

  Future<void> deleteCategory(String id) async {
    await SupabaseService.table('categories').delete().eq('id', id);
  }
}

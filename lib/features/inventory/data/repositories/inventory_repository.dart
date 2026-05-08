import 'package:my_pos/features/inventory/domain/models/inventory_log.dart';
import 'package:my_pos/services/supabase_service.dart';

class InventoryRepository {
  Future<List<InventoryLog>> getInventoryLogs({String? productId}) async {
    var query = SupabaseService.table('inventory_logs')
        .select('*, products(name)');
    
    if (productId != null) {
      query = query.eq('product_id', productId);
    }

    final data = await query.order('created_at', ascending: false).limit(100);
    return (data as List).map((e) => InventoryLog.fromJson(e)).toList();
  }

  Future<void> adjustStock({
    required String productId,
    required int quantity,
    required String type, // 'in' or 'out'
    required String reason,
  }) async {
    // 1. Get current stock
    final productData = await SupabaseService.table('products')
        .select('stock')
        .eq('id', productId)
        .single();
    
    final currentStock = productData['stock'] as int;
    final newStock = type == 'in' ? currentStock + quantity : currentStock - quantity;

    // 2. Update product stock
    await SupabaseService.table('products')
        .update({'stock': newStock})
        .eq('id', productId);

    // 3. Create inventory log
    await SupabaseService.table('inventory_logs').insert({
      'product_id': productId,
      'type': type,
      'quantity': quantity,
      'notes': reason,
    });
  }
}

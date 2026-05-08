import 'package:my_pos/features/pos/domain/models/cart_item.dart';
import 'package:my_pos/features/transactions/domain/models/transaction.dart';
import 'package:my_pos/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

class TransactionRepository {
  final _uuid = const Uuid();

  // ─── Create Transaction ───
  Future<Transaction> createTransaction({
    required List<CartItem> items,
    required double subtotal,
    required double discountAmount,
    required double taxAmount,
    required double total,
    required String paymentMethod,
    String? notes,
  }) async {
    final transactionNumber = _generateTransactionNumber();
    final cashierId = SupabaseService.currentUser?.id;

    // Insert transaction
    final txnData = await SupabaseService.table('transactions').insert({
      'transaction_number': transactionNumber,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'total': total,
      'payment_method': paymentMethod,
      'payment_status': 'completed',
      'cashier_id': cashierId,
      'notes': notes,
    }).select().single();

    final transactionId = txnData['id'] as String;

    // Insert transaction items
    final itemsData = items.map((item) => {
          ...item.toJson(),
          'transaction_id': transactionId,
        }).toList();

    await SupabaseService.table('transaction_items').insert(itemsData);

    // Update product stock
    for (final item in items) {
      await SupabaseService.client.rpc('decrement_stock', params: {
        'p_product_id': item.productId,
        'p_quantity': item.quantity,
      }).catchError((_) async {
        // Fallback: manual stock update
        final product = await SupabaseService.table('products')
            .select('stock')
            .eq('id', item.productId)
            .single();
        final currentStock = product['stock'] as int;
        await SupabaseService.table('products')
            .update({'stock': currentStock - item.quantity})
            .eq('id', item.productId);
      });
    }

    // Log inventory
    for (final item in items) {
      await SupabaseService.table('inventory_logs').insert({
        'product_id': item.productId,
        'type': 'out',
        'quantity': item.quantity,
        'notes': 'Sale: $transactionNumber',
      });
    }

    return Transaction.fromJson({
      ...txnData,
      'transaction_items': itemsData,
    });
  }

  // ─── Get Transactions ───
  Future<List<Transaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    int limit = 50,
  }) async {
    var query = SupabaseService.table('transactions')
        .select('*, transaction_items(*)');

    if (startDate != null) {
      query = query.gte('created_at', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('created_at', endDate.toIso8601String());
    }
    if (search != null && search.isNotEmpty) {
      query = query.ilike('transaction_number', '%$search%');
    }

    final data = await query
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List).map((e) => Transaction.fromJson(e)).toList();
  }

  // ─── Get Transaction Detail ───
  Future<Transaction> getTransaction(String id) async {
    final data = await SupabaseService.table('transactions')
        .select('*, transaction_items(*)')
        .eq('id', id)
        .single();
    return Transaction.fromJson(data);
  }

  // ─── Dashboard Data ───
  Future<Map<String, dynamic>> getDashboardData() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    // Today's sales
    final todayData = await SupabaseService.table('transactions')
        .select('total')
        .gte('created_at', startOfDay.toIso8601String())
        .eq('payment_status', 'completed');

    final todaySales = (todayData as List)
        .fold<double>(0, (sum, e) => sum + (e['total'] as num).toDouble());

    // Weekly sales
    final weekData = await SupabaseService.table('transactions')
        .select('total')
        .gte('created_at', startOfWeek.toIso8601String())
        .eq('payment_status', 'completed');

    final weeklySales = (weekData as List)
        .fold<double>(0, (sum, e) => sum + (e['total'] as num).toDouble());

    // Monthly sales
    final monthData = await SupabaseService.table('transactions')
        .select('total')
        .gte('created_at', startOfMonth.toIso8601String())
        .eq('payment_status', 'completed');

    final monthlySales = (monthData as List)
        .fold<double>(0, (sum, e) => sum + (e['total'] as num).toDouble());

    // Transaction count today
    final todayCount = (todayData as List).length;

    // Total revenue (all time)
    final allData = await SupabaseService.table('transactions')
        .select('total')
        .eq('payment_status', 'completed');

    final totalRevenue = (allData as List)
        .fold<double>(0, (sum, e) => sum + (e['total'] as num).toDouble());

    return {
      'today_sales': todaySales,
      'weekly_sales': weeklySales,
      'monthly_sales': monthlySales,
      'total_revenue': totalRevenue,
      'today_count': todayCount,
      'total_transactions': (allData as List).length,
    };
  }

  // ─── Best Selling Products ───
  Future<List<Map<String, dynamic>>> getBestSellingProducts({int limit = 5}) async {
    final data = await SupabaseService.table('transaction_items')
        .select('product_id, product_name, quantity')
        .order('created_at', ascending: false)
        .limit(200);

    // Aggregate by product
    final Map<String, Map<String, dynamic>> aggregated = {};
    for (final item in data as List) {
      final productId = item['product_id'] as String;
      if (aggregated.containsKey(productId)) {
        aggregated[productId]!['total_quantity'] =
            (aggregated[productId]!['total_quantity'] as int) +
                (item['quantity'] as int);
      } else {
        aggregated[productId] = {
          'product_id': productId,
          'product_name': item['product_name'],
          'total_quantity': item['quantity'] as int,
        };
      }
    }

    final sorted = aggregated.values.toList()
      ..sort((a, b) =>
          (b['total_quantity'] as int).compareTo(a['total_quantity'] as int));

    return sorted.take(limit).toList();
  }

  // ─── Daily Sales for Chart ───
  Future<List<Map<String, dynamic>>> getDailySales({int days = 7}) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day - days + 1);

    final data = await SupabaseService.table('transactions')
        .select('total, created_at')
        .gte('created_at', startDate.toIso8601String())
        .eq('payment_status', 'completed')
        .order('created_at', ascending: true);

    // Aggregate by day
    final Map<String, double> dailyMap = {};
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      dailyMap[key] = 0;
    }

    for (final item in data as List) {
      final date = DateTime.parse(item['created_at'] as String);
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      dailyMap[key] = (dailyMap[key] ?? 0) + (item['total'] as num).toDouble();
    }

    return dailyMap.entries
        .map((e) => {'date': e.key, 'total': e.value})
        .toList();
  }

  // ─── Helper ───
  String _generateTransactionNumber() {
    final now = DateTime.now();
    final datePart =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final uniquePart = _uuid.v4().substring(0, 6).toUpperCase();
    return 'TXN-$datePart-$uniquePart';
  }
}

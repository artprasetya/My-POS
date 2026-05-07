class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'My POS';
  static const String appVersion = '1.0.0';

  // Currency
  static const String defaultCurrency = 'IDR';
  static const String currencySymbol = 'Rp';
  static const int currencyDecimalDigits = 0;

  // Tax
  static const double defaultTaxRate = 0.11; // 11% PPN

  // Pagination
  static const int defaultPageSize = 20;

  // Stock
  static const int lowStockThreshold = 10;

  // Payment Methods
  static const String paymentCash = 'cash';
  static const String paymentQris = 'qris';
  static const String paymentCard = 'card';
  static const String paymentEwallet = 'ewallet';

  // Roles
  static const String roleAdmin = 'admin';
  static const String roleCashier = 'cashier';

  // Storage Buckets
  static const String productImagesBucket = 'product-images';
  static const String storeLogoBucket = 'store-logos';
}

import 'package:intl/intl.dart';
import 'package:my_pos/core/constants/app_constants.dart';

extension CurrencyExtension on num {
  /// Format number as IDR currency: Rp 150.000
  String toCurrency() {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '${AppConstants.currencySymbol} ',
      decimalDigits: AppConstants.currencyDecimalDigits,
    );
    return formatter.format(this);
  }

  /// Format as compact number: 1.5K, 2.3M
  String toCompact() {
    final formatter = NumberFormat.compact(locale: 'id_ID');
    return formatter.format(this);
  }

  /// Format with thousand separators: 150.000
  String toThousands() {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(this);
  }
}

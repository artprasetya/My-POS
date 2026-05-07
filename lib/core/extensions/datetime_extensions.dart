import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  /// Format: 7 May 2026
  String toFormattedDate() {
    return DateFormat('d MMM yyyy').format(this);
  }

  /// Format: 07/05/2026
  String toShortDate() {
    return DateFormat('dd/MM/yyyy').format(this);
  }

  /// Format: 14:30
  String toTime() {
    return DateFormat('HH:mm').format(this);
  }

  /// Format: 7 May 2026, 14:30
  String toFullDateTime() {
    return DateFormat('d MMM yyyy, HH:mm').format(this);
  }

  /// Format: 07 May
  String toDayMonth() {
    return DateFormat('dd MMM').format(this);
  }

  /// Check if same day
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Get start of day
  DateTime get startOfDay => DateTime(year, month, day);

  /// Get end of day
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);

  /// Get start of week (Monday)
  DateTime get startOfWeek {
    final daysToSubtract = weekday - 1;
    return DateTime(year, month, day - daysToSubtract);
  }

  /// Get start of month
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// Format relative time: "Just now", "5m ago", "2h ago", "Yesterday"
  String toRelativeTime() {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 2) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return toFormattedDate();
  }
}

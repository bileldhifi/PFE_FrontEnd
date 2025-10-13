import 'package:intl/intl.dart';

class DateTimeUtils {
  DateTimeUtils._();

  /// Format date as "Jan 15, 2024"
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Format date as "15/01/2024"
  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format time as "2:30 PM"
  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  /// Format date and time as "Jan 15, 2024 at 2:30 PM"
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy \'at\' h:mm a').format(date);
  }

  /// Format date range as "Jan 15 - Jan 20, 2024"
  static String formatDateRange(DateTime start, DateTime? end) {
    if (end == null) {
      return '${formatDate(start)} - Present';
    }
    
    if (start.year == end.year) {
      if (start.month == end.month) {
        return '${DateFormat('MMM dd').format(start)} - ${DateFormat('dd, yyyy').format(end)}';
      }
      return '${DateFormat('MMM dd').format(start)} - ${formatDate(end)}';
    }
    
    return '${formatDate(start)} - ${formatDate(end)}';
  }

  /// Get relative time like "2 hours ago", "3 days ago"
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  /// Check if date is this week
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
           date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// Calculate trip duration
  static String getTripDuration(DateTime start, DateTime? end) {
    final endDate = end ?? DateTime.now();
    final duration = endDate.difference(start);
    
    if (duration.inDays == 0) {
      return '1 day';
    } else if (duration.inDays < 30) {
      final days = duration.inDays + 1;
      return '$days days';
    } else if (duration.inDays < 365) {
      final months = (duration.inDays / 30).floor();
      final remainingDays = duration.inDays % 30;
      if (remainingDays == 0) {
        return '$months ${months == 1 ? 'month' : 'months'}';
      }
      return '$months ${months == 1 ? 'month' : 'months'}, $remainingDays ${remainingDays == 1 ? 'day' : 'days'}';
    } else {
      final years = (duration.inDays / 365).floor();
      final remainingMonths = ((duration.inDays % 365) / 30).floor();
      if (remainingMonths == 0) {
        return '$years ${years == 1 ? 'year' : 'years'}';
      }
      return '$years ${years == 1 ? 'year' : 'years'}, $remainingMonths ${remainingMonths == 1 ? 'month' : 'months'}';
    }
  }
}


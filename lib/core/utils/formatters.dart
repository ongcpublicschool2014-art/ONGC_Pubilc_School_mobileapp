import 'package:intl/intl.dart';

/// Formatting utilities
class Formatters {
  Formatters._();

  // Currency formatter for Indian Rupees
  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Format amount as Indian Rupees
  static String currency(double amount) {
    return _currencyFormat.format(amount);
  }

  /// Format amount as compact Indian Rupees (e.g., ₹1.5L)
  static String currencyCompact(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    }
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} L';
    }
    if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)} K';
    }
    return _currencyFormat.format(amount);
  }

  /// Format date as DD/MM/YYYY
  static String date(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format date as DD MMM YYYY (e.g., 15 Jan 2024)
  static String dateShort(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Format date as Day, DD MMM YYYY (e.g., Monday, 15 Jan 2024)
  static String dateFull(DateTime date) {
    return DateFormat('EEEE, dd MMM yyyy').format(date);
  }

  /// Format date as Month Year (e.g., January 2024)
  static String monthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  /// Format time as HH:MM AM/PM
  static String time(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  /// Format date and time
  static String dateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  /// Format mobile number with country code
  static String mobileWithCountryCode(String mobile) {
    if (mobile.startsWith('+91')) {
      return mobile;
    }
    return '+91 $mobile';
  }

  /// Format mobile number with spaces
  static String mobileFormatted(String mobile) {
    if (mobile.length != 10) return mobile;
    return '${mobile.substring(0, 5)} ${mobile.substring(5)}';
  }

  /// Format payment number
  static String paymentNumber(String number) {
    return number.toUpperCase();
  }

  /// Format admission number
  static String admissionNumber(String number) {
    return number.toUpperCase();
  }

  /// Get relative time (e.g., "2 hours ago", "Yesterday")
  static String relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return dateShort(dateTime);
    } else if (difference.inDays > 1) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inHours > 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inHours == 1) {
      return '1 hour ago';
    } else if (difference.inMinutes > 1) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  /// Format due date with status
  static String dueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.isNegative) {
      final daysPast = difference.inDays.abs();
      if (daysPast == 0) {
        return 'Due today';
      } else if (daysPast == 1) {
        return 'Overdue by 1 day';
      } else {
        return 'Overdue by $daysPast days';
      }
    } else {
      final daysLeft = difference.inDays;
      if (daysLeft == 0) {
        return 'Due today';
      } else if (daysLeft == 1) {
        return 'Due tomorrow';
      } else if (daysLeft <= 7) {
        return 'Due in $daysLeft days';
      } else {
        return 'Due on ${dateShort(dueDate)}';
      }
    }
  }
}

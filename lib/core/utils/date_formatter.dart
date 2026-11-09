import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _displayFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _shortFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _monthYearFormat = DateFormat('MMM yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return _displayFormat.format(date);
  }

  static String formatShortDate(DateTime? date) {
    if (date == null) return '-';
    return _shortFormat.format(date);
  }

  static String formatMonthYear(DateTime? date) {
    if (date == null) return '-';
    return _monthYearFormat.format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return _dateTimeFormat.format(date);
  }

  /// Calculates +N months properly clamping day-of-month to month end if necessary
  /// (e.g., Aug 31 + 6 months -> Feb 28 or 29, not March 3)
  static DateTime addMonths(DateTime date, int monthsToAdd) {
    int newYear = date.year + ((date.month + monthsToAdd - 1) ~/ 12);
    int newMonth = ((date.month + monthsToAdd - 1) % 12) + 1;

    // Find the last day of target month
    int daysInTargetMonth = DateTime(newYear, newMonth + 1, 0).day;
    int newDay = date.day > daysInTargetMonth ? daysInTargetMonth : date.day;

    return DateTime(newYear, newMonth, newDay, date.hour, date.minute, date.second);
  }

  /// Calculates remaining days from now until target date. Negative means overdue.
  static int daysRemaining(DateTime targetDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return target.difference(today).inDays;
  }

  /// Formats human-friendly remaining duration (years, months, days)
  static String formatRemainingDays(DateTime targetDate) {
    final days = daysRemaining(targetDate);
    if (days < 0) {
      final absDays = days.abs();
      return _formatPeriodString(absDays);
    } else if (days == 0) {
      return 'Due Today';
    } else if (days == 1) {
      return 'Due tomorrow';
    } else {
      return '${_formatPeriodString(days)} left';
    }
  }

  static String _formatPeriodString(int totalDays) {
    if (totalDays >= 365) {
      final years = totalDays ~/ 365;
      final remainingDays = totalDays % 365;
      final months = remainingDays ~/ 30;
      if (months > 0) {
        return '$years yr${years > 1 ? 's' : ''} $months mo${months > 1 ? 's' : ''}';
      }
      return '$years year${years > 1 ? 's' : ''}';
    }
    return '$totalDays day${totalDays != 1 ? 's' : ''}';
  }

  /// Check if date is overdue relative to start of today
  static bool isOverdue(DateTime targetDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return target.isBefore(today);
  }

  /// Check if date is within next 30 days
  static bool isDueSoon(DateTime targetDate) {
    final days = daysRemaining(targetDate);
    return days >= 0 && days <= 30;
  }
}


abstract final class AppDateUtils {
  static bool isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static DateTime startOfWeek(DateTime date) {
    final DateTime day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  static bool isSameWeek(DateTime a, DateTime b) {
    final DateTime startA = startOfWeek(a);
    final DateTime startB = startOfWeek(b);
    return isSameDate(startA, startB);
  }

  static String formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  static String formatDateTime(DateTime date) =>
      '${formatDate(date)} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}

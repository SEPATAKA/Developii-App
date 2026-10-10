abstract final class AppDateFormat {
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static String longDate(DateTime date) =>
      '${_months[date.month - 1]} ${date.day}, ${date.year}';

  static String dayFirstDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')} ${_months[date.month - 1]} ${date.year}';

  static String relativeDayDate(DateTime date, {required DateTime now}) {
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final prefix = day == today
        ? 'Today, '
        : day == yesterday
        ? 'Yesterday, '
        : '';
    return '$prefix${dayFirstDate(date)}';
  }

  static String slashDate(DateTime? date) => date == null
      ? ''
      : '${date.day.toString().padLeft(2, '0')} / ${_months[date.month - 1]} / ${date.year}';

  static String monthYear(DateTime date) =>
      '${_months[date.month - 1].substring(0, 3)} ${date.year}';

  static String dayMonth(DateTime date) =>
      '${date.day} ${_months[date.month - 1]}';

  static String time12(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute${date.hour < 12 ? 'AM' : 'PM'}';
  }
}

/// Date formatting utility in French without heavy external dependencies
class AppDateFormatter {
  AppDateFormatter._();

  static const List<String> _monthsShort = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
  ];

  static const List<String> _monthsFull = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  static String formatShort(DateTime? date) {
    if (date == null) return 'N/A';
    final day = date.day;
    final month = _monthsShort[date.month - 1];
    final year = date.year;
    return '$day $month $year';
  }

  static String formatFull(DateTime? date) {
    if (date == null) return 'N/A';
    final day = date.day;
    final month = _monthsFull[date.month - 1];
    final year = date.year;
    return '$day $month $year';
  }

  static String formatWithTime(DateTime? date) {
    if (date == null) return 'N/A';
    final shortDate = formatShort(date);
    final hours = date.hour.toString().padLeft(2, '0');
    final minutes = date.minute.toString().padLeft(2, '0');
    return '$shortDate - $hours:$minutes';
  }

  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return "À l'instant";
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} j';
    } else {
      return formatShort(date);
    }
  }
}

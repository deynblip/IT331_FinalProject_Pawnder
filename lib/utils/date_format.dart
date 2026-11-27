const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Short date such as "Nov 27, 2026".
String formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

/// Time such as "8:05 PM".
String formatTime(DateTime d) {
  final int hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final String minute = d.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${d.hour < 12 ? 'AM' : 'PM'}';
}

/// Date and time such as "Nov 27, 2026, 8:05 PM".
String formatDateTime(DateTime d) => '${formatDate(d)}, ${formatTime(d)}';
const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Short date such as "Nov 27, 2026".
String formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';
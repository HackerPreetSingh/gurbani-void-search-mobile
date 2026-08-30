import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSelectorTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const DateSelectorTile({
    super.key,
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: Text(DateFormat('yyyy-MM-dd').format(date)),
      trailing: const Icon(Icons.calendar_today, color: Colors.teal),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }
}

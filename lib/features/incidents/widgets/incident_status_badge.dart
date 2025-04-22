import 'package:flutter/material.dart';

class IncidentStatusBadge extends StatelessWidget {
  final String status;

  const IncidentStatusBadge({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status) {
      case 'reported':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        displayText = 'Reported';
        break;
      case 'in_progress':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        displayText = 'In Progress';
        break;
      case 'resolved':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        displayText = 'Resolved';
        break;
      case 'closed':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        displayText = 'Closed';
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        displayText = status
            .split('_')
            .map(
              (word) => word.substring(0, 1).toUpperCase() + word.substring(1),
            )
            .join(' ');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

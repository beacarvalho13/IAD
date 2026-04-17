import 'package:flutter/material.dart';

// Widget that represents a card for a sensor value, showing an icon, title and the value

class SensorTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const SensorTile({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) { // Visual layout
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, size: 40),
        title: Text(title),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
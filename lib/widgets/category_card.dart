import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.name,
    required this.amount,
    required this.icon,
  });

  final String name;
  final double amount;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE4F6EE),
          child: Icon(icon, color: const Color(0xFF138A5B)),
        ),
        title: Text(name),
        trailing: Text('\$${amount.toStringAsFixed(2)}'),
      ),
    );
  }
}

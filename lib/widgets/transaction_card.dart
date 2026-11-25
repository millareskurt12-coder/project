import 'package:flutter/material.dart';

import '../models/transaction_model.dart';

class TransactionCard extends StatelessWidget {
  const TransactionCard({super.key, required this.transaction, this.onTap});

  final TransactionModel transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'Income';
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isIncome
              ? const Color(0xFFE4F6EE)
              : const Color(0xFFFFEFEA),
          child: Icon(
            isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
            color: isIncome ? const Color(0xFF138A5B) : const Color(0xFFCA5B48),
          ),
        ),
        title: Text(
          transaction.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('${transaction.category} · ${transaction.date}'),
        trailing: Text(
          '${isIncome ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isIncome ? const Color(0xFF138A5B) : const Color(0xFF28364A),
          ),
        ),
      ),
    );
  }
}

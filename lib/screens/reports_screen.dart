import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/budget_model.dart';
import '../widgets/category_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.userId, this.database});

  final int userId;
  final DatabaseHelper? database;

  DatabaseHelper get _database => database ?? DatabaseHelper.instance;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<_ReportData> _reportFuture;
  final _budgetController = TextEditingController();

  String get _month {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _reportFuture = _loadReport();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<_ReportData> _loadReport() async {
    final database = widget._database;
    final transactions = await database.getTransactions(widget.userId);
    final monthTransactions = transactions.where(
      (transaction) => transaction.date.startsWith(_month),
    );
    final expenses = monthTransactions
        .where((transaction) => transaction.type == 'Expense')
        .toList();
    final spent = expenses.fold<double>(
      0,
      (total, transaction) => total + transaction.amount,
    );
    final budget = await database.getBudget(widget.userId, _month);
    final categories = <String, double>{};
    for (final transaction in expenses) {
      categories.update(
        transaction.category,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    return _ReportData(
      spent: spent,
      budget: budget,
      categories: categories,
      expenseCount: expenses.length,
    );
  }

  Future<void> _editBudget(BudgetModel? current) async {
    _budgetController.text = current?.amount.toStringAsFixed(2) ?? '';
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Monthly budget'),
        content: TextField(
          controller: _budgetController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Budget amount',
            prefixText: '\$ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(_budgetController.text.trim());
              if (parsed == null || !parsed.isFinite || parsed <= 0) return;
              Navigator.pop(context, parsed);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (amount == null) return;
    try {
      await widget._database.saveBudget(
        BudgetModel(userId: widget.userId, amount: amount, month: _month),
      );
      if (mounted) setState(() => _reportFuture = _loadReport());
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save budget: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: FutureBuilder<_ReportData>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load reports: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final report = snapshot.data!;
          final budget = report.budget?.amount ?? 0;
          final progress = budget == 0
              ? 0.0
              : (report.spent / budget).clamp(0, 1).toDouble();
          final categoryEntries = report.categories.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text(
                'This month',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text('$_month · ${report.expenseCount} expenses'),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Monthly budget'),
                          IconButton(
                            tooltip: 'Set monthly budget',
                            onPressed: () => _editBudget(report.budget),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
                      ),
                      Text(
                        '\$${report.spent.toStringAsFixed(2)} spent',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        budget == 0
                            ? 'Set a budget to track your progress.'
                            : 'of \$${budget.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
                        color: report.spent > budget && budget > 0
                            ? const Color(0xFFCA5B48)
                            : const Color(0xFF138A5B),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Spending by category',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (categoryEntries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No spending recorded this month.'),
                  ),
                )
              else
                ...categoryEntries.map(
                  (entry) => CategoryCard(
                    name: entry.key,
                    amount: entry.value,
                    icon: _categoryIcon(entry.key),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  IconData _categoryIcon(String category) => switch (category) {
    'Food' => Icons.restaurant_outlined,
    'Transport' => Icons.directions_car_outlined,
    'Shopping' => Icons.shopping_bag_outlined,
    'Bills' => Icons.receipt_outlined,
    'Health' => Icons.favorite_border_rounded,
    'Entertainment' => Icons.movie_outlined,
    _ => Icons.category_outlined,
  };
}

class _ReportData {
  const _ReportData({
    required this.spent,
    required this.budget,
    required this.categories,
    required this.expenseCount,
  });

  final double spent;
  final BudgetModel? budget;
  final Map<String, double> categories;
  final int expenseCount;
}

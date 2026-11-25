import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/transaction_model.dart';

class EditTransactionScreen extends StatefulWidget {
  const EditTransactionScreen({
    super.key,
    required this.transaction,
    this.database,
  });

  final TransactionModel transaction;
  final DatabaseHelper? database;

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late String _type;
  late String _category;
  late String _date;
  bool _saving = false;
  String? _error;
  final _categories = const [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Health',
    'Entertainment',
    'Salary',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    _titleController = TextEditingController(text: transaction.title);
    _amountController = TextEditingController(
      text: transaction.amount.toString(),
    );
    _descriptionController = TextEditingController(
      text: transaction.description,
    );
    _type = transaction.type;
    _category = _categories.contains(transaction.category)
        ? transaction.category
        : 'Other';
    _date = transaction.date;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final old = widget.transaction;
      await (widget.database ?? DatabaseHelper.instance).updateTransaction(
        TransactionModel(
          id: old.id,
          userId: old.userId,
          title: _titleController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          type: _type,
          category: _category,
          date: _date,
          description: _descriptionController.text.trim(),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not update transaction: $error');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _chooseDate() async {
    final current = DateTime.tryParse(_date) ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) {
      setState(() => _date = selected.toIso8601String().substring(0, 10));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit transaction')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Expense', label: Text('Expense')),
                ButtonSegment(value: 'Income', label: Text('Income')),
              ],
              selected: {_type},
              onSelectionChanged: (selection) =>
                  setState(() => _type = selection.first),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a title.'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
              ),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');
                return amount == null || !amount.isFinite || amount <= 0
                    ? 'Enter an amount greater than zero.'
                    : null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(_date),
              trailing: IconButton(
                onPressed: _chooseDate,
                icon: const Icon(Icons.calendar_month_outlined),
              ),
            ),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Color(0xFFB3261E))),
            ],
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BudgetModel {
  const BudgetModel({
    this.id,
    required this.userId,
    required this.amount,
    required this.month,
  });

  final int? id;
  final int userId;
  final double amount;
  final String month;

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'amount': amount,
    'month': month,
  };

  factory BudgetModel.fromMap(Map<String, Object?> map) {
    return BudgetModel(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      month: map['month'] as String,
    );
  }
}

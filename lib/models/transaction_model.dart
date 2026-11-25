class TransactionModel {
  const TransactionModel({
    this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.description = '',
  });

  final int? id;
  final int userId;
  final String title;
  final double amount;
  final String type;
  final String category;
  final String date;
  final String description;

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'title': title,
    'amount': amount,
    'type': type,
    'category': category,
    'date': date,
    'description': description,
  };

  factory TransactionModel.fromMap(Map<String, Object?> map) {
    return TransactionModel(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      category: map['category'] as String,
      date: map['date'] as String,
      description: map['description'] as String? ?? '',
    );
  }
}

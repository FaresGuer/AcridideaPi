class FeedingSchedule {
  final int? id;
  final DateTime dateTime;
  final double amount;

  const FeedingSchedule({
    this.id,
    required this.dateTime,
    required this.amount,
  });

  factory FeedingSchedule.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    final parsedAmount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse(rawAmount?.toString() ?? '') ?? 0;

    return FeedingSchedule(
      id: json['id'] as int?,
      dateTime: DateTime.parse((json['feeding_at'] ?? json['dateTime']) as String),
      amount: parsedAmount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'feeding_at': dateTime.toIso8601String(),
      'amount': amount,
    };
  }
}


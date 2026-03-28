class FieldSlot {
  final String id;
  final String fieldId;
  final DateTime startTime;
  final DateTime endTime;
  final double price;
  final bool isAvailable;

  FieldSlot({
    required this.id,
    required this.fieldId,
    required this.startTime,
    required this.endTime,
    required this.price,
    this.isAvailable = true,
  });

  factory FieldSlot.fromJson(Map<String, dynamic> json) {
    return FieldSlot(
      id: json['id'] as String,
      fieldId: json['field_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      price: (json['price'] as num).toDouble(),
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }
}

class Booking {
  final String id;
  final String fieldId;
  final String userId;
  final String slotId;
  final String status;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.fieldId,
    required this.userId,
    required this.slotId,
    required this.status,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      fieldId: json['field_id'] as String,
      userId: json['user_id'] as String,
      slotId: json['slot_id'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class Payment {
  final String id;
  final String userId;
  final double amount;
  final String status;
  final String method;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.userId,
    required this.amount,
    required this.status,
    required this.method,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      method: json['method'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

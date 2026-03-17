import 'package:json_annotation/json_annotation.dart';

part 'booking.g.dart';

@JsonSerializable()
class Booking {
  final String id;
  @JsonKey(name: 'field_id')
  final String fieldId;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'start_time')
  final String startTime;
  @JsonKey(name: 'end_time')
  final String endTime;
  final String status;
  @JsonKey(name: 'total_price')
  final double totalPrice;

  Booking({
    required this.id,
    required this.fieldId,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.totalPrice,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => _$BookingFromJson(json);
  Map<String, dynamic> toJson() => _$BookingToJson(this);
}

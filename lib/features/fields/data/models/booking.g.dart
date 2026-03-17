// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Booking _$BookingFromJson(Map<String, dynamic> json) => Booking(
  id: json['id'] as String,
  fieldId: json['field_id'] as String,
  userId: json['user_id'] as String,
  startTime: json['start_time'] as String,
  endTime: json['end_time'] as String,
  status: json['status'] as String,
  totalPrice: (json['total_price'] as num).toDouble(),
);

Map<String, dynamic> _$BookingToJson(Booking instance) => <String, dynamic>{
  'id': instance.id,
  'field_id': instance.fieldId,
  'user_id': instance.userId,
  'start_time': instance.startTime,
  'end_time': instance.endTime,
  'status': instance.status,
  'total_price': instance.totalPrice,
};

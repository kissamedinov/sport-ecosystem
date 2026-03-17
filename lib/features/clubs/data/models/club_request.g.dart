// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'club_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClubRequest _$ClubRequestFromJson(Map<String, dynamic> json) => ClubRequest(
  id: json['id'] as String,
  name: json['name'] as String,
  city: json['city'] as String,
  address: json['address'] as String,
  trainingSchedule: json['training_schedule'] as String?,
  contactPhone: json['contact_phone'] as String?,
  socialLinks: json['social_links'] as String?,
  description: json['description'] as String?,
  createdBy: json['created_by'] as String,
  status: $enumDecode(_$RequestStatusEnumMap, json['status']),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$ClubRequestToJson(ClubRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'city': instance.city,
      'address': instance.address,
      'training_schedule': instance.trainingSchedule,
      'contact_phone': instance.contactPhone,
      'social_links': instance.socialLinks,
      'description': instance.description,
      'created_by': instance.createdBy,
      'status': _$RequestStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$RequestStatusEnumMap = {
  RequestStatus.pending: 'PENDING',
  RequestStatus.approved: 'APPROVED',
  RequestStatus.rejected: 'REJECTED',
};

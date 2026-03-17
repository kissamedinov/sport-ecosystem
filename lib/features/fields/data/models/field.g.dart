// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'field.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Field _$FieldFromJson(Map<String, dynamic> json) => Field(
  id: json['id'] as String,
  name: json['name'] as String,
  location: json['location'] as String,
  ownerId: json['owner_id'] as String,
);

Map<String, dynamic> _$FieldToJson(Field instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'location': instance.location,
  'owner_id': instance.ownerId,
};

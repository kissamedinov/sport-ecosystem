import 'package:json_annotation/json_annotation.dart';

part 'field.g.dart';

@JsonSerializable()
class Field {
  final String id;
  final String name;
  final String location;
  @JsonKey(name: 'owner_id')
  final String ownerId;

  Field({
    required this.id,
    required this.name,
    required this.location,
    required this.ownerId,
  });

  factory Field.fromJson(Map<String, dynamic> json) => _$FieldFromJson(json);
  Map<String, dynamic> toJson() => _$FieldToJson(this);
}

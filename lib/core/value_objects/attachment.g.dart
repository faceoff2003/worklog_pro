// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AttachmentImpl _$$AttachmentImplFromJson(Map<String, dynamic> json) =>
    _$AttachmentImpl(
      type: $enumDecode(_$AttachmentTypeEnumMap, json['type']),
      storagePath: json['storagePath'] as String,
      name: json['name'] as String,
      note: json['note'] as String?,
      sizeBytes: (json['sizeBytes'] as num).toInt(),
    );

Map<String, dynamic> _$$AttachmentImplToJson(_$AttachmentImpl instance) =>
    <String, dynamic>{
      'type': instance.type.toJson(),
      'storagePath': instance.storagePath,
      'name': instance.name,
      'note': instance.note,
      'sizeBytes': instance.sizeBytes,
    };

const _$AttachmentTypeEnumMap = {
  AttachmentType.image: 'image',
  AttachmentType.pdf: 'pdf',
};

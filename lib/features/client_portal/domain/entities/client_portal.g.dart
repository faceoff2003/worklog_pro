// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_portal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ClientPortal _$ClientPortalFromJson(Map<String, dynamic> json) =>
    _ClientPortal(
      portalUid: json['portalUid'] as String,
      artisanUid: json['artisanUid'] as String,
      clientId: json['clientId'] as String,
      enabled: json['enabled'] as bool,
      displayName: json['displayName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ClientPortalToJson(_ClientPortal instance) =>
    <String, dynamic>{
      'portalUid': instance.portalUid,
      'artisanUid': instance.artisanUid,
      'clientId': instance.clientId,
      'enabled': instance.enabled,
      'displayName': instance.displayName,
      'createdAt': instance.createdAt.toIso8601String(),
    };

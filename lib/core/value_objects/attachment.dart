import 'package:freezed_annotation/freezed_annotation.dart';

part 'attachment.freezed.dart';
part 'attachment.g.dart';

@freezed
class Attachment with _$Attachment {
  const factory Attachment({
    required AttachmentType type,
    required String storagePath,
    required String name,
    String? note,
    required int sizeBytes,
  }) = _Attachment;

  factory Attachment.fromJson(Map<String, dynamic> json) => _$AttachmentFromJson(json);
}

enum AttachmentType {
  image,
  pdf;

  String toJson() => name;
  
  static AttachmentType fromJson(String value) {
    return AttachmentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Invalid AttachmentType: $value'),
    );
  }
}

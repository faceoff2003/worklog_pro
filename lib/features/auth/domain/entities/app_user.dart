import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

/// Represents an authenticated user in the application.
/// 
/// This is a domain entity, separate from Firebase User.
@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
    required DateTime createdAt,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
}

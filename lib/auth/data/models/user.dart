import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String username,
    required String email,
    String? avatarUrl,
    required DateTime createdAt,
    @Default('FRIENDS') String defaultVisibility,
    String? bio,
    @Default(0) int tripsCount,
    @Default(0) int stepsCount,
    @Default(0) int followersCount,
    @Default(0) int followingCount,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}


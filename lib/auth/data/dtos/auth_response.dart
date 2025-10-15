import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/user.dart';

part 'auth_response.freezed.dart';
part 'auth_response.g.dart';

@freezed
class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required String accessToken,
    required User user,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}

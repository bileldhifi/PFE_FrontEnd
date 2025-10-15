import 'package:freezed_annotation/freezed_annotation.dart';

part 'forgot_password_request.freezed.dart';
part 'forgot_password_request.g.dart';

@freezed
class ForgotPasswordRequest with _$ForgotPasswordRequest {
  const factory ForgotPasswordRequest({
    required String email,
  }) = _ForgotPasswordRequest;

  factory ForgotPasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ForgotPasswordRequestFromJson(json);
}

@freezed
class ResetPasswordRequest with _$ResetPasswordRequest {
  const factory ResetPasswordRequest({
    required String token,
    required String newPassword,
  }) = _ResetPasswordRequest;

  factory ResetPasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ResetPasswordRequestFromJson(json);
}

@freezed
class ForgotPasswordResponse with _$ForgotPasswordResponse {
  const factory ForgotPasswordResponse({
    required String message,
  }) = _ForgotPasswordResponse;

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) =>
      _$ForgotPasswordResponseFromJson(json);
}

@freezed
class ResetPasswordResponse with _$ResetPasswordResponse {
  const factory ResetPasswordResponse({
    required String message,
  }) = _ResetPasswordResponse;

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) =>
      _$ResetPasswordResponseFromJson(json);
}

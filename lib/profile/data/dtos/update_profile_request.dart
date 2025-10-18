import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_profile_request.freezed.dart';
part 'update_profile_request.g.dart';

@freezed
class UpdateProfileRequest with _$UpdateProfileRequest {
  const factory UpdateProfileRequest({
    required String username,
    String? bio,
    @Default('FRIENDS') String defaultVisibility,
  }) = _UpdateProfileRequest;

  factory UpdateProfileRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateProfileRequestFromJson(json);
}

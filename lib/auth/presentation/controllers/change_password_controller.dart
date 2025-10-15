import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repo/auth_repository.dart';

// Change password state
class ChangePasswordState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final String? successMessage;

  ChangePasswordState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.successMessage,
  });

  ChangePasswordState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    String? successMessage,
  }) {
    return ChangePasswordState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
      successMessage: successMessage,
    );
  }
}

// Change password controller
class ChangePasswordController extends StateNotifier<ChangePasswordState> {
  final AuthRepository _authRepository;
  
  ChangePasswordController(this._authRepository) : super(ChangePasswordState());

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    
    try {
      final message = await _authRepository.changePassword(currentPassword, newPassword);
      
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        successMessage: message,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
        isSuccess: false,
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearSuccess() {
    state = state.copyWith(isSuccess: false, successMessage: null);
  }

  void reset() {
    state = ChangePasswordState();
  }
}

// Provider
final changePasswordControllerProvider = StateNotifierProvider<ChangePasswordController, ChangePasswordState>((ref) {
  final authRepository = AuthRepository();
  return ChangePasswordController(authRepository);
});

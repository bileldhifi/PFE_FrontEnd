import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary_frontend/auth/data/models/user.dart';
import 'package:travel_diary_frontend/auth/data/dtos/auth_response.dart';
import 'package:travel_diary_frontend/auth/data/repo/auth_repository.dart';

// Auth state
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// Auth controller
class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  
  AuthController(this._authRepository) : super(AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final authResponse = await _authRepository.login(email, password);
      
      state = state.copyWith(
        user: authResponse.user,
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> register(String username, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final newUser = await _authRepository.register(
        username: username,
        email: email,
        password: password,
      );
      
      state = state.copyWith(
        user: newUser,
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _authRepository.forgotPassword(email);
      state = state.copyWith(
        isLoading: false,
        error: null, // Success - no error
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _authRepository.resetPassword(token, newPassword);
      state = state.copyWith(
        isLoading: false,
        error: null, // Success - no error
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = AuthState();
  }

  Future<void> checkAuthStatus() async {
    // Only set loading if we haven't checked yet
    if (!state.isAuthenticated && state.user == null) {
      state = state.copyWith(isLoading: true);
    }
    
    try {
      final isAuthenticated = await _authRepository.isAuthenticated();
      
      if (isAuthenticated) {
        final user = await _authRepository.getCurrentUser();
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          user: null,
          error: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
        isAuthenticated: false,
        user: null,
      );
    }
  }

  Future<void> refreshUser() async {
    try {
      final user = await _authRepository.getCurrentUser();
      state = state.copyWith(user: user);
    } catch (e) {
      // If refresh fails, user might need to login again
      state = state.copyWith(
        error: e.toString(),
        isAuthenticated: false,
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final authRepository = AuthRepository();
  return AuthController(authRepository);
});


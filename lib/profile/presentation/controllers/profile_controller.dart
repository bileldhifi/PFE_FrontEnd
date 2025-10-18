import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/models/user.dart';
import '../../data/repo/profile_repository.dart';
import '../../data/dtos/update_profile_request.dart';

// Profile state
class ProfileState {
  final User? currentUser;
  final Map<String, User> users; // Cache for other users
  final bool isLoading;
  final bool isUpdating;
  final String? error;
  final String? successMessage;

  ProfileState({
    this.currentUser,
    this.users = const {},
    this.isLoading = false,
    this.isUpdating = false,
    this.error,
    this.successMessage,
  });

  ProfileState copyWith({
    User? currentUser,
    Map<String, User>? users,
    bool? isLoading,
    bool? isUpdating,
    String? error,
    String? successMessage,
  }) {
    return ProfileState(
      currentUser: currentUser ?? this.currentUser,
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      error: error,
      successMessage: successMessage,
    );
  }
}

// Profile controller
class ProfileController extends StateNotifier<ProfileState> {
  final ProfileRepository _profileRepository;
  
  ProfileController(this._profileRepository) : super(ProfileState());

  /// Load current user profile
  Future<void> loadCurrentUser() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = await _profileRepository.getCurrentUser();
      state = state.copyWith(
        currentUser: user,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Load user by ID (with caching)
  Future<User?> loadUserById(String userId) async {
    // Return cached user if available
    if (state.users.containsKey(userId)) {
      return state.users[userId];
    }

    try {
      final user = await _profileRepository.getUserById(userId);
      final updatedUsers = Map<String, User>.from(state.users);
      updatedUsers[userId] = user;
      
      state = state.copyWith(users: updatedUsers);
      return user;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Update current user profile
  Future<void> updateProfile({
    required String username,
    String? bio,
    String defaultVisibility = 'FRIENDS',
  }) async {
    state = state.copyWith(isUpdating: true, error: null, successMessage: null);
    
    try {
      final request = UpdateProfileRequest(
        username: username,
        bio: bio,
        defaultVisibility: defaultVisibility,
      );

      final updatedUser = await _profileRepository.updateProfile(request);
      
      state = state.copyWith(
        currentUser: updatedUser,
        isUpdating: false,
        successMessage: 'Profile updated successfully!',
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isUpdating: false,
      );
    }
  }

  /// Delete current user account
  Future<void> deleteAccount() async {
    state = state.copyWith(isUpdating: true, error: null);
    
    try {
      await _profileRepository.deleteAccount();
      // Note: After successful deletion, the user should be logged out
      // This will be handled by the calling component
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isUpdating: false,
      );
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear success message
  void clearSuccess() {
    state = state.copyWith(successMessage: null);
  }

  /// Refresh current user data
  Future<void> refreshProfile() async {
    await loadCurrentUser();
  }
}

// Provider
final profileControllerProvider = StateNotifierProvider<ProfileController, ProfileState>((ref) {
  final profileRepository = ProfileRepository();
  return ProfileController(profileRepository);
});

// Convenience providers for specific data
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(profileControllerProvider).currentUser;
});

final profileLoadingProvider = Provider<bool>((ref) {
  return ref.watch(profileControllerProvider).isLoading;
});

final profileErrorProvider = Provider<String?>((ref) {
  return ref.watch(profileControllerProvider).error;
});

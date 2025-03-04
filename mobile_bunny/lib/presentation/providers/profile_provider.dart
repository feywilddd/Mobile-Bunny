import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/profile.dart';
import '../../data/repositories/profile_repository.dart';

// Provider for the Profile Repository
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

// State class for profile data
class ProfileState {
  final List<Profile> profiles;
  final bool isLoading;
  final String? error;

  ProfileState({
    this.profiles = const [],
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    List<Profile>? profiles,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      profiles: profiles ?? this.profiles,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// StateNotifier for profile management
class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;

  ProfileNotifier(this._repository) : super(ProfileState());

  // Fetch family profiles
  Future<void> fetchFamilyProfiles() async {
    // Avoid multiple simultaneous fetches
    if (state.isLoading) return;
    
    // Set loading state but defer state update to avoid widget build conflicts
    await Future.delayed(Duration.zero, () {
      state = state.copyWith(isLoading: true, error: null);
    });
    
    try {
      final profiles = await _repository.fetchProfiles();
      
      // Use another Future.delayed to ensure this happens outside any widget build
      await Future.delayed(Duration.zero, () {
        state = state.copyWith(
          profiles: profiles,
          isLoading: false,
        );
        
        print('Loaded ${profiles.length} profiles');
      });
    } catch (e) {
      print('Error loading profiles: $e');
      await Future.delayed(Duration.zero, () {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load profiles: $e',
        );
      });
    }
  }
  
  // Helper to compare profile lists
  bool _areProfileListsEqual(List<Profile> list1, List<Profile> list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    
    return true;
  }

  // Add a new profile
  Future<bool> addProfile(Map<String, dynamic> profileData) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final profileId = await _repository.addProfile(profileData);
      
      if (profileId != null) {
        await fetchFamilyProfiles(); // Refresh the list
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to add profile',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error adding profile: $e',
      );
      return false;
    }
  }

  // Update an existing profile
  Future<bool> updateProfile(String profileId, Map<String, dynamic> profileData) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final success = await _repository.updateProfile(profileId, profileData);
      
      if (success) {
        await fetchFamilyProfiles(); // Refresh the list
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update profile',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error updating profile: $e',
      );
      return false;
    }
  }

  // Delete a profile
  Future<bool> deleteProfile(String profileId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final success = await _repository.deleteProfile(profileId);
      
      if (success) {
        await fetchFamilyProfiles(); // Refresh the list
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to delete profile',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error deleting profile: $e',
      );
      return false;
    }
  }

  // Add allergens to a profile
  Future<bool> addAllergens(String profileId, List<String> allergens) async {
    try {
      final success = await _repository.addAllergens(profileId, allergens);
      
      if (success) {
        await fetchFamilyProfiles(); // Refresh the list
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Error adding allergens: $e',
      );
      return false;
    }
  }

  // Remove allergens from a profile
  Future<bool> removeAllergens(String profileId, List<String> allergens) async {
    try {
      final success = await _repository.removeAllergens(profileId, allergens);
      
      if (success) {
        await fetchFamilyProfiles(); // Refresh the list
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Error removing allergens: $e',
      );
      return false;
    }
  }
}

// Provider for the profile state
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repository);
});
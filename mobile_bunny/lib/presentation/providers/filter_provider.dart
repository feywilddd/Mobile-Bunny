import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to store the allergen filter state (on/off)
final allergenFilterEnabledProvider = StateProvider<bool>((ref) => true);

// Provider for profile-specific filter settings
class ProfileFilterNotifier extends StateNotifier<Map<String, bool>> {
  ProfileFilterNotifier() : super({});

  // Initialize with profiles
  void initializeWithProfiles(List<String> profileIds) {
    // Skip if profileIds is empty or null to avoid unnecessary updates
    if (profileIds.isEmpty) return;
    
    // Check if state already contains these profiles to avoid unnecessary updates
    final existingIds = state.keys.toSet();
    final newIds = profileIds.toSet();
    
    // Only update if there are actual changes to make
    if (existingIds.containsAll(newIds) && newIds.containsAll(existingIds)) {
      return; // No changes needed
    }
    
    final initialState = Map<String, bool>.fromEntries(
      profileIds.map((id) => MapEntry(id, true))
    );
    
    // Preserve existing settings for profiles that already exist
    final updatedState = {
      ...initialState,
      ...Map.fromEntries(
        state.entries.where((entry) => initialState.containsKey(entry.key))
      ),
    };
    
    // Use Future.delayed to ensure we're outside the widget build phase
    Future.delayed(Duration.zero, () {
      state = updatedState;
    });
  }

  // Toggle filter for a specific profile
  void toggleProfileFilter(String profileId, bool isEnabled) {
    state = {
      ...state,
      profileId: isEnabled,
    };
  }

  // Reset all profile filters to enabled
  void resetFilters() {
    state = Map.fromEntries(
      state.entries.map((entry) => MapEntry(entry.key, true))
    );
  }
}

// Provider for profile filter state
final profileFilterProvider = StateNotifierProvider<ProfileFilterNotifier, Map<String, bool>>((ref) {
  return ProfileFilterNotifier();
});
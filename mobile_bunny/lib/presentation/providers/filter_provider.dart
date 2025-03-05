// lib/providers/filter_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to store the allergen filter state (on/off)
final allergenFilterEnabledProvider = StateProvider<bool>((ref) => true);

// Provider for profile-specific filter settings
class ProfileFilterNotifier extends StateNotifier<Map<String, bool>> {
  ProfileFilterNotifier() : super({});
  
  // Initialize with profiles - only add new ones, don't reset existing ones
  void initializeWithProfiles(List<String> profileIds) {
    print("initializeWithProfiles called with: $profileIds");
    
    if (profileIds.isEmpty) {
      print("ProfileIds is empty, skipping initialization");
      return;
    }
    
    // Create a new map that preserves existing settings
    final Map<String, bool> newState = Map<String, bool>.from(state);
    
    // Only add new profiles that aren't already in the state
    for (final id in profileIds) {
      if (!newState.containsKey(id)) {
        newState[id] = true; // Default to enabled
      }
    }
    
    print("Final profile filter state: $newState");
    state = newState;
  }
  
  // CRITICAL FIX: Toggle filter for a specific profile using bracket notation
  void toggleProfileFilter(String profileId, bool isEnabled) {
    print("toggleProfileFilter called with profileId: $profileId, isEnabled: $isEnabled");
    
    // Create a new map with all existing entries
    final newState = Map<String, bool>.from(state);
    
    // Update the specific profile's value using bracket notation
    newState[profileId] = isEnabled;
    
    print("Updated state: $newState");
    state = newState;
  }
  
  // Reset all profile filters to enabled
  void resetFilters() {
    print("resetFilters called");
    
    final newState = Map<String, bool>.from(state);
    
    for (final id in newState.keys) {
      newState[id] = true;
    }
    
    print("Reset state: $newState");
    state = newState;
  }
}

// Provider for profile filter state
final profileFilterProvider = StateNotifierProvider<ProfileFilterNotifier, Map<String, bool>>((ref) {
  return ProfileFilterNotifier();
});

// Add a new provider to force refresh when profile allergens change
final allergenRefreshProvider = StateProvider<int>((ref) => 0);
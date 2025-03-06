import 'package:flutter_riverpod/flutter_riverpod.dart';

final allergenFilterEnabledProvider = StateProvider<bool>((ref) => true);

class ProfileFilterNotifier extends StateNotifier<Map<String, bool>> {
  ProfileFilterNotifier() : super({});

  void initializeWithProfiles(List<String> profileIds) {
    if (profileIds.isEmpty) {
      return;
    }

    final Map<String, bool> newState = Map<String, bool>.from(state);

    for (final id in profileIds) {
      if (!newState.containsKey(id)) {
        newState[id] = true;
      }
    }

    state = newState;
  }

  void toggleProfileFilter(String profileId, bool isEnabled) {
    final newState = Map<String, bool>.from(state);
    newState[profileId] = isEnabled;
    state = newState;
  }

  void resetFilters() {
    final newState = Map<String, bool>.from(state);

    for (final id in newState.keys) {
      newState[id] = true;
    }

    state = newState;
  }
}

final profileFilterProvider = StateNotifierProvider<ProfileFilterNotifier, Map<String, bool>>((ref) {
  return ProfileFilterNotifier();
});

final allergenRefreshProvider = StateProvider<int>((ref) => 0);
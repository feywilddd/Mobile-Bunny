import '../data/models/menu_item.dart';
import '../data/models/profile.dart';

class AllergenFilterUtils {
  static List<MenuItem> filterMenuItems({
    required List<MenuItem> items,
    required bool isFilterEnabled,
    required Map<String, bool> profileFilters,
    required List<Profile> profiles,
  }) {
    if (!isFilterEnabled) {
      return items;
    }
   
    return items.where((item) {
      if (item.allergens.isEmpty) {
        return true;
      }
     
      for (final entry in profileFilters.entries) {
        final profileId = entry.key;
        final isProfileEnabled = entry.value;
       
        if (!isProfileEnabled) continue;
       
        final profile = profiles.firstWhere(
          (p) => p.id == profileId,
          orElse: () => Profile(
            id: profileId,
            name: '',
            allergens: [],
            createdAt: DateTime.now(),
          ),
        );
       
        for (final allergen in profile.allergens) {
          if (item.allergens.contains(allergen)) {
            return false;
          }
        }
      }
     
      return true;
    }).toList();
  }
}
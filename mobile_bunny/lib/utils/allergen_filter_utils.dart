import '../data/models/menu_item.dart';
import '../data/models/profile.dart';

class AllergenFilterUtils {
  /// Filters a list of menu items based on allergen profiles
  /// 
  /// [items] - The list of menu items to filter
  /// [isFilterEnabled] - Whether filtering is enabled at all
  /// [profileFilters] - Map of profile IDs to boolean values (true = filter this profile)
  /// [profiles] - List of all profiles with their allergens
  /// 
  /// Returns a filtered list of menu items
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
      // If the item has no allergens, it's always shown
      if (item.allergens.isEmpty) {
        return true;
      }
      
      // For each profile that's enabled in the filter
      for (final entry in profileFilters.entries) {
        final profileId = entry.key;
        final isProfileEnabled = entry.value;
        
        // Skip profiles that are disabled in the filter
        if (!isProfileEnabled) continue;
        
        // Find the actual profile to get its allergens
        final profile = profiles.firstWhere(
          (p) => p.id == profileId,
          orElse: () => Profile(
            id: profileId,
            name: '',
            allergens: [],
            createdAt: DateTime.now(),
          ),
        );
        
        // Check if this item contains any allergens the profile is allergic to
        for (final allergen in profile.allergens) {
          if (item.allergens.contains(allergen)) {
            // This item contains an allergen the profile is allergic to
            return false;
          }
        }
      }
      
      // No allergic reactions found for any enabled profile
      return true;
    }).toList();
  }
}
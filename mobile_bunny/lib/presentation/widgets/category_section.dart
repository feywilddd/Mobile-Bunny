import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_bunny/data/models/profile.dart';
import '../pages/category_menu_page.dart';
import '../pages/item_detail_bottom_sheet.dart';
import '../../data/models/menu_item.dart';
import '../widgets/menu_item_card.dart';
import '../providers/filter_provider.dart';
import '../providers/profile_provider.dart';

class CategorySection extends ConsumerWidget {
  final String title;
  final List<MenuItem> menuItems;
  
  const CategorySection({
    super.key,
    required this.title,
    required this.menuItems,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAllergenFilterEnabled = ref.watch(allergenFilterEnabledProvider);
    final profileFilters = ref.watch(profileFilterProvider);
    final profileState = ref.watch(profileProvider);
    
    final refreshCounter = ref.watch(allergenRefreshProvider);
    
    final categoryItems = menuItems.where((item) => item.category == title).toList();
    
    List<MenuItem> filteredItems = List.from(categoryItems);
    
    if (isAllergenFilterEnabled) {
      filteredItems = categoryItems.where((item) {
        if (item.allergens.isEmpty) {
          return true;
        }
        
        for (final entry in profileFilters.entries) {
          final profileId = entry.key;
          final isProfileEnabled = entry.value;
          
          if (!isProfileEnabled) {
            continue;
          }
          
          final profile = profileState.profiles.firstWhere(
            (p) => p.id == profileId,
            orElse: () => Profile(id: '', name: '', allergens: [], createdAt: DateTime.now()),
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
    
    final displayedItems = filteredItems.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              if (isAllergenFilterEnabled) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.filter_alt,
                  color: Colors.white.withOpacity(0.7),
                  size: 14,
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: displayedItems.isEmpty
              ? Center(
                  child: Text(
                    'Aucun plat disponible pour cette catégorie',
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: displayedItems.length + 1,
                  itemBuilder: (context, index) {
                    if (index == displayedItems.length) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CategoryPage(category: title)),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.all(8),
                          color: const Color(0xFF1C1C1C),
                          child: SizedBox(
                            width: 150,
                            height: 100,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(Icons.arrow_forward, color: Colors.white),
                                const SizedBox(height: 8),
                                Text(
                                  'Voir plus $title',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => ItemDetailBottomSheet(item: displayedItems[index]),
                        );
                      },
                      child: MenuItemCard(item: displayedItems[index]),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
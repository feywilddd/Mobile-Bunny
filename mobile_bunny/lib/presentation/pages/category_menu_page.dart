import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/menu_provider.dart';
import '../providers/filter_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/menu_grid.dart';

class CategoryPage extends ConsumerWidget {
  final String category;
  const CategoryPage({super.key, required this.category});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsyncValue = ref.watch(menuProvider);
    
    final isAllergenFilterEnabled = ref.watch(allergenFilterEnabledProvider);
    final profileFilters = ref.watch(profileFilterProvider);
    final profileState = ref.watch(profileProvider);
    
    ref.watch(allergenRefreshProvider);
    
    return Scaffold(
      appBar: const CustomAppBar(showArrow: true),
      bottomNavigationBar: const CustomBottomNavigationBar(),
      backgroundColor: const Color(0xFF212529),
      body: menuAsyncValue.when(
        data: (menuItems) {
          var categoryItems = menuItems.where((item) => item.category == category).toList();
          
          if (isAllergenFilterEnabled) {
            categoryItems = categoryItems.where((item) {
              if (item.allergens.isEmpty) {
                return true;
              }
              
              for (final entry in profileFilters.entries) {
                final profileId = entry.key;
                final isProfileEnabled = entry.value;
                
                if (!isProfileEnabled) continue;
                
                final profileIndex = profileState.profiles.indexWhere((p) => p.id == profileId);
                if (profileIndex == -1) continue;
                
                final profile = profileState.profiles[profileIndex];
                
                for (final allergen in profile.allergens) {
                  if (item.allergens.contains(allergen)) {
                    return false;
                  }
                }
              }
              
              return true;
            }).toList();
          }
          
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (isAllergenFilterEnabled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDB816E).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.filter_alt,
                              color: const Color(0xFFDB816E),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Filtrage actif',
                              style: TextStyle(
                                color: const Color(0xFFDB816E),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (categoryItems.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.no_food, color: Colors.white70, size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucun plat disponible',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        if (isAllergenFilterEnabled)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  'Essayez de désactiver le filtre d\'allergènes',
                                  style: const TextStyle(color: Colors.white70),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    ref.read(allergenFilterEnabledProvider.notifier).state = false;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Filtrage des allergènes désactivé'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.filter_alt_off),
                                  label: const Text('Désactiver le filtrage'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDB816E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(child: MenuGrid(items: categoryItems)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}
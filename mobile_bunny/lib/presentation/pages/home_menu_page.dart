import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/filter_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/category_section.dart';
import '../pages/login_page.dart';
import '../pages/category_menu_page.dart';
import '../widgets/menu_item_card.dart';
import '../pages/item_detail_bottom_sheet.dart';
import '../pages/user_menu_page.dart';
import '../pages/restaurants_page.dart';

class MenuPage extends ConsumerStatefulWidget {
  const MenuPage({super.key});
  
  @override
  ConsumerState<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends ConsumerState<MenuPage> {
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize profile data and filters in initState
    _initializeFilters();
  }

  Future<void> _initializeFilters() async {
    try {
      print("MenuPage._initializeFilters - Started");
      
      // Make sure profile data is loaded first
      await ref.read(profileProvider.notifier).fetchFamilyProfiles();
      
      // Initialize filter with profile IDs
      final profiles = ref.read(profileProvider).profiles;
      final profileIds = profiles.map((profile) => profile.id).toList();
      
      print("MenuPage._initializeFilters - Initializing with profile IDs: $profileIds");
      ref.read(profileFilterProvider.notifier).initializeWithProfiles(profileIds);
      
      if (mounted) {
        setState(() {
          isInitialized = true;
          print("MenuPage._initializeFilters - Initialization complete");
        });
      }
    } catch (e) {
      print('Error initializing filters: $e');
      // Still mark as initialized so we can show something
      if (mounted) {
        setState(() {
          isInitialized = true;
          print("MenuPage._initializeFilters - Initialization failed but continuing");
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print("MenuPage.build - isInitialized: $isInitialized");
    
    final user = ref.watch(authProvider);
    final menuAsyncValue = ref.watch(menuProvider);
    
    // Also watch profile provider to ensure we rebuild when profiles change
    ref.watch(profileProvider);
    
    // Watch allergen refresh provider to rebuild when profile allergens change
    ref.watch(allergenRefreshProvider);
    
    // Log the current state of the filter
    print("MenuPage.build - Current filter state: ${ref.read(profileFilterProvider)}");
    
    if (!isInitialized) {
      return Scaffold(
        appBar: const CustomAppBar(),
        bottomNavigationBar: const CustomBottomNavigationBar(),
        backgroundColor: const Color(0xFF212529),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: const CustomAppBar(),
      bottomNavigationBar: const CustomBottomNavigationBar(),
      backgroundColor: const Color(0xFF212529),
      body: menuAsyncValue.when(
        data: (menuItems) {
          return ListView(
            children: [
              CategorySection(title: 'Entrées', menuItems: menuItems),
              CategorySection(title: 'Plats principaux', menuItems: menuItems),
              CategorySection(title: 'Desserts', menuItems: menuItems),
              CategorySection(title: 'Boissons', menuItems: menuItems),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}
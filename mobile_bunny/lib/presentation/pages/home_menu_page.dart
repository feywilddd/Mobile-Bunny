import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/menu_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/filter_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/category_section.dart';

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
    _initializeFilters();
  }

  Future<void> _initializeFilters() async {
    try {
      await ref.read(profileProvider.notifier).fetchFamilyProfiles();
     
      final profiles = ref.read(profileProvider).profiles;
      final profileIds = profiles.map((profile) => profile.id).toList();
     
      ref.read(profileFilterProvider.notifier).initializeWithProfiles(profileIds);
     
      if (mounted) {
        setState(() {
          isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuAsyncValue = ref.watch(menuProvider);
   
    ref.watch(profileProvider);
    ref.watch(allergenRefreshProvider);
   
    if (!isInitialized) {
      return Scaffold(
        appBar: const CustomAppBar(showArrow: false),
        bottomNavigationBar: const CustomBottomNavigationBar(),
        backgroundColor: const Color(0xFF212529),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
   
    return Scaffold(
      appBar: const CustomAppBar(showArrow: false),
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
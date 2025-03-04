import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/menu_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final menuAsyncValue = ref.watch(menuProvider);

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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/menu_provider.dart';
import '../pages/login_page.dart';
import '../pages/category_menu_page.dart'; 
import '../widgets/menu_item_card.dart'; 
import '../pages/item_detail_bottom_sheet.dart';
import '../../data/models/menu_item.dart';

class MenuPage extends ConsumerWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final menuAsyncValue = ref.watch(menuProvider);

    return Scaffold(
      appBar: AppBar(
				automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1C1C1C),
        title: Row(
          children: [
            const Icon(Icons.location_on, color: Color(0xFFDE0000)), // Icône de localisation rouge
            const SizedBox(width: 8), // Espace entre l'icône et le texte
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '123 Rue du Resto...', // Adresse tronquée
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Text(
                  'Ouvert jusqu\'à 23 h', 
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE4DF96),
            child: Text('CS'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFF212529),
      body: menuAsyncValue.when(
      data: (menuItems) {
        return ListView(
          children: [
            buildCategorySection('Entrées', menuItems, context),
            buildCategorySection('Plats principaux', menuItems, context),
            buildCategorySection('Desserts', menuItems, context),
            buildCategorySection('Boissons', menuItems, context),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
      bottomNavigationBar: Container(
				color: const Color(0xFF1C1C1C), 
				padding: const EdgeInsets.all(8.0),
				child: BottomNavigationBar(
					backgroundColor: const Color(0xFF1C1C1C),
					selectedItemColor: Colors.white,
					unselectedItemColor: Colors.grey,
					items: const [
						BottomNavigationBarItem(icon: Icon(Icons.edit_location), label: 'Restaurant'),
						BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Menu'),
						BottomNavigationBarItem(icon: Icon(Icons.shopping_basket), label: 'Panier'),
					],
				),
			),
    );
  }

Widget buildCategorySection(String title, List<MenuItem> menuItems, BuildContext context) {
  // Filtrer les items de la catégorie
  final categoryItems = menuItems.where((item) => item.category == title).toList().take(3).toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categoryItems.length + 1, // +1 pour "Voir plus"
          itemBuilder: (context, index) {
            if (index == categoryItems.length) {
              // Bouton "Voir plus"
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_forward, color: Colors.white),
                        Text(
                          'Voir plus $title',
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
                  builder: (context) => ItemDetailBottomSheet(item: categoryItems[index]),
                );
              },
              child: MenuItemCard(item: categoryItems[index]),
            );
          },
        ),
      ),
    ],
  );
}

}
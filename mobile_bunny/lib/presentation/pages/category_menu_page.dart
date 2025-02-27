import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_bunny/presentation/pages/home_menu_page.dart';
import '../providers/auth_provider.dart';
import '../providers/menu_provider.dart';
import '../pages/login_page.dart';
import '../widgets/menu_item_card.dart'; 
import '../pages/item_detail_bottom_sheet.dart';

class CategoryPage extends ConsumerWidget {
  final String category;

  const CategoryPage({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Filtrer les éléments de la catégorie ici
    final menuAsyncValue = ref.watch(menuProvider);
    final user = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1C1C1C),
        title: Row(
          children: [
            const Icon(Icons.location_on, color: Color(0xFFDE0000)),
            const SizedBox(width: 8), // Espace entre l'icône et le texte
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '123 Rue du Resto...', 
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
      bottomNavigationBar: Container(
				color: const Color(0xFF1C1C1C), 
				padding: const EdgeInsets.all(8.0),
				child: BottomNavigationBar(
					backgroundColor: const Color(0xFF1C1C1C),
					selectedItemColor: Colors.white,
					unselectedItemColor: Colors.grey,
					items: const [
						BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restaurant'),
						BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Menu'),
						BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Panier'),
					],
				),
			),
      backgroundColor: const Color(0xFF212529),

      body: menuAsyncValue.when(
      data: (menuItems) {
         final filteredMenuItems = menuItems
            .where((item) => item.category == category)
            .toList();
        return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft, 
              child: Text(
                category, 
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Affichage en grille des cartes
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Nombre de colonnes
                crossAxisSpacing: 10.0, // Espacement horizontal entre les cartes
                mainAxisSpacing: 10.0, // Espacement vertical entre les cartes
                childAspectRatio: 1.2, // Rapport de taille pour chaque carte
              ),
              itemCount: filteredMenuItems.length,
              itemBuilder: (context, index) {
                final item = filteredMenuItems[index];
                return GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return ItemDetailBottomSheet(item: item); // Affichage du BottomSheet
                      },
                    );
                  },
                  child: MenuItemCard(item: item), // Carte de l'item
                );
              },
            ),
          ),
        ],
      );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}
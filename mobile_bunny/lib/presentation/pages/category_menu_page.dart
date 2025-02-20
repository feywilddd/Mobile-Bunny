import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../pages/login_page.dart';
import '../widgets/menu_item_card.dart'; 
import '../pages/item_detail_bottom_sheet.dart';

class CategoryPage extends ConsumerWidget {
  final String category;

  const CategoryPage({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Filtrer les éléments de la catégorie ici
    final categoryItems = fakeData.where((item) => item['category'] == category).toList();
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
      body: Column(
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
              itemCount: categoryItems.length,
              itemBuilder: (context, index) {
                final item = categoryItems[index];
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
      ),
    );
  }
}


final List<Map<String, dynamic>> fakeData = [
  // Entrées
  {'name': 'Salade César', 'category': 'Entrées', 'price': 8.50},
  {'name': 'Soupe à l’oignon', 'category': 'Entrées', 'price': 6.00},
  {'name': 'Tartare de saumon', 'category': 'Entrées', 'price': 9.50},
  {'name': 'Bruschetta', 'category': 'Entrées', 'price': 7.00},
  {'name': 'Salade de chèvre chaud', 'category': 'Entrées', 'price': 9.00},
  {'name': 'Foie gras', 'category': 'Entrées', 'price': 15.00},
  {'name': 'Carpaccio de bœuf', 'category': 'Entrées', 'price': 12.50},
  {'name': 'Moules marinières', 'category': 'Entrées', 'price': 11.00},
  {'name': 'Ceviche', 'category': 'Entrées', 'price': 13.00},
  {'name': 'Salade de tomates mozzarella', 'category': 'Entrées', 'price': 8.00},
  
  // Plats principaux
  {'name': 'Burger Gourmet', 'category': 'Plats principaux', 'price': 14.90},
  {'name': 'Pâtes Carbonara', 'category': 'Plats principaux', 'price': 12.50},
  {'name': 'Pizza Margherita', 'category': 'Plats principaux', 'price': 11.00},
  {'name': 'Steak frites', 'category': 'Plats principaux', 'price': 16.50},
  {'name': 'Bœuf bourguignon', 'category': 'Plats principaux', 'price': 18.00},
  {'name': 'Coq au vin', 'category': 'Plats principaux', 'price': 17.00},
  {'name': 'Sole meunière', 'category': 'Plats principaux', 'price': 20.00},
  {'name': 'Pavé de saumon', 'category': 'Plats principaux', 'price': 19.00},
  {'name': 'Poulet rôti', 'category': 'Plats principaux', 'price': 15.00},
  {'name': 'Ratatouille', 'category': 'Plats principaux', 'price': 13.50},
  
  // Desserts
  {'name': 'Tiramisu', 'category': 'Desserts', 'price': 5.50},
  {'name': 'Fondant au chocolat', 'category': 'Desserts', 'price': 6.00},
  {'name': 'Crème brûlée', 'category': 'Desserts', 'price': 5.80},
  {'name': 'Panna cotta', 'category': 'Desserts', 'price': 6.50},
  {'name': 'Cheesecake', 'category': 'Desserts', 'price': 7.00},
  {'name': 'Mousse au chocolat', 'category': 'Desserts', 'price': 5.00},
  {'name': 'Eclair au chocolat', 'category': 'Desserts', 'price': 4.50},
  {'name': 'Clafoutis', 'category': 'Desserts', 'price': 5.20},
  {'name': 'Madeleine', 'category': 'Desserts', 'price': 3.80},
  {'name': 'Crumble aux pommes', 'category': 'Desserts', 'price': 5.00},
  
  // Boissons
  {'name': 'Coca-Cola', 'category': 'Boissons', 'price': 3.00},
  {'name': 'Jus d’orange', 'category': 'Boissons', 'price': 4.00},
  {'name': 'Eau minérale', 'category': 'Boissons', 'price': 2.50},
  {'name': 'Vin rouge', 'category': 'Boissons', 'price': 12.00},
  {'name': 'Bière', 'category': 'Boissons', 'price': 5.00},
  {'name': 'Café', 'category': 'Boissons', 'price': 2.20},
  {'name': 'Chocolat chaud', 'category': 'Boissons', 'price': 3.50},
  {'name': 'Milkshake à la fraise', 'category': 'Boissons', 'price': 5.50},
  {'name': 'Thé vert', 'category': 'Boissons', 'price': 3.00},
  {'name': 'Limonade', 'category': 'Boissons', 'price': 3.50},
];


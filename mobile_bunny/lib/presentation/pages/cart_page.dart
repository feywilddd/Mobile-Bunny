import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../pages/login_page.dart';
import '../pages/category_menu_page.dart'; 
import '../widgets/menu_item_card.dart'; 
import '../pages/item_detail_bottom_sheet.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

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
      body: ListView(
        children: [
          buildCategorySection('Entrées', fakeData, context),
          buildCategorySection('Plats principaux', fakeData, context),
          buildCategorySection('Desserts', fakeData, context),
          buildCategorySection('Boissons', fakeData, context),
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
    );
  }

Widget buildCategorySection(String title, List<Map<String, dynamic>> data, BuildContext context) {
  // Filtrer les données en fonction de la catégorie
  final categoryItems = data.where((item) => item['category'] == title).toList().take(3);

  // Ajouter la carte "Voir plus" à la fin de la liste
  final itemsWithSeeMore = List<Map<String, dynamic>>.from(categoryItems)
    ..add({'name': 'Voir plus $title', 'category': title, 'price': 0.0});

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
          itemCount: itemsWithSeeMore.length,
          itemBuilder: (context, index) {
            if (itemsWithSeeMore[index]['name'] == 'Voir plus $title') {
              return Card(
                margin: const EdgeInsets.all(8),
                color: const Color(0xFF1C1C1C), // Fond de la carte en gris foncé
                child: SizedBox(
                  width: 150,
                  child: GestureDetector(
                    onTap: () {
                      // Afficher la page "Voir plus"
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryPage(category: title),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Voir plus $title',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Icon(Icons.arrow_forward, color: Colors.white),
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
                  builder: (context) {
                    // Afficher le BottomSheet avec les détails de l'item
                    return ItemDetailBottomSheet(item: itemsWithSeeMore[index]);
                  },
                );
              },
              child: MenuItemCard(item: itemsWithSeeMore[index]),
            );
          },
        ),
      ),
    ],
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


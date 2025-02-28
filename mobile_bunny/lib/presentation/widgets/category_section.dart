import 'package:flutter/material.dart';
import '../pages/category_menu_page.dart'; 
import '../pages/item_detail_bottom_sheet.dart';
import '../../data/models/menu_item.dart';
import '../widgets/menu_item_card.dart';

class CategorySection extends StatelessWidget {
  final String title;
  final List<MenuItem> menuItems;

  const CategorySection({
    super.key,
    required this.title,
    required this.menuItems,
  });

  @override
  Widget build(BuildContext context) {
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
            itemCount: categoryItems.length + 1,
            itemBuilder: (context, index) {
              if (index == categoryItems.length) {
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

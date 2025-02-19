import 'package:flutter/material.dart';
import '../../data/models/menu_item.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;

  const MenuItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      color: const Color(0xFF1C1C1C),
      child: SizedBox(
        width: 150,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            item.imageUrl.isNotEmpty
                ? Image.network(item.imageUrl, height: 40) // Afficher l'image si disponible
                : const Icon(Icons.fastfood, size: 40, color: Colors.white),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                item.name,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            Text(
              '${item.price.toStringAsFixed(2)} \$',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

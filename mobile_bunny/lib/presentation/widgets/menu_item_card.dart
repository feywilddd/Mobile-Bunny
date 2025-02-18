import 'package:flutter/material.dart';

class MenuItemCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const MenuItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      color: const Color(0xFF1C1C1C), // Fond de la carte en gris foncé
      child: SizedBox(
        width: 150,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fastfood, size: 40, color: Colors.white), // Icône en blanc
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                item['name'],
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white), // Texte en blanc
              ),
            ),
            Text(
              '${item['price'].toStringAsFixed(2)} \$',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white), // Texte en blanc
            ),
          ],
        ),
      ),
    );
  }
}

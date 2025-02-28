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
      child: Container(
        width: 150,
        height: 220, 
        padding: const EdgeInsets.all(8), 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, 
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.imageUrl.isNotEmpty
                    ? Image.network(
                        item.imageUrl,
                        height: 60,
                        width: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 40, color: Colors.white),
                      )
                    : const Icon(Icons.fastfood, size: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                item.name,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 0.0),
              child: Text(
                '${item.price.toStringAsFixed(2)} \$',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

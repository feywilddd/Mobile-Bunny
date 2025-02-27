import 'package:flutter/material.dart';
import '../widgets/menu_item_card.dart';
import '../pages/item_detail_bottom_sheet.dart';
import '../../data/models/menu_item.dart';

class MenuGrid extends StatelessWidget {
  final List<MenuItem> items;

  const MenuGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
          childAspectRatio: 1.2,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return ItemDetailBottomSheet(item: item);
                },
              );
            },
            child: MenuItemCard(item: item),
          );
        },
      ),
    );
  }
}

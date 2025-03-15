import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_bunny/data/models/menu_item.dart';
import 'package:mobile_bunny/presentation/pages/basket_page.dart';
import 'package:mobile_bunny/presentation/providers/auth_provider.dart';
import 'package:mobile_bunny/presentation/providers/order_provider.dart';
import 'package:mobile_bunny/presentation/providers/restaurant_provider.dart';
import 'package:mobile_bunny/presentation/providers/address_provider.dart';

/// Helper widget for displaying menu items with add to cart functionality
class MenuItemWithCart extends ConsumerWidget {
  final MenuItem menuItem;
  
  const MenuItemWithCart({
    super.key,
    required this.menuItem,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final orderNotifier = ref.watch(orderProvider.notifier);
    final hasActiveOrder = ref.watch(hasActiveOrderProvider);
    final restaurantState = ref.watch(restaurantProvider);
    final addressState = ref.watch(addressProvider);
    
    // Add to cart function
    Future<void> addToCart() async {
      if (user == null) {
        // Show login prompt
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez vous connecter pour ajouter des articles au panier'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      
      try {
        // Check if restaurant is selected
        if (restaurantState.selectedRestaurantId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun restaurant sélectionné. Veuillez en sélectionner un d\'abord.'),
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }
        
        // Check if address is selected
        if (addressState.selectedAddressId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucune adresse de livraison sélectionnée. Veuillez en sélectionner une d\'abord.'),
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }
        
        // Add the item to cart
        final success = await orderNotifier.addItem(menuItem);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${menuItem.name} ajouté au panier'),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de l\'ajout au panier')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
    
    return Card(
      color: const Color(0xFF2C2C2C),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  menuItem.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${menuItem.price.toStringAsFixed(2)}\$',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              menuItem.description,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (menuItem.allergens.isNotEmpty)
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      children: menuItem.allergens.map((allergen) =>
                        Chip(
                          label: Text(
                            allergen,
                            style: const TextStyle(fontSize: 10),
                          ),
                          backgroundColor: Colors.amber,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        )
                      ).toList(),
                    ),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE79686),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: addToCart,
                  child: const Text(
                    'Ajouter',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget to display a cart badge in the app bar
class CartBadge extends ConsumerWidget {
  final VoidCallback onTap;
  
  const CartBadge({
    super.key,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderProvider);
    final cartItemCount = orderState.cartItemCount;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart, color: Colors.white),
          onPressed: onTap,
        ),
        if (cartItemCount > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '$cartItemCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

/// Extension for CustomAppBar to include cart badge
class AppBarWithCart extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  
  const AppBarWithCart({
    super.key,
    this.title = 'Restaurant App',
  });
  
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF212529),
      elevation: 0,
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      actions: [
        Consumer(
          builder: (context, ref, _) {
            return CartBadge(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const BasketPage()),
                );
              },
            );
          },
        ),
      ],
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
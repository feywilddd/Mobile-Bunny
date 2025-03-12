import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_bunny/data/models/address.dart';
import 'package:mobile_bunny/data/models/menu_item.dart';
import 'package:mobile_bunny/presentation/pages/basket_page.dart';
import 'package:mobile_bunny/presentation/providers/auth_provider.dart';
import 'package:mobile_bunny/presentation/providers/order_provider.dart';

// Import your providers
// import '../providers/auth_provider.dart';
// import '../providers/order_provider.dart';
// import '../models/order_model.dart';

/// Helper widget for displaying menu items with add to cart functionality
class MenuItemWithCart extends ConsumerWidget {
  final MenuItem menuItem;
  final String restaurantId;
  final Address restaurantAddress;
  
  const MenuItemWithCart({
    Key? key,
    required this.menuItem,
    required this.restaurantId,
    required this.restaurantAddress,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final orderNotifier = ref.watch(orderNotifierProvider.notifier);
    final activeOrderAsync = ref.watch(activeOrderProvider);
    
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
        // Check if we have an active order
        if (activeOrderAsync.value == null) {
          // For demo purposes, create a dummy delivery address
          final deliveryAddress = Address(
            id: 'user-addr-1',
            label: 'Home',
            street: '123 Rue Ste-Catherine',
            postalCode: 'H2X 1Z4',
            city: 'Montréal',
            additionalInfo: 'Apt 401',
            createdAt: DateTime.now(),
          );
          
          // Create a new order
          await orderNotifier.createOrder(
            restaurantId: restaurantId,
            restaurantAddress: restaurantAddress,
            deliveryAddress: deliveryAddress,
          );
        }
        
        // Add the item to cart
        await orderNotifier.addItem(menuItem);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${menuItem.name} ajouté au panier'),
            duration: const Duration(seconds: 2),
          ),
        );
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
    Key? key,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItemCount = ref.watch(cartItemCountProvider);
    
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
    Key? key,
    this.title = 'Restaurant App',
  }) : super(key: key);
  
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/menu_item.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/order_provider.dart';
import '../../presentation/providers/address_provider.dart';
import '../../presentation/providers/restaurant_provider.dart';

class ItemDetailBottomSheet extends ConsumerStatefulWidget {
  final MenuItem item;

  const ItemDetailBottomSheet({super.key, required this.item});

  @override
  ConsumerState<ItemDetailBottomSheet> createState() => _ItemDetailBottomSheetState();
}

class _ItemDetailBottomSheetState extends ConsumerState<ItemDetailBottomSheet> {
  int quantity = 1;
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    // Get needed providers
    final user = ref.watch(authProvider);
    final orderNotifier = ref.watch(orderProvider.notifier);
    final canCreateOrder = ref.watch(canCreateOrderProvider);
    final restaurantState = ref.watch(restaurantProvider);
    final addressState = ref.watch(addressProvider);

    // Function to add to cart
    Future<void> addToCart() async {
      final user = ref.read(authProvider);
      
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez vous connecter pour ajouter des articles au panier'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      
      try {
        print("Adding to cart: ${widget.item.name}, quantity: $quantity");
        
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
        
        // Add the item to cart with selected quantity
        print("Adding item with quantity: $quantity");
        final success = await orderNotifier.addItem(widget.item, quantity: quantity);
        
        if (success) {
          // Show success message and close bottom sheet
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${widget.item.name} ajouté au panier'),
                duration: const Duration(seconds: 2),
              ),
            );
            Navigator.pop(context);
          }
        } else {
          // Show error if the operation wasn't successful
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erreur lors de l\'ajout au panier')),
            );
          }
        }
      } catch (e, stackTrace) {
        print("Error adding to cart: $e");
        print("Stack trace: $stackTrace");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${e.toString()}')),
          );
        }
      }
    }
   
    return Container(
      color: const Color(0xFF212529),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.item.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.item.price.toStringAsFixed(2)} \$',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              Row(
                children: [
                  const Text(
                    'Favoris',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: Colors.yellow,
                    ),
                    onPressed: () {
                      setState(() {
                        isFavorite = !isFavorite;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          widget.item.imageUrl.isNotEmpty
              ? Center(
                  child: Image.network(
                    widget.item.imageUrl,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                )
              : const Center(
                  child: Icon(Icons.image_not_supported, color: Colors.white, size: 150),
                ),
          const SizedBox(height: 20),

          Text(
            widget.item.description,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: const Color(0xFF6E6E6E), width: 2),
                borderRadius: BorderRadius.circular(35),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (quantity > 1) {
                        setState(() {
                          quantity--;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: const Text(
                        '-',
                        style: TextStyle(color: Colors.white, fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$quantity',
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        quantity++;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: const Text(
                        '+',
                        style: TextStyle(color: Colors.white, fontSize: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDB816E),
                padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: addToCart,  // Use our addToCart function here
              child: const Text(
                'Ajouter',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
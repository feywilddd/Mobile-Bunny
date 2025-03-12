import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/menu_item.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/order_provider.dart';
import '../../data/models/address.dart'; // Make sure this import exists

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
    final orderNotifier = ref.watch(orderNotifierProvider.notifier);
    final activeOrderAsync = ref.watch(activeOrderProvider);

    // Function to add to cart
      // In your ItemDetailBottomSheet widget
    // In your ItemDetailBottomSheet widget
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
    
    // Just use the orderNotifier directly without checking the active order
    final orderNotifier = ref.read(orderNotifierProvider.notifier);
    
    try {
      // Get restaurant information
      final restaurantId = 'restaurant1';
      final restaurantAddress = Address(
        id: 'rest-addr-1',
        label: 'Restaurant',
        street: '709 Rue St Thomas',
        postalCode: 'H3C 2K2',
        city: 'Montréal',
        additionalInfo: 'Ouvert jusqu\'à 23h',
        createdAt: DateTime.now(),
      );
      
      final deliveryAddress = Address(
        id: 'user-addr-1',
        label: 'Home',
        street: '123 Rue Ste-Catherine',
        postalCode: 'H2X 1Z4',
        city: 'Montréal',
        additionalInfo: 'Apt 401',
        createdAt: DateTime.now(),
      );
      
      // Try to create the order - this should handle the case if an order already exists
      try {
        print("Creating new order with restaurantId: $restaurantId");
        await orderNotifier.createOrder(
          restaurantId: restaurantId,
          restaurantAddress: restaurantAddress,
          deliveryAddress: deliveryAddress,
        );
        print("Order created successfully");
      } catch (orderCreateError) {
        print("Order may already exist or error creating: $orderCreateError");
        // Continue anyway - we'll try to add the item
      }
      
      // Add the item to cart with selected quantity
      print("Adding item with quantity: $quantity");
      await orderNotifier.addItem(widget.item, quantity: quantity);
      
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
    } catch (orderError) {
      print("Error in order creation/manipulation: $orderError");
      rethrow;
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
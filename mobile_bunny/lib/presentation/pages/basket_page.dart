import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_bunny/data/models/address.dart';
import 'package:mobile_bunny/data/models/order.dart';
import 'package:mobile_bunny/presentation/pages/login_page.dart';
import 'package:mobile_bunny/presentation/providers/auth_provider.dart';
import 'package:mobile_bunny/presentation/providers/order_provider.dart';
import 'package:mobile_bunny/presentation/widgets/address_card.dart';

class BasketPage extends ConsumerWidget {
  const BasketPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if user is logged in
    final user = ref.watch(authProvider);
    
    // Get order state
    final orderState = ref.watch(orderProvider);
    final order = orderState.activeOrder;
    final isLoading = orderState.isLoading;
    final error = orderState.error;
    
    return Scaffold(
      backgroundColor: const Color(0xFF212529),
      appBar: AppBar(
        backgroundColor: const Color(0xFF212529),
        elevation: 0,
        title: const Text(
          'Votre commande',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: user == null 
          ? _buildLoginPrompt(context)
          : isLoading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? Center(
                      child: Text(
                        'Erreur: $error',
                        style: const TextStyle(color: Colors.white),
                      ),
                    )
                  : order == null
                      ? const Center(
                          child: Text(
                            'Votre panier est vide',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : BasketContent(order: order),
    );
  }
  
  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Veuillez vous connecter pour accéder à votre panier',
            style: TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE79686),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            onPressed: () {
              // Navigate to login page
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: const Text(
              'Se connecter',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BasketContent extends ConsumerWidget {
  final Order order;
  
  const BasketContent({super.key, required this.order});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderNotifier = ref.watch(orderProvider.notifier);
    
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Delivery Address Card
                    AddressCard(),
                    const SizedBox(height: 24),
                    
                    // Order Items
                    if (order.items.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Votre panier est vide',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                    else
                      for (final item in order.items) ...[
                        OrderItemWidget(
                          item: item,
                          onUpdateQuantity: (quantity) {
                            orderNotifier.updateItemQuantity(item.menuItemId, quantity);
                          },
                          onRemove: () {
                            orderNotifier.removeItem(item.menuItemId);
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                    // Order Summary
                    if (order.items.isNotEmpty)
                      OrderSummary(order: order),
                  ],
                ),
              ),
            ),
          ),
          // Bottom Action Bar
          if (order.items.isNotEmpty)
            BottomActionBar(order: order),
        ],
      ),
    );
  }
}

class OrderItemWidget extends StatelessWidget {
  final OrderItem item;
  final Function(int) onUpdateQuantity;
  final VoidCallback onRemove;
  
  const OrderItemWidget({
    super.key,
    required this.item,
    required this.onUpdateQuantity,
    required this.onRemove,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              item.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${item.price.toStringAsFixed(2)}\$',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          item.description,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.white, size: 18),
                    onPressed: () {
                      if (item.quantity > 1) {
                        onUpdateQuantity(item.quantity - 1);
                      } else {
                        onRemove();
                      }
                    },
                  ),
                  Text(
                    '${item.quantity}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    onPressed: () {
                      onUpdateQuantity(item.quantity + 1);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: onRemove,
            ),
          ],
        ),
      ],
    );
  }
}

class OrderSummary extends StatelessWidget {
  final Order order;
  
  const OrderSummary({super.key, required this.order});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          PriceSummaryRow(
            title: 'Sous-total',
            amount: '${order.subtotal.toStringAsFixed(2)}\$',
          ),
          const SizedBox(height: 8),
          PriceSummaryRow(
            title: 'TPS',
            amount: '${order.taxTPS.toStringAsFixed(2)}\$',
          ),
          const SizedBox(height: 8),
          PriceSummaryRow(
            title: 'TVQ',
            amount: '${order.taxTVQ.toStringAsFixed(2)}\$',
          ),
          if (order.deliveryFee > 0) ...[
            const SizedBox(height: 8),
            PriceSummaryRow(
              title: 'Frais de livraison',
              amount: '${order.deliveryFee.toStringAsFixed(2)}\$',
            ),
          ],
          const SizedBox(height: 8),
          PriceSummaryRow(
            title: 'Total',
            amount: '${order.total.toStringAsFixed(2)}\$',
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class PriceSummaryRow extends StatelessWidget {
  final String title;
  final String amount;
  final bool isBold;

  const PriceSummaryRow({
    super.key,
    required this.title,
    required this.amount,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class BottomActionBar extends ConsumerWidget {
  final Order order;
  
  const BottomActionBar({super.key, required this.order});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderNotifier = ref.watch(orderProvider.notifier);
    final isLoading = ref.watch(orderLoadingProvider);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade600),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE79686),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: isLoading ? null : () async {
                if (order.status == OrderStatus.draft) {
                  try {
                    final success = await orderNotifier.submitOrder();
                    if (success && context.mounted) {
                      // Navigate to order confirmation page
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Commande envoyée avec succès!')),
                      );
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Erreur lors de l\'envoi de la commande')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: ${e.toString()}')),
                      );
                    }
                  }
                }
              },
              child: const Text(
                'Commander',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
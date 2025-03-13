import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile_bunny/data/models/address.dart';
import 'package:mobile_bunny/data/models/order.dart';
import 'package:mobile_bunny/presentation/pages/login_page.dart';
import 'package:mobile_bunny/presentation/pages/tracking_page.dart';
import 'package:mobile_bunny/presentation/providers/address_provider.dart';
import 'package:mobile_bunny/presentation/providers/auth_provider.dart';
import 'package:mobile_bunny/presentation/providers/order_provider.dart';
import 'package:mobile_bunny/presentation/widgets/address_card.dart';

// Simple utility provider to mark orders as completed
final markOrderCompletedProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    try {
      // Get the notifier
      final orderNotifier = ref.read(orderProvider.notifier);
      
      // Set status to delivered
      await orderNotifier.updateOrderStatus(OrderStatus.delivered);
      
      // Get the repository
      final repository = ref.read(orderRepositoryProvider);
      
      // Complete the active order
      await repository.completeActiveOrder();
      
      print("Order marked as delivered and completed successfully");
    } catch (e) {
      print("Error marking order as completed: $e");
    }
  };
});

class BasketPage extends ConsumerWidget {
  const BasketPage({Key? key}) : super(key: key);

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
  
  const BasketContent({Key? key, required this.order}) : super(key: key);
  
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
    Key? key,
    required this.item,
    required this.onUpdateQuantity,
    required this.onRemove,
  }) : super(key: key);
  
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
  
  const OrderSummary({Key? key, required this.order}) : super(key: key);
  
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
    Key? key,
    required this.title,
    required this.amount,
    this.isBold = false,
  }) : super(key: key);

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
  
  const BottomActionBar({Key? key, required this.order}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(orderLoadingProvider);
    final markOrderCompleted = ref.watch(markOrderCompletedProvider);
    
    // Simplified submission that just navigates
    void handleSubmitOrder() {
      try {
        // 1. Show processing message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande envoyée avec succès!')),
        );
        
        // 2. First navigate to tracking page immediately
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (ctx) => TrackingCompletionPage(
              onComplete: markOrderCompleted,
            ),
          ),
        );
      } catch (e) {
        print("Navigation error: $e");
      }
    }
    
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
              onPressed: isLoading ? null : handleSubmitOrder,
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

class TrackingCompletionPage extends ConsumerStatefulWidget {
  final Future<void> Function() onComplete;
  
  const TrackingCompletionPage({
    Key? key, 
    required this.onComplete,
  }) : super(key: key);
  
  @override
  ConsumerState<TrackingCompletionPage> createState() => _TrackingCompletionPageState();
}

class _TrackingCompletionPageState extends ConsumerState<TrackingCompletionPage> {
  bool _isProcessing = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  // Default coordinates to use as fallback
  final LatLng _defaultRestaurantPosition = LatLng(46.03115353128858, -73.44116406758411);
  final LatLng _defaultClientPosition = LatLng(46.02358, -73.43292);
  
  @override
  void initState() {
    super.initState();
    // Process the order after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _completeOrderAndNavigate();
    });
  }
  
  // Get coordinates from the active order
  Future<Map<String, LatLng>> _getCoordinates() async {
    try {
      // Get current order
      final orderState = ref.read(orderProvider);
      final order = orderState.activeOrder;
      
      if (order == null) {
        print("No active order found, using default coordinates");
        return {
          'restaurant': _defaultRestaurantPosition,
          'client': _defaultClientPosition
        };
      }
      
      // Variables to store our coordinates
      LatLng restaurantPosition = _defaultRestaurantPosition;
      LatLng clientPosition = _defaultClientPosition;
      
      // Try to get restaurant coordinates
      try {
        // First check if restaurantId is present
        final restaurantId = order.restaurantId;
        if (restaurantId.isNotEmpty) {
          // Try to fetch from Firestore
          final restaurantDoc = await firestore.FirebaseFirestore.instance
              .collection('Restaurants')
              .doc(restaurantId)
              .get();
              
          if (restaurantDoc.exists && restaurantDoc.data() != null) {
            final data = restaurantDoc.data()!;
            
            // Check if location field exists and is a GeoPoint
            if (data.containsKey('location') && data['location'] is firestore.GeoPoint) {
              final location = data['location'] as firestore.GeoPoint;
              restaurantPosition = LatLng(location.latitude, location.longitude);
              print("Got restaurant coordinates from Firestore: $restaurantPosition");
            }
          }
        }
      } catch (e) {
        print("Error fetching restaurant coordinates: $e");
        // Continue with default coordinates
      }
      
      // Try to get delivery address coordinates
      try {
          // Check the address provider for the selected address
          final addressState = ref.read(addressProvider);
          final selectedAddressId = addressState.selectedAddressId;
          
          if (selectedAddressId != null) {
            // Try to fetch from Firestore
            final addressDoc = await firestore.FirebaseFirestore.instance
                .collection('users')
                .doc(order.userId)
                .collection('addresses')
                .doc(selectedAddressId)
                .get();
                
            if (addressDoc.exists && addressDoc.data() != null) {
              final data = addressDoc.data()!;
              
              // First try 'geoPoint' field
              if (data.containsKey('geoPoint') && data['geoPoint'] is firestore.GeoPoint) {
                final location = data['geoPoint'] as firestore.GeoPoint;
                clientPosition = LatLng(location.latitude, location.longitude);
                print("Got client coordinates from Firestore (geoPoint): $clientPosition");
              } 
              // Fallback to 'location' field for backward compatibility
              else if (data.containsKey('location') && data['location'] is firestore.GeoPoint) {
                final location = data['location'] as firestore.GeoPoint;
                clientPosition = LatLng(location.latitude, location.longitude);
                print("Got client coordinates from Firestore (location): $clientPosition");
              } else {
                // No valid coordinates found in the address document
                print("No valid coordinates found in address document. Fields available: ${data.keys.join(', ')}");
              }
            } else {
              print("Selected address document does not exist or is empty");
            }
          } else {
            print("No selected address ID found");
          }
        } catch (e) {
          print("Error fetching client coordinates: $e");
          // Continue with default coordinates
        }
      
      return {
        'restaurant': restaurantPosition,
        'client': clientPosition
      };
    } catch (e) {
      print("Error getting coordinates: $e");
      return {
        'restaurant': _defaultRestaurantPosition,
        'client': _defaultClientPosition
      };
    }
  }
  
  Future<void> _completeOrderAndNavigate() async {
    try {
      // Step 1: Complete the order
      await widget.onComplete();
      
      // Step 2: Get coordinates for tracking
      final coordinates = await _getCoordinates();
      
      // Step 3: Navigate to tracking page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TrackingPage(
              restaurantPosition: coordinates['restaurant']!,
              clientPosition: coordinates['client']!,
            ),
          ),
        );
      }
    } catch (e) {
      print("Error in _completeOrderAndNavigate: $e");
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212529),
      appBar: AppBar(
        backgroundColor: const Color(0xFF212529),
        elevation: 0,
        title: const Text(
          'Traitement de la commande',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: _isProcessing
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFFE79686)),
                SizedBox(height: 20),
                Text(
                  'Traitement de votre commande...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            )
          : _hasError
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Erreur lors du traitement de la commande',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE79686),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Retour'),
                  ),
                ],
              )
            : const SizedBox(),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_bunny/presentation/pages/restaurants_page.dart';
import 'package:mobile_bunny/presentation/pages/home_menu_page.dart';
import 'package:mobile_bunny/presentation/pages/basket_page.dart';
import 'package:mobile_bunny/presentation/providers/address_provider.dart';
import 'package:mobile_bunny/presentation/providers/order_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile_bunny/presentation/pages/tracking_page.dart';
import 'package:mobile_bunny/presentation/providers/tracking_provider.dart';

// Simple provider to check if tracking is active
final isTrackingActiveProvider = Provider<bool>((ref) {
  final trackingState = ref.watch(trackingProvider);
  
  // Check if there are route points and tracking is in progress
  return trackingState.routePoints.isNotEmpty && 
         trackingState.currentStep < trackingState.routePoints.length - 1;
});

class CustomBottomNavigationBar extends ConsumerStatefulWidget {
  const CustomBottomNavigationBar({super.key});
  
  @override
  ConsumerState<CustomBottomNavigationBar> createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends ConsumerState<CustomBottomNavigationBar> {
  int _selectedIndex = 1; // Start with Menu selected (index 1)
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    switch (index) {
      case 0: // Restaurant
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RestaurantsPage()),
        );
        break;
      case 1: // Menu
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MenuPage()),
        );
        break;
      case 2: // Cart
        _navigateToCartOrTracking();
        break;
    }
  }
  
  void _navigateToCartOrTracking() async {
  // Check if tracking is active
  final trackingState = ref.read(trackingProvider);
  final isTrackingActive = trackingState.routePoints.isNotEmpty &&
                         trackingState.currentStep < trackingState.routePoints.length - 1;
  
  if (isTrackingActive) {
    try {
      // Try to get coordinates from the active order
      final orderState = ref.read(orderProvider);
      final order = orderState.activeOrder;
      
      // Default coordinates
      LatLng restaurantPosition = LatLng(46.03115353128858, -73.44116406758411);
      LatLng clientPosition = LatLng(46.02358, -73.43292);
      
      // If there's an active order, try to get coordinates from Firestore
      if (order != null && order.restaurantId.isNotEmpty) {
        try {
          // Try to get restaurant location
          final restaurantDoc = await FirebaseFirestore.instance
              .collection('Restaurants')
              .doc(order.restaurantId)
              .get();
              
          if (restaurantDoc.exists && restaurantDoc.data() != null) {
            final data = restaurantDoc.data()!;
            if (data.containsKey('location') && data['location'] is GeoPoint) {
              final location = data['location'] as GeoPoint;
              restaurantPosition = LatLng(location.latitude, location.longitude);
            }
          }
          
          // Try to get client location
          final addressState = ref.read(addressProvider);
          final selectedAddressId = addressState.selectedAddressId;
          
          if (selectedAddressId != null) {
            final addressDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(order.userId)
                .collection('addresses')
                .doc(selectedAddressId)
                .get();
                
            if (addressDoc.exists && addressDoc.data() != null) {
              final data = addressDoc.data()!;
              if (data.containsKey('location') && data['location'] is GeoPoint) {
                final location = data['location'] as GeoPoint;
                clientPosition = LatLng(location.latitude, location.longitude);
              }
            }
          }
        } catch (e) {
          print("Error getting coordinates for tracking: $e");
          // Continue with default coordinates
        }
      }
      
      // Navigate to tracking page
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrackingPage(
              restaurantPosition: restaurantPosition,
              clientPosition: clientPosition,
              onDeliveryComplete: () {
                try {
                  // Reset tracking when delivery completes
                  ref.read(trackingProvider.notifier).resetTracking();
                  // Refresh the order state
                  ref.read(orderProvider.notifier).refreshActiveOrder();
                } catch (e) {
                  print("Error in onDeliveryComplete: $e");
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      print("Error navigating to tracking: $e");
      // If there's an error, still try to navigate with default coordinates
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrackingPage(
              restaurantPosition: LatLng(46.03115353128858, -73.44116406758411),
              clientPosition: LatLng(46.02358, -73.43292),
              onDeliveryComplete: () {
                try {
                  ref.read(trackingProvider.notifier).resetTracking();
                  ref.read(orderProvider.notifier).refreshActiveOrder();
                } catch (e) {
                  print("Error in fallback onDeliveryComplete: $e");
                }
              },
            ),
          ),
        );
      }
    }
  } else {
    // Otherwise go to basket page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BasketPage()),
    );
  }
}
  
  @override
  Widget build(BuildContext context) {
    // Get cart item count from Riverpod
    final cartItemCount = ref.watch(cartItemCountProvider);
    
    return Container(
      color: const Color(0xFF1C1C1C),
      padding: const EdgeInsets.all(8.0),
      child: BottomNavigationBar(
        backgroundColor: const Color(0xFF1C1C1C),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restaurant'),
          const BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Menu'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                if (cartItemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '$cartItemCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Panier',
          ),
        ],
      ),
    );
  }
}
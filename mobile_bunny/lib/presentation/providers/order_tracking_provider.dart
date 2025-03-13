import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile_bunny/data/models/address.dart';
import 'package:mobile_bunny/presentation/providers/order_provider.dart';
import 'package:mobile_bunny/presentation/providers/restaurant_provider.dart';
import 'package:mobile_bunny/presentation/providers/address_provider.dart';

// Provider to get tracking coordinates for the current order
final orderTrackingCoordinatesProvider = FutureProvider<Map<String, LatLng>>((ref) async {
  // Get current order
  final orderState = ref.watch(orderProvider);
  final order = orderState.activeOrder;
  
  if (order == null) {
    throw Exception('No active order to track');
  }
  
  // Default fallback coordinates
  final defaultRestaurantPosition = LatLng(46.03115353128858, -73.44116406758411);
  final defaultClientPosition = LatLng(46.02358, -73.43292);
  
  // Get restaurant coordinates from the order
  LatLng restaurantPosition;
  final restaurantLocation = order.restaurantAddress.location;
  
  if (restaurantLocation != null) {
    // Use location from order's restaurant address
    restaurantPosition = LatLng(
      restaurantLocation.latitude,
      restaurantLocation.longitude
    );
  } else {
    // Try to get the selected restaurant info
    final restaurantState = ref.watch(restaurantProvider);
    final selectedRestaurant = restaurantState.selectedRestaurant;
    
    if (selectedRestaurant != null && selectedRestaurant.location != null) {
      restaurantPosition = LatLng(
        selectedRestaurant.location!.latitude,
        selectedRestaurant.location!.longitude
      );
    } else {
      // Use a default position as fallback
      restaurantPosition = defaultRestaurantPosition;
    }
  }
  
  // Get delivery address coordinates from the order
  LatLng clientPosition;
  final deliveryLocation = order.deliveryAddress.location;
  
  if (deliveryLocation != null) {
    // Use location from order's delivery address
    clientPosition = LatLng(
      deliveryLocation.latitude,
      deliveryLocation.longitude
    );
  } else {
    // Try to get the selected address info
    final addressState = ref.watch(addressProvider);
    final selectedAddressId = addressState.selectedAddressId;
    
    if (selectedAddressId != null) {
      final selectedAddress = addressState.addresses.firstWhere(
        (addr) => addr.id == selectedAddressId,
        orElse: () => Address(
          id: '', 
          location: null, 
          label: '', 
          street: '', 
          postalCode: '', 
          city: '', 
          createdAt: DateTime.now()
        )
      );
      
      if (selectedAddress != null && selectedAddress.location != null) {
        clientPosition = LatLng(
          selectedAddress.location!.latitude,
          selectedAddress.location!.longitude
        );
      } else {
        // Use a default position as fallback
        clientPosition = defaultClientPosition;
      }
    } else {
      // Use a default position as fallback
      clientPosition = defaultClientPosition;
    }
  }
  
  return {
    'restaurant': restaurantPosition,
    'client': clientPosition
  };
});
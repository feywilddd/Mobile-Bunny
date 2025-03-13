import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_bunny/data/models/address.dart';
import 'package:mobile_bunny/data/models/order.dart';
import 'package:mobile_bunny/data/models/restaurant.dart';
import 'package:mobile_bunny/presentation/providers/order_provider.dart';
import 'package:mobile_bunny/presentation/providers/tracking_provider.dart';

// Updated markOrderCompletedProvider to pass coordinates to tracking
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
      throw e; // Re-throw to allow tracking completion page to handle
    }
  };
});

// Add this extension method to read GeoPoint from models
extension AddressExtension on Address {
  // Helper to check if the address has valid coordinates
  bool hasValidLocation() {
    return location != null;
  }
}

// Add this extension method to Restaurant model
extension RestaurantExtension on Restaurant {
  // Helper to check if the restaurant has valid coordinates
  bool hasValidLocation() {
    return location != null;
  }
}

// Helper provider to reset tracking
final resetTrackingProvider = Provider<void Function()>((ref) {
  return () {
    try {
      // Reset tracking state
      ref.read(trackingProvider.notifier).resetTracking();
      
      // Refresh active order
      ref.read(orderProvider.notifier).refreshActiveOrder();
      
      print("Tracking reset successfully");
    } catch (e) {
      print("Error resetting tracking: $e");
    }
  };
});
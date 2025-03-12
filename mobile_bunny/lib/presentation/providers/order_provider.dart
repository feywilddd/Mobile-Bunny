import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:mobile_bunny/data/models/address.dart';
import 'package:mobile_bunny/data/models/menu_item.dart';
import 'package:mobile_bunny/presentation/providers/auth_provider.dart';
import '../../data/models/order.dart';
import '../../data/repositories/order_repository.dart'; 
// Import your models and repositories
// import 'order_model.dart';
// import 'order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final user = ref.watch(authProvider);
  
  if (user == null) {
    throw Exception('User must be logged in to access orders');
  }
  
  return OrderRepository(userId: user.uid);
});

// Provider for active order stream
final activeOrderStreamProvider = StreamProvider<Order?>((ref) {
  final user = ref.watch(authProvider);
  
  // If no user, return empty stream
  if (user == null) {
    return Stream.value(null);
  }
  
  final repository = ref.watch(orderRepositoryProvider);
  return repository.streamActiveOrder();
});

// Provider for active order (async value)
final activeOrderProvider = FutureProvider<Order?>((ref) {
  final user = ref.watch(authProvider);
  
  // If no user, return null
  if (user == null) {
    return Future.value(null);
  }
  
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getActiveOrder();
});

// Provider for order history
final orderHistoryProvider = FutureProvider<List<Order>>((ref) {
  final user = ref.watch(authProvider);
  
  // If no user, return empty list
  if (user == null) {
    return Future.value([]);
  }
  
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getOrderHistory();
});

// NotifierProvider for cart operations
class OrderNotifier extends AsyncNotifier<Order?> {
  @override
  Future<Order?> build() async {
    final user = ref.read(authProvider);
    
    // If no user, return null
    if (user == null) {
      return null;
    }
    
    final repository = ref.read(orderRepositoryProvider);
    return repository.getActiveOrder();
  }
  
  // Check if user is authenticated before operations
  void _checkAuth() {
    final user = ref.read(authProvider);
    if (user == null) {
      print('User must be logged in to perform this action');
      throw Exception('User must be logged in to perform this action');
    }
  }
  
  // Create a new order
 Future<void> createOrder({  required String restaurantId,
    required Address restaurantAddress,
    required Address deliveryAddress}) async {
  _checkAuth();
  
  state = const AsyncValue.loading();
  
  state = await AsyncValue.guard(() async {
    try {
      final repository = ref.read(orderRepositoryProvider);
        
      print("Creating new order with restaurantId: $restaurantId");
      final result = await repository.createOrder(
        restaurantId: restaurantId,
        restaurantAddress: restaurantAddress,
        deliveryAddress: deliveryAddress,
      );
      
      print("Order creation completed successfully");
      return result;
    } catch (e) {
      print("Error in createOrder: $e");
      rethrow;
    }
  });
}
  
  // Add item to order
  Future<void> addItem(MenuItem menuItem, {int quantity = 1}) async {

  
  state = const AsyncValue.loading();
  
  state = await AsyncValue.guard(() async {
    // Get the repository
    final repository = ref.read(orderRepositoryProvider);
    
    // Get the latest order - don't rely on state.value which might be stale
    final activeOrder = await repository.getActiveOrder();
    
    if (activeOrder == null) {
      throw Exception('Failed to find active order');
    }
    
    // Now add the item to the order
    return repository.addItemToOrder(menuItem, quantity: quantity);
  });
}
  // Update item quantity
  Future<void> updateItemQuantity(String menuItemId, int quantity) async {
    _checkAuth();
    
    if (state.value == null) {
      throw Exception('No active order.');
    }
    
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      final repository = ref.read(orderRepositoryProvider);
      return repository.updateItemQuantity(menuItemId, quantity);
    });
  }
  
  // Remove item from order
  Future<void> removeItem(String menuItemId) async {
    _checkAuth();
    
    if (state.value == null) {
      throw Exception('No active order.');
    }
    
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      final repository = ref.read(orderRepositoryProvider);
      return repository.removeItem(menuItemId);
    });
  }
  
  // Update order status
  Future<void> updateOrderStatus(OrderStatus newStatus) async {
    _checkAuth();
    
    if (state.value == null) {
      throw Exception('No active order.');
    }
    
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      final repository = ref.read(orderRepositoryProvider);
      return repository.updateOrderStatus(newStatus);
    });
  }
  
  // Submit order for processing
  Future<void> submitOrder() async {
    _checkAuth();
    
    if (state.value == null) {
      throw Exception('No active order to submit.');
    }
    
    // Only submit if it's a draft
    if (state.value!.status != OrderStatus.draft) {
      throw Exception('Order has already been submitted.');
    }
    
    // Update status to pending
    await updateOrderStatus(OrderStatus.pending);
  }
  
  // Cancel order
  Future<void> cancelOrder() async {
    _checkAuth();
    
    if (state.value == null) {
      throw Exception('No active order to cancel.');
    }
    
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      final repository = ref.read(orderRepositoryProvider);
      await repository.cancelActiveOrder();
      return null;
    });
  }
}

final orderNotifierProvider = AsyncNotifierProvider<OrderNotifier, Order?>(() {
  return OrderNotifier();
});

// Helper provider for total items in cart
final cartItemCountProvider = Provider<int>((ref) {
  final orderAsyncValue = ref.watch(activeOrderProvider);
  
  return orderAsyncValue.when(
    data: (order) {
      if (order == null) return 0;
      
      return order.items.fold(0, (total, item) => total + item.quantity);
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Helper provider for cart subtotal
final cartSubtotalProvider = Provider<double>((ref) {
  final orderAsyncValue = ref.watch(activeOrderProvider);
  
  return orderAsyncValue.when(
    data: (order) {
      if (order == null) return 0.0;
      return order.subtotal;
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

// In order_provider.dart, add these providers

// Provider for current restaurant ID
final currentRestaurantIdProvider = StateProvider<String?>((ref) => null);

// Provider for current restaurant address
final currentRestaurantAddressProvider = StateProvider<Address?>((ref) => null);

// Modified add to cart function that doesn't need restaurant data passed to each item
final addToCartFunctionProvider = Provider<Future<void> Function(MenuItem)>((ref) {
  return (MenuItem menuItem) async {
    final user = ref.read(authProvider);
    if (user == null) {
      throw Exception('User must be logged in');
    }
    
    final restaurantId = ref.read(currentRestaurantIdProvider);
    final restaurantAddress = ref.read(currentRestaurantAddressProvider);
    
    if (restaurantId == null || restaurantAddress == null) {
      throw Exception('Restaurant information not available');
    }
    
    final orderNotifier = ref.read(orderNotifierProvider.notifier);
    final activeOrder = await ref.read(activeOrderProvider.future);
    
    // Create order if needed
    if (activeOrder == null) {
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
      
      await orderNotifier.createOrder(
        restaurantId: restaurantId,
        restaurantAddress: restaurantAddress,
        deliveryAddress: deliveryAddress,
      );
    }
    
    // Add the item
    return orderNotifier.addItem(menuItem);
  };
});

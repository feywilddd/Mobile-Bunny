import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_bunny/data/models/menu_item.dart';
import 'package:mobile_bunny/presentation/providers/auth_provider.dart';
import 'package:mobile_bunny/presentation/providers/restaurant_provider.dart';
import 'package:mobile_bunny/presentation/providers/address_provider.dart';
import '../../data/models/order.dart';
import '../../data/repositories/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final user = ref.watch(authProvider);
  
  if (user == null) {
    throw Exception('User must be logged in to access orders');
  }
  
  return OrderRepository(userId: user.uid);
});

// State class for order data
class OrderState {
  final Order? activeOrder;
  final List<Order> orderHistory;
  final bool isLoading;
  final String? error;

  OrderState({
    this.activeOrder,
    this.orderHistory = const [],
    this.isLoading = false,
    this.error,
  });

  OrderState copyWith({
    Order? activeOrder,
    List<Order>? orderHistory,
    bool? isLoading,
    String? error,
  }) {
    return OrderState(
      activeOrder: activeOrder,
      orderHistory: orderHistory ?? this.orderHistory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
  
  // Helper methods
  bool get hasActiveOrder => activeOrder != null;
  int get cartItemCount => activeOrder?.items.fold(0, (sum, item) => sum! + item.quantity) ?? 0;
  double get cartSubtotal => activeOrder?.subtotal ?? 0.0;
  double get cartTotal => activeOrder?.total ?? 0.0;
}

// StateNotifier for order management
class OrderNotifier extends StateNotifier<OrderState> {
  final OrderRepository _repository;
  final Ref _ref;

  OrderNotifier(this._repository, this._ref) : super(OrderState()) {
    // Initialize by fetching active order
    refreshActiveOrder();
  }

  // Check if user is authenticated
  void _checkAuth() {
    final user = _ref.read(authProvider);
    if (user == null) {
      print('User must be logged in to perform this action');
      throw Exception('User must be logged in to perform this action');
    }
  }

  // Refresh the active order
  Future<void> refreshActiveOrder() async {
    // Skip if not logged in
    final user = _ref.read(authProvider);
    if (user == null) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final activeOrder = await _repository.getActiveOrder();
      
      state = state.copyWith(
        activeOrder: activeOrder,
        isLoading: false,
      );
    } catch (e) {
      print('Error fetching active order: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch active order: $e',
      );
    }
  }

  // Load order history
  Future<void> loadOrderHistory() async {
    _checkAuth();
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final history = await _repository.getOrderHistory();
      
      state = state.copyWith(
        orderHistory: history,
        isLoading: false,
      );
    } catch (e) {
      print('Error fetching order history: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch order history: $e',
      );
    }
  }

  // Create a new order
  Future<bool> createOrder() async {
    _checkAuth();
    
    // Check if there's already an active order
    if (state.activeOrder != null) {
      state = state.copyWith(
        error: 'Vous avez déjà une commande active',
      );
      return false;
    }
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // The repository now handles all the logic for getting restaurant and address data
      final newOrder = await _repository.createOrder();
      
      state = state.copyWith(
        activeOrder: newOrder,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      print("Error creating order: $e");
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la création de la commande: $e',
      );
      return false;
    }
  }

  // Add item to order
  Future<bool> addItem(MenuItem menuItem, {int quantity = 1}) async {
    _checkAuth();
    
    try {
      print("Adding item to cart: ${menuItem.name}, quantity: $quantity");
      
      // If no active order, create one first
      if (state.activeOrder == null) {
        print("No active order - creating a new one");
        final created = await createOrder();
        if (!created) {
          print("Failed to create order");
          return false;
        }
      }
      
      print("Adding item to existing order");
      state = state.copyWith(isLoading: true, error: null);
      
      try {
        final updatedOrder = await _repository.addItemToOrder(menuItem, quantity: quantity);
        
        if (updatedOrder != null) {
          print("Item added successfully");
          state = state.copyWith(
            activeOrder: updatedOrder,
            isLoading: false,
          );
          return true;
        } else {
          print("Repository returned null order after adding item");
          state = state.copyWith(
            isLoading: false,
            error: 'Erreur lors de l\'ajout de l\'article au panier',
          );
          return false;
        }
      } catch (e) {
        print("Error adding item to order: $e");
        state = state.copyWith(
          isLoading: false,
          error: 'Erreur lors de l\'ajout de l\'article au panier: $e',
        );
        return false;
      }
    } catch (e) {
      print("Unexpected error in addItem: $e");
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur inattendue: $e',
      );
      return false;
    }
  }

  // Update item quantity
  Future<bool> updateItemQuantity(String menuItemId, int quantity) async {
    _checkAuth();
    
    if (state.activeOrder == null) {
      state = state.copyWith(
        error: 'No active order found',
      );
      return false;
    }
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final updatedOrder = await _repository.updateItemQuantity(menuItemId, quantity);
      
      state = state.copyWith(
        activeOrder: updatedOrder,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      print('Error updating item quantity: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update item quantity: $e',
      );
      return false;
    }
  }

  // Remove item from order
  Future<bool> removeItem(String menuItemId) async {
    _checkAuth();
    
    if (state.activeOrder == null) {
      state = state.copyWith(
        error: 'No active order found',
      );
      return false;
    }
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final updatedOrder = await _repository.removeItem(menuItemId);
      
      state = state.copyWith(
        activeOrder: updatedOrder,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      print('Error removing item from order: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to remove item from order: $e',
      );
      return false;
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(OrderStatus newStatus) async {
    _checkAuth();
    
    if (state.activeOrder == null) {
      state = state.copyWith(
        error: 'No active order found',
      );
      return false;
    }
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final updatedOrder = await _repository.updateOrderStatus(newStatus);
      
      state = state.copyWith(
        activeOrder: updatedOrder,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      print('Error updating order status: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update order status: $e',
      );
      return false;
    }
  }

  // Submit order for processing
  Future<bool> submitOrder() async {
    _checkAuth();
    
    if (state.activeOrder == null) {
      state = state.copyWith(
        error: 'No active order to submit',
      );
      return false;
    }
    
    // Only submit if it's a draft
    if (state.activeOrder!.status != OrderStatus.draft) {
      state = state.copyWith(
        error: 'Order has already been submitted',
      );
      return false;
    }
    
    return updateOrderStatus(OrderStatus.pending);
  }

  // Cancel order
  Future<bool> cancelOrder() async {
    _checkAuth();
    
    if (state.activeOrder == null) {
      state = state.copyWith(
        error: 'No active order to cancel',
      );
      return false;
    }
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _repository.cancelActiveOrder();
      
      state = state.copyWith(
        activeOrder: null,
        isLoading: false,
      );
      
      await loadOrderHistory(); // Refresh order history
      
      return true;
    } catch (e) {
      print('Error cancelling order: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to cancel order: $e',
      );
      return false;
    }
  }
}

// Provider for the order state
final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  return OrderNotifier(repository, ref);
});

// Simpler providers for UI access

// Provider to check if there's an active order
final hasActiveOrderProvider = Provider<bool>((ref) {
  final orderState = ref.watch(orderProvider);
  return orderState.hasActiveOrder;
});

// Provider for cart item count
final cartItemCountProvider = Provider<int>((ref) {
  final orderState = ref.watch(orderProvider);
  return orderState.cartItemCount;
});

// Provider for cart subtotal
final cartSubtotalProvider = Provider<double>((ref) {
  final orderState = ref.watch(orderProvider);
  return orderState.cartSubtotal;
});

// Provider for cart total
final cartTotalProvider = Provider<double>((ref) {
  final orderState = ref.watch(orderProvider);
  return orderState.cartTotal;
});

// Provider to get order error state
final orderErrorProvider = Provider<String?>((ref) {
  final orderState = ref.watch(orderProvider);
  return orderState.error;
});

// Provider to get order loading state
final orderLoadingProvider = Provider<bool>((ref) {
  final orderState = ref.watch(orderProvider);
  return orderState.isLoading;
});

// Provider to check if an order can be created
final canCreateOrderProvider = Provider<bool>((ref) {
  final hasActiveOrder = ref.watch(hasActiveOrderProvider);
  if (hasActiveOrder) return false;
  
  final hasSelectedRestaurant = ref.watch(hasSelectedRestaurantProvider);
  final hasSelectedAddress = ref.watch(hasSelectedAddressProvider);
  
  return hasSelectedRestaurant && hasSelectedAddress;
});

// Simplified add to cart function
final addToCartFunctionProvider = Provider<Future<bool> Function(MenuItem, {int quantity})>((ref) {
  return (MenuItem menuItem, {int quantity = 1}) {
    final orderNotifier = ref.read(orderProvider.notifier);
    return orderNotifier.addItem(menuItem, quantity: quantity);
  };
});
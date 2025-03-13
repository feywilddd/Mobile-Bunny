import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:mobile_bunny/data/models/order.dart' as models;
import 'package:mobile_bunny/data/models/address.dart';
import 'package:mobile_bunny/data/models/menu_item.dart';
import 'package:mobile_bunny/data/models/restaurant.dart';
import 'package:mobile_bunny/data/repositories/restaurant_repository.dart';
import 'package:mobile_bunny/data/repositories/address_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderRepository {
  final FirebaseFirestore _firestore;
  final String _userId;
  final RestaurantRepository _restaurantRepository;
  final AddressRepository _addressRepository;
  
  // Collection names
  static const String _ordersCollection = 'orders';
  static const String _usersCollection = 'users';
  
  OrderRepository({
    required String userId,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    RestaurantRepository? restaurantRepository,
    AddressRepository? addressRepository,
  }) : 
    _userId = userId,
    _firestore = firestore ?? FirebaseFirestore.instance,
    _restaurantRepository = restaurantRepository ?? RestaurantRepository(
      firestore: firestore,
      auth: auth ?? FirebaseAuth.instance,
    ),
    _addressRepository = addressRepository ?? AddressRepository(
      firestore: firestore,
      auth: auth ?? FirebaseAuth.instance,
    );

  // Reference to the active order document for this user
  DocumentReference get _activeOrderRef => 
    _firestore.collection(_usersCollection).doc(_userId).collection('active_order').doc('current');
  
  // Reference to all orders for this user
  Query<Map<String, dynamic>> get _userOrdersRef =>
    _firestore.collection(_ordersCollection).where('userId', isEqualTo: _userId);
  
  // Get the active order for the current user
  Future<models.Order?> getActiveOrder() async {
    try {
      final docSnap = await _activeOrderRef.get();
      
      if (!docSnap.exists || docSnap.data() == null) {
        return null;
      }
      
      // The active_order document just contains a reference to the actual order
      final String orderId = docSnap.get('orderId');
      
      final orderDoc = await _firestore.collection(_ordersCollection).doc(orderId).get();
      
      if (!orderDoc.exists || orderDoc.data() == null) {
        return null;
      }
      
      return models.Order.fromMap(orderDoc.id, orderDoc.data()!);
    } catch (e) {
      print('Error fetching active order: $e');
      return null;
    }
  }
  
  // Stream of the active order (for real-time updates)
  Stream<models.Order?> streamActiveOrder() {
    return _activeOrderRef.snapshots().asyncMap((docSnap) async {
      if (!docSnap.exists || docSnap.data() == null) {
        return null;
      }
      
      final String orderId = docSnap.get('orderId');
      final orderDoc = await _firestore.collection(_ordersCollection).doc(orderId).get();
      
      if (!orderDoc.exists || orderDoc.data() == null) {
        return null;
      }
      
      return models.Order.fromMap(orderDoc.id, orderDoc.data()!);
    });
  }
  

  // Update an existing order
  Future<models.Order> updateOrder(models.Order updatedOrder) async {
    final orderRef = _firestore.collection(_ordersCollection).doc(updatedOrder.id);
    
    await orderRef.update(updatedOrder.toMap());
    
    return updatedOrder;
  }
  
  // Add an item to the active order
  Future<models.Order?> addItemToOrder(MenuItem menuItem, {int quantity = 1}) async {
    print("Adding item to order: ${menuItem.name}, quantity: $quantity");
    
    try {
      // Get the active order
      final activeOrder = await getActiveOrder();
      
      if (activeOrder == null) {
        print("No active order found, creating one first");
        // Create an order first, then add the item
        final newOrder = await createOrder();
        final updatedOrder = newOrder.addItem(menuItem, quantity: quantity);
        return await updateOrder(updatedOrder);
      }
      
      print("Adding item to existing order: ${activeOrder.id}");
      final updatedOrder = activeOrder.addItem(menuItem, quantity: quantity);
      return await updateOrder(updatedOrder);
    } catch (e) {
      print("Error adding item to order: $e");
      rethrow;
    }
  }
  
  // Update item quantity in the active order
  Future<models.Order?> updateItemQuantity(String menuItemId, int quantity) async {
    final activeOrder = await getActiveOrder();
    
    if (activeOrder == null) {
      throw Exception('No active order found.');
    }
    
    final updatedOrder = activeOrder.updateItemQuantity(menuItemId, quantity);
    return await updateOrder(updatedOrder);
  }
  
  // Remove an item from the active order
  Future<models.Order?> removeItem(String menuItemId) async {
    final activeOrder = await getActiveOrder();
    
    if (activeOrder == null) {
      throw Exception('No active order found.');
    }
    
    final updatedOrder = activeOrder.removeItem(menuItemId);
    return await updateOrder(updatedOrder);
  }
  // Cancel the active order
  Future<void> cancelActiveOrder() async {
    final activeOrder = await getActiveOrder();
    
    if (activeOrder == null) {
      throw Exception('No active order found to cancel.');
    }
    
    // Update status to cancelled
    final cancelledOrder = activeOrder.updateStatus(models.OrderStatus.delivered);
    await updateOrder(cancelledOrder);
    
    // Remove from active orders
    await completeActiveOrder();
  }
  
  // Get order history for the user
  Future<List<models.Order>> getOrderHistory() async {
    try {
      final querySnapshot = await _firestore
          .collection(_ordersCollection)
          .where('userId', isEqualTo: _userId)
          .where('status', whereIn: [
            models.OrderStatus.delivered.name
          ])
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => models.Order.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching order history: $e');
      return [];
    }
  }
  
  // Check if a restaurant is selected
  Future<bool> isRestaurantSelected() async {
    final selectedRestaurantId = await _restaurantRepository.getSelectedRestaurantId();
    return selectedRestaurantId != null;
  }

   Future<models.Order?> updateOrderStatus(models.OrderStatus newStatus) async {
    final activeOrder = await getActiveOrder();
    
    if (activeOrder == null) {
      throw Exception('No active order found.');
    }
    
    final updatedOrder = activeOrder.updateStatus(newStatus);
    return await updateOrder(updatedOrder);
  }
  
  // Complete the active order (removes it from active to allow new orders)
  Future<void> completeActiveOrder() async {
    try {
      final activeOrder = await getActiveOrder();
      
      if (activeOrder == null) {
        print('No active order found to complete.');
        return; // Just return instead of throwing an exception
      }
      
      // Remove the active_order reference
      await _activeOrderRef.delete();
      
      print('Active order completed successfully');
    } catch (e) {
      print('Error completing active order: $e');
      rethrow;
    }
  }
  
  // Check if user has an active order
  Future<bool> hasActiveOrder() async {
    final activeOrder = await getActiveOrder();
    return activeOrder != null;
  }
  
  Future<models.Order> createOrder() async {
    print("Creating order in Firestore with userId: $_userId");
    
    // Check if there's already an active order
    final existingOrder = await getActiveOrder();
    if (existingOrder != null) {
      print("User already has an active order");
      throw Exception('User already has an active order. Please complete or cancel it first.');
    }
    
    // Get the selected restaurant ID
    final selectedRestaurantId = await _restaurantRepository.getSelectedRestaurantId();
    if (selectedRestaurantId == null) {
      throw Exception('No restaurant selected. Please select a restaurant first.');
    }
    
    print("Selected restaurant ID: $selectedRestaurantId");
    
    // Get restaurant data directly from Firestore for reliability
    final restaurantDoc = await _firestore.collection('Restaurants').doc(selectedRestaurantId).get();
    
    if (!restaurantDoc.exists) {
      throw Exception('Selected restaurant not found.');
    }
    
    final restaurantData = restaurantDoc.data()!;
    
    // Get the selected delivery address
    final selectedAddressId = await _addressRepository.getSelectedAddressId();
    if (selectedAddressId == null) {
      throw Exception('No delivery address selected. Please select a delivery address first.');
    }
    
    final addresses = await _addressRepository.fetchAddresses();
    final deliveryAddress = addresses.firstWhere(
      (address) => address.id == selectedAddressId,
      orElse: () => throw Exception('Selected delivery address not found.')
    );
    
    // Create restaurant address manually from Firestore data
    final restaurantAddress = Address(
      id: selectedRestaurantId,
      label: 'Restaurant',
      street: restaurantData['address'] ?? 'Unknown address',
      postalCode: '',  // Not available in restaurant data
      city: 'Joliette', // Default city
      additionalInfo: '',
      createdAt: DateTime.now(),
    );
    
    print("Restaurant address: ${restaurantAddress.street}");
    print("Delivery address: ${deliveryAddress.street}");
    
    // Create a new order
    final newOrder = models.Order.create(
      userId: _userId,
      restaurantId: selectedRestaurantId,
      restaurantAddress: restaurantAddress,
      deliveryAddress: deliveryAddress,
    );
    
    print("New order created in memory: ${newOrder.toMap()}");
    
    // Add to Firestore
    final orderRef = _firestore.collection(_ordersCollection).doc();
    final orderWithId = newOrder.copyWith(id: orderRef.id);
    
    try {
      // Create the order and set it as active in a transaction
      await _firestore.runTransaction((transaction) async {
        print("Starting Firestore transaction");
        transaction.set(orderRef, orderWithId.toMap());
        transaction.set(_activeOrderRef, {
          'orderId': orderRef.id,
          'createdAt': FieldValue.serverTimestamp(),
        });
        print("Transaction commands queued");
      });
      
      print("Order created in Firestore with ID: ${orderRef.id}");
      return orderWithId;
    } catch (e) {
      print("Error creating order in Firestore: $e");
      rethrow;
    }
  }
}
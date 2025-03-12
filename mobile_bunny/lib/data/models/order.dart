import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_bunny/data/models/address.dart';
import 'package:mobile_bunny/data/models/menu_item.dart';

class OrderItem {
  final String menuItemId;
  final String name;
  final double price;
  final String description;
  final int quantity;
  
  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.description,
    required this.quantity,
  });
  
  factory OrderItem.fromMenuItem(MenuItem menuItem, int quantity) {
    return OrderItem(
      menuItemId: menuItem.id,
      name: menuItem.name,
      price: menuItem.price,
      description: menuItem.description,
      quantity: quantity,
    );
  }
  
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      menuItemId: map['menuItemId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] as num).toDouble(),
      description: map['description'] ?? '',
      quantity: map['quantity'] ?? 1,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'description': description,
      'quantity': quantity,
    };
  }
  
  OrderItem copyWith({
    String? menuItemId,
    String? name,
    double? price,
    String? description,
    int? quantity,
  }) {
    return OrderItem(
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
    );
  }
  
  double get totalPrice => price * quantity;
}

enum OrderStatus {
  draft, // Initial state, being built
  pending, // Sent to restaurant but not confirmed
  confirmed, // Restaurant confirmed order
  preparing, // Food being prepared
  readyForPickup, // Ready for delivery person
  inDelivery, // On the way to customer
  delivered, // Successfully delivered
  cancelled, // Cancelled by customer, restaurant, or system
}

extension OrderStatusExtension on OrderStatus {
  String get name {
    switch (this) {
      case OrderStatus.draft: return 'Draft';
      case OrderStatus.pending: return 'Pending';
      case OrderStatus.confirmed: return 'Confirmed';
      case OrderStatus.preparing: return 'Preparing';
      case OrderStatus.readyForPickup: return 'Ready for Pickup';
      case OrderStatus.inDelivery: return 'In Delivery';
      case OrderStatus.delivered: return 'Delivered';
      case OrderStatus.cancelled: return 'Cancelled';
    }
  }
}

class Order {
  final String id;
  final String userId;
  final String restaurantId;
  final Address restaurantAddress;
  final Address deliveryAddress;
  final List<OrderItem> items;
  final OrderStatus status;
  final double subtotal;
  final double taxTPS;
  final double taxTVQ;
  final double deliveryFee;
  final double total;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;
  
  Order({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.restaurantAddress,
    required this.deliveryAddress,
    required this.items,
    required this.status,
    required this.subtotal,
    required this.taxTPS,
    required this.taxTVQ,
    required this.deliveryFee,
    required this.total,
    required this.createdAt,
    this.updatedAt,
    this.notes,
  });
  
  factory Order.create({
    required String userId,
    required String restaurantId,
    required Address restaurantAddress,
    required Address deliveryAddress,
  }) {
    final now = DateTime.now();
    // Default delivery fee will be updated from restaurant when recalculating
    const defaultDeliveryFee = 0.0;
    
    return Order(
      id: '', // Will be assigned by Firestore
      userId: userId,
      restaurantId: restaurantId,
      restaurantAddress: restaurantAddress,
      deliveryAddress: deliveryAddress,
      items: [],
      status: OrderStatus.draft,
      subtotal: 0,
      taxTPS: 0,
      taxTVQ: 0,
      deliveryFee: defaultDeliveryFee,
      total: 0,
      createdAt: now,
      updatedAt: now,
    );
  }
  
  factory Order.fromMap(String id, Map<String, dynamic> map) {
    final items = (map['items'] as List?)?.map((item) => OrderItem.fromMap(item)).toList() ?? [];
    
    return Order(
      id: id,
      userId: map['userId'] ?? '',
      restaurantId: map['restaurantId'] ?? '',
      restaurantAddress: Address.fromMap(
        map['restaurantAddressId'] ?? '',
        map['restaurantAddress'] ?? {},
      ),
      deliveryAddress: Address.fromMap(
        map['deliveryAddressId'] ?? '',
        map['deliveryAddress'] ?? {},
      ),
      items: items,
      status: _statusFromString(map['status'] ?? ''),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxTPS: (map['taxTPS'] as num?)?.toDouble() ?? 0.0,
      taxTVQ: (map['taxTVQ'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      notes: map['notes'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'restaurantId': restaurantId,
      'restaurantAddressId': restaurantAddress.id,
      'restaurantAddress': restaurantAddress.toMap(),
      'deliveryAddressId': deliveryAddress.id,
      'deliveryAddress': deliveryAddress.toMap(),
      'items': items.map((item) => item.toMap()).toList(),
      'status': status.name,
      'subtotal': subtotal,
      'taxTPS': taxTPS,
      'taxTVQ': taxTVQ,
      'deliveryFee': deliveryFee,
      'total': total,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? DateTime.now(),
      'notes': notes,
    };
  }
  
  Order copyWith({
    String? id,
    String? userId,
    String? restaurantId,
    Address? restaurantAddress,
    Address? deliveryAddress,
    List<OrderItem>? items,
    OrderStatus? status,
    double? subtotal,
    double? taxTPS,
    double? taxTVQ,
    double? deliveryFee,
    double? total,
    String? notes,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantAddress: restaurantAddress ?? this.restaurantAddress,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      items: items ?? this.items,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      taxTPS: taxTPS ?? this.taxTPS,
      taxTVQ: taxTVQ ?? this.taxTVQ,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      notes: notes ?? this.notes,
    );
  }
  
  // Add an item to the order
  Order addItem(MenuItem menuItem, {int quantity = 1}) {
    final existingItemIndex = items.indexWhere((item) => item.menuItemId == menuItem.id);
    
    List<OrderItem> updatedItems = List.from(items);
    
    if (existingItemIndex >= 0) {
      // Update quantity of existing item
      final existingItem = items[existingItemIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + quantity
      );
      updatedItems[existingItemIndex] = updatedItem;
    } else {
      // Add new item
      updatedItems.add(OrderItem.fromMenuItem(menuItem, quantity));
    }
    
    return _recalculateOrder(updatedItems);
  }
  
  // Update quantity of an item
  Order updateItemQuantity(String menuItemId, int quantity) {
    if (quantity <= 0) {
      return removeItem(menuItemId);
    }
    
    final updatedItems = items.map((item) {
      if (item.menuItemId == menuItemId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    
    return _recalculateOrder(updatedItems);
  }
  
  // Remove an item from the order
  Order removeItem(String menuItemId) {
    final updatedItems = items.where((item) => item.menuItemId != menuItemId).toList();
    return _recalculateOrder(updatedItems);
  }
  
  // Recalculate totals when items change
  Order _recalculateOrder(List<OrderItem> updatedItems) {
    const tpsRate = 0.05; // 5% TPS
    const tvqRate = 0.09975; // 9.975% TVQ
    
    final newSubtotal = updatedItems.fold<double>(
      0, (sum, item) => sum + (item.price * item.quantity)
    );
    
    final newTaxTPS = newSubtotal * tpsRate;
    final newTaxTVQ = newSubtotal * tvqRate;
    final newTotal = newSubtotal + newTaxTPS + newTaxTVQ + deliveryFee;
    
    return copyWith(
      items: updatedItems,
      subtotal: newSubtotal,
      taxTPS: newTaxTPS,
      taxTVQ: newTaxTVQ,
      total: newTotal,
    );
  }
  
  // Update delivery fee and recalculate total
  Order updateDeliveryFee(double newDeliveryFee) {
    if (newDeliveryFee == deliveryFee) {
      return this;
    }
    
    const tpsRate = 0.05; // 5% TPS
    const tvqRate = 0.09975; // 9.975% TVQ
    
    final newTotal = subtotal + taxTPS + taxTVQ + newDeliveryFee;
    
    return copyWith(
      deliveryFee: newDeliveryFee,
      total: newTotal,
    );
  }
  
  // Update order status
  Order updateStatus(OrderStatus newStatus) {
    return copyWith(status: newStatus);
  }
  
  static OrderStatus _statusFromString(String statusStr) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => OrderStatus.draft,
    );
  }
}
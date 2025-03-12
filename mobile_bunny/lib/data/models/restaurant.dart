import 'package:cloud_firestore/cloud_firestore.dart';
import 'address.dart';

class Restaurant {
  final String id;
  final String name;
  final String address; // Raw address string
  final GeoPoint location; // Geo coordinates
  final DateTime openingTime;
  final DateTime closingTime;
  
  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.openingTime,
    required this.closingTime,
  });
  
  bool get isOpen {
    final now = DateTime.now();
    return now.isAfter(openingTime) && now.isBefore(closingTime);
  }
  
  factory Restaurant.fromMap(String id, Map<String, dynamic> map) {
    return Restaurant(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      location: map['location'] ?? GeoPoint(0, 0),
      openingTime: (map['opening_time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      closingTime: (map['closing_time'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'location': location,
      'opening_time': openingTime,
      'closing_time': closingTime,
    };
  }
  
  // Helper to create Address object for the Order model
  Address toOrderAddress() {
    return Address(
      id: id, // Using restaurant ID as address ID
      label: name, // Using restaurant name as label
      street: address, // Full address string
      postalCode: '', // Not available in this model
      city: '', // Not available in this model
      additionalInfo: '',
      createdAt: DateTime.now(),
    );
  }
}
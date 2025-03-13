import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Update your Address model class to use GeoPoint
class Address {
  final String id;
  final String label;
  final String street;
  final String postalCode;
  final String city;
  final String? additionalInfo;
  final DateTime createdAt;
  final GeoPoint? location;  // Use GeoPoint instead of separate lat/lng
  
  Address({
    required this.id,
    required this.label,
    required this.street,
    required this.postalCode,
    required this.city,
    this.additionalInfo,
    required this.createdAt,
    this.location,  // Use GeoPoint
  });
  
  factory Address.fromMap(String id, Map<String, dynamic> map) {
    return Address(
      id: id,
      label: map['label'] ?? '',
      street: map['street'] ?? '',
      postalCode: map['postalCode'] ?? '',
      city: map['city'] ?? '',
      additionalInfo: map['additionalInfo'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: map['location'] as GeoPoint?,  // Parse GeoPoint directly
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'street': street,
      'postalCode': postalCode,
      'city': city,
      'additionalInfo': additionalInfo,
      'createdAt': createdAt,
      'location': location,  // Store as GeoPoint
    };
  }
  
  // Helper method to get LatLng for Google Maps
  LatLng? getLatLng() {
    if (location == null) return null;
    return LatLng(location!.latitude, location!.longitude);
  }
  
  // Add a copyWith method if you don't already have one
  Address copyWith({
    String? id,
    String? label,
    String? street,
    String? postalCode,
    String? city,
    String? additionalInfo,
    DateTime? createdAt,
    GeoPoint? location,
  }) {
    return Address(
      id: id ?? this.id,
      label: label ?? this.label,
      street: street ?? this.street,
      postalCode: postalCode ?? this.postalCode,
      city: city ?? this.city,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
    );
  }
}
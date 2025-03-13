import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Restaurant {
  final String id;
  final String name;
  final String address;
  final String? phoneNumber;
  final String? imageUrl;
  final List<String> categories;
  final double rating;
  final int reviewCount;
  final GeoPoint? location;  // Use GeoPoint instead of separate lat/lng
  
  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    this.phoneNumber,
    this.imageUrl,
    this.categories = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.location,  // Use GeoPoint
  });
  
  factory Restaurant.fromMap(String id, Map<String, dynamic> map) {
    return Restaurant(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      phoneNumber: map['phoneNumber'],
      imageUrl: map['imageUrl'],
      categories: List<String>.from(map['categories'] ?? []),
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      location: map['location'] as GeoPoint?,  // Parse GeoPoint directly
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phoneNumber': phoneNumber,
      'imageUrl': imageUrl,
      'categories': categories,
      'rating': rating,
      'reviewCount': reviewCount,
      'location': location,  // Store as GeoPoint
    };
  }
  
  // Helper method to get LatLng for Google Maps
  LatLng? getLatLng() {
    if (location == null) return null;
    return LatLng(location!.latitude, location!.longitude);
  }
  
  // Add a copyWith method if you don't already have one
  Restaurant copyWith({
    String? id,
    String? name,
    String? address,
    String? phoneNumber,
    String? imageUrl,
    List<String>? categories,
    double? rating,
    int? reviewCount,
    GeoPoint? location,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      imageUrl: imageUrl ?? this.imageUrl,
      categories: categories ?? this.categories,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      location: location ?? this.location,
    );
  }
}
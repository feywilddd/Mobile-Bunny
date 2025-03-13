import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/address.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AddressRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  
  // You would replace this with your actual API key
  final String _geocodingApiKey = dotenv.get('MAP_API_KEY');
  
  AddressRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;
 
  // Get current user ID or null if not authenticated
  String? get _userId => _auth.currentUser?.uid;
 
  // Reference to user's addresses collection
  CollectionReference<Map<String, dynamic>> _addressesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('addresses');
  }
 
  // Reference to user document
  DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _firestore.collection('users').doc(userId);
  }
  
  // Get location from postal code using a third-party API
  Future<GeoPoint?> _getGeoPointFromPostalCode(String postalCode, String country) async {
    try {
      // Using Google's Geocoding API as an example
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?address=$postalCode,$country&key=$_geocodingApiKey');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return GeoPoint(location['lat'], location['lng']);
        }
      }
      
      // If the API request failed or returned no results
      print('Geocoding API error: ${response.body}');
      return null;
    } catch (e) {
      print('Error getting coordinates from postal code: $e');
      return null;
    }
  }
  
  // Get device's current location
  Future<GeoPoint?> _getCurrentDeviceLocation() async {
    final location = Location();
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          return null;
        }
      }
      
      // Check for permission
      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return null;
        }
      }
      
      // Get the current location
      LocationData locationData = await location.getLocation();
      
      if (locationData.latitude != null && locationData.longitude != null) {
        return GeoPoint(locationData.latitude!, locationData.longitude!);
      }
      return null;
    } catch (e) {
      print('Error getting device location: $e');
      return null;
    }
  }
  
  // Get GeoPoint for an address (trying postal code first, then device location)
  Future<GeoPoint?> getAddressGeoPoint(String postalCode, String country) async {
    if (postalCode.isEmpty) {
      return await _getCurrentDeviceLocation();
    }
    
    // First try to get location from postal code via API
    GeoPoint? geoPoint = await _getGeoPointFromPostalCode(postalCode, country);
    
    // If postal code lookup failed, try to get device location
    if (geoPoint == null) {
      print('Postal code lookup failed, falling back to device location');
      geoPoint = await _getCurrentDeviceLocation();
    }
    
    return geoPoint;
  }
  
  // Fetch all addresses for the current user
  Future<List<Address>> fetchAddresses() async {
    final userId = _userId;
    if (userId == null) return [];
   
    try {
      final snapshot = await _addressesCollection(userId).get();
     
      return snapshot.docs.map((doc) => Address.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      print('Error fetching addresses: $e');
      return [];
    }
  }
 
  // Get the currently selected address ID
  Future<String?> getSelectedAddressId() async {
    final userId = _userId;
    if (userId == null) return null;
   
    try {
      final userDoc = await _userDoc(userId).get();
     
      return userDoc.data()?['selectedAddressId'] as String?;
    } catch (e) {
      print('Error getting selected address ID: $e');
      return null;
    }
  }
 
  // Add a new address with geopoint
  Future<String?> addAddress(Map<String, dynamic> addressData) async {
    final userId = _userId;
    if (userId == null) return null;
   
    try {
      // Get geopoint based on postal code or device location
      String postalCode = addressData['postalCode'] ?? '';
      String country = addressData['country'] ?? '';
      
      GeoPoint? geoPoint = await getAddressGeoPoint(postalCode, country);
      
      final data = {
        ...addressData,
        'geoPoint': geoPoint, // Add the geopoint to the address data
        'createdAt': FieldValue.serverTimestamp(),
      };
     
      final docRef = await _addressesCollection(userId).add(data);
     
      // If this is the first address, set it as selected
      final addresses = await fetchAddresses();
      if (addresses.length <= 1) {
        await setSelectedAddress(docRef.id);
      }
     
      return docRef.id;
    } catch (e) {
      print('Error adding address: $e');
      return null;
    }
  }
 
  // Update an existing address
  Future<bool> updateAddress(String addressId, Map<String, dynamic> addressData) async {
    final userId = _userId;
    if (userId == null) return false;
   
    try {
      // Check if postal code has changed
      if (addressData.containsKey('postalCode')) {
        String postalCode = addressData['postalCode'] ?? '';
        String country = addressData['country'] ?? '';
        
        // Update geopoint based on new postal code or device location
        GeoPoint? geoPoint = await getAddressGeoPoint(postalCode, country);
        addressData['geoPoint'] = geoPoint;
      }
      
      final data = {
        ...addressData,
        'updatedAt': FieldValue.serverTimestamp(),
      };
     
      await _addressesCollection(userId).doc(addressId).update(data);
      return true;
    } catch (e) {
      print('Error updating address: $e');
      return false;
    }
  }
 
  // Delete an address
  Future<bool> deleteAddress(String addressId) async {
    final userId = _userId;
    if (userId == null) return false;
   
    try {
      // Get the current selected address ID
      final selectedAddressId = await getSelectedAddressId();
     
      // Delete the address
      await _addressesCollection(userId).doc(addressId).delete();
     
      // If the deleted address was selected, update the selection
      if (selectedAddressId == addressId) {
        final remainingAddresses = await fetchAddresses();
        if (remainingAddresses.isNotEmpty) {
          await setSelectedAddress(remainingAddresses.first.id);
        }
      }
     
      return true;
    } catch (e) {
      print('Error deleting address: $e');
      return false;
    }
  }
 
  // Set the selected address
  Future<bool> setSelectedAddress(String addressId) async {
    final userId = _userId;
    if (userId == null) return false;
   
    try {
      // First check if the user document exists
      final userDoc = await _userDoc(userId).get();
      if (!userDoc.exists) {
        // Create the user document if it doesn't exist
        await _userDoc(userId).set({
          'selectedAddressId': addressId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing document
        await _userDoc(userId).update({'selectedAddressId': addressId});
      }
      return true;
    } catch (e) {
      print('Error setting selected address: $e');
      return false;
    }
  }
}
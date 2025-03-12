import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/restaurant.dart';

class RestaurantRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  RestaurantRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;
  
  // Get current user ID or null if not authenticated
  String? get _userId => _auth.currentUser?.uid;
  
  // Reference to restaurants collection
  CollectionReference<Map<String, dynamic>> get _restaurantsCollection {
    return _firestore.collection('restaurants');
  }
  
  // Reference to user document
  DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  // Fetch all restaurants
  Future<List<Restaurant>> fetchRestaurants() async {
    try {
      final snapshot = await _restaurantsCollection.get();
      
      return snapshot.docs.map((doc) => Restaurant.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      print('Error fetching restaurants: $e');
      return [];
    }
  }
  
  // Fetch a specific restaurant by ID
  Future<Restaurant?> fetchRestaurantById(String restaurantId) async {
    try {
      final docSnapshot = await _restaurantsCollection.doc(restaurantId).get();
      
      if (!docSnapshot.exists || docSnapshot.data() == null) {
        return null;
      }
      
      return Restaurant.fromMap(docSnapshot.id, docSnapshot.data()!);
    } catch (e) {
      print('Error fetching restaurant: $e');
      return null;
    }
  }
  
  // Get the currently selected restaurant ID
  Future<String?> getSelectedRestaurantId() async {
    final userId = _userId;
    if (userId == null) return null;
    
    try {
      final userDoc = await _userDoc(userId).get();
      
      return userDoc.data()?['selectedRestaurantId'] as String?;
    } catch (e) {
      print('Error getting selected restaurant ID: $e');
      return null;
    }
  }
  
  // Get the currently selected restaurant
  Future<Restaurant?> getSelectedRestaurant() async {
    final restaurantId = await getSelectedRestaurantId();
    if (restaurantId == null) return null;
    
    return await fetchRestaurantById(restaurantId);
  }
  
  // Set the selected restaurant
  Future<bool> setSelectedRestaurant(String restaurantId) async {
    final userId = _userId;
    if (userId == null) return false;
    
    try {
      await _userDoc(userId).update({'selectedRestaurantId': restaurantId});
      return true;
    } catch (e) {
      print('Error setting selected restaurant: $e');
      return false;
    }
  }
  
  // Clear the selected restaurant
  Future<bool> clearSelectedRestaurant() async {
    final userId = _userId;
    if (userId == null) return false;
    
    try {
      await _userDoc(userId).update({'selectedRestaurantId': FieldValue.delete()});
      return true;
    } catch (e) {
      print('Error clearing selected restaurant: $e');
      return false;
    }
  }
}
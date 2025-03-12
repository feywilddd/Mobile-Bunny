import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/address.dart';

class AddressRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

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
  
  // Add a new address
  Future<String?> addAddress(Map<String, dynamic> addressData) async {
    final userId = _userId;
    if (userId == null) return null;
    
    try {
      final data = {
        ...addressData,
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
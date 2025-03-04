import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/profile.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;
  
  // Get current user ID or null if not authenticated
  String? get _userId => _auth.currentUser?.uid;
  
  // Reference to user's family profiles collection
  CollectionReference<Map<String, dynamic>> _profilesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('familyProfiles');
  }

  // Fetch all profiles for the current user
  Future<List<Profile>> fetchProfiles() async {
    final userId = _userId;
    if (userId == null) return [];
    
    try {
      final snapshot = await _profilesCollection(userId).get();
      
      return snapshot.docs.map((doc) => Profile.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      print('Error fetching profiles: $e');
      return [];
    }
  }
  
  // Add a new profile
  Future<String?> addProfile(Map<String, dynamic> profileData) async {
    final userId = _userId;
    if (userId == null) return null;
    
    try {
      final data = {
        ...profileData,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      final docRef = await _profilesCollection(userId).add(data);
      return docRef.id;
    } catch (e) {
      print('Error adding profile: $e');
      return null;
    }
  }
  
  // Update an existing profile
  Future<bool> updateProfile(String profileId, Map<String, dynamic> profileData) async {
    final userId = _userId;
    if (userId == null) return false;
    
    try {
      final data = {
        ...profileData,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await _profilesCollection(userId).doc(profileId).update(data);
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }
  
  // Delete a profile
  Future<bool> deleteProfile(String profileId) async {
    final userId = _userId;
    if (userId == null) return false;
    
    try {
      await _profilesCollection(userId).doc(profileId).delete();
      return true;
    } catch (e) {
      print('Error deleting profile: $e');
      return false;
    }
  }
  
  // Add allergens to a profile
  Future<bool> addAllergens(String profileId, List<String> allergens) async {
    final userId = _userId;
    if (userId == null) return false;
    
    try {
      // Get the current profile
      final profileDoc = await _profilesCollection(userId).doc(profileId).get();
      final currentAllergens = List<String>.from(profileDoc.data()?['allergens'] ?? []);
      
      // Add new allergens without duplicates
      final newAllergens = {...currentAllergens, ...allergens}.toList();
      
      await _profilesCollection(userId).doc(profileId).update({
        'allergens': newAllergens,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error adding allergens: $e');
      return false;
    }
  }
  
  // Remove allergens from a profile
  Future<bool> removeAllergens(String profileId, List<String> allergens) async {
    final userId = _userId;
    if (userId == null) return false;
    
    try {
      // Get the current profile
      final profileDoc = await _profilesCollection(userId).doc(profileId).get();
      final currentAllergens = List<String>.from(profileDoc.data()?['allergens'] ?? []);
      
      // Remove the specified allergens
      final newAllergens = currentAllergens.where((a) => !allergens.contains(a)).toList();
      
      await _profilesCollection(userId).doc(profileId).update({
        'allergens': newAllergens,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error removing allergens: $e');
      return false;
    }
  }
}
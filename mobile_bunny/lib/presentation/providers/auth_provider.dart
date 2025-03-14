import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<User?> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthNotifier() : super(null) {
    _firebaseAuth.authStateChanges().listen((user) {
      state = user;
    });
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return userCredential.user;
    } catch (e) {
      print('Error during Google Sign-In: $e');
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      // Call Firebase Authentication to sign in
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

    } on FirebaseAuthException catch (e) {
      // Handle specific FirebaseAuth errors
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
        throw FirebaseAuthException(
            code: 'user-not-found', message: 'No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
        throw FirebaseAuthException(
            code: 'wrong-password',
            message: 'Wrong password provided for that user.');
      } else {
        // Re-throw other FirebaseAuth errors
        rethrow;
      }
    } catch (e) {
      // Handle any other errors
      print('Error signing in with email: $e');
      rethrow;
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
       final UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        // Vérification si l'utilisateur existe déjà dans Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          // Ajout de l'utilisateur à Firestore seulement s'il n'existe pas
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName ?? "",
            'photoURL': user.photoURL ?? "",
            'role': 'user', // Tu peux modifier ce rôle plus tard
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      print("User registered successfully"); // Debugging purpose
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
        throw FirebaseAuthException(
            code: e.code, message: 'The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
        throw FirebaseAuthException(
            code: e.code,
            message: 'The account already exists for that email.');
      } else {
        print('FirebaseAuthException: ${e.message}');
        throw FirebaseAuthException(code: e.code, message: e.message);
      }
    } catch (e) {
      print('Error signing up: $e');
      throw Exception('Error signing up: $e');
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }
}

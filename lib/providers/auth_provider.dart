import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  Future<UserCredential> createUserWithEmailAndPassword(
    String email, 
    String password, 
    String name,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user profile in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'avatarUrl': '',
        'dietaryPreferences': [],
        'themePreference': 'system',
      });
      
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
  
  Future<void> updateUserProfile({
    String? name,
    String? avatarUrl,
    List<String>? dietaryPreferences,
    String? themePreference,
  }) async {
    if (currentUser == null) return;
    
    final userDoc = _firestore.collection('users').doc(currentUser!.uid);
    
    final Map<String, dynamic> updateData = {};
    if (name != null) updateData['name'] = name;
    if (avatarUrl != null) updateData['avatarUrl'] = avatarUrl;
    if (dietaryPreferences != null) updateData['dietaryPreferences'] = dietaryPreferences;
    if (themePreference != null) updateData['themePreference'] = themePreference;
    
    await userDoc.update(updateData);
    notifyListeners();
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roamie/api/firebase_api_user.dart';
import 'package:roamie/models/user_model.dart';  
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class UserProvider with ChangeNotifier {
  
  final FirebaseUserAPI firebaseService = FirebaseUserAPI();

  // Private fields to hold the user ID, user data, and stream of user data
  String? _userId;
  Map<String, dynamic>? _currentUser;
  Stream<QuerySnapshot>? _userStream;
  String? _currentUserDocumentId;
  String? get currentUserDocumentId => _currentUserDocumentId;

  // Public getter for userId
  String? get userId => _userId;

  // initializes the provider by getting the current user ID and fetching user data
  UserProvider() {
    _userId = FirebaseAuth.instance.currentUser?.uid;
    if (_userId != null) {
      getUser(_userId!);
      loadCurrentUserDocumentId();
    }
  }
  
  // Public getter for user data stream (used with StreamBuilder)
  Stream<QuerySnapshot>? get userStream => _userStream;

  // Public getter for the current user data as a Map
  Map<String, dynamic>? get currentUser => _currentUser;

  // Fetches the user's data as a stream from Firestore and updates the provider
  void getUser(String id) {
    _userStream = firebaseService.getUserInfo(id);
    notifyListeners();
  }

  // Adds a new user to Firestore using the AppUser model
  Future<void> addUser(AppUser user) async { 
    String message = await firebaseService.addUser(user.toJson());
    print(message);
    notifyListeners();
  }

  // Updates the existing user data in Firestore and notifies listeners
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    if (userId.isEmpty) return;

    String message = await firebaseService.updateUserByUserId(userId, data);
    print(message);
    notifyListeners();
  }

  Future<void> loadCurrentUserDocumentId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _currentUserDocumentId = snapshot.docs.first.id;
        notifyListeners();
      }
    }
  }

  Future<void> removeFriend(String friendUserId) async {
    if (currentUserDocumentId == null) return;
    final result = await firebaseService.removeFriend(currentUserDocumentId!, friendUserId);
    print(result);

  }
}

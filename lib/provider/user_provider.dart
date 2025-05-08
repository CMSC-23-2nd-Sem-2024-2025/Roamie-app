import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roamie/api/firebase_api_user.dart';
import 'package:roamie/models/user_model.dart';  
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class UserProvider with ChangeNotifier {
  late final FirebaseUserAPI firebaseService;
  String? userId;

  Stream<QuerySnapshot>? userStream;

  UserProvider() {
    firebaseService = FirebaseUserAPI();
    // Get current user ID
    userId = FirebaseAuth.instance.currentUser?.uid;

    getAllUsers();
    notifyListeners();
  }

  Future<void> getUser(String id) async {
    userStream = firebaseService.getUserInfo(id);
    print(userStream);
    notifyListeners();
  }

  Future<void> addUser(AppUser user) async { 
    String message = await firebaseService.addUser(user.toJson());
    print(message);
    notifyListeners();
  }

  Future<void> getAllUsers() async {
    userStream = firebaseService.getAllUsers(); // Fetch all users
    print(userStream);
    notifyListeners();
  }

}

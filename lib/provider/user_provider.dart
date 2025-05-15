import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roamie/api/firebase_api_user.dart';
import 'package:roamie/models/user_model.dart';  
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class UserProvider with ChangeNotifier {
  final FirebaseUserAPI firebaseService = FirebaseUserAPI();
  String? userId;
  Stream<QuerySnapshot>? _userStream;

  // Get the current user ID and load user data
  UserProvider() {
    userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      getUser(userId!);
    }
  }
  
  //stream of current user data
  Stream<QuerySnapshot>? get userStream => _userStream;

  void getUser(String id) {
    _userStream = firebaseService.getUserInfo(id);
    notifyListeners();
  }

  // Add user to the collection
  Future<void> addUser(AppUser user) async { 
    String message = await firebaseService.addUser(user.toJson());
    print(message);
    notifyListeners();
  }


}

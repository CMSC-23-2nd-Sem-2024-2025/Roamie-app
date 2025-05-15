import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roamie/api/firebase_api_user.dart';
import 'package:roamie/models/user_model.dart';  
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class UserProvider with ChangeNotifier {
  final FirebaseUserAPI firebaseService = FirebaseUserAPI();
  String? _userId;
  Stream<QuerySnapshot>? _userStream;

  // getter
  String? get userId => _userId;

  // Get the current user ID and load user data
  UserProvider() {
    _userId = FirebaseAuth.instance.currentUser?.uid;
    if (_userId != null) {
      getUser(_userId!);
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

   Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    if (userId.isEmpty) return;

    String message = await firebaseService.updateUserByUserId(userId, data);
    print(message);
    notifyListeners();
  }


}

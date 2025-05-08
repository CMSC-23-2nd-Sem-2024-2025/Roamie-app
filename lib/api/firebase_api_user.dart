import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseUserAPI {

  // Create Instance
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  // Function for adding users
  Future<String> addUser(Map<String, dynamic> userData) async {
    try {
      await db.collection("users").add(userData);
      return "Successfully added user!";
    } on FirebaseException catch (e) {
      return "Failed with error '${e.code}': ${e.message}";
    }
   }

  // Get the user info via user id
  Stream<QuerySnapshot> getUserInfo(String userId) {
    return db.collection('users').where('userId', isEqualTo: userId).snapshots(); 
  }

   // Fetch all users
  Stream<QuerySnapshot> getAllUsers() {
    return db.collection('users').snapshots();
  }
}
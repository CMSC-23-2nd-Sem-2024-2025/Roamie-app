import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseTravelAPI {
  // firestore instance reference
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  // add new travel plan
  Future<String> addTravelPlan(Map<String, dynamic> plan) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        plan['ownerId'] = user.uid; // attach current user ID as owner
        plan['sharedWith'] = [user.uid]; // set with owner's ID
      }
      await db.collection("travel_plans").add(plan);
      return "Successfully added travel plan!";
    } on FirebaseException catch (e) {
      return "Failed with error '${e.code}': ${e.message}";
    }
  }

  // delete travel plan by doc id
  Future<String> deleteTravelPlan(String id) async {
    try {
      await db.collection("travel_plans").doc(id).delete();
      return "Successfully deleted travel plan!";
    } on FirebaseException catch (e) {
      return "Failed with error '${e.code}': ${e.message}";
    }
  }

  // update travel plan by doc id and new data
  Future<String> updateTravelPlan(
      String id, Map<String, dynamic> updatedData) async {
    try {
      await db.collection("travel_plans").doc(id).update(updatedData);
      return "Successfully updated travel plan!";
    } on FirebaseException catch (e) {
      return "Failed with error '${e.code}': ${e.message}";
    }
  }

  // Stream all travel plans the current user is a part of (owned or shared)
  Stream<QuerySnapshot> getTravelPlansByUser(String userId) {
    return db
        .collection("travel_plans")
        .where("sharedWith", arrayContains: userId)
        .snapshots();
  }
}

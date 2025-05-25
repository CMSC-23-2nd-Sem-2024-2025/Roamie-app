import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/travel_model.dart';

class FirebaseTravelAPI {
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  // Add travel plan with current user as owner and in sharedWith
  Future<String> addTravelPlan(Map<String, dynamic> plan) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        plan['ownerId'] = user.uid;
        plan['sharedWith'] = [user.uid];
      }
      await db.collection("travel_plans").add(plan);
      return "Successfully added travel plan!";
    } on FirebaseException catch (e) {
      return "Failed with error '${e.code}': ${e.message}";
    }
  }

  // Delete plan using doc id
  Future<String> deleteTravelPlan(String id) async {
    try {
      await db.collection("travel_plans").doc(id).delete();
      return "Successfully deleted travel plan!";
    } on FirebaseException catch (e) {
      return "Failed with error '${e.code}': ${e.message}";
    }
  }

  // Update plan using doc id and new data
  Future<String> updateTravelPlan(
      String id, Map<String, dynamic> updatedData) async {
    try {
      await db.collection("travel_plans").doc(id).update(updatedData);
      return "Successfully updated travel plan!";
    } on FirebaseException catch (e) {
      return "Failed with error '${e.code}': ${e.message}";
    }
  }

  // Get plans shared with current user
  Stream<List<TravelPlan>> getTravelPlansByUser(String userId) {
    return db
        .collection("travel_plans")
        .where("sharedWith", arrayContains: userId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return TravelPlan.fromJson(data);
            }).toList());
  }

  // Share plan by username
  Future<String> sharePlanWithUsername(String planId, String username) async {
    try {
      final uid = await getUidByUsername(username);
      if (uid == null) return "Username not found.";

      final docRef = db.collection("travel_plans").doc(planId);
      final doc = await docRef.get();
      if (!doc.exists) return "Plan not found.";

      List sharedWith = doc.get('sharedWith') ?? [];
      if (sharedWith.contains(uid)) return "User is already shared.";

      await docRef.update({
        'sharedWith': FieldValue.arrayUnion([uid])
      });

      return "Successfully shared travel plan with @$username!";
    } catch (e) {
      return "Failed to share plan: $e";
    }
  }

  // Remove UID from sharedWith list
  Future<String> removeSharedUser(String planId, String uid) async {
    try {
      await db.collection("travel_plans").doc(planId).update({
        'sharedWith': FieldValue.arrayRemove([uid])
      });
      return "Successfully removed shared user!";
    } catch (e) {
      return "Failed to remove shared user: $e";
    }
  }

  // Get UID from username
  Future<String?> getUidByUsername(String username) async {
    try {
      final snap = await db
          .collection("users")
          .where("username", isEqualTo: username)
          .get();

      if (snap.docs.isEmpty) return null;
      return snap.docs.first.data()['userId'];
    } catch (e) {
      print("Error fetching UID by username: $e");
      return null;
    }
  }

  // Get username from UID
  Future<String?> getUsernameByUid(String uid) async {
    try {
      final snap =
          await db.collection("users").where("userId", isEqualTo: uid).get();

      if (snap.docs.isEmpty) return null;
      return snap.docs.first.data()['username'];
    } catch (e) {
      print("Error fetching username by UID: $e");
      return null;
    }
  }
}

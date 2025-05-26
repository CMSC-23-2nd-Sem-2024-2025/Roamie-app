import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

class FirebaseTravelAPI {
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  // Add new travel plan with current user as owner and in sharedWith
  Future<String> addTravelPlan(Map<String, dynamic> plan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      plan['ownerId'] = user.uid;
      plan['sharedWith'] = [user.uid];
    }
    try {
      final docRef= await db.collection("travel_plans").add(plan);

      if(plan['notifyBeforeDays']!=null && plan['travelDate']!=null){
        DateTime travelDate = (plan['travelDate'] as Timestamp).toDate();
        int daysBefore = plan['notifyBeforeDays'];
        String title = plan['title']??'Travel Plan';
        await NotificationsService.scheduleNotification(id: docRef.id,title: title,travelDate: travelDate,daysBefore: daysBefore,);
      }
      
      return "Successfully added travel plan!";
    } on FirebaseException catch (e) {
      return "Failed with error '${e.code}': ${e.message}";
    }
  }

  // Delete travel plan
  Future<String> deleteTravelPlan(String id) async {
    try {
      await db.collection("travel_plans").doc(id).delete();
      return "Successfully deleted travel plan!";
    } on FirebaseException catch (e) {
      return "Failed with error '${e.code}': ${e.message}";
    }
  }

  // Update plan
  Future<String> updateTravelPlan(
      String id, Map<String, dynamic> updatedData) async {
    try {
      await db.collection("travel_plans").doc(id).update(updatedData);
      return "Successfully updated travel plan!";
    } on FirebaseException catch (e) {
      return "Failed with error '${e.code}': ${e.message}";
    }
  }

  // Get all plans where user is in sharedWith
  Stream<QuerySnapshot> getTravelPlansByUser(String userId) {
    return db
        .collection("travel_plans")
        .where("sharedWith", arrayContains: userId)
        .snapshots();
  }

  // Share plan by username (resolves UID first)
  Future<String> sharePlanWithUsername(String planId, String username) async {
    try {
      final uid = await getUidByUsername(username);
      if (uid == null) return "Username not found.";

      final docRef = db.collection("travel_plans").doc(planId);
      final docSnap = await docRef.get();
      if (!docSnap.exists) return "Plan not found";

      List sharedWith = docSnap.get('sharedWith') ?? [];
      if (sharedWith.contains(uid)) {
        return "User is already shared with this plan.";
      }

      await docRef.update({
        'sharedWith': FieldValue.arrayUnion([
          uid
        ]), //https://firebase.google.com/docs/reference/kotlin/com/google/firebase/firestore/FieldValue
      });

      return "Successfully shared travel plan with @$username!";
    } catch (e) {
      return "Failed to share plan: $e";
    }
  }

  // Remove UID from sharedWith
  Future<String> removeSharedUser(String planId, String uid) async {
    try {
      await db.collection("travel_plans").doc(planId).update({
        'sharedWith': FieldValue.arrayRemove([
          uid
        ]), //https://firebase.google.com/docs/reference/kotlin/com/google/firebase/firestore/FieldValue
      });
      return "Successfully removed shared user!";
    } catch (e) {
      return "Failed to remove shared user: $e";
    }
  }

  // Lookup UID by username
  Future<String?> getUidByUsername(String username) async {
    try {
      final snapshot = await db
          .collection("users")
          .where("username", isEqualTo: username)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first.id; // User UID = doc ID
    } catch (e) {
      return null;
    }
  }

  // Lookup username by UID
  Future<String?> getUsernameByUid(String uid) async {
    try {
      final doc = await db.collection("users").doc(uid).get();
      if (!doc.exists) return null;
      return doc.data()?['username'];
    } catch (e) {
      return null;
    }
  }
}

class NotificationsService{
  static final _notifications=FlutterLocalNotificationsPlugin();

  static Future<void> init() async{
    final android= AndroidInitializationSettings('@mipmap/ic_launcher');
    final settings= InitializationSettings(android: android);
    await _notifications.initialize(settings);
    initializeTimeZones();
  }

  static Future<void> scheduleNotification({
    required String id,
    required String title,
    required DateTime travelDate,
    required int daysBefore,
  }) async{
    final scheduledDate=travelDate.subtract(Duration(days: daysBefore));
    await _notifications.zonedSchedule(id.hashCode, title,'Your trip "$title" is in $daysBefore day/s!',  TZDateTime.from(scheduledDate, local), const NotificationDetails(android: AndroidNotificationDetails('travel_reminder', 'Travel Reminders', importance: Importance.max, priority: Priority.high),), androidAllowWhileIdle: true, uiLocalNotificationDateInterpretation:UILocalNotificationDateInterpretation.absoluteTime,matchDateTimeComponents: DateTimeComponents.dateAndTime,);
  }
}

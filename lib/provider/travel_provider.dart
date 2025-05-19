import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../api/firebase_api_travel.dart';
import '../models/travel_model.dart';

class TravelProvider extends ChangeNotifier {
  final FirebaseTravelAPI _travelAPI = FirebaseTravelAPI();

  List<TravelPlan> _plans = [];
  List<TravelPlan> get plans => _plans;

  StreamSubscription? _travelSub;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // Listen to current user's travel plans (owned and shared)
  Future<void> fetchTravelPlans() async {
    final userId = currentUserId;
    if (userId == null) return;

    _travelSub?.cancel();

    _travelSub = _travelAPI.getTravelPlansByUser(userId).listen((snapshot) {
      _plans = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return TravelPlan.fromJson(data);
      }).toList();
      notifyListeners();
    });
  }

  // Add a new travel plan
  Future<String> addTravelPlan(TravelPlan plan) async {
    final result = await _travelAPI.addTravelPlan(plan.toJson());
    await fetchTravelPlans();
    return result;
  }

  // Delete a travel plan by ID
  Future<String> deleteTravelPlan(String id) async {
    final result = await _travelAPI.deleteTravelPlan(id);
    await fetchTravelPlans();
    return result;
  }

  // Update an existing travel plan
  Future<String> updateTravelPlan(String id, TravelPlan updatedPlan) async {
    final result = await _travelAPI.updateTravelPlan(id, updatedPlan.toJson());
    await fetchTravelPlans();
    return result;
  }

  // Share a travel plan with another user by their username (calls API to resolve username -> uid)
  Future<String> sharePlanWithUser(String planId, String username) async {
    final result = await _travelAPI.sharePlanWithUsername(planId, username);
    await fetchTravelPlans();
    return result;
  }

  // Remove a shared user from a travel plan (by UID)
  Future<String> removeSharedUser(String planId, String userIdToRemove) async {
    final result = await _travelAPI.removeSharedUser(planId, userIdToRemove);
    await fetchTravelPlans();
    return result;
  }

  // Import a shared plan by adding current user to sharedWith list
  // Note: takes plan data and current username (or can be userId), you can adjust accordingly
  Future<String> importSharedPlan(
      Map<String, dynamic> planData, String username) async {
    final userId = currentUserId;
    if (userId == null) return 'No user logged in';

    final planId = planData['id'];
    if (planId == null) return 'Invalid plan data';

    // Shares plan with current user using username
    final result = await _travelAPI.sharePlanWithUsername(planId, username);
    await fetchTravelPlans();
    return result;
  }

  // Get username from UID
  Future<String?> getUsernameFromUid(String uid) async {
    final userDoc =
        await FirebaseTravelAPI.db.collection('users').doc(uid).get();
    if (!userDoc.exists) return null;
    return userDoc.data()?['username'] as String?;
  }

  // Refresh a specific plan's data from Firestore
  Future<void> reloadPlan(String planId) async {
    final userId = currentUserId;
    if (userId == null) return;

    final snapshot =
        await FirebaseTravelAPI.db.collection('travel_plans').doc(planId).get();

    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      data['id'] = snapshot.id;
      final updatedPlan = TravelPlan.fromJson(data);
      final idx = _plans.indexWhere((p) => p.id == planId);
      if (idx >= 0) {
        _plans[idx] = updatedPlan;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _travelSub?.cancel();
    super.dispose();
  }
}

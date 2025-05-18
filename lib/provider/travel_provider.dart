import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../api/firebase_api_travel.dart';
import '../models/travel_model.dart';

class TravelProvider extends ChangeNotifier {
  final FirebaseTravelAPI _travelAPI = FirebaseTravelAPI();

  List<TravelPlan> _plans = [];
  List<TravelPlan> get plans => _plans;

  // Fetch travel plans for the current user
  Future<void> fetchTravelPlans() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _travelAPI.getTravelPlansByUser(user.uid).listen((snapshot) {
      _plans = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return TravelPlan.fromJson(data);
      }).toList();
      notifyListeners();
    });
  }

  Future<String> addTravelPlan(TravelPlan plan) async {
    final result = await _travelAPI.addTravelPlan(plan.toJson());
    return result;
  }

  Future<String> deleteTravelPlan(String id) async {
    final result = await _travelAPI.deleteTravelPlan(id);
    return result;
  }

  Future<String> updateTravelPlan(String id, TravelPlan updatedPlan) async {
    final result = await _travelAPI.updateTravelPlan(id, updatedPlan.toJson());
    return result;
  }
}

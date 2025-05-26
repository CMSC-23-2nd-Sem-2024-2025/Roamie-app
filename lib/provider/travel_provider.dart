// Joshua O. Pagcaliwagan CMSC 23 CD5L Exer 9 Travel Plan Provider

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../api/firebase_api_travel.dart';
import '../models/travel_model.dart';

class TravelProvider with ChangeNotifier {
  final FirebaseTravelAPI _api = FirebaseTravelAPI();
  List<TravelPlan> _plans = [];
  List<TravelPlan> get plans => _plans;

  StreamSubscription? _sub;

  //get current userId
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  //listen to user’s travel plans
  Future<void> fetchTravelPlans() async {
    final uid = currentUserId;
    if (uid == null) return;

    _sub?.cancel();
    _sub = _api.getTravelPlansByUser(uid).listen((list) {
    //  _plans = list;
      notifyListeners();
    });
  }

  //add plan
  Future<String> addTravelPlan(TravelPlan plan) async {
    final res = await _api.addTravelPlan(plan.toJson());
    await fetchTravelPlans();
    return res;
  }

  //delete plan
  Future<String> deleteTravelPlan(String id) async {
    final res = await _api.deleteTravelPlan(id);
    await fetchTravelPlans();
    return res;
  }

  //update plan
  Future<String> updateTravelPlan(String id, TravelPlan plan) async {
    final res = await _api.updateTravelPlan(id, plan.toJson());
    await fetchTravelPlans();
    return res;
  }

  //share plan by username
  Future<String> sharePlanWithUser(String id, String username) async {
    final res = await _api.sharePlanWithUsername(id, username);
    await fetchTravelPlans();
    return res;
  }

  //remove shared user
  Future<String> removeSharedUser(String id, String uid) async {
    final res = await _api.removeSharedUser(id, uid);
    await fetchTravelPlans();
    return res;
  }

  //get username from UID via API method
  Future<String?> getUsernameFromUid(String uid) async {
    return await _api.getUsernameByUid(uid);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

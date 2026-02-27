// lib/state/restaurant_provider.dart
import 'package:flutter/material.dart';
import 'package:premium_store/core/services/firebase_service.dart';
import '../core/models/restaurant_model.dart';

class RestaurantProvider extends ChangeNotifier {
  Restaurant? _restaurant;
  bool _loading = true;

  Restaurant? get restaurant => _restaurant;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _restaurant = await FirebaseService.getRestaurant();
    _loading = false;
    notifyListeners();
  }
}

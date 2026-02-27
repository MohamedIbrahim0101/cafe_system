// lib/core/models/restaurant_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:flutter/material.dart';
import '../../app/constants.dart';

class Restaurant {
  final String id;
  final String name;
  final String logoUrl;
  final String coverImageUrl;
  final DateTime createdAt;

  Restaurant({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.coverImageUrl,
    required this.createdAt,
  });

 // lib/core/models/restaurant_model.dart
factory Restaurant.fromSnapshot(
    fs.DocumentSnapshot snapshot, {
    double coverWidth = 400, // default value
  }) {
  final data = snapshot.data() as Map<String, dynamic>;
  return Restaurant(
    id: snapshot.id,
    name: data['name'] ?? 'Premium Restaurant',
    logoUrl: imageUrlResize(data['logoUrl'], width: 200),
    coverImageUrl: imageUrlResize(data['coverImageUrl'], width: coverWidth),
    createdAt: (data['createdAt'] as fs.Timestamp).toDate(),
  );
}

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'logoUrl': logoUrl,
      'coverImageUrl': coverImageUrl,
      'createdAt': createdAt,
    };
  }
}

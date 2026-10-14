// lib/core/models/restaurant_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
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

  factory Restaurant.fromSnapshot(
    DocumentSnapshot snapshot, {
    double coverWidth = 400,
  }) {
    // 🔥 تحويل آمن للـ data للوقاية من خطأ LegacyJavaScriptObject على Web
    final rawData = snapshot.data();
    final Map<String, dynamic> data =
        rawData != null ? Map<String, dynamic>.from(rawData as Map) : {};

    return Restaurant(
      id: snapshot.id,
      name: data['name'] ?? 'Premium Restaurant',
      logoUrl: imageUrlResize(data['logoUrl'] ?? '', width: 200),
      coverImageUrl: imageUrlResize(data['coverImageUrl'] ?? '', width: coverWidth),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'logoUrl': logoUrl,
      'coverImageUrl': coverImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Restaurant copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? coverImageUrl,
    DateTime? createdAt,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
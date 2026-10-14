// lib/core/models/table_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TableModel {
  final String id;
  final int tableNumber;
  final String restaurantId; // 🔥 تم إضافة حقل معرف المطعم لعزل الطاولات
  final String qrUrl; // يخزن الرابط الكامل مع معرف المطعم والطاولة: https://qalyoubfantasy.web.app/#/menu?restaurantId=XYZ&table=1
  final bool isOccupied; // حالة الطاولة (مشغولة / متاحة)
  final DateTime createdAt;

  TableModel({
    required this.id,
    required this.tableNumber,
    required this.restaurantId,
    required this.qrUrl,
    this.isOccupied = false,
    required this.createdAt,
  });

  factory TableModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Table document data is null');
    }

    return TableModel(
      id: snapshot.id,
      tableNumber: int.tryParse(data['tableNumber']?.toString() ?? '0') ?? 0,
      restaurantId: data['restaurantId'] ?? '',
      qrUrl: data['qrUrl'] ?? '',
      isOccupied: data['isOccupied'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'tableNumber': tableNumber,
        'restaurantId': restaurantId,
        'qrUrl': qrUrl,
        'isOccupied': isOccupied,
        'createdAt': FieldValue.serverTimestamp(),
      };

  TableModel copyWith({
    String? id,
    int? tableNumber,
    String? restaurantId,
    String? qrUrl,
    bool? isOccupied,
    DateTime? createdAt,
  }) {
    return TableModel(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      restaurantId: restaurantId ?? this.restaurantId,
      qrUrl: qrUrl ?? this.qrUrl,
      isOccupied: isOccupied ?? this.isOccupied,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
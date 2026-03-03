// lib/core/models/table_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TableModel {
  final String id;
  final int tableNumber;
  final String qrUrl; // هذا سيخزن الرابط الكامل مثل: https://qalyoubfantasy.web.app/#/menu?table=1
  final DateTime createdAt;

  TableModel({
    required this.id,
    required this.tableNumber,
    required this.qrUrl,
    required this.createdAt,
  });

  factory TableModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Table document data is null');
    }

    return TableModel(
      id: snapshot.id,
      // التأكد من تحويل الرقم بشكل صحيح سواء كان int أو string
      tableNumber: int.tryParse(data['tableNumber']?.toString() ?? '0') ?? 0,
      qrUrl: data['qrUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'tableNumber': tableNumber,
        'qrUrl': qrUrl,
        'createdAt': FieldValue.serverTimestamp(), // استخدام وقت السيرفر أفضل للدقة
      };
}
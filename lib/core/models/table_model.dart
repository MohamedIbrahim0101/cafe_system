// lib/core/models/table_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TableModel {
  final String id;
  final int tableNumber;
  final String qrUrl; // QR data string
  final DateTime createdAt;

  TableModel({
    required this.id,
    required this.tableNumber,
    required this.qrUrl,
    required this.createdAt,
  });

  factory TableModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return TableModel(
      id: snapshot.id,
      tableNumber: data['tableNumber'] ?? 0,
      qrUrl: data['qrUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'tableNumber': tableNumber,
        'qrUrl': qrUrl,
        'createdAt': createdAt,
      };
}

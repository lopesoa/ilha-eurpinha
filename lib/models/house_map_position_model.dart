import 'package:cloud_firestore/cloud_firestore.dart';

class HouseMapPosition {
  final String? id;
  final String houseId;
  final double x;
  final double y;

  HouseMapPosition({
    this.id,
    required this.houseId,
    required this.x,
    required this.y,
  });

  factory HouseMapPosition.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HouseMapPosition(
      id: doc.id,
      houseId: data['houseId'] ?? '',
      x: (data['x'] as num?)?.toDouble() ?? 0.0,
      y: (data['y'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'houseId': houseId, 'x': x, 'y': y};
  }

  HouseMapPosition copyWith({
    String? id,
    String? houseId,
    double? x,
    double? y,
  }) {
    return HouseMapPosition(
      id: id ?? this.id,
      houseId: houseId ?? this.houseId,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}

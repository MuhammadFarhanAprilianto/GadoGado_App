import 'package:cloud_firestore/cloud_firestore.dart';

enum ShopStatus { open, ishoma, closed }

class ShopSettingsModel {
  final ShopStatus status;
  final DateTime lastUpdated;
  final bool isManualOverride;

  ShopSettingsModel({
    required this.status,
    required this.lastUpdated,
    this.isManualOverride = false,
  });

  factory ShopSettingsModel.fromFirestore(Map<String, dynamic> data) {
    return ShopSettingsModel(
      status: ShopStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ShopStatus.closed,
      ),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      isManualOverride: data['isManualOverride'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'status': status.name,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'isManualOverride': isManualOverride,
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'food_item_model.dart';

class CartItemModel {
  final FoodItemModel foodItem;
  int quantity;
  String? notes;

  CartItemModel({
    required this.foodItem,
    this.quantity = 1,
    this.notes,
  });

  double get totalPrice => foodItem.price * quantity;

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      foodItem: FoodItemModel.fromJson(map['foodItem'] ?? {}),
      quantity: map['quantity'] ?? 1,
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'foodItem': foodItem.toFirestore(),
      'quantity': quantity,
      'notes': notes,
    };
  }
}

enum OrderStatus { pending, preparing, ready, completed, finished, cancelled }
enum ServiceType { dineIn, takeAway, rsvp, delivery }
enum PaymentMethod { cash, qris, bankTransfer, eWallet }

class OrderModel {
  final String id;
  final String userId;
  final List<CartItemModel> items;
  final double subtotal;
  final double tax;
  final double serviceCharge;
  final double totalAmount;
  final OrderStatus status;
  final ServiceType serviceType;
  final PaymentMethod paymentMethod;
  final String? rsvpTime;
  final String? rsvpDate;
  final String? deliveryAddress;
  final double? deliveryFee;
  final String? specialInstructions;
  final DateTime timestamp;
  final DateTime? completedAt;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final String? ratingNote;
  final DateTime? ratedAt;
  final String? paymentProofUrl;
  final String? customerName;
  final String? customerPhone;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.serviceCharge,
    required this.totalAmount,
    required this.status,
    required this.serviceType,
    required this.paymentMethod,
    this.rsvpTime,
    this.rsvpDate,
    this.deliveryAddress,
    this.deliveryFee,
    this.specialInstructions,
    required this.timestamp,
    this.completedAt,
    this.latitude,
    this.longitude,
    this.rating,
    this.ratingNote,
    this.ratedAt,
    this.paymentProofUrl,
    this.customerName,
    this.customerPhone,
  });

  factory OrderModel.fromFirestore(Map<String, dynamic> data, String id, {List<CartItemModel> items = const []}) {
    return OrderModel(
      id: id,
      userId: data['id_user'] ?? data['userId'] ?? '',
      items: items,
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      tax: (data['pajak'] ?? data['tax'] ?? 0).toDouble(),
      serviceCharge: (data['biaya_layanan'] ?? data['serviceCharge'] ?? 0).toDouble(),
      totalAmount: (data['total'] ?? data['totalAmount'] ?? 0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      serviceType: ServiceType.values.firstWhere(
        (e) => e.name == (data['tipe_layanan'] ?? data['serviceType']),
        orElse: () => ServiceType.dineIn,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == (data['metode_pembayaran'] ?? data['paymentMethod']),
        orElse: () => PaymentMethod.cash,
      ),
      rsvpTime: data['waktu_reservasi'] ?? data['rsvpTime'],
      rsvpDate: data['tanggal_reservasi'] ?? data['rsvpDate'],
      deliveryAddress: data['alamat_pengiriman'] ?? data['deliveryAddress'],
      deliveryFee: (data['biaya_pengiriman'] ?? data['deliveryFee'] as num?)?.toDouble(),
      specialInstructions: data['catatan_khusus'] ?? data['specialInstructions'],
      timestamp: data['waktu_pesan'] != null
          ? (data['waktu_pesan'] as Timestamp).toDate()
          : data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
      completedAt: data['waktu_selesai'] != null
          ? (data['waktu_selesai'] as Timestamp).toDate()
          : data['completedAt'] != null
              ? (data['completedAt'] as Timestamp).toDate()
              : null,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      rating: (data['rating'] as num?)?.toDouble(),
      ratingNote: data['catatan_rating'] ?? data['ratingNote'],
      ratedAt: data['waktu_rating'] != null
          ? (data['waktu_rating'] as Timestamp).toDate()
          : data['ratedAt'] != null
              ? (data['ratedAt'] as Timestamp).toDate()
              : null,
      paymentProofUrl: data['bukti_pembayaran_url'] ?? data['paymentProofUrl'],
      customerName: data['nama_pelanggan'] ?? data['customerName'],
      customerPhone: data['hp_pelanggan'] ?? data['customerPhone'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id_user': userId,
      'total': totalAmount,
      'subtotal': subtotal,
      'pajak': tax,
      'biaya_layanan': serviceCharge,
      'status': status.name,
      'tipe_layanan': serviceType.name,
      'metode_pembayaran': paymentMethod.name,
      'waktu_reservasi': rsvpTime,
      'tanggal_reservasi': rsvpDate,
      'alamat_pengiriman': deliveryAddress,
      'biaya_pengiriman': deliveryFee,
      'catatan_khusus': specialInstructions,
      'waktu_pesan': Timestamp.fromDate(timestamp),
      'waktu_selesai': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'catatan_rating': ratingNote,
      'waktu_rating': ratedAt != null ? Timestamp.fromDate(ratedAt!) : null,
      'bukti_pembayaran_url': paymentProofUrl,
      'nama_pelanggan': customerName,
      'hp_pelanggan': customerPhone,
    };
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    List<CartItemModel>? items,
    double? subtotal,
    double? tax,
    double? serviceCharge,
    double? totalAmount,
    OrderStatus? status,
    ServiceType? serviceType,
    PaymentMethod? paymentMethod,
    String? rsvpTime,
    String? rsvpDate,
    String? deliveryAddress,
    double? deliveryFee,
    String? specialInstructions,
    DateTime? timestamp,
    DateTime? completedAt,
    double? latitude,
    double? longitude,
    double? rating,
    String? ratingNote,
    DateTime? ratedAt,
    String? paymentProofUrl,
    String? customerName,
    String? customerPhone,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      serviceType: serviceType ?? this.serviceType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      rsvpTime: rsvpTime ?? this.rsvpTime,
      rsvpDate: rsvpDate ?? this.rsvpDate,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      timestamp: timestamp ?? this.timestamp,
      completedAt: completedAt ?? this.completedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      ratingNote: ratingNote ?? this.ratingNote,
      ratedAt: ratedAt ?? this.ratedAt,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
    );
  }
}

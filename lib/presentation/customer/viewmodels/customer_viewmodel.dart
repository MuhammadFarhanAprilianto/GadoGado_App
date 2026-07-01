import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gado_gado_app/data/models/food_item_model.dart';
import 'package:gado_gado_app/data/models/order_model.dart';
import 'package:gado_gado_app/data/models/raw_ingredient_model.dart';
import 'package:gado_gado_app/data/models/topping_model.dart';
import 'package:gado_gado_app/data/services/inventory_service.dart';
import 'package:gado_gado_app/data/models/shop_settings_model.dart';
import 'package:gado_gado_app/core/utils/menu_id_helper.dart';
class CustomerViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final InventoryService _inventoryService = InventoryService();
  final _supabase = Supabase.instance.client;
  List<FoodItemModel> _menuItems = [];
  List<RawIngredientModel> _ingredients = [];
  final List<CartItemModel> _cart = [];
  List<OrderModel> _orders = [];
  List<ToppingModel> _toppings = [];
  List<ToppingModel> get toppings => _toppings;
  String _selectedCategory = 'All';
  String _specialInstructions = '';
  ServiceType _serviceType = ServiceType.dineIn;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  TimeOfDay? _rsvpTime;
  DateTime? _rsvpDate;
  ShopStatus _shopStatus = ShopStatus.open;

  StreamSubscription<QuerySnapshot>? _ordersSub;
  StreamSubscription<QuerySnapshot>? _detailsSub;
  StreamSubscription? _toppingsSub;
  List<DocumentSnapshot> _orderDocs = [];
  List<DocumentSnapshot> _detailDocs = [];

  @override
  void dispose() {
    _ordersSub?.cancel();
    _detailsSub?.cancel();
    _toppingsSub?.cancel();
    super.dispose();
  }

  // Delivery Location Data
  LatLng? _deliveryLatLng;
  String _deliveryAddress = 'Belum dipilih';
  double _deliveryDistance = 0.0;
  
  // Shop location: Jl. Batu Kinyang 11, Batu Ampar, Kramat Jati
  LatLng _shopLatLng = const LatLng(-6.274442, 106.858739);
  String _shopAddress = 'Jl. Batu Kinyang 11, Batu Ampar, Kramat Jati';

  // Payment proof for Bank/E-Wallet
  String? _paymentProofPath;

  // Tab Navigation
  int _currentTabIndex = 0;

  List<FoodItemModel> get menuItems => _selectedCategory == 'All'
      ? _menuItems
      : _menuItems.where((item) => item.category == _selectedCategory).toList();

  List<RawIngredientModel> get ingredients => _ingredients;
  List<CartItemModel> get cart => _cart;
  List<OrderModel> get orders => _orders;
  String get selectedCategory => _selectedCategory;
  String get specialInstructions => _specialInstructions;
  ServiceType get serviceType => _serviceType;
  PaymentMethod get paymentMethod => _paymentMethod;
  TimeOfDay? get rsvpTime => _rsvpTime;
  DateTime? get rsvpDate => _rsvpDate;
  
  LatLng? get deliveryLatLng => _deliveryLatLng;
  String get deliveryAddress => _deliveryAddress;
  double get deliveryDistance => _deliveryDistance;
  LatLng get shopLatLng => _shopLatLng;
  String get shopAddress => _shopAddress;
  String? get paymentProofPath => _paymentProofPath;
  int get currentTabIndex => _currentTabIndex;
  ShopStatus get shopStatus => _shopStatus;

  double get subtotal => _cart.fold(0, (total, item) => total + item.totalPrice);
  double get tax10 => subtotal * 0.1;
  double get serviceCharge => subtotal > 0 ? 2500 : 0; // Fixed mock service charge
  
  double get deliveryFee {
    if (_serviceType != ServiceType.delivery || subtotal == 0) return 0;
    // Calculation: Rp 5.000 per 500 meters (Rp 10.000 per KM)
    double calculated = _deliveryDistance * 10000;
    // Set a minimum fee of Rp 5.000
    return calculated < 5000 ? 5000 : (calculated / 100).ceilToDouble() * 100;
  }
  
  double get grandTotal => subtotal + tax10 + serviceCharge + (subtotal > 0 ? deliveryFee : 0);
  int get cartCount => _cart.fold(0, (total, item) => total + item.quantity);

  // Today's stats for Admin Dashboard sync (Calculated from finished orders ONLY)
  double get todayRevenue => todayOrders
      .where((o) => o.status == OrderStatus.finished)
      .fold(0, (total, o) => total + o.totalAmount);
      
  int get todayOrderCount => todayOrders
      .where((o) => o.status == OrderStatus.finished)
      .length;

  List<OrderModel> get todayOrders {
    final now = DateTime.now();
    return _orders.where((o) => 
      o.timestamp.year == now.year && 
      o.timestamp.month == now.month && 
      o.timestamp.day == now.day
    ).toList();
  }

  CustomerViewModel() {
    _listenToIngredients();
    _listenToMenu();
    _listenToShopStatus();
    _listenToToppings();
  }

  void _listenToToppings() {
    _toppingsSub = _firestore.collection('toppings').snapshots().listen((snapshot) {
      if (snapshot.docs.isEmpty) {
        _bootstrapToppings();
      } else {
        _toppings = snapshot.docs
            .map((doc) => ToppingModel.fromFirestore(doc.data(), doc.id))
            .toList();
        notifyListeners();
      }
    });
  }

  void _bootstrapToppings() async {
    if (_ingredients.isEmpty) {
      final snapshot = await _firestore.collection('bahan').get();
      _ingredients = snapshot.docs.map((doc) {
        final data = doc.data();
        final stok = (data['stok'] ?? 0).toDouble();
        final threshold = (data['ambang_batas_stok'] ?? data['minStockThreshold'] ?? 5).toDouble();
        return RawIngredientModel(
          id: doc.id,
          name: data['nama_bahan'] ?? data['name'] ?? '',
          category: data['kategori'] ?? data['category'] ?? 'Umum',
          amount: stok,
          unit: data['satuan'] ?? data['unit'] ?? '',
          minStockThreshold: threshold,
          isLowStock: stok < threshold,
        );
      }).toList();
    }

    String getIngId(String name) => _ingredients.firstWhere(
      (i) => i.name.toLowerCase() == name.toLowerCase(),
      orElse: () => RawIngredientModel(id: 'dummy_$name', name: name, category: '', amount: 0, unit: ''),
    ).id;

    final initialToppings = [
      ToppingModel(id: '', name: 'Telor', price: 5000, ingredientId: getIngId('Telur')),
      ToppingModel(id: '', name: 'Lontong', price: 3000, ingredientId: getIngId('Lontong')),
    ];

    for (var top in initialToppings) {
      await _firestore.collection('toppings').add(top.toFirestore());
    }
  }

  bool isToppingAvailable(ToppingModel topping) {
    if (topping.ingredientId.isEmpty) return true;
    final ingredient = _ingredients.firstWhere(
      (i) => i.id == topping.ingredientId,
      orElse: () => RawIngredientModel(id: '', name: '', category: '', amount: 0, unit: ''),
    );
    return ingredient.id.isNotEmpty && ingredient.amount > 0;
  }

  void _listenToIngredients() {
    _firestore.collection('bahan').snapshots().listen((snapshot) {
      _ingredients = snapshot.docs.map((doc) {
        final data = doc.data();
        final stok = (data['stok'] ?? 0).toDouble();
        final threshold = (data['ambang_batas_stok'] ?? data['minStockThreshold'] ?? 5).toDouble();
        return RawIngredientModel(
          id: doc.id,
          name: data['nama_bahan'] ?? data['name'] ?? '',
          category: data['kategori'] ?? data['category'] ?? 'Umum',
          amount: stok,
          unit: data['satuan'] ?? data['unit'] ?? '',
          minStockThreshold: threshold,
          isLowStock: stok < threshold,
        );
      }).toList();
      notifyListeners();
    });
  }

  int getRemainingPortions(FoodItemModel item) {
    return InventoryService.calculateRemainingPortions(item, _ingredients);
  }

  void _listenToMenu() {
    _firestore.collection('menu').snapshots().listen((snapshot) {
      if (snapshot.docs.isEmpty) {
        // If DB is empty, seed initial data for the user
        _bootstrapMenu();
      } else {
        _menuItems = snapshot.docs
            .map((doc) => FoodItemModel.fromFirestore(doc.data(), doc.id))
            .toList();
        notifyListeners();
      }
    });
  }

  void _listenToShopStatus() {
    _firestore.collection('settings').doc('shop_status').snapshots().listen((snapshot) {
      debugPrint('CUSTOMER SHOP STATUS SNAPSHOT: exists=${snapshot.exists}');
      if (snapshot.exists) {
        final data = snapshot.data();
        debugPrint('CUSTOMER SHOP STATUS DATA: $data');
        if (data != null) {
          try {
            _shopStatus = ShopStatus.values.firstWhere(
              (e) => e.name == data['status'],
              orElse: () => ShopStatus.closed,
            );
            debugPrint('CUSTOMER SHOP STATUS PARSED: $_shopStatus');
            if (data['latitude'] != null && data['longitude'] != null) {
              _shopLatLng = LatLng(
                (data['latitude'] as num).toDouble(),
                (data['longitude'] as num).toDouble(),
              );
            }
            if (data['address'] != null) {
              _shopAddress = data['address'] as String;
            }
            notifyListeners();
          } catch (e, stack) {
            debugPrint('Error parsing shop status in CustomerViewModel: $e');
            debugPrint(stack.toString());
          }
        }
      }
    }, onError: (err) {
      debugPrint('CUSTOMER SHOP STATUS STREAM ERROR: $err');
    });
  }

  void listenToOrders(String userId) {
    if (userId.isEmpty) return;
    _ordersSub?.cancel();
    _detailsSub?.cancel();

    _ordersSub = _firestore
        .collection('orders')
        .where('id_user', isEqualTo: userId)
        .snapshots()
        .listen((ordersSnapshot) {
      _orderDocs = ordersSnapshot.docs;
      _rebuildOrders();
    });

    _detailsSub = _firestore.collection('detail').snapshots().listen((detailsSnapshot) {
      _detailDocs = detailsSnapshot.docs;
      _rebuildOrders();
    });
  }

  void _rebuildOrders() {
    if (_orderDocs.isEmpty) {
      _orders = [];
      notifyListeners();
      return;
    }

    final List<OrderModel> rebuilt = [];

    for (var orderDoc in _orderDocs) {
      final orderData = orderDoc.data() as Map<String, dynamic>;
      final orderId = orderDoc.id;

      final orderDetails = _detailDocs.where((d) => d['id_order'] == orderId).toList();
      
      final List<CartItemModel> items = [];
      for (var det in orderDetails) {
        final detData = det.data() as Map<String, dynamic>;
        final menuId = detData['id_menu'] ?? '';
        final normalizedId = MenuIdHelper.normalizeMenuId(menuId);
        final quantity = (detData['jml'] ?? 0).toInt();
        final price = (detData['harga'] ?? 0).toDouble();
        final notes = detData['catatan'] as String?;

        final foodItem = _menuItems.firstWhere(
          (m) => m.id == normalizedId,
          orElse: () => FoodItemModel(
            id: menuId,
            name: detData['nama_menu'] ?? 'Menu Telah Dihapus',
            description: '',
            price: price,
            image: '',
            category: '',
          ),
        );

        items.add(CartItemModel(
          foodItem: foodItem.copyWith(price: price),
          quantity: quantity,
          notes: notes,
        ));
      }

      rebuilt.add(OrderModel.fromFirestore(orderData, orderId, items: items));
    }

    _orders = rebuilt;
    _orders.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSpecialInstructions(String value) {
    _specialInstructions = value;
    notifyListeners();
  }

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  void setServiceType(ServiceType value) {
    _serviceType = value;
    if (_serviceType != ServiceType.rsvp) {
      _rsvpTime = null; // Clear RSVP details if mode changes
      _rsvpDate = null;
    }
    notifyListeners();
  }

  void setRsvpDate(DateTime date) {
    _rsvpDate = date;
    notifyListeners();
  }

  bool setRsvpTime(TimeOfDay time) {
    // Validating operating hours: 10:00 to 17:00
    if (time.hour < 10 || time.hour > 17) {
      return false; // Invalid time
    }
    _rsvpTime = time;
    notifyListeners();
    return true;
  }

  void setPaymentMethod(PaymentMethod value) {
    _paymentMethod = value;
    notifyListeners();
  }

  void updateDeliveryLocation(LatLng latLng, String address, double distanceInKm) {
    _deliveryLatLng = latLng;
    _deliveryAddress = address;
    _deliveryDistance = distanceInKm;
    notifyListeners();
  }

  void setPaymentProof(String? path) {
    _paymentProofPath = path;
    notifyListeners();
  }

  Future<String?> uploadPaymentProof(File file, String userId) async {
    try {
      final String fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = 'payment_proofs/$fileName';
      
      await _supabase.storage.from('avatars').upload(
        filePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );
      
      return _supabase.storage.from('avatars').getPublicUrl(filePath);
    } catch (e) {
      debugPrint('Error uploading payment proof: $e');
      return null;
    }
  }

  void addToCart(FoodItemModel item, {String? notes, double? customPrice}) {
    if (_shopStatus == ShopStatus.closed) return;
    
    final foodWithPrice = customPrice != null ? item.copyWith(price: customPrice) : item;
    final index = _cart.indexWhere((c) => c.foodItem.id == item.id && c.notes == notes);
    if (index >= 0) {
      _cart[index].quantity++;
    } else {
      _cart.add(CartItemModel(foodItem: foodWithPrice, quantity: 1, notes: notes));
    }
    notifyListeners();
  }

  void removeFromCart(String itemId, [String? notes]) {
    _cart.removeWhere((c) => c.foodItem.id == itemId && (notes == null || c.notes == notes));
    notifyListeners();
  }

  void updateQuantity(String itemId, String? notes, int delta) {
    final index = _cart.indexWhere((c) => c.foodItem.id == itemId && c.notes == notes);
    if (index >= 0) {
      _cart[index].quantity += delta;
      if (_cart[index].quantity <= 0) {
        _cart.removeAt(index);
      }
      notifyListeners();
    }
  }

  Future<String?> placeOrder(String userId, String customerName, {String? customerPhone}) async {
    if (_cart.isEmpty) return 'Keranjang kosong';
    if (_shopStatus == ShopStatus.closed) return 'Warung sedang tutup';
    
    // 1. Validate Stock
    if (!InventoryService.validateStockAvailability(_cart, _ingredients)) {
      return 'Maaf, stok bahan baku tidak mencukupi untuk pesanan Anda.';
    }

    try {
      String? paymentProofUrl;
      if (_paymentMethod != PaymentMethod.cash && _paymentProofPath != null) {
        final File file = File(_paymentProofPath!);
        paymentProofUrl = await uploadPaymentProof(file, userId);
        if (paymentProofUrl == null) {
          return 'Gagal mengunggah bukti pembayaran. Silakan coba lagi.';
        }
      }

      final dateStr = DateFormat('dd_MM_yyyy').format(DateTime.now());
      final cleanName = customerName.replaceAll(RegExp(r'\s+'), '_').replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
      final timeStr = DateFormat('HHmmss').format(DateTime.now());
      final customId = '${dateStr}_${cleanName}_$timeStr';

      final orderData = OrderModel(
        id: customId,
        userId: userId,
        items: List.from(_cart),
        subtotal: subtotal,
        tax: tax10,
        serviceCharge: serviceCharge,
        totalAmount: grandTotal,
        status: OrderStatus.pending,
        serviceType: _serviceType,
        paymentMethod: _paymentMethod,
        rsvpTime: _rsvpTime != null
            ? '${_rsvpTime!.hour.toString().padLeft(2, '0')}:${_rsvpTime!.minute.toString().padLeft(2, '0')}'
            : null,
        rsvpDate: _rsvpDate != null 
            ? DateFormat('yyyy-MM-dd').format(_rsvpDate!) 
            : null,
        deliveryFee: _serviceType == ServiceType.delivery ? deliveryFee : null,
        deliveryAddress: _serviceType == ServiceType.delivery ? _deliveryAddress : null,
        latitude: _serviceType == ServiceType.delivery ? _deliveryLatLng?.latitude : null,
        longitude: _serviceType == ServiceType.delivery ? _deliveryLatLng?.longitude : null,
        specialInstructions:
            _specialInstructions.isEmpty ? null : _specialInstructions,
        timestamp: DateTime.now(),
        paymentProofUrl: paymentProofUrl,
        customerName: customerName,
        customerPhone: customerPhone,
      );

      // 2. Add Order to Firestore
      await _firestore.collection('orders').doc(customId).set(orderData.toFirestore());

      // 3. Add Details to Firestore
      for (var cartItem in _cart) {
        final orderMenuId = MenuIdHelper.applyServiceTypeToMenuId(cartItem.foodItem.id, _serviceType);
        await _firestore.collection('detail').add({
          'id_order': customId,
          'id_menu': orderMenuId,
          'jml': cartItem.quantity,
          'harga': cartItem.foodItem.price,
          'catatan': cartItem.notes,
        });
      }

      // 4. Deduct Ingredients Stock
      await _inventoryService.deductIngredients(_cart);

      // Deduct toppings ingredients
      final batch = _firestore.batch();
      for (var cartItem in _cart) {
        if (cartItem.notes != null) {
          final notes = cartItem.notes!.toLowerCase();
          for (var topping in _toppings) {
            if (notes.contains(topping.name.toLowerCase()) && topping.ingredientId.isNotEmpty) {
              final docRef = _firestore.collection('bahan').doc(topping.ingredientId);
              batch.update(docRef, {
                'stok': FieldValue.increment(-1.0 * cartItem.quantity),
              });
            }
          }
        }
      }
      await batch.commit();

      _cart.clear();
      _specialInstructions = '';
      _rsvpTime = null;
      _rsvpDate = null;
      _paymentProofPath = null;
      notifyListeners();
      return null; // Success
    } catch (e) {
      debugPrint('Error placing order: $e');
      return 'Gagal memproses pesanan: $e';
    }
  }

  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      _orders[index] = _orders[index].copyWith(status: newStatus);
      notifyListeners();
    }
  }

  Future<bool> submitOrderRating(String orderId, double rating, String note) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'rating': rating,
        'catatan_rating': note,
        'waktu_rating': Timestamp.now(),
        'status': OrderStatus.finished.name, // Auto finalize if rated
      });

      // Sync Laporan
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (orderDoc.exists) {
        final orderData = orderDoc.data()!;
        final timestamp = orderData['waktu_pesan'] != null
            ? (orderData['waktu_pesan'] as Timestamp).toDate()
            : DateTime.now();
        await _syncLaporanForDate(timestamp);
      }

      return true;
    } catch (e) {
      debugPrint('Error submitting rating: $e');
      return false;
    }
  }

  Future<bool> finishOrder(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.finished.name,
      });

      // Sync Laporan
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (orderDoc.exists) {
        final orderData = orderDoc.data()!;
        final timestamp = orderData['waktu_pesan'] != null
            ? (orderData['waktu_pesan'] as Timestamp).toDate()
            : DateTime.now();
        await _syncLaporanForDate(timestamp);
      }

      return true;
    } catch (e) {
      debugPrint('Error finishing order: $e');
      return false;
    }
  }

  Future<void> _syncLaporanForDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

      // Query finished orders for this date
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: OrderStatus.finished.name)
          .where('waktu_pesan', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('waktu_pesan', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      double totalRevenue = 0.0;
      int orderCount = 0;

      for (var doc in ordersSnapshot.docs) {
        totalRevenue += (doc.data()['total'] ?? doc.data()['totalAmount'] ?? 0.0).toDouble();
        orderCount++;
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      await _firestore.collection('laporan').doc(dateStr).set({
        'tanggal': Timestamp.fromDate(startOfDay),
        'total_pemasukan': totalRevenue,
        'jumlah_order': orderCount,
      });
    } catch (e) {
      debugPrint('Error syncing laporan: $e');
    }
  }

  void toggleMenuAvailability(String itemId, bool isAvailable) {
    final index = _menuItems.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      _menuItems[index] = _menuItems[index].copyWith(isAvailable: isAvailable);
      notifyListeners();
    }
  }

  void _bootstrapMenu() async {
    // Wait for ingredients to be loaded to link them
    if (_ingredients.isEmpty) {
      final snapshot = await _firestore.collection('bahan').get();
      _ingredients = snapshot.docs.map((doc) {
        final data = doc.data();
        final stok = (data['stok'] ?? 0).toDouble();
        final threshold = (data['ambang_batas_stok'] ?? data['minStockThreshold'] ?? 5).toDouble();
        return RawIngredientModel(
          id: doc.id,
          name: data['nama_bahan'] ?? data['name'] ?? '',
          category: data['kategori'] ?? data['category'] ?? 'Umum',
          amount: stok,
          unit: data['satuan'] ?? data['unit'] ?? '',
          minStockThreshold: threshold,
          isLowStock: stok < threshold,
        );
      }).toList();
    }

    String getIngId(String name) => _ingredients.firstWhere(
      (i) => i.name.toLowerCase() == name.toLowerCase(),
      orElse: () => RawIngredientModel(id: 'dummy_$name', name: name, category: '', amount: 0, unit: ''),
    ).id;

    final initialMenu = [
      FoodItemModel(
        id: '1',
        name: 'Gado-Gado Spesial',
        description: 'Campuran sayuran kukus, tahu, tempe, dan saus kacang resep rahasia 24 jam kami.',
        price: 35000,
        image: 'assets/images/Gado-Gado.jpg',
        category: 'Makanan Utama',
        isBestSeller: true,
        recipe: [
          RecipeItemModel(ingredientId: getIngId('Kacang tanah'), ingredientName: 'Kacang tanah', quantityPerPortion: 0.1), // 100g
          RecipeItemModel(ingredientId: getIngId('Tahu'), ingredientName: 'Tahu', quantityPerPortion: 2), // 2 pcs
          RecipeItemModel(ingredientId: getIngId('Tempe'), ingredientName: 'Tempe', quantityPerPortion: 2), // 2 pcs
          RecipeItemModel(ingredientId: getIngId('Lontong'), ingredientName: 'Lontong', quantityPerPortion: 1), // 1 pc
          RecipeItemModel(ingredientId: getIngId('Telur'), ingredientName: 'Telur', quantityPerPortion: 1), // 1 pc
        ],
      ),
      FoodItemModel(
        id: '2',
        name: 'Ketoprak',
        description: 'Ketupat, bihun, tauge, dan tahu yang disiram saus kacang kental dan bumbu bawang putih yang gurih.',
        price: 28000,
        image: 'assets/images/Ketoprak.jpg',
        category: 'Makanan Utama',
        isNew: true,
        recipe: [
          RecipeItemModel(ingredientId: getIngId('Kacang tanah'), ingredientName: 'Kacang tanah', quantityPerPortion: 0.08), // 80g
          RecipeItemModel(ingredientId: getIngId('Tahu'), ingredientName: 'Tahu', quantityPerPortion: 2),
          RecipeItemModel(ingredientId: getIngId('Bihun'), ingredientName: 'Bihun', quantityPerPortion: 50), // 50g
          RecipeItemModel(ingredientId: getIngId('Lontong'), ingredientName: 'Lontong', quantityPerPortion: 1),
        ],
      ),
      FoodItemModel(
        id: '3',
        name: 'Karedok',
        description: 'Sayuran segar mentah yang dicampur dengan bumbu kacang kencur yang harum dan menggugah selera.',
        price: 30000,
        image: 'assets/images/Karedok.jpg',
        category: 'Makanan Utama',
        isNew: true,
        recipe: [
          RecipeItemModel(ingredientId: getIngId('Kacang tanah'), ingredientName: 'Kacang tanah', quantityPerPortion: 0.08),
          RecipeItemModel(ingredientId: getIngId('Kencur'), ingredientName: 'Kencur', quantityPerPortion: 10), // 10g
          RecipeItemModel(ingredientId: getIngId('Kacang Panjang'), ingredientName: 'Kacang Panjang', quantityPerPortion: 0.05), // 50g
        ],
      ),
      FoodItemModel(
        id: '4',
        name: 'Es Campur Mpo',
        description: 'Campuran segar buah tropis, cincau, dan susu kental manis di atas es serut.',
        price: 18000,
        image: 'assets/images/Es Buah.jpg',
        category: 'Drinks',
        recipe: [
          RecipeItemModel(ingredientId: getIngId('Cincau'), ingredientName: 'Cincau', quantityPerPortion: 50),
          RecipeItemModel(ingredientId: getIngId('Susu kental manis'), ingredientName: 'Susu kental manis', quantityPerPortion: 1),
          RecipeItemModel(ingredientId: getIngId('Es batu'), ingredientName: 'Es batu', quantityPerPortion: 0.2), // 200g
        ],
      ),
      FoodItemModel(
        id: '5',
        name: 'Es Teh Manis',
        description: 'Teh melati autentik yang diseduh segar dan disajikan dingin. Pembersih palet yang sempurna.',
        price: 7000,
        image: 'assets/images/Es_Teh.jpg',
        category: 'Drinks',
        recipe: [
          RecipeItemModel(ingredientId: getIngId('Teh celup'), ingredientName: 'Teh celup', quantityPerPortion: 1),
          RecipeItemModel(ingredientId: getIngId('Gula'), ingredientName: 'Gula', quantityPerPortion: 0.02), // 20g
          RecipeItemModel(ingredientId: getIngId('Es batu'), ingredientName: 'Es batu', quantityPerPortion: 0.1),
        ],
      ),
    ];

    for (var item in initialMenu) {
      await _firestore.collection('menu').add(item.toFirestore());
    }
  }
}

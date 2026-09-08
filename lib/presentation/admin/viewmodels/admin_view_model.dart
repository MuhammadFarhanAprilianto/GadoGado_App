import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gado_gado_app/data/models/food_item_model.dart';
import 'package:gado_gado_app/data/models/order_model.dart';
import 'package:gado_gado_app/data/models/shop_settings_model.dart';
import 'package:gado_gado_app/data/models/raw_ingredient_model.dart';
import 'package:gado_gado_app/data/models/topping_model.dart';
import 'package:gado_gado_app/core/utils/menu_id_helper.dart';

class AdminViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _supabase = Supabase.instance.client;
  List<RawIngredientModel> _ingredients = [];
  List<FoodItemModel> _menuItems = [];
  List<OrderModel> _allOrders = [];
  List<Map<String, dynamic>> _allExpenses = [];
  List<ToppingModel> _toppings = [];
  ShopStatus _shopStatus = ShopStatus.closed;
  bool _isManualOverride = false;
  Timer? _autoStatusTimer;

  StreamSubscription<QuerySnapshot>? _ordersSub;
  StreamSubscription<QuerySnapshot>? _detailsSub;
  StreamSubscription? _toppingsSub;
  List<DocumentSnapshot> _orderDocs = [];
  List<DocumentSnapshot> _detailDocs = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RawIngredientModel> get ingredients => _ingredients;
  List<ToppingModel> get toppings => _toppings;
  List<FoodItemModel> get menuItems => _menuItems;
  List<OrderModel> get allOrders => _allOrders;
  List<Map<String, dynamic>> get allExpenses => _allExpenses;
  ShopStatus get shopStatus => _shopStatus;
  bool get isManualOverride => _isManualOverride;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get inStockCount => _ingredients.where((i) => i.amount > 0).length;
  int get outOfStockCount => _ingredients.where((i) => i.amount <= 0).length;
  
  List<RawIngredientModel> get lowStockIngredients => _ingredients.where((i) => i.isLowStock).toList();
  int get lowStockCount => lowStockIngredients.length;

  int get menuReadinessPercentage {
    if (_menuItems.isEmpty) return 0;
    final available = _menuItems.where((item) => item.isAvailable).length;
    return ((available / _menuItems.length) * 100).toInt();
  }

  List<OrderModel> get incomingOrders => _allOrders
      .where((o) => o.status != OrderStatus.finished && o.status != OrderStatus.cancelled)
      .toList();

  // Today's stats for Admin Dashboard sync
  List<OrderModel> get todayOrders {
    final now = DateTime.now();
    return _allOrders.where((o) =>
        o.timestamp.year == now.year &&
        o.timestamp.month == now.month &&
        o.timestamp.day == now.day).toList();
  }

  double get todayRevenue => todayOrders
      .where((o) => o.status == OrderStatus.finished)
      .fold(0, (total, o) => total + o.totalAmount);

  int get todayOrderCount => todayOrders
      .where((o) => o.status == OrderStatus.finished)
      .length;

  AdminViewModel() {
    _listenToIngredients();
    _listenToMenu();
    _listenToAllOrders();
    _listenToShopStatus();
    _listenToExpenses();
    _listenToToppings();
    _initAutoStatusTimer();
  }

  void _initAutoStatusTimer() {
    // Check every minute if we need to auto-transition
    _autoStatusTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAndApplyAutoStatus();
    });
    // Initial check
    _checkAndApplyAutoStatus();
  }

  void _checkAndApplyAutoStatus() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    
    // Logic boundaries:
    // 10:00, 12:00, 13:00, 17:00
    
    ShopStatus targetStatus;
    if (hour >= 10 && hour < 12) {
      targetStatus = ShopStatus.open;
    } else if (hour >= 12 && hour < 13) {
      targetStatus = ShopStatus.ishoma;
    } else if (hour >= 13 && hour < 17) {
      targetStatus = ShopStatus.open;
    } else {
      targetStatus = ShopStatus.closed;
    }

    // Auto-update logic:
    // We auto-update only if:
    // 1. It's exactly the start of a boundary (minute 0)
    // 2. OR if the shop is currently OPEN/ISHOMA during CLOSED hours (safety net)
    // Note: We respect the manual override if it's set, unless we transition past a boundary.
    bool isBoundary = minute == 0 && (hour == 10 || hour == 12 || hour == 13 || hour == 17);
    
    if (_isManualOverride) {
      if (isBoundary && _shopStatus != targetStatus) {
        updateShopStatus(targetStatus, isManual: false);
      }
    } else {
      bool isIllegalOpen = targetStatus == ShopStatus.closed && _shopStatus != ShopStatus.closed;
      bool isStandardTransition = minute == 0;
      if (isIllegalOpen || (isStandardTransition && _shopStatus != targetStatus)) {
        updateShopStatus(targetStatus, isManual: false);
      }
    }
  }

  @override
  void dispose() {
    _autoStatusTimer?.cancel();
    _ordersSub?.cancel();
    _detailsSub?.cancel();
    _toppingsSub?.cancel();
    super.dispose();
  }

  void _listenToShopStatus() {
    _firestore
        .collection('settings')
        .doc('shop_status')
        .snapshots()
        .listen((snapshot) {
      debugPrint('ADMIN SHOP STATUS SNAPSHOT: exists=${snapshot.exists}');
      if (snapshot.exists) {
        final data = snapshot.data();
        debugPrint('ADMIN SHOP STATUS DATA: $data');
        if (data != null) {
          try {
            _shopStatus = ShopStatus.values.firstWhere(
              (e) => e.name == data['status'],
              orElse: () => ShopStatus.closed,
            );
            _isManualOverride = data['isManualOverride'] ?? false;
            debugPrint('ADMIN SHOP STATUS PARSED: $_shopStatus, isManualOverride: $_isManualOverride');
            notifyListeners();
          } catch (e, stack) {
            debugPrint('Error parsing shop status in AdminViewModel: $e');
            debugPrint(stack.toString());
          }
        }
      } else {
        // Initialize if doesn't exist
        debugPrint('ADMIN SHOP STATUS DOCUMENT DOES NOT EXIST. INITIALIZING...');
        updateShopStatus(ShopStatus.closed, isManual: false);
      }
    }, onError: (err) {
      debugPrint('ADMIN SHOP STATUS STREAM ERROR: $err');
    });
  }

  Future<void> updateShopStatus(ShopStatus status, {bool isManual = true}) async {
    await _firestore.collection('settings').doc('shop_status').set({
      'status': status.name,
      'lastUpdated': FieldValue.serverTimestamp(),
      'isManualOverride': isManual,
    }, SetOptions(merge: true));
  }

  Future<void> updateShopLocation(double latitude, double longitude, String address) async {
    await _firestore.collection('settings').doc('shop_status').set({
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _listenToIngredients() {
    _firestore.collection('bahan').snapshots().listen((snapshot) {
      _ingredients = snapshot.docs.map((doc) {
        final data = doc.data();
        final rawStok = data['stok'] ?? data['amount'] ?? 0;
        final rawMin = data['ambang_batas_stok'] ?? data['minStockThreshold'] ?? 5;
        final stok = (rawStok is num) ? rawStok.toDouble() : (double.tryParse(rawStok.toString()) ?? 0.0);
        final threshold = (rawMin is num) ? rawMin.toDouble() : (double.tryParse(rawMin.toString()) ?? 5.0);
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
    }, onError: (e) {
      _errorMessage = 'Error syncing ingredients: $e';
      notifyListeners();
    });
  }

  Future<void> refreshIngredients() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final snapshot = await _firestore.collection('bahan').get();
      _ingredients = snapshot.docs.map((doc) {
        final data = doc.data();
        final rawStok = data['stok'] ?? data['amount'] ?? 0;
        final rawMin = data['ambang_batas_stok'] ?? data['minStockThreshold'] ?? 5;
        final stok = (rawStok is num) ? rawStok.toDouble() : (double.tryParse(rawStok.toString()) ?? 0.0);
        final threshold = (rawMin is num) ? rawMin.toDouble() : (double.tryParse(rawMin.toString()) ?? 5.0);
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
    } catch (e) {
      _errorMessage = 'Gagal memuat ulang: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _listenToMenu() {
    _firestore.collection('menu').snapshots().listen((snapshot) {
      final List<FoodItemModel> items = [];
      for (var doc in snapshot.docs) {
        try {
          items.add(FoodItemModel.fromFirestore(doc.data(), doc.id));
        } catch (e, stack) {
          debugPrint('Error parsing menu item ${doc.id} in AdminViewModel: $e');
          debugPrint(stack.toString());
        }
      }
      _menuItems = items;
      notifyListeners();
    }, onError: (error) {
      debugPrint('ADMIN MENU STREAM ERROR: $error');
    });
  }

  void _listenToAllOrders() {
    _ordersSub?.cancel();
    _detailsSub?.cancel();

    _ordersSub = _firestore
        .collection('orders')
        .snapshots()
        .listen((ordersSnapshot) {
      _orderDocs = ordersSnapshot.docs;
      _rebuildOrders();
    }, onError: (error) {
      debugPrint('ADMIN ORDERS STREAM ERROR: $error');
    });

    _detailsSub = _firestore.collection('detail').snapshots().listen((detailsSnapshot) {
      _detailDocs = detailsSnapshot.docs;
      _rebuildOrders();
    }, onError: (error) {
      debugPrint('ADMIN DETAILS STREAM ERROR: $error');
    });
  }

  void _rebuildOrders() {
    if (_orderDocs.isEmpty) {
      _allOrders = [];
      notifyListeners();
      return;
    }

    final List<OrderModel> rebuilt = [];

    for (var orderDoc in _orderDocs) {
      try {
        final orderData = orderDoc.data() as Map<String, dynamic>?;
        if (orderData == null) continue;
        final orderId = orderDoc.id;

        final orderDetails = _detailDocs.where((d) {
          try {
            final data = d.data() as Map<String, dynamic>?;
            return data != null && data['id_order'] == orderId;
          } catch (_) {
            return false;
          }
        }).toList();
        
        final List<CartItemModel> items = [];
        for (var det in orderDetails) {
          try {
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
          } catch (e, stack) {
            debugPrint('Error parsing order detail item: $e');
            debugPrint(stack.toString());
          }
        }

        rebuilt.add(OrderModel.fromFirestore(orderData, orderId, items: items));
      } catch (e, stack) {
        debugPrint('Error parsing order ${orderDoc.id} in AdminViewModel: $e');
        debugPrint(stack.toString());
      }
    }

    _allOrders = rebuilt;
    _allOrders.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final Map<String, dynamic> updates = {'status': newStatus.name};
    if (newStatus == OrderStatus.finished) {
      updates['waktu_selesai'] = FieldValue.serverTimestamp();
      updates['rating'] = 4.5 + (DateTime.now().millisecond % 10) / 10.0;
      updates['catatan_rating'] = 'Sangat memuaskan!';
      updates['waktu_rating'] = FieldValue.serverTimestamp();
    }
    await _firestore.collection('orders').doc(orderId).update(updates);

    if (newStatus == OrderStatus.finished) {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (orderDoc.exists) {
        final orderData = orderDoc.data()!;
        final timestamp = orderData['waktu_pesan'] != null
            ? (orderData['waktu_pesan'] as Timestamp).toDate()
            : DateTime.now();
        await _syncLaporanForDate(timestamp);
      }
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

  Future<void> toggleItemAvailability(String itemId, bool isAvailable) async {
    await _firestore.collection('menu').doc(itemId).update({'isAvailable': isAvailable});
  }

  Future<void> addFoodItem(FoodItemModel item) async {
    final letter = MenuIdHelper.getCategoryLetter(item.category);
    int maxIndex = 0;
    final regex = RegExp('^#?$letter(\\d+)0_');
    for (var menuItem in _menuItems) {
      final match = regex.firstMatch(menuItem.id);
      if (match != null) {
        final idx = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (idx > maxIndex) {
          maxIndex = idx;
        }
      }
    }
    final nextIndex = maxIndex + 1;
    final cleanName = MenuIdHelper.cleanMenuName(item.name);
    final customId = '#$letter${nextIndex}0_$cleanName';

    await _firestore
        .collection('menu')
        .doc(customId)
        .set(item.toFirestore())
        .timeout(const Duration(seconds: 10));
  }

  Future<void> updateFoodItem(FoodItemModel item) async {
    await _firestore
        .collection('menu')
        .doc(item.id)
        .update(item.toFirestore())
        .timeout(const Duration(seconds: 10));
  }

  Future<String> uploadImage(File file, String folder) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = '$folder/$fileName';
      
      await _supabase.storage.from('menu-images').upload(
        filePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      ).timeout(const Duration(seconds: 30));
      
      final String publicUrl = _supabase.storage.from('menu-images').getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image to Supabase: $e');
      throw e.toString().contains('Timeout') 
          ? 'Koneksi unggah lambat, silakan coba lagi.' 
          : 'Gagal mengunggah gambar ke Supabase: $e';
    }
  }

  Future<void> deleteFoodItem(String itemId, {String? imageUrl}) async {
    try {
      // 1. Delete from Firestore
      await _firestore.collection('menu').doc(itemId).delete();
      
      // 2. Optional: Delete from Supabase Storage if it's a Supabase URL
      if (imageUrl != null && imageUrl.contains('supabase.co')) {
        try {
          // Extract file path from URL (e.g., folder/filename.jpg)
          final uri = Uri.parse(imageUrl);
          final pathSegments = uri.pathSegments;
          if (pathSegments.length >= 3) {
            // Path is usually /storage/v1/object/public/bucket-name/folder/file.jpg
            // We need the part after bucket-name
            final filePath = pathSegments.sublist(pathSegments.indexOf('menu-images') + 1).join('/');
            await _supabase.storage.from('menu-images').remove([filePath]);
          }
        } catch (e) {
          debugPrint('Silent error deleting image from storage: $e');
          // Don't throw here, Firestore deletion was successful
        }
      }
    } catch (e) {
      throw 'Gagal menghapus menu: $e';
    }
  }

  Future<void> addIngredient(String name, double amount, String unit, {String category = 'General', double? minThreshold}) async {
    await _firestore.collection('bahan').add({
      'nama_bahan': name,
      'kategori': category,
      'stok': amount,
      'satuan': unit,
      'ambang_batas_stok': minThreshold ?? 5.0,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> seedInitialIngredients() async {
    final List<Map<String, dynamic>> seeds = [
      // Sayuran
      {'name': 'Kangkung', 'category': 'Sayuran', 'amount': 0.0, 'unit': 'kg', 'min': 5.0},
      {'name': 'Toge', 'category': 'Sayuran', 'amount': 0.0, 'unit': 'kg', 'min': 5.0},
      {'name': 'Kol', 'category': 'Sayuran', 'amount': 0.0, 'unit': 'kg', 'min': 5.0},
      {'name': 'Timun', 'category': 'Sayuran', 'amount': 0.0, 'unit': 'kg', 'min': 5.0},
      {'name': 'Kacang Panjang', 'category': 'Sayuran', 'amount': 0.0, 'unit': 'kg', 'min': 5.0},
      {'name': 'Terong Belanda', 'category': 'Sayuran', 'amount': 0.0, 'unit': 'kg', 'min': 5.0},
      // Protein / Pelengkap
      {'name': 'Tahu', 'category': 'Protein / Pelengkap', 'amount': 0.0, 'unit': 'pcs', 'min': 50.0},
      {'name': 'Tempe', 'category': 'Protein / Pelengkap', 'amount': 0.0, 'unit': 'pcs', 'min': 50.0},
      {'name': 'Telur', 'category': 'Protein / Pelengkap', 'amount': 0.0, 'unit': 'kg', 'min': 2.0},
      {'name': 'Lontong', 'category': 'Protein / Pelengkap', 'amount': 0.0, 'unit': 'pcs', 'min': 30.0},
      {'name': 'Bihun', 'category': 'Protein / Pelengkap', 'amount': 0.0, 'unit': 'gram', 'min': 1000.0},
      // Pelengkap
      {'name': 'Cincau', 'category': 'Pelengkap', 'amount': 0.0, 'unit': 'gram', 'min': 500.0},
      {'name': 'Kolang-kaling', 'category': 'Pelengkap', 'amount': 0.0, 'unit': 'gram', 'min': 500.0},
      {'name': 'Agar Agar', 'category': 'Pelengkap', 'amount': 0.0, 'unit': 'pcs', 'min': 10.0},
      // Bumbu
      {'name': 'Kacang tanah', 'category': 'Bumbu', 'amount': 0.0, 'unit': 'kg', 'min': 2.0},
      {'name': 'Bawang putih', 'category': 'Bumbu', 'amount': 0.0, 'unit': 'kg', 'min': 1.0},
      {'name': 'Cabai', 'category': 'Bumbu', 'amount': 0.0, 'unit': 'kg', 'min': 1.0},
      {'name': 'Gula merah', 'category': 'Bumbu', 'amount': 0.0, 'unit': 'kg', 'min': 1.0},
      {'name': 'Garam', 'category': 'Bumbu', 'amount': 0.0, 'unit': 'gram', 'min': 500.0},
      {'name': 'Kencur', 'category': 'Bumbu', 'amount': 0.0, 'unit': 'gram', 'min': 100.0},
      {'name': 'Kecap manis', 'category': 'Bumbu', 'amount': 0.0, 'unit': 'ml', 'min': 500.0},
      {'name': 'Gula', 'category': 'Bumbu', 'amount': 0.0, 'unit': 'kg', 'min': 1.0},
      {'name': 'Teh celup', 'category': 'Bumbu', 'amount': 0.0, 'unit': 'pcs', 'min': 25.0},
      // Minuman / Cairan
      {'name': 'Air', 'category': 'Minuman / Cairan', 'amount': 0.0, 'unit': 'liter', 'min': 19.0},
      {'name': 'Susu kental manis', 'category': 'Minuman / Cairan', 'amount': 0.0, 'unit': 'pcs', 'min': 10.0},
      {'name': 'Sirup', 'category': 'Minuman / Cairan', 'amount': 0.0, 'unit': 'liter', 'min': 2.0},
      // Buah
      {'name': 'Alpukat', 'category': 'Buah', 'amount': 0.0, 'unit': 'kg', 'min': 3.0},
      {'name': 'Tape', 'category': 'Buah', 'amount': 0.0, 'unit': 'kg', 'min': 2.0},
      {'name': 'Buah Naga', 'category': 'Buah', 'amount': 0.0, 'unit': 'kg', 'min': 3.0},
      // Lainnya
      {'name': 'Kerupuk', 'category': 'Lainnya', 'amount': 0.0, 'unit': 'gram', 'min': 1000.0},
      {'name': 'Es batu', 'category': 'Lainnya', 'amount': 0.0, 'unit': 'kg', 'min': 5.0},
    ];

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final batch = _firestore.batch();
      int count = 0;
      for (var seed in seeds) {
        final existing = _ingredients.any((i) => i.name.toLowerCase() == seed['name'].toString().toLowerCase());
        if (!existing) {
          final docRef = _firestore.collection('bahan').doc();
          batch.set(docRef, {
            'nama_bahan': seed['name'],
            'kategori': seed['category'],
            'stok': seed['amount'],
            'satuan': seed['unit'],
            'ambang_batas_stok': seed['min'],
            'timestamp': FieldValue.serverTimestamp(),
          });
          count++;
        }
      }
      
      if (count > 0) {
        await batch.commit();
        await refreshIngredients(); // Forced Aggressive Fetch
      }
    } catch (e) {
      _errorMessage = 'Gagal inisialisasi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateIngredientDetails(String id, double amount, double? minThreshold) async {
    // 1. Optimistic Local Update (Instant 0ms UI reactivity)
    final index = _ingredients.indexWhere((i) => i.id == id);
    if (index != -1) {
      final old = _ingredients[index];
      final threshold = minThreshold ?? old.minStockThreshold ?? 5.0;
      _ingredients[index] = RawIngredientModel(
        id: old.id,
        name: old.name,
        category: old.category,
        amount: amount,
        unit: old.unit,
        minStockThreshold: threshold,
        isLowStock: amount < threshold,
      );
      notifyListeners();
    }

    // 2. Real-time Firestore Database Write
    try {
      await _firestore.collection('bahan').doc(id).set({
        'stok': amount,
        'amount': amount,
        'ambang_batas_stok': minThreshold ?? 5.0,
        'minStockThreshold': minThreshold ?? 5.0,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating ingredient details in Firestore: $e');
    }
  }

  Future<void> updateIngredientAmount(String id, double amount) async {
    // 1. Optimistic Local Update
    final index = _ingredients.indexWhere((i) => i.id == id);
    if (index != -1) {
      final old = _ingredients[index];
      final threshold = old.minStockThreshold ?? 5.0;
      _ingredients[index] = RawIngredientModel(
        id: old.id,
        name: old.name,
        category: old.category,
        amount: amount,
        unit: old.unit,
        minStockThreshold: threshold,
        isLowStock: amount < threshold,
      );
      notifyListeners();
    }

    // 2. Real-time Firestore Database Write
    try {
      await _firestore.collection('bahan').doc(id).set({
        'stok': amount,
        'amount': amount,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating ingredient amount in Firestore: $e');
    }
  }

  Future<void> updateIngredientThreshold(String id, double? minThreshold) async {
    final threshold = minThreshold ?? 5.0;
    // 1. Optimistic Local Update
    final index = _ingredients.indexWhere((i) => i.id == id);
    if (index != -1) {
      final old = _ingredients[index];
      _ingredients[index] = RawIngredientModel(
        id: old.id,
        name: old.name,
        category: old.category,
        amount: old.amount,
        unit: old.unit,
        minStockThreshold: threshold,
        isLowStock: old.amount < threshold,
      );
      notifyListeners();
    }

    // 2. Real-time Firestore Database Write
    try {
      await _firestore.collection('bahan').doc(id).set({
        'ambang_batas_stok': threshold,
        'minStockThreshold': threshold,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating ingredient threshold in Firestore: $e');
    }
  }

  Future<void> deleteIngredient(String id) async {
    // Optimistic remove
    _ingredients.removeWhere((i) => i.id == id);
    notifyListeners();

    try {
      await _firestore.collection('bahan').doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting ingredient in Firestore: $e');
    }
  }

  void _listenToExpenses() {
    _firestore
        .collection('restock')
        .orderBy('tanggal', descending: true)
        .snapshots()
        .listen((snapshot) {
      _allExpenses = snapshot.docs.map((doc) {
        final data = doc.data();
        final ingId = data['id_bahan'] ?? '';
        final ingredient = _ingredients.firstWhere(
          (i) => i.id == ingId,
          orElse: () => RawIngredientModel(id: ingId, name: 'Bahan Baku', category: 'General', amount: 0, unit: ''),
        );
        return {
          'id': doc.id,
          'ingredientId': ingId,
          'ingredientName': ingredient.name,
          'amount': (data['jumlah'] ?? 0).toDouble(),
          'cost': (data['biaya'] ?? 0).toDouble(),
          'timestamp': (data['tanggal'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
      notifyListeners();
    });
  }

  Future<void> recordExpense(String ingredientId, String ingredientName, double amount, double cost, {String? userId, String? keterangan}) async {
    await _firestore.collection('restock').add({
      'id_bahan': ingredientId,
      'id_user': userId ?? 'system_admin',
      'jumlah': amount,
      'biaya': cost,
      'tanggal': FieldValue.serverTimestamp(),
      'keterangan': keterangan ?? 'Restock bahan $ingredientName',
    });
  }

  void _listenToToppings() {
    _toppingsSub = _firestore.collection('toppings').snapshots().listen((snapshot) {
      _toppings = snapshot.docs
          .map((doc) => ToppingModel.fromFirestore(doc.data(), doc.id))
          .toList();
      notifyListeners();
    });
  }

  Future<void> addTopping(String name, double price, String ingredientId) async {
    await _firestore.collection('toppings').add({
      'nama': name,
      'harga': price,
      'id_bahan': ingredientId,
    });
  }

  Future<void> updateTopping(ToppingModel topping) async {
    await _firestore.collection('toppings').doc(topping.id).update(topping.toFirestore());
  }

  Future<void> deleteTopping(String id) async {
    await _firestore.collection('toppings').doc(id).delete();
  }
}

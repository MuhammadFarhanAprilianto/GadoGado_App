import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gado_gado_app/data/models/order_model.dart';
import 'package:gado_gado_app/data/models/food_item_model.dart';
import 'package:gado_gado_app/core/utils/menu_id_helper.dart';
import 'package:flutter/material.dart';

class OwnerViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<OrderModel> _allOrders = [];
  List<OrderModel> _filteredOrders = [];
  List<FoodItemModel> _menuItems = [];
  List<Map<String, dynamic>> _laporanList = [];
  List<Map<String, dynamic>> get laporanList => _laporanList;
  
  // Filter state
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String _filterStatus = 'All'; // 'All', 'Paid', 'Cancelled'
  String _selectedPeriod = 'month'; // 'day', 'week', 'month'

  double _totalRevenue = 0;
  String _revenueTrend = "0% vs last period";
  int _totalOrders = 0;
  double _avgCheck = 0;
  double _avgRating = 0.0;
  int _avgPrepTime = 0;
  List<double> _weeklySales = [0, 0, 0, 0, 0, 0, 0];
  double _maxWeeklySales = 0;
  List<Map<String, dynamic>> _topItems = [];

  StreamSubscription? _ordersSub;
  StreamSubscription? _detailsSub;
  StreamSubscription? _menuSub;
  StreamSubscription? _laporanSub;
  List<DocumentSnapshot> _orderDocs = [];
  List<DocumentSnapshot> _detailDocs = [];

  OwnerViewModel() {
    _setSelectedPeriod('month');
    _listenToMenu();
    _listenToOrders();
    _listenToLaporan();
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    _detailsSub?.cancel();
    _menuSub?.cancel();
    _laporanSub?.cancel();
    super.dispose();
  }

  void _setSelectedPeriod(String period) {
    _selectedPeriod = period;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (period == 'day') {
      _filterStartDate = today;
      _filterEndDate = today.add(const Duration(hours: 23, minutes: 59, seconds: 59));
    } else if (period == 'week') {
      _filterStartDate = today.subtract(Duration(days: today.weekday - 1));
      _filterEndDate = today.add(const Duration(days: 7 - 1, hours: 23, minutes: 59, seconds: 59));
    } else {
      // Month
      _filterStartDate = DateTime(now.year, now.month, 1);
      _filterEndDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    }
  }

  void setPeriod(String period) {
    _setSelectedPeriod(period);
    _calculateStats();
    notifyListeners();
  }

  void _listenToMenu() {
    _menuSub = _firestore.collection('menu').snapshots().listen((snapshot) {
      _menuItems = snapshot.docs
          .map((doc) => FoodItemModel.fromFirestore(doc.data(), doc.id))
          .toList();
      _rebuildOrders();
    });
  }

  void _listenToOrders() {
    _ordersSub?.cancel();
    _detailsSub?.cancel();

    _ordersSub = _firestore
        .collection('orders')
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
      _allOrders = [];
      _calculateStats();
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

    _allOrders = rebuilt;
    _allOrders.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _calculateStats();
    notifyListeners();
  }

  void _listenToLaporan() {
    _laporanSub = _firestore
        .collection('laporan')
        .orderBy('tanggal', descending: true)
        .snapshots()
        .listen((snapshot) {
      _laporanList = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'tanggal': (data['tanggal'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'total_pemasukan': (data['total_pemasukan'] ?? 0).toDouble(),
          'jumlah_order': (data['jumlah_order'] ?? 0).toInt(),
        };
      }).toList();
      notifyListeners();
    });
  }

  void setFilterDateRange(DateTime start, DateTime end) {
    _filterStartDate = start;
    _filterEndDate = DateTime(end.year, end.month, end.day, 23, 59, 59);
    _calculateStats();
    notifyListeners();
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    _calculateStats();
    notifyListeners();
  }

  void _calculateStats() {
    if (_allOrders.isEmpty) return;

    // 1. Filter Orders
    _filteredOrders = _allOrders.where((o) {
      bool dateMatch = true;
      if (_filterStartDate != null && _filterEndDate != null) {
        dateMatch = o.timestamp.isAfter(_filterStartDate!) && o.timestamp.isBefore(_filterEndDate!);
      }

      bool statusMatch = true;
      if (_filterStatus == 'Paid') {
        // Assume 'completed', 'finished', 'ready' are paid
        statusMatch = [OrderStatus.completed, OrderStatus.finished, OrderStatus.ready].contains(o.status);
      } else if (_filterStatus == 'Cancelled') {
        statusMatch = o.status == OrderStatus.cancelled;
      }

      return dateMatch && statusMatch;
    }).toList();

    // 2. Calculate Main Stats
    _totalOrders = _filteredOrders.length;
    _totalRevenue = _filteredOrders.fold(0.0, (total, o) => total + o.totalAmount);
    _avgCheck = _totalOrders > 0 ? _totalRevenue / _totalOrders : 0;

    // Pulse Stats (Rating and Prep Time)
    final finishedOrders = _filteredOrders.where((o) => o.status == OrderStatus.finished).toList();
    if (finishedOrders.isNotEmpty) {
      // 1. Avg Rating
      double totalRating = finishedOrders.fold(0.0, (total, o) => total + (o.rating ?? 0));
      int ratedCount = finishedOrders.where((o) => o.rating != null).length;
      _avgRating = ratedCount > 0 ? totalRating / ratedCount : 4.8; // Fallback to 4.8 if none rated yet

      // 2. Avg Prep Time
      double totalPrepMinutes = 0;
      int prepCount = 0;
      for (var o in finishedOrders) {
        if (o.completedAt != null) {
          totalPrepMinutes += o.completedAt!.difference(o.timestamp).inMinutes;
          prepCount++;
        }
      }
      _avgPrepTime = prepCount > 0 ? (totalPrepMinutes / prepCount).round() : 12; // Fallback to 12 mins
    } else {
      _avgRating = 0.0;
      _avgPrepTime = 0;
    }

    // 3. Calculate Trend (Compare with previous period of same length)
    if (_filterStartDate != null && _filterEndDate != null) {
        final duration = _filterEndDate!.difference(_filterStartDate!);
        final prevStartDate = _filterStartDate!.subtract(duration);
        final prevEndDate = _filterStartDate!.subtract(const Duration(seconds: 1));

        final prevPeriodOrders = _allOrders.where((o) =>
            o.timestamp.isAfter(prevStartDate) && o.timestamp.isBefore(prevEndDate)
        ).toList();

        final prevRevenue = prevPeriodOrders.fold(0.0, (total, o) => total + o.totalAmount);
        
        if (prevRevenue > 0) {
            double percentage = ((_totalRevenue - prevRevenue) / prevRevenue) * 100;
            _revenueTrend = "${percentage > 0 ? '+' : ''}${percentage.toStringAsFixed(1)}% vs periode lalu";
        } else {
            _revenueTrend = "Periode baru";
        }
    }

    // 4. Weekly Sales (Mon-Sun)
    List<double> weekly = [0, 0, 0, 0, 0, 0, 0];
    final now = DateTime.now();
    DateTime firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
    double maxVal = 0;
    for (int i = 0; i < 7; i++) {
        DateTime day = DateTime(firstDayOfWeek.year, firstDayOfWeek.month, firstDayOfWeek.day).add(Duration(days: i));
        double dayTotal = _allOrders.where((o) => 
            o.timestamp.year == day.year && 
            o.timestamp.month == day.month && 
            o.timestamp.day == day.day &&
            o.status != OrderStatus.cancelled // Only count non-cancelled for sales trend
        ).fold(0.0, (total, o) => total + o.totalAmount);
        
        weekly[i] = dayTotal;
        if (dayTotal > maxVal) maxVal = dayTotal;
    }
    _weeklySales = weekly;
    _maxWeeklySales = maxVal;

    // 5. Top Items Calculation (from filtered orders)
    Map<String, int> itemCount = {};
    for (var order in _filteredOrders) {
      for (var item in order.items) {
          itemCount[item.foodItem.name] = (itemCount[item.foodItem.name] ?? 0) + item.quantity;
      }
    }

    var sortedItems = itemCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    _topItems = sortedItems.take(5).map((e) => {
      'title': e.key,
      'subtitle': '${e.value} pesanan di periode ini',
      'tag': e.value > 10 ? 'POPULER' : 'NORMAL',
      'tagColor': e.value > 10 ? Colors.orange : Colors.blue,
    }).toList();
  }

  // Getters
  List<OrderModel> get filteredOrders => _filteredOrders;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;
  String get filterStatus => _filterStatus;
  String get selectedPeriod => _selectedPeriod;
  double get totalRevenue => _totalRevenue;
  String get revenueTrend => _revenueTrend;
  int get totalOrders => _totalOrders;
  double get avgCheck => _avgCheck;
  double get avgRating => _avgRating;
  int get avgPrepTime => _avgPrepTime;
  List<double> get weeklySales => _weeklySales;
  double get maxWeeklySales => _maxWeeklySales;
  List<Map<String, dynamic>> get topItems => _topItems;

  void applyFilters() {
    _calculateStats();
    notifyListeners();
  }

  Future<void> refreshDashboard() async {
    _calculateStats();
    notifyListeners();
  }
}

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gado_gado_app/data/models/user_model.dart';
import 'package:intl/intl.dart';

class AuthViewModel extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitializing = true; // true saat startup, false setelah selesai cek auth
  String? _errorMessage;
  bool _hasCleanedMenu = false; // Menghindari pembersihan berulang dalam satu sesi
  bool _hasMigratedOrders = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Notification Settings
  bool _appNotifications = true;
  bool _emailAlerts = false;
  bool _specialOffers = true;

  bool get appNotifications => _appNotifications;
  bool get emailAlerts => _emailAlerts;
  bool get specialOffers => _specialOffers;

  String _selectedLanguage = 'id';
  String get selectedLanguage => _selectedLanguage;

  void setLanguage(String lang) {
    _selectedLanguage = lang;
    notifyListeners();
  }

  void toggleNotifications(String type) {
    if (type == 'app') _appNotifications = !_appNotifications;
    if (type == 'email') _emailAlerts = !_emailAlerts;
    if (type == 'offers') _specialOffers = !_specialOffers;
    notifyListeners();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _supabase = Supabase.instance.client;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  AuthViewModel() {
    _initAuth();
  }

  /// Inisialisasi auth saat app pertama kali dibuka.
  /// Gunakan cache Firestore (source: cache) agar startup instan,
  /// lalu sync dengan server di latar belakang.
  Future<void> _initAuth() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      // Tidak ada sesi yang tersimpan, langsung ke halaman login
      _isInitializing = false;
      notifyListeners();
      return;
    }

    debugPrint('AuthViewModel._initAuth: User sudah login: ${firebaseUser.uid}');

    try {
      // ── Fast path: cari dokumen berdasarkan uid (field yang kita simpan) ──
      final String docId = await _resolveDocId(firebaseUser.uid, firebaseUser.email);
      if (docId.isNotEmpty) {
        // Muat data dari cache Firestore dulu (instan, tanpa tunggu network)
        try {
          final cachedDoc = await _firestore
              .collection('users')
              .doc(docId)
              .get(const GetOptions(source: Source.cache));
          if (cachedDoc.exists) {
            _currentUser = UserModel.fromFirestore(cachedDoc.data()!, docId);
            _isInitializing = false;
            notifyListeners();
            debugPrint('AuthViewModel._initAuth: Loaded from CACHE, doc: $docId');
          }
        } catch (_) {
          // Cache miss — lanjut ambil dari server
        }

        // Start realtime listener (ini juga akan update data dari server)
        _startUserListener(docId);
      }
    } catch (e) {
      debugPrint('AuthViewModel._initAuth: Error: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Cari docId di Firestore berdasarkan Firebase Auth UID.
  /// Fast path: query by 'uid' field.
  /// Fallback: query by 'email' (untuk akun lama yang belum punya field uid).
  Future<String> _resolveDocId(String uid, String? email) async {
    // ── Fast path: uid field ──
    try {
      final snap = await _firestore
          .collection('users')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 8));
      if (snap.docs.isNotEmpty) {
        debugPrint('AuthViewModel._resolveDocId: Found by uid → ${snap.docs.first.id}');

        // Jika ada dokumen yang belum punya uid tersimpan, update
        final data = snap.docs.first.data();
        if ((data['uid'] as String?)?.isEmpty ?? true) {
          _firestore.collection('users').doc(snap.docs.first.id).update({'uid': uid});
        }
        return snap.docs.first.id;
      }
    } catch (e) {
      debugPrint('AuthViewModel._resolveDocId: uid query failed: $e');
    }

    // ── Fallback: email field ──
    if (email != null && email.isNotEmpty) {
      try {
        final snap = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 10));
        if (snap.docs.isNotEmpty) {
          final docId = snap.docs.first.id;
          debugPrint('AuthViewModel._resolveDocId: Found by email → $docId. Backfilling uid...');
          // Backfill uid field agar next login bisa pakai fast path
          _firestore.collection('users').doc(docId).update({'uid': uid}).catchError(
            (e) => debugPrint('Backfill uid failed: $e'),
          );
          return docId;
        }
      } catch (e) {
        debugPrint('AuthViewModel._resolveDocId: email query failed: $e');
      }
    }

    return '';
  }

  void _startUserListener(String docId) {
    _userSubscription?.cancel();
    _userSubscription = _firestore
        .collection('users')
        .doc(docId)
        .snapshots()
        .listen(
      (doc) {
        if (doc.exists) {
          _currentUser = UserModel.fromFirestore(doc.data()!, docId);
          _isInitializing = false;
          notifyListeners();
          debugPrint('AuthViewModel._startUserListener: Realtime update received for $docId');

          // Hapus field translation lama di collection 'menu' secara otomatis jika login sebagai admin/owner
          if (!_hasCleanedMenu && (_currentUser!.role == 'admin' || _currentUser!.role == 'owner')) {
            _hasCleanedMenu = true;
            _cleanMenuTranslationFields();
            _migrateExistingOrdersToCustomIds();
          }
        }
      },
      onError: (e) => debugPrint('AuthViewModel._startUserListener: Error: $e'),
    );
  }

  /// Membersihkan field translation lama (name_id, name_en, dll) dari collection 'menu' jika masih ada.
  Future<void> _cleanMenuTranslationFields() async {
    try {
      debugPrint('AuthViewModel._cleanMenuTranslationFields: Checking legacy translation fields in menu...');
      final snapshot = await _firestore.collection('menu').get().timeout(const Duration(seconds: 10));
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final updates = <String, dynamic>{};
        if (data.containsKey('name_id')) updates['name_id'] = FieldValue.delete();
        if (data.containsKey('name_en')) updates['name_en'] = FieldValue.delete();
        if (data.containsKey('description_id')) updates['description_id'] = FieldValue.delete();
        if (data.containsKey('description_en')) updates['description_en'] = FieldValue.delete();

        // ── Perbaikan Mismatch Resep Telur (1.0 kg -> 0.06 kg) ──
        if (data.containsKey('resep') && data['resep'] is List) {
          final List<dynamic> currentRecipe = data['resep'] as List;
          bool needsUpdate = false;
          final List<Map<String, dynamic>> updatedRecipe = [];
          
          for (var r in currentRecipe) {
            if (r is Map) {
              final Map<String, dynamic> rMap = Map<String, dynamic>.from(r);
              final String name = rMap['nama_bahan'] ?? rMap['ingredientName'] ?? '';
              final double qty = (rMap['jumlah_per_porsi'] ?? rMap['quantityPerPortion'] ?? 0.0).toDouble();
              
              if (name.toLowerCase() == 'telur' && (qty == 1.0 || qty == 1)) {
                rMap['jumlah_per_porsi'] = 0.06;
                needsUpdate = true;
              }
              updatedRecipe.add(rMap);
            }
          }
          if (needsUpdate) {
            updates['resep'] = updatedRecipe;
          }
        }

        if (updates.isNotEmpty) {
          await _firestore.collection('menu').doc(doc.id).update(updates);
          debugPrint('AuthViewModel._cleanMenuTranslationFields: Cleared legacy translation fields / updated egg quantity for menu item: ${doc.id}');
        }
      }
    } catch (e) {
      debugPrint('AuthViewModel._cleanMenuTranslationFields: Error: $e');
    }
  }

  /// Hitung User ID berikutnya (User_01, User_02, ...).
  Future<String> _getNextUserId() async {
    debugPrint('AuthViewModel._getNextUserId: Querying highest User_XX ID');
    try {
      final snapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: 'User_')
          .where(FieldPath.documentId, isLessThanOrEqualTo: 'User_\uf8ff')
          .orderBy(FieldPath.documentId, descending: true)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));

      int maxNumber = 0;
      if (snapshot.docs.isNotEmpty) {
        final highestId = snapshot.docs.first.id;
        debugPrint('AuthViewModel._getNextUserId: Highest User ID found: $highestId');
        final match = RegExp(r'^User_(\d+)$').firstMatch(highestId);
        if (match != null) {
          maxNumber = int.tryParse(match.group(1) ?? '0') ?? 0;
        }
      }
      final nextDocId = 'User_${(maxNumber + 1).toString().padLeft(2, '0')}';
      debugPrint('AuthViewModel._getNextUserId: Next ID → $nextDocId');
      return nextDocId;
    } catch (e) {
      debugPrint('AuthViewModel._getNextUserId: Error: $e. Falling back to fetching all docs.');
      // Fallback: fetch all if range query fails
      final snapshot = await _firestore
          .collection('users')
          .get()
          .timeout(const Duration(seconds: 10));

      int maxNumber = 0;
      final regex = RegExp(r'^User_(\d+)$');
      for (var doc in snapshot.docs) {
        final match = regex.firstMatch(doc.id);
        if (match != null) {
          final numVal = int.tryParse(match.group(1) ?? '0') ?? 0;
          if (numVal > maxNumber) maxNumber = numVal;
        }
      }
      final nextDocId = 'User_${(maxNumber + 1).toString().padLeft(2, '0')}';
      debugPrint('AuthViewModel._getNextUserId: Fallback Next ID → $nextDocId');
      return nextDocId;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOGIN
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> login(String email, String password, [String? selectedPortal]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    debugPrint('AuthViewModel.login: Starting login for $email');

    try {
      // 1. Firebase Auth Sign In
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final uid = userCredential.user!.uid;
      debugPrint('AuthViewModel.login: Firebase Auth OK, uid=$uid');

      // 2. Resolve Firestore document (fast via uid, fallback via email)
      final docId = await _resolveDocId(uid, email.trim());
      if (docId.isEmpty) {
        await _auth.signOut();
        throw 'Data profil tidak ditemukan di database.';
      }

      // 3. Fetch user document (get dari server untuk data terbaru)
      final userDoc = await _firestore
          .collection('users')
          .doc(docId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!userDoc.exists) {
        await _auth.signOut();
        throw 'Dokumen profil tidak ditemukan.';
      }

      final userData = userDoc.data()!;
      final actualRole = (userData['role'] as String? ?? 'pelanggan').toLowerCase();
      debugPrint('AuthViewModel.login: role=$actualRole, docId=$docId');

      // 4. Validasi portal/role (opsional)
      if (selectedPortal != null) {
        String mappedPortal = selectedPortal.toLowerCase();
        if (mappedPortal == 'customer') mappedPortal = 'pelanggan';
        if (actualRole != mappedPortal) {
          await _auth.signOut();
          throw 'Gagal: Akun anda terdaftar sebagai $actualRole, bukan $selectedPortal.';
        }
      }

      // 5. Set user & mulai realtime listener
      _currentUser = UserModel.fromFirestore(userData, docId);
      _startUserListener(docId);

      _isLoading = false;
      notifyListeners();
      debugPrint('AuthViewModel.login: Selesai — login berhasil.');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthViewModel.login: FirebaseAuthException: ${e.code}');
      _errorMessage = _getAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('AuthViewModel.login: Error: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // REGISTER
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    debugPrint('AuthViewModel.register: Starting registration for $email, role=$role');

    try {
      // 1. Buat akun di Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final uid = userCredential.user!.uid;
      debugPrint('AuthViewModel.register: Firebase Auth user created, uid=$uid');

      String mappedRole = role.toLowerCase();
      if (mappedRole == 'customer') mappedRole = 'pelanggan';

      // 2. Generate User_XX doc ID
      final nextDocId = await _getNextUserId();
      debugPrint('AuthViewModel.register: Generated doc ID: $nextDocId');

      // 3. Simpan ke Firestore — SERTAKAN uid untuk fast login di masa depan
      final userModel = UserModel(
        id: nextDocId,
        uid: uid,        // ← Kunci utama perbaikan ini
        name: name,
        email: email.trim(),
        role: mappedRole,
        phone: phone,
      );

      await _firestore
          .collection('users')
          .doc(nextDocId)
          .set(userModel.toFirestore())
          .timeout(const Duration(seconds: 10));
      debugPrint('AuthViewModel.register: User document saved: $nextDocId');

      // 4. Sign out — biarkan user login manual setelah register
      await _auth.signOut().timeout(const Duration(seconds: 5));

      _isLoading = false;
      notifyListeners();
      debugPrint('AuthViewModel.register: Registration completed.');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthViewModel.register: FirebaseAuthException: ${e.code}');
      // Clean up Auth user jika sudah dibuat tapi step berikutnya gagal
      try {
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          await currentUser.delete();
          debugPrint('AuthViewModel.register: Cleaned up Auth user on FirebaseAuthException');
        }
      } catch (_) {}

      _errorMessage = _getAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('AuthViewModel.register: Error: $e');
      // Clean up Auth user jika sudah dibuat tapi step berikutnya gagal
      try {
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          await currentUser.delete();
          debugPrint('AuthViewModel.register: Cleaned up Auth user on general exception');
        }
      } catch (_) {}

      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PROFILE
  // ─────────────────────────────────────────────────────────────────────────

  Future<String?> uploadAvatar(File file) async {
    try {
      if (_currentUser == null) return null;
      final String fileName = '${_currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = 'profile_pics/$fileName';
      await _supabase.storage.from('avatars').upload(
        filePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );
      return _supabase.storage.from('avatars').getPublicUrl(filePath);
    } catch (e) {
      debugPrint('AuthViewModel.uploadAvatar: Error: $e');
      return null;
    }
  }

  Future<bool> saveProfilePersistently({
    String? name,
    String? phone,
    File? imageFile,
  }) async {
    if (_currentUser == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? imageUrl = _currentUser!.profilePic;
      if (imageFile != null) {
        final uploadedUrl = await uploadAvatar(imageFile);
        if (uploadedUrl != null) imageUrl = uploadedUrl;
      }

      final updatedData = {
        'nama': name ?? _currentUser!.name,
        'hp': phone ?? _currentUser!.phone,
        'avatar_url': imageUrl,
      };

      await _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .update(updatedData);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menyimpan profil: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void updateAvatar(String? path) {
    if (_currentUser == null) return;
    _currentUser = UserModel(
      id: _currentUser!.id,
      uid: _currentUser!.uid,
      name: _currentUser!.name,
      email: _currentUser!.email,
      role: _currentUser!.role,
      profilePic: path,
      phone: _currentUser!.phone,
    );
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CHANGE PASSWORD
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) throw 'User tidak ditemukan.';
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword.trim(),
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword.trim());
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────────────────────────────────

  void logout() async {
    await _userSubscription?.cancel();
    _userSubscription = null;
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MIGRATION (manual, tidak otomatis dijalankan)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> runUserMigration() async {
    debugPrint('AuthViewModel.runUserMigration: Starting...');
    try {
      final usersSnapshot = await _firestore
          .collection('users')
          .get()
          .timeout(const Duration(seconds: 15));
      final regex = RegExp(r'^User_\d+$');
      int maxNumber = 0;
      final uidMap = <String, String>{};

      for (var doc in usersSnapshot.docs) {
        final match = RegExp(r'^User_(\d+)$').firstMatch(doc.id);
        if (match != null) {
          final numVal = int.tryParse(match.group(1) ?? '0') ?? 0;
          if (numVal > maxNumber) maxNumber = numVal;
        }
      }

      for (var doc in usersSnapshot.docs) {
        if (regex.hasMatch(doc.id)) {
          uidMap[doc.id] = doc.id;
        } else {
          maxNumber++;
          final nextDocId = 'User_${maxNumber.toString().padLeft(2, '0')}';
          final data = doc.data();
          await _firestore.collection('users').doc(nextDocId).set(data)
              .timeout(const Duration(seconds: 5));
          await _firestore.collection('users').doc(doc.id).delete()
              .timeout(const Duration(seconds: 5));
          uidMap[doc.id] = nextDocId;
          debugPrint('Migration: ${doc.id} → $nextDocId');
        }
      }
    } catch (e) {
      debugPrint('AuthViewModel.runUserMigration: Error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
      case 'invalid-email':
        return 'Email Anda Salah';
      case 'wrong-password':
        return 'Harap Memasuki Password Yang Benar';
      case 'invalid-credential':
        return 'Harap Mengecek Kembali Email/Password Yang Anda Masukan';
      case 'email-already-in-use':
        return 'Email sudah digunakan oleh akun lain.';
      case 'weak-password':
        return 'Password terlalu lemah (min. 6 karakter).';
      default:
        return 'Harap Mengecek Kembali Email/Password Yang Anda Masukan';
    }
  }

  Future<void> _migrateExistingOrdersToCustomIds() async {
    if (_hasMigratedOrders) return;
    _hasMigratedOrders = true;

    try {
      debugPrint('AuthViewModel._migrateExistingOrdersToCustomIds: Fetching orders for ID migration...');
      final ordersSnapshot = await _firestore.collection('orders').get().timeout(const Duration(seconds: 15));
      
      final userCache = <String, String>{};

      for (var doc in ordersSnapshot.docs) {
        final orderId = doc.id;
        
        final isCustomId = RegExp(r'^\d{2}_\d{2}_\d{4}_').hasMatch(orderId);
        if (isCustomId) {
          continue;
        }

        final data = doc.data();
        final timestamp = (data['waktu_pesan'] as Timestamp?)?.toDate() ?? DateTime.now();
        final userId = data['id_user'] as String? ?? 'guest';

        String customerName = 'Pelanggan';
        if (userId != 'guest') {
          if (userCache.containsKey(userId)) {
            customerName = userCache[userId]!;
          } else {
            final userDoc = await _firestore.collection('users').doc(userId).get();
            if (userDoc.exists) {
              final userData = userDoc.data();
              customerName = userData?['nama'] ?? userData?['name'] ?? 'Pelanggan';
            }
            userCache[userId] = customerName;
          }
        }

        final dateStr = DateFormat('dd_MM_yyyy').format(timestamp);
        final cleanName = customerName.replaceAll(RegExp(r'\s+'), '_').replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
        final timeStr = DateFormat('HHmmss').format(timestamp);
        final customId = '${dateStr}_${cleanName}_$timeStr';

        if (customId != orderId) {
          debugPrint('Migrating order document: $orderId ➔ $customId');

          await _firestore.collection('orders').doc(customId).set(data);

          final detailsSnapshot = await _firestore
              .collection('detail')
              .where('id_order', isEqualTo: orderId)
              .get();

          for (var detailDoc in detailsSnapshot.docs) {
            await _firestore.collection('detail').doc(detailDoc.id).update({
              'id_order': customId,
            });
          }

          await _firestore.collection('orders').doc(orderId).delete();
          debugPrint('Finished migrating order: $orderId ➔ $customId');
        }
      }
      debugPrint('AuthViewModel._migrateExistingOrdersToCustomIds: All legacy order IDs migrated successfully!');
    } catch (e) {
      debugPrint('AuthViewModel._migrateExistingOrdersToCustomIds: Error during order ID migration: $e');
    }
  }
}

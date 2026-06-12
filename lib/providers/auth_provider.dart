import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../services/app_log.dart';
import '../services/customer_display_service.dart';
import '../services/printer_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _user;
  String? _userName;
  String? _userRole;
  String? _displayName;
  String? _storeName;
  String? _ipName;
  String? _address;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  String? get uid => _user?.uid;
  String? get userRole => _userRole;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Кассир: приоритет — displayName из профиля, запасной — email-префикс
  String get displayName =>
      _displayName ?? _userName ?? _user?.email?.split('@').first ?? 'Кассир';
  String get userName => displayName;

  // Название магазина из профиля
  String get storeName => _storeName ?? 'МОЙ МАГАЗИН';
  String get ipName => _ipName ?? '';
  String get address => _address ?? '';

  AuthProvider() {
    _auth.authStateChanges().listen((user) {
      _user = user;
      if (user != null) {
        _loadUserProfile(user.uid);
      } else {
        _userName = null;
        _userRole = null;
        _displayName = null;
        _storeName = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      appLog('Профиль: запрос users/$uid (первый вызов Firestore)');
      // Читаем роль из корневого документа users/{uid}
      final doc = await _db.collection('users').doc(uid).get();
      appLog('Профиль: users/$uid получен');
      if (doc.exists) {
        _userName = doc.data()?['name'] as String?;
        _userRole = doc.data()?['role'] as String?;
      }
      // Читаем профиль кассира из users/{uid}/profile/info
      final profileDoc = await _db
          .collection('users')
          .doc(uid)
          .collection('profile')
          .doc('info')
          .get();
      appLog('Профиль: profile/info получен');
      if (profileDoc.exists) {
        _displayName = profileDoc.data()?['displayName'] as String?;
        _storeName = profileDoc.data()?['storeName'] as String?;
        _ipName = profileDoc.data()?['ipName'] as String?;
        _address = profileDoc.data()?['address'] as String?;
      }
      // Передаём данные магазина в принтер и на экран покупателя сразу
      // после входа — иначе после перезапуска чеки печатались без
      // ИП/адреса, пока пользователь не пересохранит настройки.
      PrinterService().setShopInfo(
        name: _storeName ?? '',
        ipName: _ipName ?? '',
        address: _address ?? '',
      );
      CustomerDisplayService().setShopName(_storeName ?? '');
      appLog('Профиль: загружен полностью');
    } catch (e) {
      appLog('Профиль: ОШИБКА загрузки: $e');
    }
    notifyListeners();
  }

  Future<void> saveProfile({
    required String displayName,
    required String storeName,
    String ipName = '',
    String address = '',
  }) async {
    if (_user == null) return;
    final uid = _user!.uid;
    await _db
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('info')
        .set({
      'displayName': displayName.trim(),
      'storeName': storeName.trim(),
      'ipName': ipName.trim(),
      'address': address.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _displayName = displayName.trim().isEmpty ? null : displayName.trim();
    _storeName = storeName.trim().isEmpty ? null : storeName.trim();
    _ipName = ipName.trim().isEmpty ? null : ipName.trim();
    _address = address.trim().isEmpty ? null : address.trim();
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'Ошибка входа. Проверьте интернет-соединение.';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _userName = null;
    _userRole = null;
    _displayName = null;
    _storeName = null;
    _ipName = null;
    _address = null;
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'invalid-email':
        return 'Неверный формат email';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      case 'user-disabled':
        return 'Пользователь заблокирован';
      case 'invalid-credential':
        return 'Неверный логин или пароль';
      case 'network-request-failed':
        return 'Нет подключения к интернету';
      default:
        return 'Ошибка входа. Попробуйте ещё раз';
    }
  }
}

import 'package:flutter/foundation.dart';
import '../models/sale.dart';
import '../services/firebase_service.dart';

class SalesProvider with ChangeNotifier {
  final FirebaseService _service = FirebaseService();

  List<Sale> _sales = [];
  bool _isLoading = false;
  String? _error;
  String? _uid;

  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  List<Sale> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get uid => _uid;
  DateTime get fromDate => _fromDate;
  DateTime get toDate => _toDate;

  // Нақты сатылымдар (қайтарымдар алынып тасталған)
  List<Sale> get actualSales => _sales.where((s) => !s.isReturn).toList();
  List<Sale> get returnSales => _sales.where((s) => s.isReturn).toList();

  double get totalRevenue => _sales.fold(0, (sum, s) => sum + s.total);
  int get totalTransactions => actualSales.length;
  // Орташа чек — таза айналымнан (возвраттар шегерілген): барлығы
  // қайтарылса 0 болады. Возврат сатудан көп болса (кешегі чек бүгін
  // қайтарылса) теріс шықпауы үшін 0-ге шектейміз.
  double get averageCheck => actualSales.isEmpty
      ? 0
      : (totalRevenue / actualSales.length).clamp(0, double.infinity);
  double get cashRevenue => _sales.fold(0, (sum, s) {
        if (s.paymentMethod == PaymentMethod.cash) return sum + s.total;
        if (s.paymentMethod == PaymentMethod.combined) {
          return sum + (s.cashAmount ?? 0);
        }
        return sum;
      });
  double get cardRevenue => _sales.fold(0, (sum, s) {
        if (s.paymentMethod == PaymentMethod.card) return sum + s.total;
        if (s.paymentMethod == PaymentMethod.combined) {
          return sum + (s.cardAmount ?? 0);
        }
        return sum;
      });
  int get cashCount =>
      actualSales.where((s) => s.paymentMethod == PaymentMethod.cash).length;
  int get cardCount =>
      actualSales.where((s) => s.paymentMethod == PaymentMethod.card).length;
  int get combinedCount =>
      actualSales.where((s) => s.paymentMethod == PaymentMethod.combined).length;

  void setUid(String uid) {
    _uid = uid;
    loadToday();
  }

  void clear() {
    _uid = null;
    _sales = [];
    _error = null;
    notifyListeners();
  }

  void loadToday() {
    _fromDate = DateTime.now();
    _toDate = DateTime.now();
    _loadSales();
  }

  void loadThisMonth() {
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = now;
    _loadSales();
  }

  void loadYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    _fromDate = yesterday;
    _toDate = yesterday;
    _loadSales();
  }

  void loadThisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    _fromDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    _toDate = now;
    _loadSales();
  }

  void loadDateRange(DateTime from, DateTime to) {
    _fromDate = from;
    _toDate = to;
    _loadSales();
  }

  Future<void> _loadSales() async {
    if (_uid == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sales =
          await _service.getSalesByDateRangeOnce(_uid!, _fromDate, _toDate);
      _isLoading = false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<Sale> saveSale(Sale sale, {required String uid}) async {
    return await _service.saveSale(sale, uid: uid);
  }

  Future<Sale?> findSaleByReceiptNumber(int receiptNumber) async {
    if (_uid == null) return null;
    return await _service.getSaleByReceiptNumber(_uid!, receiptNumber);
  }

  // true — по чеку уже был оформлен возврат (флаг или старый возврат по ссылке)
  Future<bool> isSaleAlreadyReturned(Sale sale) async {
    if (sale.isReturned) return true;
    if (_uid == null) return false;
    return await _service.hasReturnForSale(_uid!, sale.id);
  }

  Future<void> processReturn({
    required Sale originalSale,
    required List<SaleItem> itemsToReturn,
    required String? cashierName,
  }) async {
    if (_uid == null) return;

    // Защита от повторного возврата (в т.ч. если чек нашли до оформления
    // возврата с другой кассы)
    if (await isSaleAlreadyReturned(originalSale)) {
      throw Exception('По этому чеку уже оформлен возврат');
    }

    final returnTotal = itemsToReturn.fold(0.0, (sum, item) => sum + item.total);

    // Для комбинированной оплаты распределяем возврат пропорционально
    // нал/карта долям оригинала — иначе общая выручка уменьшается,
    // а разбивка нал/карта остаётся прежней и цифры расходятся.
    double? returnCashAmount;
    double? returnCardAmount;
    if (originalSale.paymentMethod == PaymentMethod.combined &&
        originalSale.total > 0) {
      final ratio = returnTotal / originalSale.total;
      returnCashAmount = -((originalSale.cashAmount ?? 0) * ratio);
      returnCardAmount = -((originalSale.cardAmount ?? 0) * ratio);
    }

    final returnSale = Sale(
      id: '',
      items: itemsToReturn,
      total: -returnTotal,
      paymentMethod: originalSale.paymentMethod,
      amountPaid: 0,
      change: 0,
      createdAt: DateTime.now(),
      cashierName: cashierName,
      receiptNumber: 0,
      isReturn: true,
      originalSaleId: originalSale.id,
      userId: _uid,
      cashAmount: returnCashAmount,
      cardAmount: returnCardAmount,
    );
    await _service.saveSale(returnSale, uid: _uid!);
    await _service.markSaleReturned(_uid!, originalSale.id);
    await _loadSales();
  }

  // Revenue grouped by day of month (for chart)
  Map<int, double> get revenueByDay {
    final result = <int, double>{};
    for (final sale in _sales) {
      final day = sale.createdAt.day;
      result[day] = (result[day] ?? 0) + sale.total;
    }
    return result;
  }

  // Revenue grouped by hour (for chart)
  Map<int, double> get revenueByHour {
    final result = <int, double>{};
    for (int i = 0; i < 24; i++) {
      result[i] = 0;
    }
    for (final sale in _sales) {
      final hour = sale.createdAt.hour;
      result[hour] = (result[hour] ?? 0) + sale.total;
    }
    return result;
  }
}

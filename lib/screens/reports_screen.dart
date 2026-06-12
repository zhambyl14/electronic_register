import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sale.dart';
import '../providers/auth_provider.dart';
import '../providers/sales_provider.dart';
import '../services/export_service.dart';
import '../services/printer_service.dart';
import '../utils/money.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _activePeriod = 0; // 0=Бүгін 1=Кеше 2=Апта 3=Ай 4=Диапазон
  int _activePayment = 0; // 0=Барлығы 1=Нал 2=Карта
  bool _chartByHour = false;
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  bool _isExporting = false;
  String _searchReceipt = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildFilters(),
                const SizedBox(height: 14),
                _buildStatCards(),
                const SizedBox(height: 14),
                _buildChart(),
                const SizedBox(height: 14),
                _buildTransactionTable(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          const Text(
            'Отчёты',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2332),
            ),
          ),
          const Spacer(),
          Consumer<SalesProvider>(
            builder: (context, provider, _) => ElevatedButton.icon(
              onPressed:
                  provider.sales.isEmpty ? null : () => _printReport(provider),
              icon: const Icon(Icons.print, size: 15),
              label: const Text('Печать'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Consumer<SalesProvider>(
            builder: (context, provider, _) => ElevatedButton.icon(
              onPressed:
                  (_isExporting || provider.sales.isEmpty) ? null : _export,
              icon: _isExporting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download, size: 15),
              label: const Text('Скачать PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final provider = context.read<SalesProvider>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period row
          Row(
            children: [
              const SizedBox(
                width: 70,
                child: Text('Период:',
                    style:
                        TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
              ),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _FilterChip(
                      label: 'Сегодня',
                      isActive: _activePeriod == 0,
                      onTap: () {
                        setState(() => _activePeriod = 0);
                        provider.loadToday();
                      },
                    ),
                    _FilterChip(
                      label: 'Вчера',
                      isActive: _activePeriod == 1,
                      onTap: () {
                        setState(() => _activePeriod = 1);
                        provider.loadYesterday();
                      },
                    ),
                    _FilterChip(
                      label: 'Неделя',
                      isActive: _activePeriod == 2,
                      onTap: () {
                        setState(() => _activePeriod = 2);
                        provider.loadThisWeek();
                      },
                    ),
                    _FilterChip(
                      label: 'Месяц',
                      isActive: _activePeriod == 3,
                      onTap: () {
                        setState(() => _activePeriod = 3);
                        provider.loadThisMonth();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF0F2F5)),
          const SizedBox(height: 10),

          // Date range row
          Row(
            children: [
              const SizedBox(
                width: 70,
                child: Text('Диапазон:',
                    style:
                        TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
              ),
              _DateButton(
                  date: _fromDate,
                  onPicked: (d) => setState(() => _fromDate = d)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('—',
                    style: TextStyle(color: Color(0xFF9CA3AF))),
              ),
              _DateButton(
                  date: _toDate,
                  onPicked: (d) => setState(() => _toDate = d)),
              const SizedBox(width: 10),
              _FilterChip(
                label: 'Применить',
                isActive: _activePeriod == 4,
                onTap: () {
                  setState(() => _activePeriod = 4);
                  provider.loadDateRange(_fromDate, _toDate);
                },
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF0F2F5)),
          const SizedBox(height: 10),

          // Payment filter row
          Row(
            children: [
              const SizedBox(
                width: 70,
                child: Text('Оплата:',
                    style:
                        TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
              ),
              _FilterChip(
                label: 'Все',
                isActive: _activePayment == 0,
                onTap: () => setState(() => _activePayment = 0),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Наличные',
                isActive: _activePayment == 1,
                onTap: () => setState(() => _activePayment = 1),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Карта',
                isActive: _activePayment == 2,
                onTap: () => setState(() => _activePayment = 2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return Consumer<SalesProvider>(
      builder: (context, p, _) {
        if (p.isLoading) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator()));
        }

        final hasReturns = p.returnSales.isNotEmpty;
        final returnAmount = p.returnSales
            .fold(0.0, (sum, s) => sum + s.total.abs());

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.receipt_long,
                    iconColor: const Color(0xFF4A9EFF),
                    value: p.totalTransactions.toString(),
                    label: 'Чеков',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    icon: Icons.payments_outlined,
                    iconColor: const Color(0xFF10B981),
                    value: '${formatMoney(p.totalRevenue)} ₸',
                    label: 'Выручка',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    icon: Icons.trending_up,
                    iconColor: const Color(0xFFF59E0B),
                    value: '${formatMoney(p.averageCheck)} ₸',
                    label: 'Средний чек',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: const Color(0xFF8B5CF6),
                    value:
                        '${formatMoney(p.cashRevenue)} / ${formatMoney(p.cardRevenue)} ₸',
                    label: 'Нал / Карта',
                  ),
                ),
              ],
            ),
            if (hasReturns) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.assignment_return,
                        color: Color(0xFFEF4444), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Возвраты: ${p.returnSales.length} шт — ${formatMoney(returnAmount)} ₸ (учтено в выручке)',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFDC2626)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildChart() {
    return Consumer<SalesProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading || provider.sales.isEmpty) {
          return const SizedBox.shrink();
        }

        final data =
            _chartByHour ? provider.revenueByHour : provider.revenueByDay;

        if (data.isEmpty || data.values.every((v) => v == 0)) {
          return const SizedBox.shrink();
        }

        final sortedKeys = data.keys.toList()..sort();
        final maxVal = data.values.fold(0.0, (a, b) => a > b ? a : b);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('График продаж',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A2332))),
                  const Spacer(),
                  _FilterChip(
                    label: 'По дням',
                    isActive: !_chartByHour,
                    onTap: () => setState(() => _chartByHour = false),
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: 'По часам',
                    isActive: _chartByHour,
                    onTap: () => setState(() => _chartByHour = true),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxVal * 1.2,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final key = sortedKeys[group.x.toInt()];
                          final label = _chartByHour
                              ? '${key.toString().padLeft(2, '0')}:00'
                              : '$key';
                          return BarTooltipItem(
                            '$label\n${formatMoney(rod.toY)} ₸',
                            const TextStyle(
                                color: Colors.white, fontSize: 11),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            final idx = val.toInt();
                            if (idx >= sortedKeys.length) {
                              return const SizedBox.shrink();
                            }
                            final key = sortedKeys[idx];
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _chartByHour
                                    ? '${key.toString().padLeft(2, '0')}h'
                                    : '$key',
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF9CA3AF)),
                              ),
                            );
                          },
                          reservedSize: 22,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                          getTitlesWidget: (val, meta) {
                            if (val == 0) return const SizedBox.shrink();
                            return Text(
                              _formatK(val),
                              style: const TextStyle(
                                  fontSize: 9, color: Color(0xFF9CA3AF)),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(
                      show: true,
                      drawVerticalLine: false,
                    ),
                    barGroups: List.generate(
                      sortedKeys.length,
                      (i) => BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: data[sortedKeys[i]] ?? 0,
                            color: const Color(0xFF4A9EFF),
                            width: _chartByHour ? 8 : 14,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatK(double val) {
    if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(1)}M';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(0)}K';
    return val.toStringAsFixed(0);
  }

  Widget _buildTransactionTable() {
    return Consumer<SalesProvider>(
      builder: (context, provider, _) {
        var sales = provider.sales;

        if (_activePayment == 1) {
          sales = sales
              .where((s) => s.paymentMethod == PaymentMethod.cash)
              .toList();
        } else if (_activePayment == 2) {
          sales = sales
              .where((s) => s.paymentMethod == PaymentMethod.card)
              .toList();
        }

        if (_searchReceipt.isNotEmpty) {
          sales = sales
              .where((s) => s.receiptNumber
                  .toString()
                  .padLeft(4, '0')
                  .contains(_searchReceipt))
              .toList();
        }

        return Container(
          decoration: _cardDecoration(),
          child: Column(
            children: [
              // Toolbar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  children: [
                    const Text('Продажи',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A2332))),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${sales.length}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280))),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 200,
                      height: 36,
                      child: TextField(
                        onChanged: (v) =>
                            setState(() => _searchReceipt = v),
                        decoration: const InputDecoration(
                          hintText: 'Поиск по чеку №',
                          hintStyle: TextStyle(fontSize: 12),
                          prefixIcon: Icon(Icons.search,
                              size: 16, color: Color(0xFFADB5BD)),
                          isDense: true,
                          filled: true,
                          fillColor: Color(0xFFF5F7FA),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius:
                                BorderRadius.all(Radius.circular(8)),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (sales.isEmpty && !provider.isLoading)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      _searchReceipt.isEmpty
                          ? 'Продаж за выбранный период нет'
                          : 'Чеков по запросу не найдено',
                      style:
                          const TextStyle(color: Color(0xFF9CA3AF)),
                    ),
                  ),
                )
              else ...[
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(
                      top: BorderSide(color: Color(0xFFF0F2F5)),
                      bottom: BorderSide(color: Color(0xFFF0F2F5)),
                    ),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                          width: 80,
                          child: Text('Время',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9CA3AF)))),
                      SizedBox(
                          width: 90,
                          child: Text('Чек №',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9CA3AF)))),
                      Expanded(
                          child: Text('Товары',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9CA3AF)))),
                      SizedBox(
                          width: 120,
                          child: Text('Сумма',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9CA3AF)))),
                      SizedBox(
                          width: 110,
                          child: Text('Оплата',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9CA3AF)))),
                      SizedBox(width: 50),
                    ],
                  ),
                ),

                ...sales.asMap().entries.map(
                    (entry) => _buildSaleRow(entry.value, entry.key)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSaleRow(Sale sale, int index) {
    final timeStr = DateFormat('HH:mm').format(sale.createdAt);
    final isReturn = sale.isReturn;
    final productNames = sale.items.map((i) => i.productName).join(', ');
    final isEven = index.isEven;

    Color badgeBg;
    Color badgeFg;
    String badgeLabel;
    switch (sale.paymentMethod) {
      case PaymentMethod.cash:
        badgeBg = const Color(0xFFDBEAFE);
        badgeFg = const Color(0xFF1D4ED8);
        badgeLabel = 'Наличные';
        break;
      case PaymentMethod.card:
        badgeBg = const Color(0xFFFEF3C7);
        badgeFg = const Color(0xFF92400E);
        badgeLabel = 'Карта';
        break;
      case PaymentMethod.combined:
        badgeBg = const Color(0xFFEDE9FE);
        badgeFg = const Color(0xFF5B21B6);
        badgeLabel = 'Нал+Карта';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isReturn
            ? const Color(0xFFFFF5F5)
            : (isEven ? Colors.white : const Color(0xFFFAFBFC)),
        border: const Border(bottom: BorderSide(color: Color(0xFFF0F2F5))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(timeStr,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF6B7280))),
          ),
          SizedBox(
            width: 90,
            child: Row(
              children: [
                if (isReturn)
                  const Icon(Icons.assignment_return,
                      size: 12, color: Color(0xFFEF4444)),
                if (isReturn) const SizedBox(width: 3),
                Text(
                  isReturn
                      ? 'Возврат'
                      : '#${sale.receiptNumber.toString().padLeft(4, '0')}',
                  style: TextStyle(
                      fontSize: 12,
                      color: isReturn
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF1A2332),
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(productNames,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF1A2332)),
                overflow: TextOverflow.ellipsis),
          ),
          SizedBox(
            width: 120,
            child: Text(
              '${formatMoney(sale.total)} ₸',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isReturn
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF1A2332)),
            ),
          ),
          SizedBox(
            width: 110,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badgeLabel,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: badgeFg),
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: IconButton(
              icon: const Icon(Icons.visibility_outlined,
                  size: 16, color: Color(0xFF9CA3AF)),
              onPressed: () => _showSaleDetail(sale),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  void _showSaleDetail(Sale sale) {
    final isReturn = sale.isReturn;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          isReturn
              ? 'Возврат (чек #${sale.originalSaleId ?? '?'})'
              : 'Чек #${sale.receiptNumber.toString().padLeft(4, '0')}',
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat('dd.MM.yyyy HH:mm').format(sale.createdAt),
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6B7280))),
              if (isReturn)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('ВОЗВРАТ',
                      style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              const SizedBox(height: 8),
              ...sale.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(child: Text(item.productName)),
                        Text(
                            '${item.quantity.toStringAsFixed(item.unit == 'кг' ? 3 : 0)} ${item.unit} × ${formatMoney(item.price)} ₸ = ${formatMoney(item.total)} ₸',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ИТОГО:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${formatMoney(sale.total)} ₸',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isReturn
                              ? const Color(0xFFEF4444)
                              : null)),
                ],
              ),
              if (!isReturn) ...[
                if (sale.paymentMethod == PaymentMethod.combined) ...[
                  Text(
                      'Наличные: ${formatMoney(sale.cashAmount ?? 0)} ₸',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280))),
                  Text(
                      'Карта: ${formatMoney(sale.cardAmount ?? 0)} ₸',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280))),
                ] else ...[
                  Text('Оплачено: ${formatMoney(sale.amountPaid)} ₸',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280))),
                ],
                Text('Сдача: ${formatMoney(sale.change)} ₸',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
              ],
              Text('Способ оплаты: ${sale.paymentLabel}',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть')),
        ],
      ),
    );
  }

  // Даты активного периода — для шапки отчёта «с … до …»
  (DateTime, DateTime) _currentRange() {
    final now = DateTime.now();
    switch (_activePeriod) {
      case 1: // вчера
        final y = now.subtract(const Duration(days: 1));
        return (
          DateTime(y.year, y.month, y.day),
          DateTime(y.year, y.month, y.day, 23, 59, 59),
        );
      case 2: // неделя (с понедельника)
        final monday = now.subtract(Duration(days: now.weekday - 1));
        return (DateTime(monday.year, monday.month, monday.day), now);
      case 3: // месяц
        return (DateTime(now.year, now.month, 1), now);
      case 4: // выбранный диапазон
        return (_fromDate, _toDate);
      default: // сегодня
        return (DateTime(now.year, now.month, now.day), now);
    }
  }

  Future<void> _printReport(SalesProvider provider) async {
    final auth = context.read<AuthProvider>();
    final (from, to) = _currentRange();
    try {
      await PrinterService().printTurnoverReport(
        from: from,
        to: to,
        cashierName: auth.displayName,
        cash: provider.cashRevenue,
        card: provider.cardRevenue,
        total: provider.totalRevenue,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка печати: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _export() async {
    setState(() => _isExporting = true);
    try {
      final provider = context.read<SalesProvider>();
      await ExportService().exportSalesToPdf(
        provider.sales,
        totalRevenue: provider.totalRevenue,
        cashRevenue: provider.cashRevenue,
        cardRevenue: provider.cardRevenue,
        fromDate: provider.fromDate,
        toDate: provider.toDate,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ошибка экспорта: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      );
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color:
              isActive ? const Color(0xFF2563EB) : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.white : const Color(0xFF4A5568),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onPicked;
  const _DateButton({required this.date, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today,
                size: 12, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 6),
            Text(DateFormat('dd.MM.yyyy').format(date),
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF1A2332))),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  const _StatCard(
      {required this.icon,
      required this.iconColor,
      required this.value,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2332),
              )),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}

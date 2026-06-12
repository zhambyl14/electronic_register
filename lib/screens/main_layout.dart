import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/products_provider.dart';
import '../providers/sales_provider.dart';
import '../services/app_log.dart';
import '../services/local_settings.dart';
import '../services/scale_service.dart';
import 'cashier_screen.dart';
import 'products_screen.dart';
import 'reports_screen.dart';
import 'returns_screen.dart';
import 'settings_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  final ScaleService _scaleService = ScaleService();
  StreamSubscription? _weightSub;

  final List<_NavItem> _navItems = [
    const _NavItem(icon: Icons.point_of_sale, label: 'Касса'),
    const _NavItem(icon: Icons.inventory_2, label: 'Товары'),
    const _NavItem(icon: Icons.bar_chart, label: 'Отчёты'),
    const _NavItem(icon: Icons.assignment_return, label: 'Возврат'),
    const _NavItem(icon: Icons.settings, label: 'Настройки'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initForUser());
    _connectScale();
  }

  void _initForUser() {
    if (!mounted) return;
    final uid = context.read<AuthProvider>().uid;
    if (uid != null) {
      appLog('MainLayout: загрузка товаров и продаж, uid=$uid');
      context.read<ProductsProvider>().loadProducts(uid);
      context.read<SalesProvider>().setUid(uid);
      appLog('MainLayout: запросы данных отправлены');
    }
  }

  Future<void> _connectScale() async {
    // Подключаемся ТОЛЬКО к порту, явно выбранному в настройках весов.
    // Перебор всех портов на другой машине открывает порты чужих устройств
    // (VFD, принтер, внутренние устройства POS) и роняет приложение нативно.
    try {
      final savedPort = LocalSettings().getString('scalePort');
      if (savedPort == null) return;
      appLog('MainLayout: подключение весов к порту $savedPort');
      if (!ScaleService.getAvailablePorts().contains(savedPort)) return;

      final baud = LocalSettings().getInt('scaleBaud') ?? 9600;
      final ok = await _scaleService.connect(savedPort, baudRate: baud);
      appLog('MainLayout: весы ${ok ? 'подключены' : 'не отвечают'}');
      if (ok) {
        if (mounted) {
          context.read<CartProvider>().setScaleConnected(true);
        }
        _weightSub = _scaleService.weightStream.listen((weight) {
          if (mounted) {
            context.read<CartProvider>().updateScaleWeight(weight);
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Выйти из системы'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Выйти', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<CartProvider>().clearAll();
      context.read<ProductsProvider>().clear();
      context.read<SalesProvider>().clear();
      await context.read<AuthProvider>().signOut();
    }
  }

  @override
  void dispose() {
    _weightSub?.cancel();
    _scaleService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                CashierScreen(),
                ProductsScreen(),
                ReportsScreen(),
                ReturnsScreen(),
                SettingsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 224,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F172A), Color(0xFF111C33)],
        ),
      ),
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.point_of_sale,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'iMag Kassa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Nav items
          ...List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            final isActive = _selectedIndex == index;
            return _buildNavItem(
              icon: item.icon,
              label: item.label,
              isActive: isActive,
              onTap: () => setState(() => _selectedIndex = index),
            );
          }),

          const Spacer(),

          // Scale status
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cart.scaleConnected
                              ? const Color(0xFF10B981)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Весы',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            cart.scaleConnected
                                ? 'Подключены'
                                : 'Нет связи',
                            style: TextStyle(
                              color: cart.scaleConnected
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF6B7280),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // User info + logout
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 17),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        auth.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _logout,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.logout,
                            color: Colors.white.withValues(alpha: 0.55),
                            size: 17,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: isActive
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    )
                  : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? Colors.white : const Color(0xFF8B96A5),
                  size: 21,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFF9CA3AF),
                    fontSize: 14.5,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

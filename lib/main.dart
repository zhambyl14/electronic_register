import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/products_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/sales_provider.dart';
import 'screens/main_layout.dart';
import 'screens/login_screen.dart';
import 'services/app_log.dart';
import 'services/customer_display_service.dart';
import 'services/local_settings.dart';
import 'services/printer_service.dart';
import 'services/scale_service.dart';

void _log(String msg) => appLog(msg);

/// Контекст с пакетом корней Mozilla. Сначала пробуем добавить их к
/// системным корням; если BoringSSL ругается на дубликаты — используем
/// только пакет (он полный, системные корни не нужны).
SecurityContext _buildSecurityContext(Uint8List pem) {
  try {
    final ctx = SecurityContext(withTrustedRoots: true);
    ctx.setTrustedCertificatesBytes(pem);
    return ctx;
  } on TlsException {
    final ctx = SecurityContext(withTrustedRoots: false);
    ctx.setTrustedCertificatesBytes(pem);
    return ctx;
  }
}

class _CertHttpOverrides extends HttpOverrides {
  final SecurityContext ctx;
  _CertHttpOverrides(this.ctx);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(ctx);
    // Страховка для картинок: даже при недостроенной цепочке пропускаем
    // ТОЛЬКО хосты Cloudinary, остальные блокируются как обычно.
    client.badCertificateCallback = (cert, host, port) {
      final allow = host == 'cloudinary.com' || host.endsWith('.cloudinary.com');
      appLog('Сертификат $host не прошёл проверку — '
          '${allow ? 'разрешено (изображения)' : 'заблокировано'}');
      return allow;
    };
    return client;
  }
}

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    initAppLog();
    _log('=== ЗАПУСК iMag Kassa ===');

    FlutterError.onError = (details) {
      _log('FlutterError: ${details.exception}\n${details.stack}');
      FlutterError.presentError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      _log('PlatformError: $error\n$stack');
      return true;
    };

    _log('Шаг 1: Flutter инициализирован');

    // На старых Windows (POS-машины без обновлений) хранилище корневых
    // сертификатов устарело: Dart/BoringSSL не строит цепочку до Cloudinary
    // (CERTIFICATE_VERIFY_FAILED) и фото не грузятся. Подключаем свежий
    // пакет корней Mozilla из ресурсов приложения.
    try {
      final pem = await rootBundle.load('assets/certs/cacert.pem');
      HttpOverrides.global =
          _CertHttpOverrides(_buildSecurityContext(pem.buffer.asUint8List()));
      _log('Шаг 1.6: пакет корневых сертификатов подключён');
    } catch (e) {
      _log('Шаг 1.6: ОШИБКА загрузки сертификатов: $e');
    }

    // Локальное состояние Firestore (leveldb + heartbeat) на POS-машинах
    // повреждается и нативно роняет SDK при первом же запросе в следующем
    // запуске (кэш всё равно отключён ниже). Удаляем перед инициализацией.
    // Авторизация хранится отдельно (%APPDATA%\firebase) и не трогается.
    try {
      final base = Platform.environment['LOCALAPPDATA'];
      if (base != null) {
        for (final name in ['firestore', 'firebase-heartbeat']) {
          final dir = Directory('$base\\$name');
          if (dir.existsSync()) {
            dir.deleteSync(recursive: true);
            _log('Шаг 1.5: удалена папка $name');
          }
        }
      }
    } catch (e) {
      _log('Шаг 1.5: не удалось очистить состояние Firestore: $e');
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _log('Шаг 2: Firebase OK');
    } catch (e) {
      _log('Шаг 2: ОШИБКА Firebase: $e');
      debugPrint('Firebase init error: $e');
    }

    // Firebase C++ SDK на Windows нативно падает при первом обращении к
    // Firestore на части POS-машин (leveldb-кэш). Краш происходит после
    // авто-логина при первой загрузке данных и не ловится из Dart, поэтому
    // на Windows отключаем локальный кэш полностью — касса работает онлайн.
    try {
      FirebaseFirestore.instance.settings =
          const Settings(persistenceEnabled: false);
      _log('Шаг 2.1: кэш Firestore отключён (Windows)');
    } catch (e) {
      _log('Шаг 2.1: ОШИБКА настройки Firestore: $e');
    }

    // Диагностика: фиксируем смену состояния авторизации, чтобы по логу
    // было видно, дошло ли приложение до загрузки данных после входа.
    try {
      FirebaseAuth.instance.authStateChanges().listen((user) {
        _log('Auth: состояние изменилось, uid=${user?.uid ?? 'нет'}');
      });
    } catch (_) {}

    try {
      await CustomerDisplayService().start();
      _log('Шаг 3: CustomerDisplay OK');
    } catch (e) {
      _log('Шаг 3: ОШИБКА CustomerDisplay: $e');
    }

    // Восстанавливаем сохранённые COM-порты, но только если такой порт
    // реально есть на этой машине — иначе не трогаем порты вообще.
    try {
      await LocalSettings().load();
      final available = ScaleService.getAvailablePorts();
      final rawPort = LocalSettings().getString('rawPrinterPort');
      if (rawPort != null && available.contains(rawPort)) {
        PrinterService().setRawPrinterPort(rawPort);
      }
      CustomerDisplayService().setVfdProtocol(
          LocalSettings().getString('vfdProtocol') ?? 'epson');
      CustomerDisplayService()
          .setVfdBaud(LocalSettings().getInt('vfdBaud') ?? 9600);
      final vfdPort = LocalSettings().getString('vfdPort');
      if (vfdPort != null && available.contains(vfdPort)) {
        CustomerDisplayService().setVfdPort(vfdPort);
      }
      _log('Шаг 4: Настройки портов OK');
    } catch (e) {
      _log('Шаг 4: ОШИБКА настроек портов: $e');
    }

    _log('Шаг 5: runApp');
    runApp(const MagKassaApp());
  }, (error, stack) {
    _log('НЕПЕРЕХВАЧЕННАЯ ОШИБКА: $error\n$stack');
  });
}

class MagKassaApp extends StatelessWidget {
  const MagKassaApp({super.key});

  // Тема рассчитана на сенсорный моноблок: крупные цели нажатия (48-52px),
  // скруглённые формы, спокойная светлая палитра.
  ThemeData _buildTheme() {
    const seed = Color(0xFF2563EB);
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: 'Segoe UI',
      scaffoldBackgroundColor: const Color(0xFFF3F5F9),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkSparkle.splashFactory,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F9FC),
        hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: seed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: 'Segoe UI',
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          side: const BorderSide(color: Color(0xFFD7DEE8)),
          foregroundColor: const Color(0xFF374151),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Segoe UI',
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: const BorderSide(color: Color(0xFFB9C2CF), width: 1.6),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        insetPadding: const EdgeInsets.all(16),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEDF0F4),
        thickness: 1,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(3),
      ),
      tooltipTheme: const TooltipThemeData(waitDuration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
      ],
      child: MaterialApp(
        title: 'iMag Kassa',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F7FA),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const MainLayout();
        }
        return const LoginScreen();
      },
    );
  }
}

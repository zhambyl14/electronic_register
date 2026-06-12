import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import '../models/cart_item.dart';
import '../utils/money.dart';

class CustomerDisplayService {
  static final CustomerDisplayService _instance =
      CustomerDisplayService._internal();
  factory CustomerDisplayService() => _instance;
  CustomerDisplayService._internal();

  // ── HTTP / Browser mode ────────────────────────────────────────────────────
  HttpServer? _server;
  final List<HttpResponse> _sseClients = [];
  static const int httpPort = 8765;
  String get displayUrl => 'http://localhost:$httpPort';

  // ── VFD Serial mode ────────────────────────────────────────────────────────
  String? _vfdPort;

  // Протокол дисплея: разные модели понимают разные команды.
  //  epson  — ESC/POS, 2x20, кириллица CP866 (по умолчанию)
  //  cd5220 — CD5220/DSP-800 и совместимые, 2x20, CP866
  //  aedex  — AEDEX (однострочные/числовые), только латиница
  //  plain  — просто сумма цифрами + CR (простейшие числовые табло)
  String _vfdProtocol = 'epson';

  // ── Shared state ───────────────────────────────────────────────────────────
  double _total = 0;
  List<CartItem> _items = [];
  String _shopName = 'iMag Kassa';

  // ──────────────────────────────────────────────────────────────────────────

  Future<void> start() async {
    if (_server != null) return;
    try {
      _server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        httpPort,
        shared: true,
      );
      _handleHttp();
    } catch (_) {}
  }

  void setShopName(String name) {
    _shopName = name.isNotEmpty ? name : 'iMag Kassa';
  }

  void setVfdPort(String? port) {
    _vfdPort = port;
    if (port != null) {
      _sendVfd(_items, _total);
    }
  }

  String? get vfdPort => _vfdPort;

  void setVfdProtocol(String protocol) {
    _vfdProtocol = protocol;
    if (_vfdPort != null) {
      _sendVfd(_items, _total);
    }
  }

  String get vfdProtocol => _vfdProtocol;

  // Скорость порта дисплея. Встроенные 8-разрядные LED-табло моноблоков
  // чаще всего работают на 2400 бод, внешние VFD — на 9600.
  int _vfdBaud = 9600;

  void setVfdBaud(int baud) {
    _vfdBaud = baud;
    if (_vfdPort != null) {
      _sendVfd(_items, _total);
    }
  }

  int get vfdBaud => _vfdBaud;

  void updateCart(List<CartItem> items, double total) {
    _items = items;
    _total = total;
    _pushSse();
    _sendVfd(items, total);
  }

  // Call after payment confirmed
  void showPaymentComplete(double total, double change) {
    if (_vfdProtocol == 'plain') {
      _portWrite(Uint8List.fromList('${formatMoney(change)}\r\n'.codeUnits));
    } else if (_vfdProtocol == 'aedex') {
      _writeVfdLines(_center('RAHMET!', 20),
          _center('SDACHA: ${formatMoney(change)}', 20));
    } else {
      final line1 = _center('РАХМЕТ! СПАСИБО!', 20);
      final line2 = _center('Сдача: ${formatMoney(change)} тг', 20);
      _writeVfdLines(line1, line2);
    }

    // Restore normal display after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      _sendVfd(_items, _total);
    });
  }

  // ── VFD helpers ────────────────────────────────────────────────────────────

  void _sendVfd(List<CartItem> items, double total) {
    if (_vfdPort == null) return;

    // Простейшие числовые табло: только сумма цифрами.
    if (_vfdProtocol == 'plain') {
      _portWrite(Uint8List.fromList('${formatMoney(total)}\r\n'.codeUnits));
      return;
    }

    String line1;
    String line2;
    if (_vfdProtocol == 'aedex') {
      // AEDEX-дисплеи не понимают кириллицу — латиница.
      if (items.isEmpty) {
        line1 = _center('KASSA', 20);
        line2 = _center('KOS KELDINIZ!', 20);
      } else {
        line1 = _padRight('TOVAR: ${items.length}', 20);
        line2 = _padRight('ITOGO: ${formatMoney(total)}', 20);
      }
    } else if (items.isEmpty) {
      line1 = _center(_shopName, 20);
      line2 = _center('Добро пожаловать!', 20);
    } else {
      final count = items.length;
      final totalStr = _formatMoney(total);
      line1 = _padRight('Товаров: $count шт.', 20);
      line2 = _padRight('Итого: $totalStr', 20);
    }
    _writeVfdLines(line1, line2);
  }

  void _writeVfdLines(String line1, String line2) {
    if (_vfdPort == null) return;
    final List<int> buf;
    switch (_vfdProtocol) {
      case 'cd5220':
        buf = <int>[
          0x1B, 0x40,            // ESC @ — инициализация
          0x0C,                  // Clear
          0x1B, 0x51, 0x41,      // ESC Q A — запись в верхнюю строку
          ..._cp866(line1),
          0x0D,
          0x1B, 0x51, 0x42,      // ESC Q B — запись в нижнюю строку
          ..._cp866(line2),
          0x0D,
        ];
        break;
      case 'aedex':
        buf = <int>[
          ...'!#1'.codeUnits,    // верхняя строка
          ..._ascii(line1),
          0x0D,
          ...'!#2'.codeUnits,    // нижняя строка (1-строчные игнорируют)
          ..._ascii(line2),
          0x0D,
        ];
        break;
      default: // epson ESC/POS
        buf = <int>[
          0x1B, 0x40,           // ESC @ — инициализация
          0x0C,                 // Clear display
          ..._cp866(line1),     // Строка 1 (20 символов)
          0x0D, 0x0A,           // CRLF → строка 2
          ..._cp866(line2),     // Строка 2 (20 символов)
        ];
    }
    _portWrite(Uint8List.fromList(buf));
  }

  // Только ASCII: всё прочее заменяется на '?'.
  List<int> _ascii(String text) =>
      text.codeUnits.map((c) => c < 0x80 ? c : 0x3F).toList();

  void _portWrite(Uint8List bytes) {
    if (_vfdPort == null) return;
    try {
      final port = SerialPort(_vfdPort!);
      if (port.openWrite()) {
        try {
          final cfg = SerialPortConfig()
            ..baudRate = _vfdBaud
            ..bits = 8
            ..stopBits = 1
            ..parity = SerialPortParity.none
            ..setFlowControl(SerialPortFlowControl.none);
          port.config = cfg;
          port.write(bytes, timeout: 1000);
        } finally {
          port.close();
        }
      }
    } catch (_) {}
  }

  // CP866 encoding for Cyrillic VFD displays
  List<int> _cp866(String text) {
    return text.codeUnits.map((c) {
      if (c < 0x80) return c;
      if (c >= 0x0410 && c <= 0x042F) return 0x80 + (c - 0x0410); // А–Я
      if (c >= 0x0430 && c <= 0x043F) return 0xA0 + (c - 0x0430); // а–п
      if (c >= 0x0440 && c <= 0x044F) return 0xE0 + (c - 0x0440); // р–я
      if (c == 0x0401) return 0xF0; // Ё
      if (c == 0x0451) return 0xF1; // ё
      return 0x3F; // ?
    }).toList();
  }

  String _center(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    final pad = (width - text.length) ~/ 2;
    return (' ' * pad + text).padRight(width);
  }

  String _padRight(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    return text.padRight(width);
  }

  String _formatMoney(double amount) {
    final text = formatMoney(amount); // '709.5' или '710'
    final dot = text.indexOf('.');
    final intPart = dot == -1 ? text : text.substring(0, dot);
    final frac = dot == -1 ? '' : text.substring(dot);
    if (intPart.length <= 3) return '$intPart$frac тг';
    final buf = StringBuffer();
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write(' ');
      buf.write(intPart[i]);
      count++;
    }
    return '${buf.toString().split('').reversed.join()}$frac тг';
  }

  // ── HTTP / SSE helpers ─────────────────────────────────────────────────────

  void _pushSse() {
    if (_sseClients.isEmpty) return;
    final itemsJson = _items.map((item) {
      final qtyFmt = item.product.isByWeight
          ? item.quantity.toStringAsFixed(3)
          : item.quantity.toStringAsFixed(0);
      return {
        'name': item.product.name,
        'qty': '$qtyFmt ${item.product.unitLabel}',
        'price': item.effectivePrice,
        'total': item.total,
      };
    }).toList();
    final payload = jsonEncode({
      'shopName': _shopName,
      'total': _total,
      'items': itemsJson,
    });
    final event = 'data: $payload\n\n';
    final dead = <HttpResponse>[];
    for (final client in _sseClients) {
      try {
        client.write(event);
      } catch (_) {
        dead.add(client);
      }
    }
    for (final d in dead) { _sseClients.remove(d); }
  }

  Future<void> _handleHttp() async {
    await for (final req in _server!) {
      if (req.uri.path == '/events') {
        req.response.headers
          ..set('Content-Type', 'text/event-stream; charset=utf-8')
          ..set('Cache-Control', 'no-cache')
          ..set('Connection', 'keep-alive')
          ..set('Access-Control-Allow-Origin', '*');
        req.response.bufferOutput = false;
        _sseClients.add(req.response);
        _pushSse();
      } else {
        req.response.headers.contentType = ContentType.html;
        req.response.write(_buildHtml());
        await req.response.close();
      }
    }
  }

  Future<void> stop() async {
    for (final c in _sseClients) {
      try { await c.close(); } catch (_) {}
    }
    _sseClients.clear();
    await _server?.close(force: true);
    _server = null;
  }

  // ── Browser HTML ───────────────────────────────────────────────────────────

  String _buildHtml() {
    return r'''<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="utf-8">
  <title>Экран покупателя</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      background: #0F172A; color: #F1F5F9;
      font-family: 'Segoe UI', Tahoma, sans-serif;
      height: 100vh; display: flex; flex-direction: column;
      overflow: hidden; user-select: none;
    }
    .header {
      background: #1E293B; padding: 14px 32px;
      display: flex; align-items: center;
      border-bottom: 1px solid #334155; flex-shrink: 0;
    }
    .shop-name { font-size: 20px; font-weight: 700; color: #E2E8F0; }
    .dot { width: 8px; height: 8px; background: #10B981; border-radius: 50%;
           margin-left: auto; animation: pulse 2s infinite; }
    @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:.3} }
    .content { flex: 1; display: flex; flex-direction: column; overflow: hidden; position: relative; }
    #idle {
      position: absolute; inset: 0; display: flex; flex-direction: column;
      align-items: center; justify-content: center; gap: 12px; transition: opacity .4s;
    }
    #idle .kz { font-size: 52px; font-weight: 800; }
    #idle .ru { font-size: 28px; color: #64748B; }
    #active {
      position: absolute; inset: 0; display: none; flex-direction: column; opacity: 0; transition: opacity .3s;
    }
    .scroll { flex: 1; overflow-y: auto; padding: 16px 40px; display: flex; flex-direction: column; gap: 8px; }
    .scroll::-webkit-scrollbar { width: 4px; }
    .scroll::-webkit-scrollbar-thumb { background: #334155; border-radius: 2px; }
    .row {
      display: flex; align-items: center; gap: 16px;
      background: #1E293B; border-radius: 12px; padding: 14px 20px;
      animation: in .2s ease;
    }
    @keyframes in { from{opacity:0;transform:translateY(8px)} to{opacity:1;transform:none} }
    .rname { flex:1; font-size:18px; font-weight:600; color:#E2E8F0;
             white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
    .rqty  { font-size:15px; color:#94A3B8; white-space:nowrap; }
    .rtot  { font-size:20px; font-weight:700; color:#34D399; white-space:nowrap; min-width:120px; text-align:right; }
    .footer {
      background: linear-gradient(135deg,#059669,#10B981);
      padding: 22px 40px; display: flex; align-items: center;
      justify-content: space-between; flex-shrink: 0; transition: opacity .4s;
    }
    .footer.hidden { opacity:0; pointer-events:none; }
    .flabel { font-size:26px; font-weight:600; color:rgba(255,255,255,.85); }
    .famount { font-size:58px; font-weight:900; color:#fff; letter-spacing:-2px; line-height:1; }
  </style>
</head>
<body>
  <div class="header">
    <span id="shop-name" class="shop-name">iMag Kassa</span>
    <span class="dot"></span>
  </div>
  <div class="content">
    <div id="idle"><div class="kz">Қош келдіңіз!</div><div class="ru">Добро пожаловать!</div></div>
    <div id="active"><div class="scroll" id="list"></div></div>
  </div>
  <div class="footer hidden" id="footer">
    <div class="flabel">ИТОГО</div>
    <div class="famount" id="total">0 ₸</div>
  </div>
  <script>
    function fmt(n){return new Intl.NumberFormat('ru-RU').format(Math.round(n))+' ₸';}
    function render(d){
      document.getElementById('shop-name').textContent=d.shopName||'iMag Kassa';
      var has=d.items&&d.items.length>0;
      var idle=document.getElementById('idle');
      var active=document.getElementById('active');
      var footer=document.getElementById('footer');
      var list=document.getElementById('list');
      if(has){
        idle.style.opacity='0'; idle.style.pointerEvents='none';
        active.style.display='flex'; active.style.opacity='1';
        footer.classList.remove('hidden');
        list.innerHTML='';
        d.items.forEach(function(item){
          var r=document.createElement('div'); r.className='row';
          r.innerHTML='<div class="rname">'+item.name+'</div>'+
            '<div class="rqty">'+item.qty+' \xd7 '+fmt(item.price)+'</div>'+
            '<div class="rtot">'+fmt(item.total)+'</div>';
          list.appendChild(r);
        });
        document.getElementById('total').textContent=fmt(d.total);
      } else {
        idle.style.opacity='1'; idle.style.pointerEvents='';
        active.style.opacity='0';
        setTimeout(function(){if(!d.items||!d.items.length)active.style.display='none';},300);
        footer.classList.add('hidden');
      }
    }
    function connect(){
      var s=new EventSource('/events');
      s.onmessage=function(e){try{render(JSON.parse(e.data));}catch(_){}};
      s.onerror=function(){s.close();setTimeout(connect,3000);};
    }
    connect();
  </script>
</body>
</html>''';
  }
}

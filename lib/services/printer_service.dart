import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../utils/money.dart';

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  String _shopName = 'МОЙ МАГАЗИН';
  String _shopBin = '';
  String _ipName = '';
  String _address = '';
  String? _rawPrinterPort;
  int _codePage = 0x11; // default CP866

  String get shopName => _shopName;
  String get ipName => _ipName;
  String get address => _address;

  void setShopInfo({
    required String name,
    String bin = '',
    String ipName = '',
    String address = '',
  }) {
    _shopName = name.isNotEmpty ? name : 'МОЙ МАГАЗИН';
    _shopBin = bin;
    _ipName = ipName;
    _address = address;
  }

  void setRawPrinterPort(String? port) {
    _rawPrinterPort = port;
  }

  String? get rawPrinterPort => _rawPrinterPort;

  /// Set raw printer code page (ESC t n). Default is 0x11 (17) => CP866 on many
  /// XPrinter models. Try other values (18,19,21,25...) if characters are wrong.
  void setRawPrinterCodePage(int codePage) {
    _codePage = codePage & 0xFF;
  }

  int get rawPrinterCodePage => _codePage;

  // ── Public entry point ──────────────────────────────────────────────────────

  Future<void> printReceipt(Sale sale) async {
    if (_rawPrinterPort != null) {
      await _printReceiptRaw(sale);
    } else {
      final pdf = await _buildReceiptPdf(sale);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf,
        name: 'Чек #${sale.receiptNumber}',
      );
    }
  }

  Future<List<Printer>> getAvailablePrinters() async {
    return await Printing.listPrinters();
  }

  Future<void> printReceiptToPrinter(Sale sale, Printer printer) async {
    final pdf = await _buildReceiptPdf(sale);
    await Printing.directPrintPdf(
      printer: printer,
      onLayout: (PdfPageFormat format) async => pdf,
    );
  }

  // ── PDF receipt (Windows printers) ──────────────────────────────────────────

  Future<Uint8List> _buildReceiptPdf(Sale sale) async {
    final doc = pw.Document();
    final effectiveShopName = sale.storeName ?? _shopName;

    // Load a Cyrillic-capable TTF from assets if available. Add a font file
    // at `assets/fonts/NotoSans-Regular.ttf` and include it in pubspec.yaml.
    // If not present, fall back to Helvetica (may not support Cyrillic).
    pw.Font baseFont;
    try {
      final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      final bd = fontData.buffer.asByteData(fontData.offsetInBytes, fontData.lengthInBytes);
      baseFont = pw.Font.ttf(bd);
    } catch (e) {
      throw Exception(
          'Missing font asset assets/fonts/NotoSans-Regular.ttf. Add a Cyrillic-capable TTF (e.g. Noto Sans) to assets/fonts and register it in pubspec.yaml, then run `flutter pub get`.');
    }

    // Use paper width matching printable area: 48mm for XP-58 (Print Setup shows 58(48)).
    const pageWidth = 48.0 * PdfPageFormat.mm;

    // Estimate page height based on content so the PDF won't be clipped by the
    // Windows printer driver. Use a simple heuristic: header/footer + 2 lines
    // per item. Each line ~5mm.
    final headerLines = 12;
    final footerLines = 8;
    final perItemLines = 2;
    final totalLines = headerLines + sale.items.length * perItemLines + footerLines;
    final pageHeightMm = (totalLines * 5.0).clamp(120.0, 1000.0);
    final pageFormat = PdfPageFormat(
      pageWidth,
      pageHeightMm * PdfPageFormat.mm,
      marginAll: 1.5 * PdfPageFormat.mm,
    );

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              if (_ipName.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    _ipName,
                    style: pw.TextStyle(font: baseFont, fontSize: 9),
                  ),
                ),
              pw.Center(
                child: pw.Text(
                  effectiveShopName,
                  style: pw.TextStyle(
                    font: baseFont,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              if (_address.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    _address,
                    style: pw.TextStyle(font: baseFont, fontSize: 8),
                  ),
                ),
              if (_shopBin.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    'БИН: $_shopBin',
                    style: pw.TextStyle(font: baseFont, fontSize: 8),
                  ),
                ),
              pw.Divider(thickness: 0.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    DateFormat('dd.MM.yyyy HH:mm').format(sale.createdAt),
                    style: pw.TextStyle(font: baseFont, fontSize: 8),
                  ),
                  pw.Text(
                    'Чек #${sale.receiptNumber.toString().padLeft(4, '0')}',
                    style: pw.TextStyle(font: baseFont, fontSize: 8),
                  ),
                ],
              ),
              pw.Text(
                'Кассир: ${sale.cashierName ?? 'Кассир'}',
                style: pw.TextStyle(font: baseFont, fontSize: 8),
              ),
              pw.Divider(thickness: 0.5),
              ...sale.items.map((item) => pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Text(
                        item.productName,
                        style: pw.TextStyle(
                          font: baseFont,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '${item.quantity.toStringAsFixed(item.unit == 'кг' ? 3 : 0)} ${item.unit} × ${formatMoney(item.price)} тг',
                            style: pw.TextStyle(font: baseFont, fontSize: 8),
                          ),
                          pw.Text(
                            '${formatMoney(item.total)} тг',
                            style: pw.TextStyle(
                              font: baseFont,
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                    ],
                  )),
              pw.Divider(thickness: 0.8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'ИТОГО:',
                    style: pw.TextStyle(
                      font: baseFont,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${formatMoney(sale.total)} тг',
                    style: pw.TextStyle(
                      font: baseFont,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              if (sale.paymentMethod == PaymentMethod.combined) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Наличные:', style: pw.TextStyle(font: baseFont, fontSize: 8)),
                    pw.Text('${formatMoney(sale.cashAmount ?? 0)} тг',
                        style: pw.TextStyle(font: baseFont, fontSize: 8)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Карта:', style: pw.TextStyle(font: baseFont, fontSize: 8)),
                    pw.Text('${formatMoney(sale.cardAmount ?? 0)} тг',
                        style: pw.TextStyle(font: baseFont, fontSize: 8)),
                  ],
                ),
              ] else ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Оплачено:', style: pw.TextStyle(font: baseFont, fontSize: 8)),
                    pw.Text('${formatMoney(sale.amountPaid)} тг',
                        style: pw.TextStyle(font: baseFont, fontSize: 8)),
                  ],
                ),
              ],
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                    pw.Text('Сдача:', style: pw.TextStyle(font: baseFont, fontSize: 8)),
                    pw.Text('${formatMoney(sale.change)} тг',
                      style: pw.TextStyle(font: baseFont, fontSize: 8)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Способ оплаты:',
                      style: pw.TextStyle(font: baseFont, fontSize: 8)),
                  pw.Text(
                    sale.paymentLabel,
                    style: pw.TextStyle(
                      font: baseFont,
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 0.5),
              pw.Center(
                child: pw.Text(
                  'Спасибо за покупку! Ждём вас снова!',
                  style: pw.TextStyle(font: baseFont, fontSize: 8),
                ),
              ),
              pw.SizedBox(height: 8),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // ── Raw ESC/POS CP866 (термопринтер через COM-порт) ─────────────────────────

  Future<void> _printReceiptRaw(Sale sale) async {
    final bytes = _buildReceiptRaw(sale);
    await _sendToPort(bytes);
  }

  /// Print receipt as a bitmap image (raster) to the raw ESC/POS printer.
  /// This renders the receipt using Flutter text layout and sends a GS v 0
  /// raster image command which ensures all Cyrillic glyphs are printed.
  Future<void> printReceiptBitmap(Sale sale) async {
    final bytes = await _buildReceiptBitmap(sale);
    await _sendToPort(bytes);
  }

  Uint8List _buildReceiptRaw(Sale sale) {
    final buf = <int>[];
    final effectiveShopName = sale.storeName ?? _shopName;

    void esc(List<int> cmd) => buf.addAll(cmd);

    void printLine(String text) {
      // Replace Tenge sign with 'тг' for printers lacking ₸ glyph.
      final safe = text.replaceAll('\u20B8', 'тг');
      buf.addAll(_encodeCP866(safe));
      buf.add(0x0A);
    }

    void printCenter(String text) {
      esc([0x1B, 0x61, 0x01]);
      printLine(text);
      esc([0x1B, 0x61, 0x00]);
    }

    void printBoldCenter(String text) {
      esc([0x1B, 0x61, 0x01, 0x1B, 0x45, 0x01]);
      printLine(text);
      esc([0x1B, 0x45, 0x00, 0x1B, 0x61, 0x00]);
    }

    void printBold(String text) {
      esc([0x1B, 0x45, 0x01]);
      printLine(text);
      esc([0x1B, 0x45, 0x00]);
    }

    void printLineWithRight(String left, String right, {int width = 42}) {
      final spaces = width - left.length - right.length;
      final padded = spaces > 0 ? left + (' ' * spaces) + right : '$left $right';
      printLine(padded);
    }

    // Init + set code page (configurable)
    esc([0x1B, 0x40]);                 // ESC @ — сброс принтера
    esc([0x1B, 0x74, _codePage]);      // ESC t n — set code page (default 17 => CP866)
    // Switch to smaller built-in font B for better fitting on narrow paper
    esc([0x1B, 0x4D, 0x01]);          // ESC M 1 — Font B

    // Шапка чека
    if (_ipName.isNotEmpty) printCenter(_ipName);
    printBoldCenter(effectiveShopName);
    if (_address.isNotEmpty) printCenter(_address);
    if (_shopBin.isNotEmpty) printCenter('БИН: $_shopBin');
    printLine('--------------------------------');

    // Дата, номер чека, кассир
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(sale.createdAt);
    printLine(dateStr);
    printLine('Чек #${sale.receiptNumber.toString().padLeft(4, '0')}');
    printLine('Кассир: ${sale.cashierName ?? 'Кассир'}');
    printLine('--------------------------------');

    // Товары
    for (final item in sale.items) {
      printBold(item.productName);
      final qty = item.quantity.toStringAsFixed(item.unit == 'кг' ? 3 : 0);
      final priceStr = formatMoney(item.price);
      final totalStr = '${formatMoney(item.total)} T';
      final left = '$qty ${item.unit} x $priceStr T';
      printLineWithRight(left, totalStr);
    }

    printLine('================================');

    // Итого
    printBold('ИТОГО: ${formatMoney(sale.total)} T');
    if (sale.paymentMethod == PaymentMethod.combined) {
      printLine('Наличные: ${formatMoney(sale.cashAmount ?? 0)} T');
      printLine('Карта: ${formatMoney(sale.cardAmount ?? 0)} T');
    } else {
      printLine('Оплачено: ${formatMoney(sale.amountPaid)} T');
    }
    printLine('Сдача: ${formatMoney(sale.change)} T');
    printLine('Способ оплаты: ${sale.paymentLabel}');
    printLine('--------------------------------');
    printCenter('Спасибо за покупку!');
    printCenter('Ждём вас снова!');

    // Прокрутка и обрезка
    buf.addAll([0x0A, 0x0A, 0x0A, 0x0A]);
    buf.addAll([0x1D, 0x56, 0x41, 0x00]); // GS V A — полный порез

    return Uint8List.fromList(buf);
  }

  // ── Отчёт «Оборот кассы» ────────────────────────────────────────────────────

  Future<void> printTurnoverReport({
    required DateTime from,
    required DateTime to,
    required String cashierName,
    required double cash,
    required double card,
    required double total,
  }) async {
    if (_rawPrinterPort != null) {
      await _sendToPort(_buildTurnoverRaw(
        from: from,
        to: to,
        cashierName: cashierName,
        cash: cash,
        card: card,
        total: total,
      ));
    } else {
      final pdf = await _buildTurnoverPdf(
        from: from,
        to: to,
        cashierName: cashierName,
        cash: cash,
        card: card,
        total: total,
      );
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf,
        name: 'Оборот кассы',
      );
    }
  }

  Uint8List _buildTurnoverRaw({
    required DateTime from,
    required DateTime to,
    required String cashierName,
    required double cash,
    required double card,
    required double total,
  }) {
    final buf = <int>[];
    final df = DateFormat('dd.MM.yyyy');

    void esc(List<int> cmd) => buf.addAll(cmd);

    void printLine(String text) {
      buf.addAll(_encodeCP866(text.replaceAll('₸', 'тг')));
      buf.add(0x0A);
    }

    void printCenter(String text) {
      esc([0x1B, 0x61, 0x01]);
      printLine(text);
      esc([0x1B, 0x61, 0x00]);
    }

    void printBoldCenter(String text) {
      esc([0x1B, 0x61, 0x01, 0x1B, 0x45, 0x01]);
      printLine(text);
      esc([0x1B, 0x45, 0x00, 0x1B, 0x61, 0x00]);
    }

    void printBold(String text) {
      esc([0x1B, 0x45, 0x01]);
      printLine(text);
      esc([0x1B, 0x45, 0x00]);
    }

    void printLineWithRight(String left, String right, {int width = 42}) {
      final spaces = width - left.length - right.length;
      final padded =
          spaces > 0 ? left + (' ' * spaces) + right : '$left $right';
      printLine(padded);
    }

    esc([0x1B, 0x40]);            // сброс
    esc([0x1B, 0x74, _codePage]); // кодовая страница
    esc([0x1B, 0x4D, 0x01]);      // Font B

    printBoldCenter('ОБОРОТ КАССЫ');
    printCenter(_shopName);
    printLine('--------------------------------');
    printLine('с  ${df.format(from)}');
    printLine('до ${df.format(to)}');
    printLine('Кассир: $cashierName');
    printLine('--------------------------------');
    printLineWithRight('Наличные:', '${formatMoney(cash)} T');
    printLineWithRight('Оплата картой:', '${formatMoney(card)} T');
    printLine('________________________________');
    printBold('ОБЩИЙ: ${formatMoney(total)} T');
    printLine('--------------------------------');
    printCenter('Программный продукт');
    printCenter('iMag Kassa');

    buf.addAll([0x0A, 0x0A, 0x0A, 0x0A]);
    buf.addAll([0x1D, 0x56, 0x41, 0x00]); // порез

    return Uint8List.fromList(buf);
  }

  Future<Uint8List> _buildTurnoverPdf({
    required DateTime from,
    required DateTime to,
    required String cashierName,
    required double cash,
    required double card,
    required double total,
  }) async {
    final doc = pw.Document();
    final df = DateFormat('dd.MM.yyyy');

    final fontData =
        await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final baseFont = pw.Font.ttf(fontData.buffer
        .asByteData(fontData.offsetInBytes, fontData.lengthInBytes));

    const pageWidth = 48.0 * PdfPageFormat.mm;
    final pageFormat = PdfPageFormat(
      pageWidth,
      120 * PdfPageFormat.mm,
      marginAll: 1.5 * PdfPageFormat.mm,
    );

    pw.Widget row(String left, String right, {bool bold = false}) {
      final style = pw.TextStyle(
        font: baseFont,
        fontSize: 9,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      );
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [pw.Text(left, style: style), pw.Text(right, style: style)],
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(
              child: pw.Text('ОБОРОТ КАССЫ',
                  style: pw.TextStyle(
                      font: baseFont,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold)),
            ),
            pw.Center(
              child: pw.Text(_shopName,
                  style: pw.TextStyle(font: baseFont, fontSize: 10)),
            ),
            pw.Divider(thickness: 0.5),
            pw.Text('с  ${df.format(from)}',
                style: pw.TextStyle(font: baseFont, fontSize: 9)),
            pw.Text('до ${df.format(to)}',
                style: pw.TextStyle(font: baseFont, fontSize: 9)),
            pw.Text('Кассир: $cashierName',
                style: pw.TextStyle(font: baseFont, fontSize: 9)),
            pw.Divider(thickness: 0.5),
            row('Наличные:', '${formatMoney(cash)} тг'),
            pw.SizedBox(height: 2),
            row('Оплата картой:', '${formatMoney(card)} тг'),
            pw.Divider(thickness: 0.5),
            row('ОБЩИЙ:', '${formatMoney(total)} тг', bold: true),
            pw.Divider(thickness: 0.5),
            pw.Center(
              child: pw.Text('Программный продукт',
                  style: pw.TextStyle(font: baseFont, fontSize: 8)),
            ),
            pw.Center(
              child: pw.Text('iMag Kassa',
                  style: pw.TextStyle(
                      font: baseFont,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  // Unicode → CP866
  List<int> _encodeCP866(String text) {
    return text.codeUnits.map((orig) {
      var c = orig;

      // Remap some Kazakh-specific Cyrillic letters to closest Russian equivalents
      switch (orig) {
        case 0x04D8: // Ә
          c = 0x0410; // А
          break;
        case 0x04D9: // ә
          c = 0x0430; // а
          break;
        case 0x0492: // Ғ
          c = 0x0413; // Г
          break;
        case 0x0493: // ғ
          c = 0x0433; // г
          break;
        case 0x049A: // Қ
          c = 0x041A; // К
          break;
        case 0x049B: // қ
          c = 0x043A; // к
          break;
        case 0x04A2: // Ң
          c = 0x041D; // Н
          break;
        case 0x04A3: // ң
          c = 0x043D; // н
          break;
        case 0x04AE: // Ү
          c = 0x0423; // У
          break;
        case 0x04AF: // ү
          c = 0x0443; // у
          break;
        case 0x04B0: // Ұ
          c = 0x0423; // У
          break;
        case 0x04B1: // ұ
          c = 0x0443; // у
          break;
        case 0x04E8: // Ө
          c = 0x041E; // О
          break;
        case 0x04E9: // ө
          c = 0x043E; // о
          break;
        case 0x0406: // І
          c = 0x0418; // И
          break;
        case 0x0456: // і
          c = 0x0438; // и
          break;
        case 0x04BB: // һ
          c = 0x0445; // х
          break;
      }

      if (c < 0x80) return c;                              // ASCII
      if (c >= 0x0410 && c <= 0x042F) return 0x80 + (c - 0x0410); // А–Я
      if (c >= 0x0430 && c <= 0x043F) return 0xA0 + (c - 0x0430); // а–п
      if (c >= 0x0440 && c <= 0x044F) return 0xE0 + (c - 0x0440); // р–я
      if (c == 0x0401) return 0xF0; // Ё
      if (c == 0x0451) return 0xF1; // ё
      if (c == 0x20B8) return 0x54; // ₸ → T
      return 0x3F;                                        // '?' для остального
    }).toList();
  }

  Future<void> _sendToPort(Uint8List bytes) async {
    if (_rawPrinterPort == null) return;
    final port = SerialPort(_rawPrinterPort!);
    if (!port.openWrite()) {
      throw Exception('Не удалось открыть порт $_rawPrinterPort');
    }
    try {
      port.write(bytes, timeout: 3000);
    } finally {
      port.close();
    }
  }

  Future<Uint8List> _buildReceiptBitmap(Sale sale) async {
    // Printer dots per mm (approx for 203 DPI). Use 48mm printable width.
    const double dotsPerMm = 8.0;
    final int widthPx = (48.0 * dotsPerMm).round(); // 48mm printable width

    // Build lines similar to text receipt
    final List<String> lines = [];
    final effectiveShopName = sale.storeName ?? _shopName;
    if (_ipName.isNotEmpty) lines.add(_ipName);
    lines.add(effectiveShopName);
    if (_address.isNotEmpty) lines.add(_address);
    if (_shopBin.isNotEmpty) lines.add('БИН: $_shopBin');
    lines.add('--------------------------------');
    lines.add(DateFormat('dd.MM.yyyy HH:mm').format(sale.createdAt));
    lines.add('Чек #${sale.receiptNumber.toString().padLeft(4, '0')}');
    lines.add('Кассир: ${sale.cashierName ?? 'Кассир'}');
    lines.add('--------------------------------');
    for (final item in sale.items) {
      lines.add(item.productName);
      final qty = item.quantity.toStringAsFixed(item.unit == 'кг' ? 3 : 0);
      final left = '$qty ${item.unit} x ${formatMoney(item.price)} тг';
      final right = '${formatMoney(item.total)} тг';
      lines.add('$left    $right');
    }
    lines.add('================================');
    lines.add('ИТОГО: ${formatMoney(sale.total)} тг');
    if (sale.paymentMethod == PaymentMethod.combined) {
      lines.add('Наличные: ${formatMoney(sale.cashAmount ?? 0)} тг');
      lines.add('Карта: ${formatMoney(sale.cardAmount ?? 0)} тг');
    } else {
      lines.add('Оплачено: ${formatMoney(sale.amountPaid)} тг');
    }
    lines.add('Сдача: ${formatMoney(sale.change)} тг');
    lines.add('Способ оплаты: ${sale.paymentLabel}');
    lines.add('--------------------------------');
    lines.add('Спасибо за покупку!');
    lines.add('Ждём вас снова!');

    // Text style — smaller font so lines fit on 48mm printable area
    const double fontSize = 10.0; // logical pixels
    final textStyle = TextStyle(fontFamily: 'NotoSans', fontSize: fontSize, color: ui.Color(0xFF000000));

    // Measure total height
    final tp = TextPainter(textDirection: ui.TextDirection.ltr);
    double y = 8.0; // top padding
    final double lineSpacing = fontSize * 1.1;
    for (final l in lines) {
      tp.text = TextSpan(text: l, style: textStyle);
      tp.layout(maxWidth: widthPx.toDouble());
      y += tp.height > 0 ? tp.height : lineSpacing;
      y += 2.0; // small gap
    }
    final int heightPx = (y + 16).ceil();

    // Draw to canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, widthPx.toDouble(), heightPx.toDouble()));
    final paint = Paint()..color = ui.Color(0xFFFFFFFF);
    canvas.drawRect(Rect.fromLTWH(0, 0, widthPx.toDouble(), heightPx.toDouble()), paint);

    // draw text lines
    // draw text lines with right-aligned amounts when present
    double curY = 8.0;
    final double padding = 4.0;
    for (final l in lines) {
      if (l.contains('    ')) {
        // expected format: left + spaces + right
        final parts = l.split(RegExp(r'\s{2,}'));
        final left = parts.isNotEmpty ? parts.first : l;
        final right = parts.length > 1 ? parts.last : '';

        // draw right-aligned
        tp.text = TextSpan(text: right, style: textStyle);
        tp.layout(maxWidth: widthPx.toDouble());
        final rightW = tp.width;
        tp.paint(canvas, Offset(widthPx - padding - rightW, curY));

        // draw left with ellipsis if too long
        final leftMaxW = widthPx - padding * 2 - rightW - 8.0;
        tp.text = TextSpan(text: left, style: textStyle);
        tp.layout(maxWidth: leftMaxW);
        tp.paint(canvas, Offset(padding, curY));
        curY += tp.height + 2.0;
        continue;
      }

      tp.text = TextSpan(text: l, style: textStyle);
      tp.layout(maxWidth: widthPx.toDouble());
      tp.paint(canvas, Offset(padding, curY));
      curY += tp.height + 2.0;
    }

    final picture = recorder.endRecording();
    final ui.Image img = await picture.toImage(widthPx, heightPx);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) throw Exception('Failed to rasterize image');
    final Uint8List rgba = byteData.buffer.asUint8List();

    // Convert to monochrome bytes (1 = black)
    final int widthBytes = ((widthPx + 7) ~/ 8);
    final List<int> imgBytes = [];
    for (int yRow = 0; yRow < heightPx; yRow++) {
      for (int xByte = 0; xByte < widthBytes; xByte++) {
        int byte = 0;
        for (int bit = 0; bit < 8; bit++) {
          final int x = xByte * 8 + bit;
          if (x >= widthPx) continue;
          final int idx = (yRow * widthPx + x) * 4;
          final int r = rgba[idx];
          final int g = rgba[idx + 1];
          final int b = rgba[idx + 2];
          final int lum = ((0.299 * r) + (0.587 * g) + (0.114 * b)).round();
          final bool black = lum < 128;
          if (black) {
            byte |= (0x80 >> bit);
          }
        }
        imgBytes.add(byte);
      }
    }

    // Build ESC/POS raster header: GS v 0
    final List<int> buf = [];
    buf.addAll([0x1B, 0x40]); // init
    buf.addAll([0x1B, 0x61, 0x01]); // center
    final xL = widthBytes & 0xFF;
    final xH = (widthBytes >> 8) & 0xFF;
    final yL = heightPx & 0xFF;
    final yH = (heightPx >> 8) & 0xFF;
    buf.addAll([0x1D, 0x76, 0x30, 0x00, xL, xH, yL, yH]);
    buf.addAll(imgBytes);
    buf.addAll([0x0A, 0x0A, 0x0A]);
    buf.addAll([0x1D, 0x56, 0x41, 0x00]); // cut

    return Uint8List.fromList(buf);
  }
}

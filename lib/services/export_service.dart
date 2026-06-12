import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/sale.dart';
import '../utils/money.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  Future<void> exportSalesToPdf(
    List<Sale> sales, {
    required double totalRevenue,
    required double cashRevenue,
    required double cardRevenue,
    required DateTime fromDate,
    required DateTime toDate,
    String shopName = 'iMag Kassa',
  }) async {
    // ── Font ──────────────────────────────────────────────────────────────────
    pw.Font font;
    pw.Font fontBold;
    try {
      final regular =
          await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      font = pw.Font.ttf(
          regular.buffer.asByteData(regular.offsetInBytes, regular.lengthInBytes));
      fontBold = font;
    } catch (_) {
      font = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    pw.TextStyle ts(double size, {bool bold = false, PdfColor? color}) =>
        pw.TextStyle(
          font: bold ? fontBold : font,
          fontSize: size,
          color: color,
        );

    // ── Computed stats ────────────────────────────────────────────────────────
    final actualSales = sales.where((s) => !s.isReturn).toList();
    final returnSales = sales.where((s) => s.isReturn).toList();

    final returnAmount =
        returnSales.fold(0.0, (sum, s) => sum + s.total.abs());

    final dateFmt = DateFormat('dd.MM.yyyy');
    final timeFmt = DateFormat('HH:mm');
    final periodStr = fromDate.day == toDate.day &&
            fromDate.month == toDate.month &&
            fromDate.year == toDate.year
        ? dateFmt.format(fromDate)
        : '${dateFmt.format(fromDate)} — ${dateFmt.format(toDate)}';

    // ── Colors ────────────────────────────────────────────────────────────────
    const headerBg = PdfColor.fromInt(0xFF1E3A5F);
    const rowAltBg = PdfColor.fromInt(0xFFF5F7FA);
    const greenColor = PdfColor.fromInt(0xFF059669);
    const redColor = PdfColor.fromInt(0xFFDC2626);
    const greyText = PdfColor.fromInt(0xFF6B7280);

    // ── Page format: A4 portrait ──────────────────────────────────────────────
    final format = PdfPageFormat.a4.copyWith(
      marginLeft: 12 * PdfPageFormat.mm,
      marginRight: 12 * PdfPageFormat.mm,
      marginTop: 14 * PdfPageFormat.mm,
      marginBottom: 14 * PdfPageFormat.mm,
    );

    final doc = pw.Document();

    // ── Helper: summary row ───────────────────────────────────────────────────
    pw.Widget summaryRow(String label, String value,
        {PdfColor? valueColor}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          children: [
            pw.SizedBox(width: 160,
                child: pw.Text(label, style: ts(9, color: greyText))),
            pw.Text(value,
                style: ts(10, bold: true, color: valueColor)),
          ],
        ),
      );
    }

    // ── Helper: table cell ────────────────────────────────────────────────────
    pw.Widget cell(String text,
        {bool bold = false,
        PdfColor? color,
        pw.Alignment align = pw.Alignment.centerLeft}) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
        alignment: align,
        child: pw.Text(text, style: ts(7, bold: bold, color: color),
            maxLines: 2, overflow: pw.TextOverflow.clip),
      );
    }

    // ── Helper: payment label ─────────────────────────────────────────────────
    String payLabel(Sale s) {
      switch (s.paymentMethod) {
        case PaymentMethod.cash:
          return 'Наличные';
        case PaymentMethod.card:
          return 'Карта';
        case PaymentMethod.combined:
          final c = formatMoney(s.cashAmount ?? 0);
          final k = formatMoney(s.cardAmount ?? 0);
          return 'Нал+Карта\n($c+$k)';
      }
    }

    // ── Data rows: одна строка на каждую позицию чека (Excel-стиль).
    //    Дата/время/чек/способ/итого — только на первой строке чека.
    final dataRows = <pw.TableRow>[];
    for (int saleIdx = 0; saleIdx < sales.length; saleIdx++) {
      final s = sales[saleIdx];
      final isReturn = s.isReturn;
      final bg = isReturn
          ? const PdfColor.fromInt(0xFFFFF1F2)
          : (saleIdx.isOdd ? rowAltBg : PdfColors.white);
      final fg = isReturn ? redColor : PdfColors.black;
      final receiptStr = isReturn
          ? 'Возврат'
          : '#${s.receiptNumber.toString().padLeft(4, '0')}';
      final totalStr =
          isReturn ? '−${_fmt(s.total.abs())}' : _fmt(s.total);

      for (int i = 0; i < s.items.length; i++) {
        final item = s.items[i];
        final first = i == 0;
        final qtyStr =
            item.quantity.toStringAsFixed(item.unit == 'кг' ? 3 : 0);
        final sumStr =
            isReturn ? '−${_fmt(item.total.abs())}' : _fmt(item.total);
        dataRows.add(pw.TableRow(
          decoration: pw.BoxDecoration(color: bg),
          children: [
            cell(first ? dateFmt.format(s.createdAt) : '', color: fg),
            cell(first ? timeFmt.format(s.createdAt) : '', color: fg),
            cell(first ? receiptStr : '',
                bold: first && !isReturn, color: fg),
            cell(item.productName, color: fg),
            cell(qtyStr, color: fg, align: pw.Alignment.centerRight),
            cell(item.unit, color: fg),
            cell(_fmt(item.price),
                color: fg, align: pw.Alignment.centerRight),
            cell(sumStr,
                bold: true, color: fg, align: pw.Alignment.centerRight),
            cell(first ? payLabel(s) : '', color: fg),
            cell(first ? totalStr : '',
                bold: true, color: fg, align: pw.Alignment.centerRight),
          ],
        ));
      }
    }

    // ── Build pages ───────────────────────────────────────────────────────────
    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Title block
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 10),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(width: 1.5, color: headerBg),
                ),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ОТЧЁТ ПО ПРОДАЖАМ',
                          style: ts(16, bold: true, color: headerBg)),
                      pw.SizedBox(height: 2),
                      pw.Text(shopName,
                          style: ts(10, color: greyText)),
                    ],
                  ),
                  pw.Spacer(),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Период: $periodStr', style: ts(9)),
                      pw.Text(
                          'Сформирован: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
                          style: ts(8, color: greyText)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            // Summary block (only on first page)
            if (ctx.pageNumber == 1) ...[
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Stats column 1
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFF0F7FF),
                        borderRadius: pw.BorderRadius.all(
                            pw.Radius.circular(6)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('СВОДКА',
                              style: ts(9, bold: true, color: headerBg)),
                          pw.SizedBox(height: 6),
                          summaryRow('Общая выручка:',
                              '${_fmt(totalRevenue)} тг',
                              valueColor: greenColor),
                          summaryRow('Наличные:', '${_fmt(cashRevenue)} тг'),
                          summaryRow('Карта:', '${_fmt(cardRevenue)} тг'),
                          if (returnAmount > 0)
                            summaryRow(
                                'Возвраты:',
                                '−${_fmt(returnAmount)} тг',
                                valueColor: redColor),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  // Stats column 2
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFF0FDF4),
                        borderRadius: pw.BorderRadius.all(
                            pw.Radius.circular(6)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('ТРАНЗАКЦИИ',
                              style: ts(9, bold: true, color: headerBg)),
                          pw.SizedBox(height: 6),
                          summaryRow(
                              'Всего чеков:', '${actualSales.length}'),
                          summaryRow('Возвратов:',
                              '${returnSales.length}',
                              valueColor: returnSales.isEmpty
                                  ? null
                                  : redColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Text('СПИСОК ПРОДАЖ',
                  style: ts(9, bold: true, color: headerBg)),
              pw.SizedBox(height: 4),
            ],
          ],
        ),

        build: (ctx) => [
          pw.Table(
            border: pw.TableBorder.all(
                width: 0.4, color: const PdfColor.fromInt(0xFFDDE1E7)),
            columnWidths: const {
              0: pw.FixedColumnWidth(44), // Дата
              1: pw.FixedColumnWidth(26), // Время
              2: pw.FixedColumnWidth(36), // Чек №
              3: pw.FlexColumnWidth(), // Товар
              4: pw.FixedColumnWidth(28), // Кол-во
              5: pw.FixedColumnWidth(16), // Ед.
              6: pw.FixedColumnWidth(38), // Цена
              7: pw.FixedColumnWidth(42), // Сумма
              8: pw.FixedColumnWidth(54), // Способ оплаты
              9: pw.FixedColumnWidth(42), // Итого
            },
            children: [
              // Table header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: headerBg),
                children: [
                  'Дата', 'Время', 'Чек №', 'Товар', 'Кол-о', 'Ед.',
                  'Цена (тг)', 'Сумма (тг)', 'Способ оплаты', 'Итого (тг)',
                ].map((h) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 4, vertical: 5),
                      child: pw.Text(h,
                          style: ts(7,
                              bold: true,
                              color: PdfColors.white)),
                    )).toList(),
              ),
              ...dataRows,
            ],
          ),
        ],

        footer: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('iMag Kassa — $shopName',
                style: ts(7, color: greyText)),
            pw.Text(
                'Страница ${ctx.pageNumber} из ${ctx.pagesCount}',
                style: ts(7, color: greyText)),
          ],
        ),
      ),
    );

    // ── Save & open ───────────────────────────────────────────────────────────
    final bytes = await doc.save();
    final dir = await getApplicationDocumentsDirectory();
    final filename =
        'imag_kassa_otchet_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    await OpenFile.open(file.path);
  }

  // Formats number with spaces: 45000 → "45 000"
  static String _fmt(double amount) {
    final text = formatMoney(amount); // '709.5' или '710'
    final dot = text.indexOf('.');
    final n = dot == -1 ? text : text.substring(0, dot);
    final frac = dot == -1 ? '' : text.substring(dot);
    final buf = StringBuffer();
    int count = 0;
    for (int i = n.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write(' '); // non-breaking space
      buf.write(n[i]);
      count++;
    }
    return '${buf.toString().split('').reversed.join()}$frac';
  }
}

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/analytics.dart';

/// Inatengeneza PDF ya "Ripoti ya Takwimu" kwa mtindo unaofanana na
/// muundo wa brand ya Nyumba Mkononi (banner ya navy, stat cards za
/// rangi, majedwali ya vipindi, na chart ya mwenendo wa miezi).
class PdfReportService {
  static const _navy = PdfColor.fromInt(0xFF0D3B66);
  static const _green = PdfColor.fromInt(0xFF2E9E5B);
  static const _purple = PdfColor.fromInt(0xFF6C4AB6);
  static const _orange = PdfColor.fromInt(0xFFE8871E);

  static const _monthNames = [
    'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
    'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba',
  ];

  static Future<Uint8List> generate({
    required String periodLabel,
    required AnalyticsSummary summary,
    required List<MonthlyPoint> monthly,
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')} ${_monthNames[now.month - 1]} ${now.year}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        header: (context) => context.pageNumber == 1
            ? _buildHeader(periodLabel, dateStr, timeStr)
            : pw.SizedBox(),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _sectionTitle('Muhtasari wa Jumla', 'Hali ya sasa ya mfumo wa Nyumba Mkononi'),
                pw.SizedBox(height: 10),
                _summaryCardsRow(summary),
                pw.SizedBox(height: 20),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: _periodTable('Akaunti Mpya Zilizosajiliwa', _green, [
                        _row('Leo (Siku 1)', summary.registrationsToday),
                        _row('Wiki (Siku 7)', summary.registrationsThisWeek),
                        _row('Mwezi (Siku 30)', summary.registrationsThisMonth),
                        _row('Mwaka (Siku 365)', summary.registrationsThisYear),
                      ]),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: _periodTable('Watumiaji Walioingia (Login)', _navy, [
                        _row('Leo (Siku 1)', summary.loginsToday),
                        _row('Wiki (Siku 7)', summary.loginsThisWeek),
                        _row('Mwezi (Siku 30)', summary.loginsThisMonth),
                        _row('Mwaka (Siku 365)', summary.loginsThisYear),
                      ]),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                _sectionTitle('Mwenendo wa Akaunti Mpya kwa Mwezi', 'Miezi 12 iliyopita'),
                pw.SizedBox(height: 10),
                _monthlyChart(monthly),
              ],
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  // --- Header / Footer ----------------------------------------------

  static pw.Widget _buildHeader(String periodLabel, String date, String time) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      color: _navy,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Nyumba Mkononi',
                style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('Pata Nyumba, Pata Maisha', style: const pw.TextStyle(color: PdfColors.white, fontSize: 9)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'RIPOTI YA TAKWIMU',
                style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('Ripoti ya $periodLabel', style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
              pw.SizedBox(height: 4),
              pw.Text('Tarehe: $date   Muda: $time', style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Mfumo wa Nyumba Mkononi', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.Text(
            'Ukurasa ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  // --- Sections ------------------------------------------------------

  static pw.Widget _sectionTitle(String title, String subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _navy)),
        pw.Text(subtitle, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      ],
    );
  }

  static pw.Widget _summaryCardsRow(AnalyticsSummary s) {
    return pw.Row(
      children: [
        _statCard('Jumla ya Watumiaji', _formatNumber(s.totalUsers), _navy),
        pw.SizedBox(width: 8),
        _statCard('Wapangishaji', _formatNumber(s.totalSellers), _green),
        pw.SizedBox(width: 8),
        _statCard('Wanunuzi/Wapangaji', _formatNumber(s.totalBuyers), _purple),
        pw.SizedBox(width: 8),
        _statCard('Yanayosubiri Kupitiwa', _formatNumber(s.pendingProperties), _orange),
      ],
    );
  }

  static pw.Widget _statCard(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(6)),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
            pw.SizedBox(height: 6),
            pw.Text(value, style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _periodTable(String title, PdfColor accent, List<pw.TableRow> rows) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: pw.BoxDecoration(
              color: accent,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(6),
                topRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Table(
              columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(1)},
              children: rows,
            ),
          ),
        ],
      ),
    );
  }

  static pw.TableRow _row(String label, int value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(
            _formatNumber(value),
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  // --- Monthly trend chart (line chart drawn manually) -------------------

  static pw.Widget _monthlyChart(List<MonthlyPoint> monthly) {
    if (monthly.isEmpty) {
      return pw.Text('Hakuna data ya kutosha bado', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600));
    }

    const chartWidth = 500.0;
    const chartHeight = 140.0;
    final maxVal = monthly.map((m) => m.total).fold<int>(0, (a, b) => a > b ? a : b);
    final top = maxVal <= 0 ? 10 : (((maxVal / 10).ceil() + 1) * 10);

    double xFor(int index) => monthly.length <= 1 ? 0 : (index / (monthly.length - 1)) * chartWidth;
    double yFor(int value) => (value / top) * chartHeight;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Stack(
            children: [
              pw.SizedBox(
                width: chartWidth,
                height: chartHeight + 16,
                child: pw.CustomPaint(
                  size: const PdfPoint(chartWidth, chartHeight + 16),
                  painter: (canvas, size) {
                    // Grid lines (usawa)
                    canvas
                      ..setColor(PdfColors.grey300)
                      ..setLineWidth(0.5);
                    for (int i = 0; i <= 4; i++) {
                      final y = 16 + (i / 4) * chartHeight;
                      canvas
                        ..moveTo(0, y)
                        ..lineTo(chartWidth, y)
                        ..strokePath();
                    }
                    // Line ya mwenendo
                    canvas
                      ..setColor(_navy)
                      ..setLineWidth(1.5);
                    for (int i = 0; i < monthly.length - 1; i++) {
                      final x1 = xFor(i);
                      final y1 = 16 + chartHeight - yFor(monthly[i].total);
                      final x2 = xFor(i + 1);
                      final y2 = 16 + chartHeight - yFor(monthly[i + 1].total);
                      canvas
                        ..moveTo(x1, y1)
                        ..lineTo(x2, y2)
                        ..strokePath();
                    }
                    // Dots kwenye kila point
                    canvas.setColor(_navy);
                    for (int i = 0; i < monthly.length; i++) {
                      final x = xFor(i);
                      final y = 16 + chartHeight - yFor(monthly[i].total);
                      canvas
                        ..drawEllipse(x, y, 2, 2)
                        ..fillPath();
                    }
                  },
                ),
              ),
              ...monthly.asMap().entries.map((e) {
                final x = xFor(e.key);
                final y = chartHeight - yFor(e.value.total);
                return pw.Positioned(
                  left: x - 10,
                  top: y - 2,
                  child: pw.Text(_formatNumber(e.value.total), style: const pw.TextStyle(fontSize: 6)),
                );
              }),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: monthly
                .map((m) => pw.Text(
                      _shortMonth(m.period),
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  static String _shortMonth(String period) {
    final parts = period.split('-');
    if (parts.length != 2) return period;
    final monthIndex = int.tryParse(parts[1]);
    if (monthIndex == null || monthIndex < 1 || monthIndex > 12) return period;
    return '${_monthNames[monthIndex - 1].substring(0, 3)} ${parts[0].substring(2)}';
  }

  static String _formatNumber(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

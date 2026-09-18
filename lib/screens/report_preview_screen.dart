import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/analytics.dart';
import '../services/pdf_report_service.dart';

class ReportPreviewScreen extends StatelessWidget {
  final String periodLabel;
  final AnalyticsSummary summary;
  final List<MonthlyPoint> monthly;

  const ReportPreviewScreen({
    super.key,
    required this.periodLabel,
    required this.summary,
    required this.monthly,
  });

  @override
  Widget build(BuildContext context) {
    final filename = 'ripoti_ya_${periodLabel.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    return Scaffold(
      appBar: AppBar(title: Text('Ripoti ya $periodLabel')),
      body: PdfPreview(
        build: (format) => PdfReportService.generate(
          periodLabel: periodLabel,
          summary: summary,
          monthly: monthly,
        ),
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
        pdfFileName: filename,
      ),
    );
  }
}

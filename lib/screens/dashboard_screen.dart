import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/analytics.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/stat_card.dart';
import 'report_preview_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  AnalyticsSummary? _summary;
  List<MonthlyPoint> _monthly = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await AuthService().getToken();
      if (token == null) throw ApiException('Hujaingia', 401);
      final api = ApiService(token);
      final summary = await api.getAnalyticsSummary();
      final monthly = await api.getRegistrationsByMonth(months: 12);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _monthly = monthly;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Imeshindikana kupakua data ya dashboard');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _load, child: const Text('Jaribu tena')),
          ],
        ),
      );
    }

    final s = _summary!;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Akaunti', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.6,
            children: [
              StatCard(label: 'Wanunuzi/Wapangaji', value: s.totalBuyers, icon: Icons.person, color: const Color(0xFF6C4AB6)),
              StatCard(label: 'Wapangishaji', value: s.totalSellers, icon: Icons.home_work, color: const Color(0xFF2E9E5B)),
              StatCard(label: 'Jumla Watumiaji', value: s.totalUsers, icon: Icons.people, color: const Color(0xFF0D3B66)),
              StatCard(
                label: 'Matangazo Yanasubiri',
                value: s.pendingProperties,
                icon: Icons.pending_actions,
                color: const Color(0xFFE8871E),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Akaunti Mpya Zilizosajiliwa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _PeriodRow(
            labels: const ['Leo', 'Wiki', 'Mwezi', 'Mwaka'],
            values: [s.registrationsToday, s.registrationsThisWeek, s.registrationsThisMonth, s.registrationsThisYear],
          ),
          const SizedBox(height: 20),
          const Text('Watumiaji Walioingia (Logins)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _PeriodRow(
            labels: const ['Leo', 'Wiki', 'Mwezi', 'Mwaka'],
            values: [s.loginsToday, s.loginsThisWeek, s.loginsThisMonth, s.loginsThisYear],
          ),
          const SizedBox(height: 20),
          const Text('Akaunti Mpya kwa Mwezi (Miezi 12 Iliyopita)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          _buildLegend(),
          const SizedBox(height: 8),
          SizedBox(height: 220, child: _buildMonthlyChart()),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openReportPicker,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Pakua Ripoti (PDF)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D3B66),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _openReportPicker() async {
    if (_summary == null) return;
    final label = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Chagua Muda wa Ripoti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ...['Siku', 'Wiki', 'Mwezi', 'Mwaka'].map(
              (label) => ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text('Ripoti ya $label'),
                onTap: () => Navigator.of(context).pop(label),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (label != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReportPreviewScreen(periodLabel: label, summary: _summary!, monthly: _monthly),
        ),
      );
    }
  }

  Widget _buildLegend() {
    Widget dot(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        );
    return Wrap(
      spacing: 16,
      children: [
        dot(Colors.teal, 'Jumla'),
        dot(Colors.blue, 'Wanunuzi/Wapangaji'),
        dot(Colors.orange, 'Wapangishaji'),
      ],
    );
  }

  Widget _buildMonthlyChart() {
    if (_monthly.isEmpty) return const Center(child: Text('Hakuna data ya kutosha bado'));

    List<FlSpot> spotsFor(int Function(MonthlyPoint) selector) {
      return _monthly
          .asMap()
          .entries
          .map((e) => FlSpot(e.key.toDouble(), selector(e.value).toDouble()))
          .toList();
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= _monthly.length) return const SizedBox.shrink();
                // "2026-01" -> "01/26"
                final parts = _monthly[i].period.split('-');
                final label = parts.length == 2 ? '${parts[1]}/${parts[0].substring(2)}' : _monthly[i].period;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(label, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spotsFor((m) => m.total),
            isCurved: true,
            color: Colors.teal,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: spotsFor((m) => m.buyer),
            isCurved: true,
            color: Colors.blue,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: spotsFor((m) => m.seller),
            isCurved: true,
            color: Colors.orange,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

class _PeriodRow extends StatelessWidget {
  final List<String> labels;
  final List<int> values;
  const _PeriodRow({required this.labels, required this.values});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 8),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Text('${values[i]}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(labels[i], style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

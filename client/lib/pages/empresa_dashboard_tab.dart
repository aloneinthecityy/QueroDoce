import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/empresa.dart';

class EmpresaDashboardTab extends StatelessWidget {
  final Empresa empresa;
  const EmpresaDashboardTab({super.key, required this.empresa});

  static final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  Stream<QuerySnapshot<Map<String, dynamic>>> get _stream =>
      FirebaseFirestore.instance
          .collection('pedidos')
          .where('idEmpresa', isEqualTo: empresa.idEmpresa)
          .snapshots();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFEE0084)),
          );
        }

        final pedidos = snapshot.data?.docs.map((d) => d.data()).toList() ?? [];

        final total = pedidos.length;
        final faturamento = pedidos.fold<double>(
          0,
          (sum, p) => sum + ((p['valorPedido'] as num?)?.toDouble() ?? 0),
        );

        // Contagem por status
        final statusCount = <String, int>{};
        for (final p in pedidos) {
          final s = p['status'] as String? ?? 'recebido';
          statusCount[s] = (statusCount[s] ?? 0) + 1;
        }

        // Contagem por forma de pagamento
        final pagamentoCount = <String, int>{};
        for (final p in pedidos) {
          final pg = p['formaPagamento'] as String? ?? 'Outro';
          pagamentoCount[pg] = (pagamentoCount[pg] ?? 0) + 1;
        }

        // Pedidos por dia — últimos 7 dias
        final hoje = DateTime.now();
        final ultimos7Dias = List.generate(7, (i) {
          final dia = hoje.subtract(Duration(days: 6 - i));
          return DateTime(dia.year, dia.month, dia.day);
        });

        final pedidosPorDia = <DateTime, int>{};
        for (final dia in ultimos7Dias) {
          pedidosPorDia[dia] = 0;
        }
        for (final p in pedidos) {
          final ts = p['dataPedido'];
          if (ts is Timestamp) {
            final data = ts.toDate();
            final diaKey = DateTime(data.year, data.month, data.day);
            if (pedidosPorDia.containsKey(diaKey)) {
              pedidosPorDia[diaKey] = (pedidosPorDia[diaKey] ?? 0) + 1;
            }
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cards de resumo
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    icon: Icons.receipt_long,
                    label: 'Total de pedidos',
                    value: total.toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryCard(
                    icon: Icons.attach_money,
                    label: 'Faturamento',
                    value: _currency.format(faturamento),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Gráfico de linha — pedidos por dia
            _sectionTitle('Pedidos nos últimos 7 dias'),
            const SizedBox(height: 12),
            _lineCard(pedidosPorDia, ultimos7Dias),
            const SizedBox(height: 24),

            // Gráfico de pizza — pedidos por status
            if (statusCount.isNotEmpty) ...[
              _sectionTitle('Pedidos por status'),
              const SizedBox(height: 12),
              _pieCard(statusCount, _statusLabel, _statusColor),
              const SizedBox(height: 24),
            ],

            // Gráfico de barras — formas de pagamento
            if (pagamentoCount.isNotEmpty) ...[
              _sectionTitle('Formas de pagamento'),
              const SizedBox(height: 12),
              _barCard(pagamentoCount),
            ],
          ],
        );
      },
    );
  }

  Widget _lineCard(Map<DateTime, int> pedidosPorDia, List<DateTime> dias) {
    final maxY = pedidosPorDia.values.fold(0, (a, b) => a > b ? a : b).toDouble();
    final labelFormat = DateFormat('dd/MM');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF8CFE5)),
      ),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY < 1 ? 2 : maxY + 1,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: const Color(0xFFF8CFE5),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: (value, _) => Text(
                    value.toInt().toString(),
                    style: GoogleFonts.inter(fontSize: 11),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, _) {
                    final i = value.toInt();
                    if (i < 0 || i >= dias.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        labelFormat.format(dias[i]),
                        style: GoogleFonts.inter(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(dias.length, (i) {
                  return FlSpot(i.toDouble(), pedidosPorDia[dias[i]]!.toDouble());
                }),
                isCurved: true,
                color: const Color(0xFFEE0084),
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 4,
                    color: const Color(0xFFEE0084),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFFEE0084).withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF8CFE5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFEE0084), size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.pixelifySans(
              fontSize: 18,
              color: const Color(0xFF313130),
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.pixelifySans(
        fontSize: 16,
        letterSpacing: 0,
        color: const Color(0xFF313130),
      ),
    );
  }

  Widget _pieCard(
    Map<String, int> data,
    String Function(String) labelFn,
    Color Function(int) colorFn,
  ) {
    final entries = data.entries.toList();
    final total = data.values.fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF8CFE5)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: List.generate(entries.length, (i) {
                  final pct = entries[i].value / total * 100;
                  return PieChartSectionData(
                    value: entries[i].value.toDouble(),
                    color: colorFn(i),
                    title: '${pct.toStringAsFixed(0)}%',
                    radius: 60,
                    titleStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: List.generate(entries.length, (i) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colorFn(i),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${labelFn(entries[i].key)} (${entries[i].value})',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _barCard(Map<String, int> data) {
    final entries = data.entries.toList();
    final maxY = data.values.fold(0, (a, b) => a > b ? a : b).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF8CFE5)),
      ),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            maxY: maxY + 1,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, _) => Text(
                    value.toInt().toString(),
                    style: GoogleFonts.inter(fontSize: 11),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    final i = value.toInt();
                    if (i < 0 || i >= entries.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        entries[i].key,
                        style: GoogleFonts.inter(fontSize: 11),
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(
              entries.length,
              (i) => BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: entries[i].value.toDouble(),
                    color: const Color(0xFFEE0084),
                    width: 28,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'aguardando_entregador': return 'Aguardando';
      case 'aceito': return 'Aceito';
      case 'coletando': return 'Coletando';
      case 'em_entrega': return 'Em entrega';
      case 'entregue': return 'Entregue';
      default: return 'Recebido';
    }
  }

  Color _statusColor(int index) {
    const colors = [
      Color(0xFFEE0084),
      Color(0xFFFF6BC1),
      Color(0xFFFFB3DC),
      Color(0xFFB70062),
      Color(0xFF7A003F),
      Color(0xFFFF91CC),
    ];
    return colors[index % colors.length];
  }
}
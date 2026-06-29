import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class EntregadorDashboardTab extends StatelessWidget {
  const EntregadorDashboardTab({super.key, required this.entregadorId});

  final int entregadorId;

  static final _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  Stream<QuerySnapshot<Map<String, dynamic>>> get _stream =>
      FirebaseFirestore.instance
          .collection('pedidos')
          .where('entregadorId', isEqualTo: entregadorId)
          .snapshots();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF7FC),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFEE0084)),
            );
          }

          if (snapshot.hasError) {
            return _state(
              icon: Icons.cloud_off_outlined,
              title: 'Nao conseguimos carregar seu dashboard',
              message: 'Confira sua conexao e tente novamente em instantes.',
            );
          }

        final pedidos = snapshot.data?.docs.map((d) => d.data()).toList() ?? [];
        pedidos.sort((a, b) {
          final aDate = a['dataPedido'];
          final bDate = b['dataPedido'];
          if (aDate is Timestamp && bDate is Timestamp) {
            return bDate.compareTo(aDate);
          }
          return 0;
        });

        final entregues = pedidos.where((p) {
          return _read(p, 'status') == 'entregue';
        }).toList();
        final andamento = pedidos.where((p) {
          return _isEmAndamento(_read(p, 'status'));
        }).toList();

        final ganhos = entregues.fold<double>(
          0,
          (sum, p) => sum + _readMoney(p, 'taxaEntrega'),
        );

        final statusCount = <String, int>{};
        for (final p in pedidos) {
          final status = _read(p, 'status', fallback: 'aceito');
          statusCount[status] = (statusCount[status] ?? 0) + 1;
        }

        final hoje = DateTime.now();
        final ultimos7Dias = List.generate(7, (i) {
          final dia = hoje.subtract(Duration(days: 6 - i));
          return DateTime(dia.year, dia.month, dia.day);
        });

        final entregasPorDia = <DateTime, int>{};
        final ganhosPorDia = <DateTime, double>{};
        for (final dia in ultimos7Dias) {
          entregasPorDia[dia] = 0;
          ganhosPorDia[dia] = 0;
        }

        for (final p in pedidos) {
          final ts = p['dataPedido'];
          if (ts is! Timestamp) continue;

          final data = ts.toDate();
          final diaKey = DateTime(data.year, data.month, data.day);
          if (!entregasPorDia.containsKey(diaKey)) continue;

          entregasPorDia[diaKey] = (entregasPorDia[diaKey] ?? 0) + 1;
          if (_read(p, 'status') == 'entregue') {
            ganhosPorDia[diaKey] =
                (ganhosPorDia[diaKey] ?? 0) + _readMoney(p, 'taxaEntrega');
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _summaryGrid(
              total: pedidos.length,
              entregues: entregues.length,
              andamento: andamento.length,
              ganhos: ganhos,
            ),
            const SizedBox(height: 24),
            if (pedidos.isEmpty) ...[
              _emptyCard(),
            ] else ...[
              _sectionTitle('Entregas nos ultimos 7 dias'),
              const SizedBox(height: 12),
              _lineCard(entregasPorDia, ultimos7Dias),
              const SizedBox(height: 24),
              if (statusCount.isNotEmpty) ...[
                _sectionTitle('Entregas por status'),
                const SizedBox(height: 12),
                _pieCard(statusCount, _statusLabel, _statusColor),
                const SizedBox(height: 24),
              ],
              _sectionTitle('Ganhos por dia'),
              const SizedBox(height: 12),
              _moneyBarCard(ganhosPorDia, ultimos7Dias),
            ],
          ],
        );
        },
      ),
    );
  }

  Widget _summaryGrid({
    required int total,
    required int entregues,
    required int andamento,
    required double ganhos,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.45,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _summaryCard(
          icon: Icons.route_outlined,
          label: 'Total de entregas',
          value: total.toString(),
        ),
        _summaryCard(
          icon: Icons.check_circle_outline,
          label: 'Concluidas',
          value: entregues.toString(),
        ),
        _summaryCard(
          icon: Icons.timer_outlined,
          label: 'Em andamento',
          value: andamento.toString(),
        ),
        _summaryCard(
          icon: Icons.payments_outlined,
          label: 'Ganhos estimados',
          value: _currency.format(ganhos),
        ),
      ],
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFEE0084), size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.pixelifySans(
                fontSize: 18,
                color: const Color(0xFF313130),
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineCard(Map<DateTime, int> entregasPorDia, List<DateTime> dias) {
    final maxY = entregasPorDia.values
        .fold(0, (a, b) => a > b ? a : b)
        .toDouble();
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
                  return FlSpot(
                    i.toDouble(),
                    entregasPorDia[dias[i]]!.toDouble(),
                  );
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

  Widget _moneyBarCard(Map<DateTime, double> data, List<DateTime> dias) {
    final maxY = data.values.fold(0.0, (a, b) => a > b ? a : b);
    final labelFormat = DateFormat('dd/MM');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF8CFE5)),
      ),
      child: SizedBox(
        height: 210,
        child: BarChart(
          BarChartData(
            maxY: maxY < 1 ? 10 : maxY * 1.25,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 46,
                  getTitlesWidget: (value, _) => Text(
                    _compactMoney(value),
                    style: GoogleFonts.inter(fontSize: 10),
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
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(
              dias.length,
              (i) => BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[dias[i]] ?? 0.0,
                    color: const Color(0xFFEE0084),
                    width: 22,
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

  Widget _emptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF8CFE5)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.insights_outlined,
            size: 46,
            color: Color(0xFFEE0084),
          ),
          const SizedBox(height: 12),
          Text(
            'Sem entregas no dashboard ainda',
            textAlign: TextAlign.center,
            style: GoogleFonts.pixelifySans(
              fontSize: 18,
              color: const Color(0xFF313130),
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Quando voce aceitar entregas, seus indicadores aparecem aqui.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _state({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFEE0084), size: 58),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.pixelifySans(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  String _read(
    Map<String, dynamic> data,
    String key, {
    String fallback = '',
  }) {
    final value = data[key];
    if (value == null || value.toString().trim().isEmpty) return fallback;
    return value.toString();
  }

  double _readMoney(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString().replaceAll(',', '.')) ?? 0;
  }

  bool _isEmAndamento(String status) {
    return status == 'aceito' ||
        status == 'coletando' ||
        status == 'em_entrega';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'aguardando_entregador':
        return 'Aguardando';
      case 'aceito':
        return 'Aceito';
      case 'coletando':
        return 'Coletando';
      case 'em_entrega':
        return 'Em entrega';
      case 'entregue':
        return 'Entregue';
      default:
        return status.isEmpty ? 'Recebido' : status;
    }
  }

  String _compactMoney(double value) {
    if (value >= 1000) {
      return 'R\$${(value / 1000).toStringAsFixed(1)}k';
    }
    return 'R\$${value.toStringAsFixed(0)}';
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

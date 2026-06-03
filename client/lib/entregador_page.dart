import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'controllers/entregador_controller.dart';

class EntregadorPage extends StatefulWidget {
  const EntregadorPage({super.key, required this.entregadorId});

  final int entregadorId;

  @override
  State<EntregadorPage> createState() => _EntregadorPageState();
}

class _EntregadorPageState extends State<EntregadorPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionSubscription;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  static const Color _primaryPink = Color(0xFFEE0084);
  static const Color _brightPink = Color(0xFFFF2BA0);
  static const Color _softPink = Color(0xFFFFF1F8);
  static const Color _darkText = Color(0xFF2F2530);
  static const Color _mutedText = Color(0xFF756A75);

  bool get _temEntregadorValido => widget.entregadorId > 0;

  Stream<QuerySnapshot<Map<String, dynamic>>> get _pedidosDisponiveisStream {
    return _firestore
        .collection('pedidos')
        .where('status', isEqualTo: 'aguardando_entregador')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get _minhasEntregasStream {
    return _firestore
        .collection('pedidos')
        .where('entregadorId', isEqualTo: widget.entregadorId)
        .where('status', whereIn: ['aceito', 'coletando', 'em_entrega'])
        .snapshots();
  }

  Future<void> _aceitarEntrega(String pedidoDocId) async {
    if (!_temEntregadorValido) {
      _showSnackBar(
        'ID do entregador invalido. Saia e faca login novamente.',
        isError: true,
      );
      return;
    }

    try {
      await _firestore.collection('pedidos').doc(pedidoDocId).update({
        'status': 'aceito',
        'entregadorId': widget.entregadorId,
        'id_entregador': widget.entregadorId,
        'entregador_id': widget.entregadorId,
      });

      await EntregadorController.notificarCliente(
        pedidoDocId: pedidoDocId,
        novoStatus: 'aceito',
        firestore: _firestore,
      );

      if (!mounted) return;
      _showSnackBar('Entrega aceita com sucesso!');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Nao foi possivel aceitar a entrega: $e', isError: true);
    }
  }

  Future<void> _iniciarRastreamento(String pedidoDocId) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('Por favor, ative a localização no seu dispositivo.', isError: true);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Permissão de localização negada.', isError: true);
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _showSnackBar('Permissão de localização permanentemente negada.', isError: true);
      return;
    }

    await _pararRastreamento();

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _atualizarLocalizacaoNoFirestore(pedidoDocId, position);
    });
  }

  Future<void> _pararRastreamento() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<void> _atualizarLocalizacaoNoFirestore(String pedidoDocId, Position position) async {
    try {
      await _firestore.collection('pedidos').doc(pedidoDocId).update({
        'localizacaoEntregador': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'atualizadoEm': FieldValue.serverTimestamp(),
        }
      });
    } catch (e) {
      debugPrint('Erro ao atualizar localização: $e');
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _atualizarStatus(String pedidoDocId, String novoStatus) async {
    if (!_temEntregadorValido) {
      _showSnackBar(
        'ID do entregador invalido. Saia e faca login novamente.',
        isError: true,
      );
      return;
    }

    try {
      await _firestore.collection('pedidos').doc(pedidoDocId).update({
        'status': novoStatus,
        'entregadorId': widget.entregadorId,
        'id_entregador': widget.entregadorId,
        'entregador_id': widget.entregadorId,
      });

      await EntregadorController.notificarCliente(
        pedidoDocId: pedidoDocId,
        novoStatus: novoStatus,
        firestore: _firestore,
      );

      if (novoStatus == 'em_entrega') {
        _iniciarRastreamento(pedidoDocId);
      } else if (novoStatus == 'entregue') {
        _pararRastreamento();
      }

      if (!mounted) return;
      _showSnackBar('Status atualizado para ${_statusLabel(novoStatus)}.');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erro ao atualizar status: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red.shade700 : _primaryPink,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: _brightPink,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delivery_dining),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Area do Entregador',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.pixelifySans(
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth >= 900;

            return RefreshIndicator(
              color: _primaryPink,
              onRefresh: () async {
                await Future<void>.delayed(const Duration(milliseconds: 450));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32 : 16,
                  vertical: 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildPedidosDisponiveis()),
                              const SizedBox(width: 20),
                              Expanded(child: _buildMinhasEntregas()),
                            ],
                          )
                        : Column(
                            children: [
                              _buildPedidosDisponiveis(),
                              const SizedBox(height: 24),
                              _buildMinhasEntregas(),
                            ],
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPedidosDisponiveis() {
    return _SectionShell(
      icon: Icons.local_shipping_outlined,
      title: 'Pedidos Disponiveis',
      subtitle: 'Entregas aguardando um entregador',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _pedidosDisponiveisStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }

          if (snapshot.hasError) {
            return _buildStateMessage(
              icon: Icons.wifi_off_rounded,
              title: 'Erro de conexao',
              message: 'Nao foi possivel carregar os pedidos disponiveis.',
            );
          }

          final pedidos = snapshot.data?.docs ?? [];
          if (pedidos.isEmpty) {
            return _buildStateMessage(
              icon: Icons.inbox_outlined,
              title: 'Nenhum pedido disponivel',
              message: 'Novos pedidos aparecerao aqui em tempo real.',
            );
          }

          return Column(
            children: pedidos.map((doc) {
              return _PedidoCard(
                data: doc.data(),
                currencyFormat: _currencyFormat,
                statusLabel: _statusLabel,
                initiallyExpanded: false,
                trailing: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _aceitarEntrega(doc.id),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Aceitar Entrega'),
                    style: _primaryButtonStyle(),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildMinhasEntregas() {
    return _SectionShell(
      icon: Icons.two_wheeler_rounded,
      title: 'Minhas Entregas',
      subtitle: 'Pedidos aceitos e em andamento',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _minhasEntregasStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }

          if (snapshot.hasError) {
            return _buildStateMessage(
              icon: Icons.cloud_off_rounded,
              title: 'Erro de conexao',
              message: 'Nao foi possivel carregar suas entregas.',
            );
          }

          final entregas = snapshot.data?.docs ?? [];
          if (entregas.isEmpty) {
            return _buildStateMessage(
              icon: Icons.assignment_turned_in_outlined,
              title: 'Você ainda não tem entregas',
              message: 'Aceite um pedido para acompanhar o andamento aqui.',
            );
          }

          return Column(
            children: entregas.map((doc) {
              final data = doc.data();
              final status = (data['status'] ?? '').toString();

              return _PedidoCard(
                data: data,
                currencyFormat: _currencyFormat,
                statusLabel: _statusLabel,
                showStatus: true,
                initiallyExpanded: false,
                trailing: _buildStatusAction(doc.id, status),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildStatusAction(String pedidoDocId, String status) {
    final action = _nextStatusAction(status);
    if (action == null) {
      return _DeliveredBanner(statusLabel: _statusLabel(status));
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _atualizarStatus(pedidoDocId, action.nextStatus),
        icon: Icon(action.icon),
        label: Text(action.label),
        style: _primaryButtonStyle(),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: _primaryPink,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Center(child: CircularProgressIndicator(color: _primaryPink)),
    );
  }

  Widget _buildStateMessage({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: _softPink,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF8CFE5)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 38, color: _primaryPink),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _darkText,
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _mutedText, fontSize: 13),
          ),
        ],
      ),
    );
  }

  _StatusAction? _nextStatusAction(String status) {
    switch (status) {
      case 'aceito':
        return const _StatusAction(
          label: 'Pedido Coletado',
          nextStatus: 'coletando',
          icon: Icons.shopping_bag_outlined,
        );
      case 'coletando':
        return const _StatusAction(
          label: 'Iniciar Entrega',
          nextStatus: 'em_entrega',
          icon: Icons.route_outlined,
        );
      case 'em_entrega':
        return const _StatusAction(
          label: 'Finalizar Entrega',
          nextStatus: 'entregue',
          icon: Icons.flag_outlined,
        );
      default:
        return null;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'aguardando_entregador':
        return 'Aguardando entregador';
      case 'aceito':
        return 'Aceito';
      case 'coletando':
        return 'Coletando';
      case 'em_entrega':
        return 'Em entrega';
      case 'entregue':
        return 'Entregue';
      default:
        return 'Status desconhecido';
    }
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFEE0084), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4F2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: const Color(0xFFEE0084)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.pixelifySans(
                          color: Color(0xFF2F2530),
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: Color(0xFF756A75),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _PedidoCard extends StatefulWidget {
  const _PedidoCard({
    required this.data,
    required this.currencyFormat,
    required this.statusLabel,
    required this.trailing,
    this.showStatus = false,
    this.initiallyExpanded = false,
  });

  final Map<String, dynamic> data;
  final NumberFormat currencyFormat;
  final String Function(String status) statusLabel;
  final Widget trailing;
  final bool showStatus;
  final bool initiallyExpanded;

  @override
  State<_PedidoCard> createState() => _PedidoCardState();
}

class _PedidoCardState extends State<_PedidoCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final nomeEmpresa = _readString('nomeEmpresa');
    final nomeCliente = _readString('nomeCliente');
    final endereco = _readString('enderecoEntrega');
    final idPedido = _readString('idPedido');
    final status = _readString('status');
    final valor = widget.data['valorPedido'];
    final valorText = valor is num
        ? widget.currencyFormat.format(valor)
        : widget.currencyFormat.format(0);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1DCE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: Color(0xFFEE0084),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomeEmpresa,
                      style: GoogleFonts.pixelifySans(
                        color: Color(0xFF2F2530),
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      idPedido.isEmpty
                          ? 'Pedido sem codigo'
                          : 'Pedido $idPedido',
                      style: GoogleFonts.inter(
                        color: Color(0xFF756A75),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.showStatus)
                _StatusPill(label: widget.statusLabel(status)),
            ],
          ),
          const SizedBox(height: 12),
          _InfoLine(
            icon: Icons.payments_outlined,
            label: 'Valor',
            value: valorText,
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  _InfoLine(
                    icon: Icons.person_outline,
                    label: 'Cliente',
                    value: nomeCliente,
                  ),
                  const SizedBox(height: 10),
                  _InfoLine(
                    icon: Icons.location_on_outlined,
                    label: 'Entrega',
                    value: endereco,
                  ),
                  const SizedBox(height: 16),
                  widget.trailing,
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 19,
              ),
              label: Text(_expanded ? 'Ver menos' : 'Ver mais'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEE0084),
                side: const BorderSide(color: Color(0xFFF8CFE5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _readString(String key) {
    final value = widget.data[key];
    if (value == null) return '';
    return value.toString();
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: const Color(0xFFEE0084)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Color(0xFF3B323B),
                fontSize: 14,
                height: 1.25,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(
                  text: value.isEmpty ? 'Nao informado' : value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4F2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFFB70062),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DeliveredBanner extends StatelessWidget {
  const _DeliveredBanner({required this.statusLabel});

  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8EF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB7E4C7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF238B45)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusLabel,
              style: const TextStyle(
                color: Color(0xFF1F6F3A),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusAction {
  const _StatusAction({
    required this.label,
    required this.nextStatus,
    required this.icon,
  });

  final String label;
  final String nextStatus;
  final IconData icon;
}

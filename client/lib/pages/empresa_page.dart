import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/empresa.dart';
import '../main.dart';
import 'empresa_produtos_tab.dart';
import 'empresa_perfil_tab.dart';
import 'empresa_dashboard_tab.dart';

class EmpresaPage extends StatefulWidget {
  final Empresa empresa;

  const EmpresaPage({super.key, required this.empresa});

  @override
  State<EmpresaPage> createState() => _EmpresaPageState();
}

class _EmpresaPageState extends State<EmpresaPage> {
  late Empresa _empresa;
  int _selectedIndex = 0;
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _empresa = widget.empresa;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get _pedidosStream {
    return FirebaseFirestore.instance
        .collection('pedidos')
        .where('idEmpresa', isEqualTo: _empresa.idEmpresa)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyWidget;
    switch (_selectedIndex) {
      case 0:
        bodyWidget = _buildPedidosTab();
        break;
      case 1:
        bodyWidget = EmpresaProdutosTab(empresa: _empresa);
        break;
      case 2:
        bodyWidget = EmpresaDashboardTab(empresa: _empresa);
        break;
      case 3:
        bodyWidget = EmpresaPerfilTab(
          empresa: _empresa,
          onProfileUpdated: (updatedEmpresa) {
            setState(() {
              _empresa = updatedEmpresa;
            });
          },
        );
        break;
      default:
        bodyWidget = _buildPedidosTab();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFFF2BA0),
        title: Row(
          children: [
            const Icon(Icons.storefront),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _empresa.nmEmpresa,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.pixelifySans(
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: bodyWidget,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFF2BA0),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.receipt_long, "Pedidos", _selectedIndex == 0, () {
                setState(() => _selectedIndex = 0);
              }),
              _buildNavItem(Icons.cookie_outlined, "Doces", _selectedIndex == 1, () {
                setState(() => _selectedIndex = 1);
              }),
              _buildNavItem(Icons.bar_chart, "Dashboard", _selectedIndex == 2, () {
                setState(() => _selectedIndex = 2);
              }),
              _buildNavItem(Icons.person, "Perfil", _selectedIndex == 3, () {
                setState(() => _selectedIndex = 3);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.pixelifySans(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPedidosTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _pedidosStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFEE0084)),
          );
        }

        if (snapshot.hasError) {
          return _state(
            icon: Icons.cloud_off_outlined,
            title: 'Nao conseguimos carregar seus pedidos',
            message:
                'Confira sua conexao e tente novamente em instantes.',
          );
        }

        final pedidos = snapshot.data?.docs.toList() ?? [];
        pedidos.sort((a, b) {
          final aDate = a.data()['dataPedido'];
          final bDate = b.data()['dataPedido'];
          if (aDate is Timestamp && bDate is Timestamp) {
            return bDate.compareTo(aDate);
          }
          return 0;
        });

        if (pedidos.isEmpty) {
          return _state(
            icon: Icons.receipt_long_outlined,
            title: 'Nenhum pedido recebido',
            message: 'Os pedidos finalizados pelos clientes aparecem aqui.',
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: pedidos.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (_, index) => _pedidoCard(pedidos[index].data()),
            ),
          ),
        );
      },
    );
  }

  Widget _pedidoCard(Map<String, dynamic> pedido) {
    final valor = pedido['valorPedido'];
    final itens = pedido['itens'];
    final itensList = itens is List ? itens : const [];

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
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Color(0xFFEE0084)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pedido ${_read(pedido, 'idPedido', fallback: pedido.hashCode.toString())}',
                  style: GoogleFonts.pixelifySans(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF313130),
                    letterSpacing: 0,
                  ),
                ),
              ),
              _statusPill(_read(pedido, 'status')),
            ],
          ),
          const SizedBox(height: 12),
          _info(Icons.person_outline, _read(pedido, 'nomeCliente')),
          const SizedBox(height: 8),
          _info(Icons.location_on_outlined, _read(pedido, 'enderecoEntrega')),
          const SizedBox(height: 8),
          _info(
            Icons.payments_outlined,
            valor is num ? _currencyFormat.format(valor) : 'Valor indisponível',
          ),
          const SizedBox(height: 12),
          Text(
            'Itens',
            style: GoogleFonts.pixelifySans(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          ...itensList.map((item) {
            final itemMap = item is Map ? item : const {};
            return Text(
              '${itemMap['quantidade'] ?? 1}x ${itemMap['nomeProduto'] ?? 'Produto'}',
              style: GoogleFonts.inter(color: Colors.grey.shade700),
            );
          }),
        ],
      ),
    );
  }

  Widget _statusPill(String status) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _statusLabel(status),
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.pixelifySans(
          color: const Color(0xFFB70062),
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
      ),
    );
  }

  Widget _info(IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFFEE0084)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value.isEmpty ? 'Não informado' : value,
            style: GoogleFonts.inter(fontSize: 13),
          ),
        ),
      ],
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

  String _read(Map<String, dynamic> data, String key, {String fallback = ''}) {
    final value = data[key];
    if (value == null || value.toString().trim().isEmpty) return fallback;
    return value.toString();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'aguardando_entregador': return 'Aguardando entregador';
      case 'aceito': return 'Aceito';
      case 'coletando': return 'Coletando';
      case 'em_entrega': return 'Em entrega';
      case 'entregue': return 'Entregue';
      default: return status;
    }
  }
}

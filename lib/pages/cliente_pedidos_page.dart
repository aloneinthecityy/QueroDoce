import 'package:app/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ClientePedidosPage extends StatelessWidget {
  ClientePedidosPage({super.key});

  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  Stream<QuerySnapshot<Map<String, dynamic>>> _pedidosStream(int idCliente) {
    // Firestore esperado:
    // Colecao: pedidos
    // Campos principais: idCliente, idPedido, nomeEmpresa, enderecoEntrega,
    // valorPedido, taxaEntrega, status, dataPedido e itens.
    return FirebaseFirestore.instance
        .collection('pedidos')
        .where('idCliente', isEqualTo: idCliente)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = AuthService.usuarioLogado;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFFFF2BA0),
        title: Text(
          'Meus pedidos',
          style: GoogleFonts.pixelifySans(
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
        ),
      ),
      body: usuario == null
          ? _emptyState(
              icon: Icons.person_off_outlined,
              title: 'Entre para ver seus pedidos',
              message: 'Faca login como cliente para acompanhar suas compras.',
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _pedidosStream(usuario.idPessoa),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFEE0084)),
                  );
                }

                if (snapshot.hasError) {
                  return _emptyState(
                    icon: Icons.cloud_off_outlined,
                    title: 'Erro ao carregar',
                    message: 'Nao foi possivel buscar seus pedidos agora.',
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
                  return _emptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Nenhum pedido ainda',
                    message:
                        'Quando voce finalizar uma compra, ela aparece aqui.',
                  );
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: pedidos.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _pedidoCard(pedidos[index].data());
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _pedidoCard(Map<String, dynamic> pedido) {
    final itens = pedido['itens'];
    final itensList = itens is List ? itens : const [];
    final valor = pedido['valorPedido'];
    final dataPedido = pedido['dataPedido'];

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.storefront_outlined, color: Color(0xFFEE0084)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _read(pedido, 'nomeEmpresa', fallback: 'Empresa'),
                      style: GoogleFonts.pixelifySans(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF313130),
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDate(dataPedido),
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _statusPill(_read(pedido, 'status')),
            ],
          ),
          const SizedBox(height: 14),
          _info(
            Icons.location_on_outlined,
            _read(
              pedido,
              'enderecoEntrega',
              fallback: 'Endereco nao informado',
            ),
          ),
          const SizedBox(height: 10),
          _info(
            Icons.payments_outlined,
            valor is num ? _currencyFormat.format(valor) : 'Valor indisponivel',
          ),
          const SizedBox(height: 14),
          Text(
            'Itens do pedido',
            style: GoogleFonts.pixelifySans(
              fontWeight: FontWeight.w400,
              fontSize: 15,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          ...itensList.map((item) {
            final itemMap = item is Map ? item : const {};
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${itemMap['quantidade'] ?? 1}x ${itemMap['nomeProduto'] ?? 'Produto'}',
                style: GoogleFonts.inter(color: Colors.grey.shade700),
              ),
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

  Widget _info(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFEE0084), size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 13))),
      ],
    );
  }

  Widget _emptyState({
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
            Icon(icon, size: 58, color: const Color(0xFFEE0084)),
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
        return 'Recebido';
    }
  }

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      return DateFormat('dd/MM/yyyy HH:mm').format(value.toDate());
    }
    return 'Data indisponivel';
  }
}

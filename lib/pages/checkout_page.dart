import 'package:app/models/carrinho_item.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../utils/html_image.dart';

class CheckoutPage extends StatefulWidget {
  final List<CarrinhoItem> itens;
  final double subtotal;
  final double taxaEntrega;
  final double total;
  final String tipoEntrega;

  const CheckoutPage({
    super.key,
    required this.itens,
    required this.subtotal,
    required this.taxaEntrega,
    required this.total,
    required this.tipoEntrega,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // Forma de pagamento de exemplo
  final String _formaPagamento = "Pix";
  bool _incluirCpf = false;

  // Formatador de moeda
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FC),
      appBar: _buildAppBar("Tela de pagamento/revisão"),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informações da loja
                  if (widget.itens.isNotEmpty &&
                      widget.itens.first.nmEmpresa != null)
                    _buildStoreInfo(widget.itens.first.nmEmpresa!),
                  const SizedBox(height: 16),

                  // Forma de pagamento
                  _buildPaymentMethodSection(),
                  const SizedBox(height: 24),

                  // Resumo de valores
                  _buildValueSummarySection(),
                  const SizedBox(height: 24),

                  // CPF na nota
                  _buildCpfOnReceiptSection(),
                  const SizedBox(height: 32),

                  // Revisão dos itens (Opcional, mas útil para o contexto)
                  _buildItemsReviewSection(),
                ],
              ),
            ),
          ),
          // Footer com botão Revisar Pedido
          _buildFooterButton(context),
        ],
      ),
    );
  }

  // Widget para a AppBar
  PreferredSizeWidget _buildAppBar(String title) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFFFF2BA0)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "SACOLA",
            style: GoogleFonts.pixelifySans(
              fontSize: 20,
              color: const Color(0xFFFF2BA0),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.shopping_bag, color: Color(0xFFFF2BA0)),
        ],
      ),
      actions: const [
        // Placeholder
        SizedBox(width: 50),
      ],
    );
  }

  // Widget para informações da loja (reutilizado do CartPage)
  Widget _buildStoreInfo(String nomeLoja) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Ícone ou Logo da Loja (Placeholder)
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFFFB3D9),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                nomeLoja.isNotEmpty ? nomeLoja[0].toUpperCase() : 'L',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF2BA0),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nomeLoja,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para a seção de forma de pagamento
  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Forma de pagamento",
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/icons/logo-pix.png',
                    width: 22,
                    height: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formaPagamento,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  // TODO: Implementar lógica para trocar/selecionar forma de pagamento
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Funcionalidade de troca de pagamento em desenvolvimento',
                      ),
                    ),
                  );
                },
                child: Text(
                  "Trocar",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFFFF2BA0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget para a seção de resumo de valores
  Widget _buildValueSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Resumo de valores",
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildResumoLinha("Subtotal", widget.subtotal),
        const SizedBox(height: 8),
        _buildResumoLinha(
          "Taxa de entrega",
          widget.taxaEntrega,
          isFree: widget.taxaEntrega == 0.0,
        ),
        const SizedBox(height: 8),
        _buildResumoLinha("Total", widget.total, isBold: true),
      ],
    );
  }

  // Widget para a seção CPF na Nota
  Widget _buildCpfOnReceiptSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _incluirCpf,
                      onChanged: (bool? newValue) {
                        setState(() {
                          _incluirCpf = newValue ?? false;
                        });
                      },
                      activeColor: const Color(0xFFFF2BA0),
                    ),
                    const Text('CPF na nota?'),
                  ],
                ),
                Text(
                  'Opcional',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (_incluirCpf)
            GestureDetector(
              onTap: () {
                // TODO: Implementar lógica para adicionar/editar CPF
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Funcionalidade de Adicionar CPF em desenvolvimento',
                    ),
                  ),
                );
              },
              child: Text(
                "Adicionar",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFFFF2BA0),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Linha do resumo de valores
  Widget _buildResumoLinha(
    String label,
    double valor, {
    bool isBold = false,
    bool isFree = false,
  }) {
    final valorText = isFree && valor == 0.0
        ? "Grátis"
        : _currencyFormat.format(valor);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
        Text(
          valorText,
          style: GoogleFonts.inter(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isFree && valor == 0.0
                ? const Color(0xFF4CAF50)
                : Colors.black87,
          ),
        ),
      ],
    );
  }

  // Widget para revisão dos itens (simplificado)
  Widget _buildItemsReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Itens no Pedido (${widget.itens.length})",
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.itens.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "${item.nuQtd}x ${item.nmProduto ?? 'Produto'}",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Text(
                  _currencyFormat.format(item.totalItem),
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Footer com o botão principal
  Widget _buildFooterButton(BuildContext context) {
    final valorText = _currencyFormat.format(widget.total);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Pedido finalizado no valor de $valorText, forma de entrega: ${widget.tipoEntrega}.',
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF2BA0),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            "Revisar pedido $valorText",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

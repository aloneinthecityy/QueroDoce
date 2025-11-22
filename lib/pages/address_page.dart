import 'package:app/models/carrinho_item.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'checkout_page.dart'; // Próxima tela
// Para acessar os getters de subtotal/total

class AddressPage extends StatefulWidget {
  final List<CarrinhoItem> itens;
  final double subtotal;
  final double taxaEntrega;
  final double total;

  const AddressPage({
    super.key,
    required this.itens,
    required this.subtotal,
    required this.taxaEntrega,
    required this.total,
  });

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  // 0: Entrega, 1: Retirada na loja
  int _selectedDeliveryOption = 0; 
  // Endereço e loja de exemplo (devem vir de models/controllers reais)
  final String _enderecoEntrega = "Rua Goiabeira, 208\nJardim do Bosque - Casa";
  final String _nomeLoja = "Gleiciane Bolos e Cia"; 
  final String _enderecoLoja = "Rua do Comércio, 500\nCentro - Loja 10"; 

  // Formatador de moeda
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FC),
      appBar: _buildAppBar("Tela de endereço"),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Detalhe do endereço
                  _buildAddressSection(),
                  const SizedBox(height: 24),

                  Text(
                    "Opções de entrega",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Opção de Entrega (Delivery)
                  _buildDeliveryOption(
                    index: 0,
                    title: "Padrão",
                    description: "Hoje, 30 - 50min",
                    price: widget.taxaEntrega,
                  ),
                  const SizedBox(height: 12),

                  // Opção de Retirada na loja
                  _buildDeliveryOption(
                    index: 1,
                    title: "Retirar na loja",
                    description: "Hoje, 30 - 50min",
                    price: 0.00,
                    isFree: true,
                  ),

                  const SizedBox(height: 32),
                  const Divider(),

                  // Resumo de valores (para consistência)
                  _buildValueSummary(),
                ],
              ),
            ),
          ),
          // Footer com botão continuar
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
      actions: [
        // Placeholder para manter o espaçamento consistente se necessário
        const SizedBox(width: 50), 
      ],
    );
  }

  // Widget para a seção de endereço
  Widget _buildAddressSection() {
    final endereco = _selectedDeliveryOption == 0 ? _enderecoEntrega : _enderecoLoja;
    final titulo = _selectedDeliveryOption == 0 ? "Entregar no endereço" : "Retirar na loja: $_nomeLoja";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB3D9), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: Implementar lógica para trocar/selecionar endereço ou loja
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funcionalidade de troca de endereço em desenvolvimento')),
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
          const SizedBox(height: 8),
          Text(
            endereco,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Widget para as opções de entrega
  Widget _buildDeliveryOption({
    required int index,
    required String title,
    required String description,
    required double price,
    bool isFree = false,
  }) {
    final isSelected = _selectedDeliveryOption == index;
    final priceText = isFree ? "Grátis" : _currencyFormat.format(price);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDeliveryOption = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF2BA0) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  priceText,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isFree ? const Color(0xFF4CAF50) : Colors.black87,
                    fontWeight: isFree ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 8),
                Radio<int>(
                  value: index,
                  groupValue: _selectedDeliveryOption,
                  onChanged: (int? value) {
                    if (value != null) {
                      setState(() {
                        _selectedDeliveryOption = value;
                      });
                    }
                  },
                  activeColor: const Color(0xFFFF2BA0),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget para o resumo de valores
  Widget _buildValueSummary() {
    final totalAposEntrega = widget.subtotal + 
      (_selectedDeliveryOption == 0 ? widget.taxaEntrega : 0.0);

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
          _selectedDeliveryOption == 0 ? widget.taxaEntrega : 0.0,
          isFree: _selectedDeliveryOption == 1,
        ),
        const SizedBox(height: 8),
        _buildResumoLinha("Total", totalAposEntrega, isBold: true),
      ],
    );
  }

  // Linha do resumo de valores
  Widget _buildResumoLinha(String label, double valor, {bool isBold = false, bool isFree = false}) {
    final valorText = isFree && valor == 0.0 ? "Grátis" : _currencyFormat.format(valor);

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
            color: isFree && valor == 0.0 ? const Color(0xFF4CAF50) : Colors.black87,
          ),
        ),
      ],
    );
  }

  // Footer com o botão principal
  Widget _buildFooterButton(BuildContext context) {
    final totalAposEntrega = widget.subtotal + 
      (_selectedDeliveryOption == 0 ? widget.taxaEntrega : 0.0);
    final valorText = _currencyFormat.format(totalAposEntrega);

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
            // Navegar para a tela de Pagamento/Revisão
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CheckoutPage(
                  itens: widget.itens,
                  subtotal: widget.subtotal,
                  taxaEntrega: _selectedDeliveryOption == 0 ? widget.taxaEntrega : 0.0,
                  total: totalAposEntrega,
                  tipoEntrega: _selectedDeliveryOption == 0 ? 'Entrega Padrão' : 'Retirada na Loja',
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
            "Continuar",
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
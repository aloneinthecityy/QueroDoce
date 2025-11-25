import 'dart:convert';

import 'package:app/controllers/empresa_controller.dart';
import 'package:app/controllers/pessoa_controller.dart';
import 'package:app/models/carrinho_item.dart';
import 'package:app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'checkout_page.dart';

class AddressPage extends StatefulWidget {
  final List<CarrinhoItem> itens;
  final double subtotal;
  final double taxaEntrega;
  final double total;
  final int idEmpresa;

  const AddressPage({
    super.key,
    required this.itens,
    required this.subtotal,
    required this.taxaEntrega,
    required this.total,
    required this.idEmpresa,
  });

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  int _opcaoEntrega = 0; // 0: Entrega, 1: Retirada na loja
  String _enderecoEntrega = "";
  String _nomeLoja = "";
  String _enderecoLoja = "";
  bool isLoading = true;

  late final NumberFormat _currencyFormat;
  late int idEmpresa;

  @override
  void initState() {
    super.initState();
    _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    idEmpresa = widget.idEmpresa;
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => isLoading = true);

    final usuario = AuthService.usuarioLogado;

    try {
      if (usuario != null) {
        String? ruaLogradouro;

        if (usuario.nuCep.isNotEmpty) {
          try {
            final cep = usuario.nuCep.replaceAll(RegExp(r'\D'), '');

            if (cep.length == 8) {
              final url = Uri.parse('https://viacep.com.br/ws/$cep/json/');
              final response = await http.get(url);

              if (response.statusCode == 200) {
                final data = json.decode(response.body);

                if (data['erro'] == null && data['logradouro'] != null) {
                  ruaLogradouro = data['logradouro'].toString().trim();
                }
              }
            }
          } catch (e) {
            print('Erro ao consultar CEP: $e');
          }
        }

        // ====== MONTA ENDEREÇO DO USUÁRIO ======
        if (ruaLogradouro != null && ruaLogradouro.isNotEmpty) {
          final numero = (usuario.nuEndereco != null && usuario.nuEndereco! > 0)
              ? ', ${usuario.nuEndereco}'
              : '';

          _enderecoEntrega = '$ruaLogradouro$numero';
        } else {
          final enderecoData = await PessoaController.buscarEndereco(
            usuario.idPessoa,
          );

          _enderecoEntrega = enderecoData ?? usuario.enderecoFormatado;
        }
      }

      final loja = await EmpresaController.buscarEmpresa(idEmpresa);

      if (loja != null) {
        _nomeLoja = loja.nmEmpresa;

        String ruaLoja = "";

        try {
          final cepLoja = loja.nuCep.replaceAll(RegExp(r'\D'), '');
          if (cepLoja.length == 8) {
            final urlLoja = Uri.parse(
              'https://viacep.com.br/ws/$cepLoja/json/',
            );
            final responseLoja = await http.get(urlLoja);

            if (responseLoja.statusCode == 200) {
              final dataLoja = json.decode(responseLoja.body);
              if (dataLoja['erro'] == null && dataLoja['logradouro'] != null) {
                ruaLoja = dataLoja['logradouro'].toString().trim();
              }
            }
          }
        } catch (e) {
          print('Erro ao consultar CEP da loja: $e');
        }

        final numeroLoja = (loja.nuEndereco > 0) ? ', ${loja.nuEndereco}' : '';

        final complementoLoja = (loja.dsComplemento.isNotEmpty)
            ? ' - ${loja.dsComplemento}'
            : '';

        _enderecoLoja = "$ruaLoja$numeroLoja$complementoLoja";
      } else {
        _nomeLoja = "Loja não encontrada";
        _enderecoLoja = "";
      }
    } catch (e) {
      print("Erro no carregamento de dados: $e");
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF2BA0)),
        ),
      );
    }

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
                  _buildDeliveryOption(
                    index: 0,
                    title: "Padrão",
                    description: "Hoje, 30 - 50min",
                    price: widget.taxaEntrega,
                  ),
                  const SizedBox(height: 12),
                  _buildDeliveryOption(
                    index: 1,
                    title: "Retirar na loja",
                    description: "Hoje, 30 - 50min",
                    price: 0.00,
                    isFree: true,
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  _buildValueSummary(),
                ],
              ),
            ),
          ),
          _buildFooterButton(context),
        ],
      ),
    );
  }

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
      actions: const [SizedBox(width: 50)],
    );
  }

  Widget _buildAddressSection() {
    final endereco = _opcaoEntrega == 0 ? _enderecoEntrega : _enderecoLoja;
    final titulo = _opcaoEntrega == 0
        ? "Entregar no endereço"
        : "Retirar na loja: $_nomeLoja";

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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Funcionalidade de troca de endereço em desenvolvimento',
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
          const SizedBox(height: 8),
          Text(
            endereco,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOption({
    required int index,
    required String title,
    required String description,
    required double price,
    bool isFree = false,
  }) {
    final isSelected = _opcaoEntrega == index;
    final priceText = isFree ? "Grátis" : _currencyFormat.format(price);

    return GestureDetector(
      onTap: () => setState(() => _opcaoEntrega = index),
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
                    fontWeight: isFree ? FontWeight.bold : FontWeight.normal,
                    color: isFree ? const Color(0xFF4CAF50) : Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Radio<int>(
                  value: index,
                  // ignore: deprecated_member_use
                  groupValue: _opcaoEntrega,
                  // ignore: deprecated_member_use
                  onChanged: (value) => setState(() => _opcaoEntrega = value!),
                  activeColor: const Color(0xFFFF2BA0),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueSummary() {
    final totalAposEntrega =
        widget.subtotal + (_opcaoEntrega == 0 ? widget.taxaEntrega : 0.0);

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
          _opcaoEntrega == 0 ? widget.taxaEntrega : 0.0,
          isFree: _opcaoEntrega == 1,
        ),
        const SizedBox(height: 8),
        _buildResumoLinha("Total", totalAposEntrega, isBold: true),
      ],
    );
  }

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

  Widget _buildFooterButton(BuildContext context) {
    final totalAposEntrega =
        widget.subtotal + (_opcaoEntrega == 0 ? widget.taxaEntrega : 0.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CheckoutPage(
                  itens: widget.itens,
                  subtotal: widget.subtotal,
                  taxaEntrega: _opcaoEntrega == 0 ? widget.taxaEntrega : 0.0,
                  total: totalAposEntrega,
                  tipoEntrega: _opcaoEntrega == 0
                      ? 'Entrega Padrão'
                      : 'Retirada na Loja',
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

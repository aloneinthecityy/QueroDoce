import 'package:app/pages/address_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/carrinho_item.dart';
import '../controllers/carrinho_controller.dart';
import '../services/auth_service.dart';
import '../utils/html_image.dart' as html_image;

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<CarrinhoItem> itens = [];
  bool isLoading = true;
  bool _removendo = false;

  @override
  void initState() {
    super.initState();
    _carregarItens();
  }

  Future<void> _carregarItens() async {
    final usuario = AuthService.usuarioLogado;
    if (usuario == null) {
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);
    final itensData = await CarrinhoController.listarItens(usuario.idPessoa);
    setState(() {
      itens = itensData;
      isLoading = false;
    });
  }

  Future<void> _alterarQuantidade(CarrinhoItem item, int novaQuantidade) async {
    final usuario = AuthService.usuarioLogado;
    if (usuario == null) return;

    setState(() {
      item.nuQtd = novaQuantidade;
    });

    await CarrinhoController.alterarQuantidade(
      usuario.idPessoa,
      item.idProduto,
      novaQuantidade,
    );
  }

  Future<void> _removerItem(CarrinhoItem item) async {
    final usuario = AuthService.usuarioLogado;
    if (usuario == null) return;

    if (item.nuQtd > 1) {
      setState(() {
        item.nuQtd -= 1;
      });

      await CarrinhoController.removerItem(usuario.idPessoa, item.idProduto);
    } else {
      setState(() {
        itens.removeWhere((i) => i.idProduto == item.idProduto);
      });

      await CarrinhoController.removerItem(usuario.idPessoa, item.idProduto);
    }
  }

  Future<void> _limparCarrinho() async {
    final usuario = AuthService.usuarioLogado;
    if (usuario == null) return;

    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Esvaziar carrinho'),
        content: const Text('Tem certeza que deseja remover todos os itens?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmacao == true) {
      final sucesso = await CarrinhoController.limparCarrinho(usuario.idPessoa);
      if (sucesso) {
        _carregarItens();
      }
    }
  }

  double get _subtotal {
    return itens.fold(0, (sum, item) => sum + item.totalItem);
  }

  double get _taxaEntrega => 5.00;

  double get _total => _subtotal + _taxaEntrega;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FC),
      appBar: AppBar(
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
          if (itens.isNotEmpty)
            TextButton(
              onPressed: _limparCarrinho,
              child: Text(
                "esvaziar",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFFFFB3D9),
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF2BA0)),
            )
          : itens.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sua sacola está vazia',
                    style: GoogleFonts.inter(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Informações da loja (agrupando por empresa)
                        if (itens.isNotEmpty && itens.first.nmEmpresa != null)
                          _buildStoreInfo(itens.first.nmEmpresa!),
                        const SizedBox(height: 16),

                        // Itens adicionados
                        Text(
                          "Itens adicionados",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Lista de itens
                        ...itens.map((item) => _buildItemCard(item)),

                        const SizedBox(height: 16),
                        const Divider(),

                        // Resumo de valores
                        Text(
                          "Resumo de valores",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildResumoLinha("Subtotal", _subtotal),
                        const SizedBox(height: 8),
                        _buildResumoLinha("Taxa de entrega", _taxaEntrega),
                        const SizedBox(height: 8),
                        _buildResumoLinha("Total", _total, isBold: true),
                      ],
                    ),
                  ),
                ),

                // Footer com botão continuar
                Container(
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
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Valor total da compra",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            "R\$ ${_total.toStringAsFixed(2)} / ${itens.length} ${itens.length == 1 ? 'item' : 'itens'}",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Navegar para a tela de checkout
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddressPage(
                                  itens: itens, // sua lista de itens
                                  subtotal: _subtotal,
                                  taxaEntrega: _taxaEntrega,
                                  total: _total,
                                  idEmpresa: itens.first.idEmpresa,
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
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStoreInfo(String nomeLoja) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB3D9),
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

  Widget _buildItemCard(CarrinhoItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Imagem do produto
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: item.nmImagem != null && item.nmImagem!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildHtmlImage(_getImageUrl(item.nmImagem!)),
                  )
                : const Icon(Icons.image, size: 30),
          ),
          const SizedBox(width: 12),
          // Informações do produto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nmProduto ?? 'Produto',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (item.dsProduto != null && item.dsProduto!.isNotEmpty)
                  Text(
                    item.dsProduto!.length > 30
                        ? '${item.dsProduto!.substring(0, 30)}...'
                        : item.dsProduto!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Controles de quantidade
          Row(
            children: [
              GestureDetector(
                onTap: _removendo ? null : () => _removerItem(item),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFFF2BA0),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.nuQtd.toString(),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _removendo
                    ? null
                    : () => _alterarQuantidade(item, item.nuQtd + 1),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.add,
                    color: Color(0xFFFF2BA0),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumoLinha(String label, double valor, {bool isBold = false}) {
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
          "R\$${valor.toStringAsFixed(2)}",
          style: GoogleFonts.inter(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  String _getImageUrl(String imagem) {
    // Remove espaços em branco
    imagem = imagem.trim();

    // Se já for uma URL completa (http:// ou https://), usar diretamente
    if (imagem.startsWith('http://') || imagem.startsWith('https://')) {
      return imagem;
    }
    // Caso contrário, concatenar com o caminho base
    return 'http://200.19.1.19/usuario01/$imagem';
  }

  Widget _buildHtmlImage(String src) {
    return html_image.buildHtmlImage(
      src,
      viewId: 'cart-img-${src.hashCode}',
    );
  }
}

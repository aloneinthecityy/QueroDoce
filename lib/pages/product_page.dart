import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import '../models/produto.dart';
import '../controllers/carrinho_controller.dart';
import '../services/auth_service.dart';

class ProductPage extends StatefulWidget {
  final Produto produto;

  const ProductPage({super.key, required this.produto});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  int quantidade = 1;
  final TextEditingController _observacaoController = TextEditingController();
  bool _adicionando = false;
  final Set<String> _registeredViews = {};

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _adicionarAoCarrinho() async {
    final usuario = AuthService.usuarioLogado;
    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado')),
      );
      return;
    }

    setState(() => _adicionando = true);

    final sucesso = await CarrinhoController.adicionarItem(
      usuario.idPessoa,
      widget.produto.idProduto,
      quantidade,
    );

    setState(() => _adicionando = false);

    if (sucesso) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produto adicionado ao carrinho!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao adicionar produto'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagem do produto
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: widget.produto.nmImagem.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                            child: _buildHtmlImage(_getImageUrl(widget.produto.nmImagem)),
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 100),
                          ),
                  ),
                  // Botão voltar
                  Positioned(
                    top: 16,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF2BA0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categoria
                    Text(
                      "Bolos e tortas",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Nome do produto
                    Text(
                      widget.produto.nmProduto,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Descrição
                    Text(
                      widget.produto.dsProduto,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Serve até
                    Text(
                      "Serve até 1 pessoa",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Observações
                    Text(
                      "Alguma observação?",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF2BA0),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _observacaoController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: "Digite suas observações...",
                          hintStyle: GoogleFonts.inter(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Quantidade e botão adicionar
                    Row(
                      children: [
                        // Controles de quantidade
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, color: Color(0xFFFF2BA0)),
                                onPressed: quantidade > 1
                                    ? () => setState(() => quantidade--)
                                    : null,
                              ),
                              Text(
                                quantidade.toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, color: Color(0xFFFF2BA0)),
                                onPressed: () => setState(() => quantidade++),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Botão adicionar
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _adicionando ? null : _adicionarAoCarrinho,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF2BA0),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _adicionando
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Adicionar",
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        "R\$${(widget.produto.vlProduto * quantidade).toStringAsFixed(2)}",
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
    // Cria um ID único para o elemento HTML
    final String viewId = 'img-product-${src.hashCode}';
    
    // Registra a plataforma view se ainda não foi registrada
    if (!_registeredViews.contains(viewId)) {
      ui_web.platformViewRegistry.registerViewFactory(
        viewId,
        (int viewId) {
          final img = web.HTMLImageElement()
            ..src = src
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.objectFit = 'cover'
            ..style.objectPosition = 'center';
          
          return img;
        },
      );
      _registeredViews.add(viewId);
    }

    return HtmlElementView(viewType: viewId);
  }
}


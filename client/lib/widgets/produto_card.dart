import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/produto.dart';
import '../utils/html_image.dart' as html_image;
import '../pages/product_page.dart';
import '../pages/empresa_produtos_page.dart';

class ProdutoCard extends StatefulWidget {
  final Produto produto;
  final bool showEmpresa;

  const ProdutoCard({
    super.key,
    required this.produto,
    this.showEmpresa = true,
  });

  @override
  State<ProdutoCard> createState() => _ProdutoCardState();
}

class _ProdutoCardState extends State<ProdutoCard> {
  bool _isHovered = false;

  String _getImageUrl(String imagem) {
    imagem = imagem.trim();
    if (imagem.startsWith('http://') || imagem.startsWith('https://')) {
      return imagem;
    }
    return 'localhost/backend/imagens/$imagem';
  }

  Widget _buildHtmlImage(String src) {
    return html_image.buildHtmlImage(
      src,
      viewId: 'card-img-${widget.produto.idProduto}-${src.hashCode}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final produto = widget.produto;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductPage(produto: produto),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()
            ..translate(0.0, _isHovered ? -6.0 : 0.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFFFF2BA0).withOpacity(0.5)
                  : Colors.grey.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? const Color(0xFFFF2BA0).withOpacity(0.15)
                    : Colors.black.withOpacity(0.05),
                blurRadius: _isHovered ? 12 : 6,
                spreadRadius: _isHovered ? 1 : 0,
                offset: Offset(0, _isHovered ? 6 : 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                // Imagem do produto
                Positioned.fill(
                  child: produto.nmImagem.isNotEmpty
                      ? _buildHtmlImage(_getImageUrl(produto.nmImagem))
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                ),
                // Nome do produto (canto superior esquerdo)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      produto.nmProduto,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Preço e nome da loja (canto inferior direito)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'R\$${produto.vlProduto.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF2BA0),
                          ),
                        ),
                        if (widget.showEmpresa && produto.nmEmpresa != null)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              // Navega para a página de produtos da empresa
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EmpresaProdutosPage(
                                    idEmpresa: produto.idEmpresa,
                                    nmEmpresa: produto.nmEmpresa!,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Text(
                                  produto.nmEmpresa!,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: const Color(0xFFFF2BA0),
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

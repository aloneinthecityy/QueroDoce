import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import '../models/produto.dart';
import '../models/categoria.dart';
import '../models/banner.dart';
import '../controllers/produto_controller.dart';
import '../controllers/categoria_controller.dart';
import '../controllers/banner_controller.dart';
import '../controllers/pessoa_controller.dart';
import '../services/auth_service.dart';
import 'product_page.dart';
import 'cart_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Produto> produtos = [];
  List<Categoria> categorias = [];
  BannerModel? banner;
  String? endereco;
  int? categoriaSelecionada;
  bool isLoading = true;
  final Set<String> _registeredViews = {};

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => isLoading = true);
    
    final usuario = AuthService.usuarioLogado;
    if (usuario != null) {
      final enderecoData = await PessoaController.buscarEndereco(usuario.idPessoa);
      setState(() => endereco = enderecoData ?? usuario.enderecoFormatado);
    }

    final produtosData = await ProdutoController.listarProdutosRecentes();
    final categoriasData = await CategoriaController.listarCategorias();
    final bannerData = await BannerController.buscarUltimoBanner();

    setState(() {
      produtos = produtosData;
      categorias = categoriasData;
      banner = bannerData;
      isLoading = false;
    });
  }

  Future<void> _filtrarPorCategoria(int? idCategoria) async {
    setState(() {
      categoriaSelecionada = idCategoria;
      isLoading = true;
    });

    List<Produto> produtosFiltrados;
    if (idCategoria == null) {
      produtosFiltrados = await ProdutoController.listarProdutosRecentes();
    } else {
      produtosFiltrados = await ProdutoController.listarProdutosPorCategoria(idCategoria);
    }

    setState(() {
      produtos = produtosFiltrados;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      body: SafeArea(
        child: Column(
          children: [
            // Header com endereço
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                          Flexible(
                            child: Text(
                              endereco ?? 'Carregando...',
                              style: GoogleFonts.pixelifySans(
                                fontSize: 16,
                                color: const Color(0xFFFF2BA0),
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFFFF2BA0),
                    size: 20,
                  ),
                ],
              ),
            ),

            // Banner
            if (banner != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF2BA0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Imagem do banner (se houver)
                    if (banner!.nmImagem.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildHtmlImage(_getImageUrl(banner!.nmImagem)),
                      ),
                    // Texto do banner
                    Positioned(
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Text(
                          "Bateu a vontade?\nPede um docinho!",
                          style: GoogleFonts.pixelifySans(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Categorias (badges)
            Container(
              height: 50,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Badge "Tudo"
                  _buildCategoriaBadge(
                    label: "Tudo",
                    isSelected: categoriaSelecionada == null,
                    onTap: () => _filtrarPorCategoria(null),
                  ),
                  const SizedBox(width: 8),
                  // Badges das categorias
                  ...categorias.map((categoria) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildCategoriaBadge(
                          label: categoria.nmCategoria,
                          isSelected: categoriaSelecionada == categoria.idCategoria,
                          onTap: () => _filtrarPorCategoria(categoria.idCategoria),
                        ),
                      )),
                ],
              ),
            ),

            // Lista de produtos
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF2BA0)))
                  : produtos.isEmpty
                      ? Center(
                          child: Text(
                            'Nenhum produto encontrado',
                            style: GoogleFonts.inter(color: Colors.white70),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: produtos.length,
                          itemBuilder: (context, index) {
                            return _buildProdutoCard(produtos[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFF2BA0),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, "Inicio", true, () {}),
            _buildNavItem(Icons.search, "Busca", false, () {}),
            _buildNavItem(Icons.shopping_bag, "Sacola", false, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            }),
            _buildNavItem(Icons.person, "Perfil", false, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriaBadge({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF2BA0) : const Color(0xFFFFB3D9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.pixelifySans(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildProdutoCard(Produto produto) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductPage(produto: produto),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do produto
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: produto.nmImagem.isNotEmpty
                    ? _buildHtmlImage(_getImageUrl(produto.nmImagem))
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 50, color: Colors.grey),
                      ),
              ),
            ),
            // Informações do produto
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produto.nmProduto,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'R\$${produto.vlProduto.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF2BA0),
                          ),
                        ),
                        if (produto.nmEmpresa != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF2BA0).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              produto.nmEmpresa!,
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                color: const Color(0xFFFF2BA0),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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
    final String viewId = 'img-${src.hashCode}';
    
    // Registra a plataforma view se ainda não foi registrada
    if (!_registeredViews.contains(viewId)) {
      ui_web.platformViewRegistry.registerViewFactory(
        viewId,
        (int viewId) {
          final img = html.ImageElement()
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


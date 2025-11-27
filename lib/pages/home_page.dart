import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/produto.dart';
import '../models/categoria.dart';
import '../models/banner.dart';
import '../controllers/produto_controller.dart';
import '../controllers/categoria_controller.dart';
import '../controllers/banner_controller.dart';
import '../controllers/pessoa_controller.dart';
import '../services/auth_service.dart';
import '../utils/html_image.dart' as html_image;
import 'product_page.dart';
import 'cart_page.dart';
import 'search_page.dart';
import 'profile_page.dart';

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

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => isLoading = true);

    final usuario = AuthService.usuarioLogado;
    if (usuario != null) {
      // Busca a rua/logradouro via CEP
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

      // Monta o endereço completo: rua/logradouro + número
      if (ruaLogradouro != null && ruaLogradouro.isNotEmpty) {
        final numero = usuario.nuEndereco != null && usuario.nuEndereco! > 0
            ? ', ${usuario.nuEndereco}'
            : '';
        setState(() => endereco = '$ruaLogradouro$numero');
      } else {
        // Fallback para o endereço formatado original
        final enderecoData = await PessoaController.buscarEndereco(
          usuario.idPessoa,
        );
        setState(() => endereco = enderecoData ?? usuario.enderecoFormatado);
      }
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
      produtosFiltrados = await ProdutoController.listarProdutosPorCategoria(
        idCategoria,
      );
    }

    setState(() {
      produtos = produtosFiltrados;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
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
          ],
              ),
            ),

            // Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              height: 150,
              child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/banner.png',
            width: double.infinity,
            height: 150,
            fit: BoxFit.contain,
          ),
              ),
            ),

            // Categorias (badges)
            Container(
              height: 35,
              margin: const EdgeInsets.only(bottom: 12),
              child: Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width > 600 ? 600 : double.infinity,
                child: Align(
                alignment: MediaQuery.of(context).size.width > 600
                  ? Alignment.center
                  : Alignment.centerLeft,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
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
                  ...categorias.map(
                    (categoria) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildCategoriaBadge(
                      label: categoria.nmCategoria,
                      isSelected: categoriaSelecionada == categoria.idCategoria,
                      onTap: () => _filtrarPorCategoria(categoria.idCategoria),
                    ),
                    ),
                  ),
                  ],
                ),
                ),
              ),
              ),
            ),

            // Lista de produtos
            Expanded(
              child: LayoutBuilder(
              builder: (context, constraints) {
                // Limita largura máxima em desktop/tablet
                double maxGridWidth = MediaQuery.of(context).size.width > 1200
                  ? 1000
                  : MediaQuery.of(context).size.width > 900
                    ? 800
                    : MediaQuery.of(context).size.width > 600
                      ? 500
                      : double.infinity;

                int crossAxisCount = MediaQuery.of(context).size.width > 1200
                  ? 5
                  : MediaQuery.of(context).size.width > 900
                    ? 4
                    : MediaQuery.of(context).size.width > 600
                      ? 3
                      : 2;

                double childAspectRatio = MediaQuery.of(context).size.width > 600
                  ? 0.7
                  : 0.75;

            return Center(
              child: Container(
                width: maxGridWidth,
                child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
              color: Color(0xFFFF2BA0),
                  ),
                )
              : produtos.isEmpty
                  ? Center(
                child: Text(
                  'Nenhum produto encontrado',
                  style: GoogleFonts.inter(color: Colors.white70),
                ),
              )
                  : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: produtos.length,
                itemBuilder: (context, index) {
                  return _buildProdutoCard(produtos[index]);
                },
              ),
              ),
            );
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
            _buildNavItem(Icons.search, "Busca", false, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            }),
            _buildNavItem(Icons.shopping_bag, "Sacola", false, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            }),
            _buildNavItem(Icons.person, "Perfil", false, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            }),
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
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Imagem do produto
              Positioned.fill(
                child: produto.nmImagem.isNotEmpty
                    ? _buildHtmlImage(_getImageUrl(produto.nmImagem))
                    : Container(
                        color: Colors.grey[300],
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
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
                        Text(
                          produto.nmEmpresa!,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
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
    return html_image.buildHtmlImage(
      src,
      viewId: 'home-img-${src.hashCode}',
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/produto.dart';
import '../models/empresa.dart';
import '../controllers/produto_controller.dart';
import '../controllers/empresa_controller.dart';
import '../widgets/produto_card.dart';
import '../utils/html_image.dart' as html_image;
import 'cart_page.dart';

class EmpresaProdutosPage extends StatefulWidget {
  final int idEmpresa;
  final String nmEmpresa;

  const EmpresaProdutosPage({
    super.key,
    required this.idEmpresa,
    required this.nmEmpresa,
  });

  @override
  State<EmpresaProdutosPage> createState() => _EmpresaProdutosPageState();
}

class _EmpresaProdutosPageState extends State<EmpresaProdutosPage> {
  List<Produto> produtos = [];
  Empresa? empresa;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => isLoading = true);
    
    // Carrega em paralelo produtos da empresa e detalhes da empresa
    final resultados = await Future.wait([
      ProdutoController.listarProdutosPorEmpresa(widget.idEmpresa),
      EmpresaController.buscarEmpresa(widget.idEmpresa),
    ]);

    setState(() {
      produtos = resultados[0] as List<Produto>;
      empresa = resultados[1] as Empresa?;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFFF2BA0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.nmEmpresa,
          style: GoogleFonts.pixelifySans(
            fontSize: 20,
            color: const Color(0xFFFF2BA0),
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF2BA0),
              ),
            )
          : Column(
              children: [
                // Info Card da Empresa com estilo premium
                _buildEmpresaHeader(),
                
                // Divisor e Título dos Produtos
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Text(
                        'Cardápio / Doces',
                        style: GoogleFonts.pixelifySans(
                          fontSize: 18,
                          color: const Color(0xFFFF2BA0),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB3D9).withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${produtos.length} itens',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFFFF2BA0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de produtos
                Expanded(
                  child: produtos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cookie_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhum doce cadastrado no momento.',
                                style: GoogleFonts.inter(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
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

                            double childAspectRatio =
                                MediaQuery.of(context).size.width > 600 ? 0.7 : 0.75;

                            return Center(
                              child: SizedBox(
                                width: maxGridWidth,
                                child: GridView.builder(
                                  padding: const EdgeInsets.all(16),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: childAspectRatio,
                                  ),
                                  itemCount: produtos.length,
                                  itemBuilder: (context, index) {
                                    return ProdutoCard(
                                      produto: produtos[index],
                                      showEmpresa: false,
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmpresaHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF2BA0),
            Color(0xFFFF52C1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF2BA0).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: empresa != null && empresa!.nmImagem.isNotEmpty
                      ? _buildLogoImage(empresa!.nmImagem)
                      : const Icon(
                          Icons.storefront,
                          color: Color(0xFFFF2BA0),
                          size: 32,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.nmEmpresa,
                      style: GoogleFonts.pixelifySans(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (empresa != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'CNPJ: ${empresa!.nuCnpj}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (empresa != null) ...[
            const Divider(color: Colors.white24, height: 24),
            Row(
              children: [
                const Icon(Icons.email_outlined, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  empresa!.dsEmail,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'CEP: ${empresa!.nuCep} ${empresa!.dsComplemento.isNotEmpty ? "- ${empresa!.dsComplemento}" : ""} Nº ${empresa!.nuEndereco}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogoImage(String imagem) {
    imagem = imagem.trim();
    String src;
    if (imagem.startsWith('http://') || imagem.startsWith('https://')) {
      src = imagem;
    } else {
      src = 'http://localhost/backend/$imagem';
    }
    // Para logo, usamos BoxFit.cover
    return html_image.buildHtmlImage(
      src,
      viewId: 'empresa-logo-${widget.idEmpresa}-${src.hashCode}',
      fit: BoxFit.cover,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/produto.dart';
import '../controllers/produto_controller.dart';
import '../widgets/produto_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Produto> produtos = [];
  bool isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pesquisar() async {
    final termo = _searchController.text.trim();
    if (termo.isEmpty) {
      setState(() {
        produtos = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      _hasSearched = true;
    });

    final resultados = await ProdutoController.pesquisarProdutos(termo);

    setState(() {
      produtos = resultados;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF2BA0)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: "Buscar produtos...",
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFFF2BA0)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          produtos = [];
                          _hasSearched = false;
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onSubmitted: (_) => _pesquisar(),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: _pesquisar,
            child: Text(
              "Buscar",
              style: GoogleFonts.inter(
                color: const Color(0xFFFF2BA0),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF2BA0)),
            )
          : _hasSearched
              ? produtos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum produto encontrado',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tente buscar com outros termos',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width > 1200
                            ? 700
                            : MediaQuery.of(context).size.width > 900
                                ? 600
                                : MediaQuery.of(context).size.width > 600
                                    ? 500
                                    : double.infinity,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: produtos.length,
                          itemBuilder: (context, index) {
                            return ProdutoCard(produto: produtos[index]);
                          },
                        ),
                      ),
                    )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Digite o nome do produto',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Busque por nome, descrição ou empresa',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }


}


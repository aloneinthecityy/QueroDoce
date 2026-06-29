import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/produto.dart';
import '../models/empresa.dart';
import '../controllers/produto_controller.dart';
import '../utils/html_image.dart' as html_image;

class EmpresaProdutosTab extends StatefulWidget {
  final Empresa empresa;

  const EmpresaProdutosTab({super.key, required this.empresa});

  @override
  State<EmpresaProdutosTab> createState() => _EmpresaProdutosTabState();
}

class _EmpresaProdutosTabState extends State<EmpresaProdutosTab> {
  List<Produto> produtos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  Future<void> _carregarProdutos() async {
    setState(() => isLoading = true);
    final data = await ProdutoController.listarProdutosPorEmpresa(widget.empresa.idEmpresa);
    setState(() {
      produtos = data;
      isLoading = false;
    });
  }

  String _getImageUrl(String imagem) {
    imagem = imagem.trim();
    if (imagem.startsWith('http://') || imagem.startsWith('https://')) {
      return imagem;
    }
    return 'http://localhost/backend/$imagem';
  }

  Widget _buildHtmlImage(String src) {
    return html_image.buildHtmlImage(
      src,
      viewId: 'empresa-prod-img-${src.hashCode}',
      fit: BoxFit.cover,
    );
  }

  void _excluirProduto(Produto produto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Excluir Doce',
          style: GoogleFonts.pixelifySans(color: const Color(0xFFFF2BA0)),
        ),
        content: Text('Tem certeza que deseja excluir "${produto.nmProduto}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2BA0)),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Excluir', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => isLoading = true);
      final sucesso = await ProdutoController.excluirProduto(produto.idProduto);
      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doce excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _carregarProdutos();
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nao deu para excluir esse doce agora. Tente novamente.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _abrirFormulario({Produto? produto}) async {
    final nomeController = TextEditingController(text: produto?.nmProduto ?? '');
    final descricaoController = TextEditingController(text: produto?.dsProduto ?? '');
    final valorController = TextEditingController(text: produto?.vlProduto.toString() ?? '');
    final qtdController = TextEditingController(text: produto?.nuQtd.toString() ?? '');
    final imagemController = TextEditingController(text: produto?.nmImagem ?? 'doces/chocolate.jpg');
    bool disponivel = produto?.flDisponivel ?? true;

    final formKey = GlobalKey<FormState>();

    final salvar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBuilder) {
            return AlertDialog(
              title: Text(
                produto == null ? 'Adicionar Novo Doce' : 'Editar Doce',
                style: GoogleFonts.pixelifySans(color: const Color(0xFFFF2BA0)),
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nomeController,
                          decoration: const InputDecoration(
                            labelText: 'Nome do Doce',
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF2BA0))),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Insira o nome' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descricaoController,
                          decoration: const InputDecoration(
                            labelText: 'Descrição',
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF2BA0))),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Insira a descrição' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: valorController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Preço (R\$)',
                                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF2BA0))),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Insira o preço';
                                  if (double.tryParse(v) == null) return 'Valor inválido';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: qtdController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Quantidade',
                                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF2BA0))),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Insira a quantidade';
                                  if (int.tryParse(v) == null) return 'Número inválido';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: imagemController,
                          decoration: const InputDecoration(
                            labelText: 'Nome/Caminho da Imagem',
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF2BA0))),
                            helperText: 'Ex: doces/chocolate.jpg ou URL completa',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Insira a imagem' : null,
                        ),
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          title: const Text('Disponível para Venda'),
                          activeColor: const Color(0xFFFF2BA0),
                          value: disponivel,
                          onChanged: (val) {
                            setStateBuilder(() {
                              disponivel = val ?? true;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancelar', style: GoogleFonts.inter(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2BA0)),
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: Text('Salvar', style: GoogleFonts.inter(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (salvar == true) {
      setState(() => isLoading = true);
      final novoProduto = Produto(
        idProduto: produto?.idProduto ?? 0,
        idEmpresa: widget.empresa.idEmpresa,
        nmProduto: nomeController.text.trim(),
        dsProduto: descricaoController.text.trim(),
        nmImagem: imagemController.text.trim(),
        vlProduto: double.parse(valorController.text.trim()),
        nuQtd: int.parse(qtdController.text.trim()),
        flDisponivel: disponivel,
      );

      bool sucesso;
      if (produto == null) {
        sucesso = await ProdutoController.inserirProduto(novoProduto);
      } else {
        sucesso = await ProdutoController.alterarProduto(novoProduto);
      }

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(produto == null ? 'Doce adicionado com sucesso!' : 'Doce atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _carregarProdutos();
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nao deu para salvar esse doce agora. Tente novamente.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FC),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF2BA0),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _abrirFormulario(),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF2BA0),
              ),
            )
          : produtos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cookie_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum doce cadastrado.',
                        style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2BA0)),
                        onPressed: () => _abrirFormulario(),
                        child: Text('Cadastrar Primeiro Doce', style: GoogleFonts.inter(color: Colors.white)),
                      )
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: produtos.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final prod = produtos[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF8CFE5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: prod.nmImagem.isNotEmpty
                                  ? _buildHtmlImage(_getImageUrl(prod.nmImagem))
                                  : Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image, color: Colors.grey),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prod.nmProduto,
                                  style: GoogleFonts.pixelifySans(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Preço: R\$${prod.vlProduto.toStringAsFixed(2)} | Qtd: ${prod.nuQtd}',
                                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: prod.flDisponivel ? Colors.green.shade50 : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    prod.flDisponivel ? 'Disponível' : 'Indisponível',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: prod.flDisponivel ? Colors.green.shade700 : Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _abrirFormulario(produto: prod),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _excluirProduto(prod),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/categoria_controller.dart';
import '../controllers/empresa_controller.dart';
import '../models/categoria.dart';
import '../models/empresa.dart';
import '../utils/html_image.dart' as html_image;

class EmpresaPerfilTab extends StatefulWidget {
  final Empresa empresa;
  final Function(Empresa) onProfileUpdated;

  const EmpresaPerfilTab({
    super.key,
    required this.empresa,
    required this.onProfileUpdated,
  });

  @override
  State<EmpresaPerfilTab> createState() => _EmpresaPerfilTabState();
}

class _EmpresaPerfilTabState extends State<EmpresaPerfilTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _cnpjController;
  late TextEditingController _emailController;
  late TextEditingController _cepController;
  late TextEditingController _enderecoController;
  late TextEditingController _complementoController;
  late TextEditingController _imagemController;
  late TextEditingController _senhaController;

  bool _isLoading = false;
  bool _isLoadingCategorias = false;
  List<Categoria> _categorias = [];
  final Set<int> _categoriasSelecionadas = {};

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.empresa.nmEmpresa);
    _cnpjController = TextEditingController(text: widget.empresa.nuCnpj);
    _emailController = TextEditingController(text: widget.empresa.dsEmail);
    _cepController = TextEditingController(text: widget.empresa.nuCep);
    _enderecoController =
        TextEditingController(text: widget.empresa.nuEndereco.toString());
    _complementoController =
        TextEditingController(text: widget.empresa.dsComplemento);
    _imagemController = TextEditingController(text: widget.empresa.nmImagem);
    _senhaController = TextEditingController(text: widget.empresa.dsSenha);
    _categoriasSelecionadas.addAll(widget.empresa.idsCategoria);
    _imagemController.addListener(_onImagemChanged);
    _carregarCategorias();
  }

  void _onImagemChanged() {
    setState(() {});
  }

  Future<void> _carregarCategorias() async {
    setState(() => _isLoadingCategorias = true);
    final categorias = await CategoriaController.listarCategorias();
    if (!mounted) return;
    setState(() {
      _categorias = categorias;
      _isLoadingCategorias = false;
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cnpjController.dispose();
    _emailController.dispose();
    _cepController.dispose();
    _enderecoController.dispose();
    _complementoController.dispose();
    _imagemController.removeListener(_onImagemChanged);
    _imagemController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final idsCategoria = _categoriasSelecionadas.toList()..sort();
    final nomesCategoria = <String>[];
    for (final categoria in _categorias) {
      if (_categoriasSelecionadas.contains(categoria.idCategoria)) {
        nomesCategoria.add(categoria.nmCategoria);
      }
    }

    final empresaAtualizada = Empresa(
      idEmpresa: widget.empresa.idEmpresa,
      nmEmpresa: _nomeController.text.trim(),
      nuCnpj: _cnpjController.text.trim(),
      dsEmail: _emailController.text.trim(),
      nuCep: _cepController.text.trim(),
      nuEndereco: int.parse(_enderecoController.text.trim()),
      dsComplemento: _complementoController.text.trim(),
      nmImagem: _imagemController.text.trim(),
      dsSenha: _senhaController.text.trim(),
      idCategoria: idsCategoria.isNotEmpty ? idsCategoria.first : 0,
      nmCategoria: nomesCategoria.join(', '),
      idsCategoria: idsCategoria,
      nomesCategoria: nomesCategoria,
    );

    final sucesso = await EmpresaController.alterarEmpresa(empresaAtualizada);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (sucesso) {
      widget.onProfileUpdated(empresaAtualizada);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nao deu para salvar as alteracoes do perfil agora. Tente novamente.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FC),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF2BA0)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 550),
                  child: Card(
                    elevation: 4,
                    shadowColor: const Color(0xFFFF2BA0).withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFF8CFE5)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informacoes da Loja',
                              style: GoogleFonts.pixelifySans(
                                fontSize: 20,
                                color: const Color(0xFFFF2BA0),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const Divider(height: 24, color: Color(0xFFF8CFE5)),
                            TextFormField(
                              controller: _nomeController,
                              decoration: const InputDecoration(
                                labelText: 'Nome Fantasia',
                                prefixIcon: Icon(
                                  Icons.storefront,
                                  color: Color(0xFFFF2BA0),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Color(0xFFFF2BA0)),
                                ),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Insira o nome fantasia'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _cnpjController,
                              decoration: const InputDecoration(
                                labelText: 'CNPJ',
                                prefixIcon: Icon(
                                  Icons.badge_outlined,
                                  color: Color(0xFFFF2BA0),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Color(0xFFFF2BA0)),
                                ),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Insira o CNPJ'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _buildCategoriaField(),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'E-mail',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: Color(0xFFFF2BA0),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Color(0xFFFF2BA0)),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Insira o e-mail';
                                }
                                if (!v.contains('@')) {
                                  return 'E-mail invalido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _senhaController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Senha de Acesso',
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: Color(0xFFFF2BA0),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Color(0xFFFF2BA0)),
                                ),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Insira a senha'
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Localizacao e Imagem',
                              style: GoogleFonts.pixelifySans(
                                fontSize: 18,
                                color: const Color(0xFFFF2BA0),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const Divider(height: 24, color: Color(0xFFF8CFE5)),
                            TextFormField(
                              controller: _cepController,
                              decoration: const InputDecoration(
                                labelText: 'CEP',
                                prefixIcon: Icon(
                                  Icons.map_outlined,
                                  color: Color(0xFFFF2BA0),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Color(0xFFFF2BA0)),
                                ),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Insira o CEP'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _enderecoController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Numero',
                                      prefixIcon: Icon(
                                        Icons.home_outlined,
                                        color: Color(0xFFFF2BA0),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Color(0xFFFF2BA0)),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Obrigatorio';
                                      }
                                      if (int.tryParse(v) == null) {
                                        return 'Invalido';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _complementoController,
                                    decoration: const InputDecoration(
                                      labelText: 'Complemento',
                                      prefixIcon: Icon(
                                        Icons.info_outline,
                                        color: Color(0xFFFF2BA0),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Color(0xFFFF2BA0)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildPreviewLogo(),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _imagemController,
                              decoration: const InputDecoration(
                                labelText: 'Logo / Imagem da Empresa',
                                prefixIcon: Icon(
                                  Icons.image_outlined,
                                  color: Color(0xFFFF2BA0),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Color(0xFFFF2BA0)),
                                ),
                                helperText:
                                    'Caminho relativo (ex: logo.png) ou URL',
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Insira o caminho da imagem'
                                  : null,
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF2BA0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _salvarPerfil,
                                child: Text(
                                  'Salvar Alteracoes',
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
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCategoriaField() {
    if (_isLoadingCategorias) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: CircularProgressIndicator(color: Color(0xFFFF2BA0)),
        ),
      );
    }

    return FormField<Set<int>>(
      initialValue: _categoriasSelecionadas,
      validator: (_) {
        if (_categoriasSelecionadas.isEmpty) {
          return 'Escolha pelo menos uma categoria da empresa';
        }
        return null;
      },
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categorias',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: field.hasError
                      ? Colors.red.shade700
                      : const Color(0xFFF8CFE5),
                ),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categorias.map((categoria) {
                  final selected =
                      _categoriasSelecionadas.contains(categoria.idCategoria);
                  return FilterChip(
                    label: Text(categoria.nmCategoria),
                    selected: selected,
                    selectedColor: const Color(0xFFFFE4F2),
                    checkmarkColor: const Color(0xFFFF2BA0),
                    side: BorderSide(
                      color: selected
                          ? const Color(0xFFFF2BA0)
                          : const Color(0xFFF8CFE5),
                    ),
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _categoriasSelecionadas.add(categoria.idCategoria);
                        } else {
                          _categoriasSelecionadas.remove(categoria.idCategoria);
                        }
                      });
                      field.didChange(_categoriasSelecionadas);
                    },
                  );
                }).toList(),
              ),
            ),
            if (field.hasError) ...[
              const SizedBox(height: 6),
              Text(
                field.errorText!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPreviewLogo() {
    final path = _imagemController.text.trim();
    String src = '';
    if (path.isNotEmpty) {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        src = path;
      } else {
        src = 'http://localhost/backend/$path';
      }
    }

    return Center(
      child: Column(
        children: [
          Text(
            'Pre-visualizacao do Logo',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF2BA0).withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: src.isNotEmpty
                  ? html_image.buildHtmlImage(
                      src,
                      viewId: 'perfil-preview-logo-${src.hashCode}',
                      fit: BoxFit.cover,
                    )
                  : const Icon(
                      Icons.storefront,
                      size: 48,
                      color: Color(0xFFFF2BA0),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

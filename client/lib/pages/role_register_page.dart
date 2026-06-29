import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../controllers/categoria_controller.dart';
import '../controllers/empresa_controller.dart';
import '../controllers/entregador_controller.dart';
import '../models/categoria.dart';
import '../models/empresa.dart';
import '../pages/empresa_page.dart';
import '../entregador_page.dart';

class RoleRegisterPage extends StatefulWidget {
  const RoleRegisterPage({super.key, required this.isEntregador});

  final bool isEntregador;

  @override
  State<RoleRegisterPage> createState() => _RoleRegisterPageState();
}

class _RoleRegisterPageState extends State<RoleRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _cpfCnpjController = TextEditingController();
  final _celularController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _cepController = TextEditingController();
  final _numeroController = TextEditingController();
  final _imagemController = TextEditingController();
  final _cnhController = TextEditingController();

  bool _loading = false;
  bool _loadingCategorias = false;
  String? _locomocao;
  final Set<int> _categoriasSelecionadas = {};
  List<Categoria> _categorias = [];

  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );

  final _cnpjMask = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {'#': RegExp(r'[0-9]')},
  );

  final _celularMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  final _cepMask = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {'#': RegExp(r'[0-9]')},
  );

  bool get _isEntregador => widget.isEntregador;
  bool get _usaBicicleta => _locomocao == 'B';

  @override
  void initState() {
    super.initState();
    if (!_isEntregador) {
      _carregarCategorias();
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfCnpjController.dispose();
    _celularController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _cepController.dispose();
    _numeroController.dispose();
    _imagemController.dispose();
    _cnhController.dispose();
    super.dispose();
  }

  Future<void> _carregarCategorias() async {
    setState(() => _loadingCategorias = true);
    final categorias = await CategoriaController.listarCategorias();
    if (!mounted) return;
    setState(() {
      _categorias = categorias;
      _loadingCategorias = false;
    });
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final success = _isEntregador
          ? await _cadastrarEntregador()
          : await _cadastrarEmpresa();

      if (!mounted || !success) return;

      if (_isEntregador) {
        await _entrarAutomaticamenteEntregador();
      } else {
        await _entrarAutomaticamenteEmpresa();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _cadastrarEmpresa() async {
    final numero = int.tryParse(_numeroController.text.trim()) ?? 0;
    final idsCategoria = _categoriasSelecionadas.toList()..sort();
    final empresa = Empresa(
      idEmpresa: 0,
      nmEmpresa: _nomeController.text.trim(),
      dsEmail: _emailController.text.trim(),
      nmImagem: _imagemController.text.trim(),
      dsSenha: _senhaController.text.trim(),
      nuCnpj: _onlyDigits(_cpfCnpjController.text),
      nuCep: _onlyDigits(_cepController.text),
      dsComplemento: '',
      nuEndereco: numero,
      idCategoria: idsCategoria.isNotEmpty ? idsCategoria.first : 0,
      idsCategoria: idsCategoria,
    );

    final success = await EmpresaController.inserirEmpresa(empresa);
    if (!success && mounted) {
      _showError(
        EmpresaController.ultimoErroCadastro ??
            'Nao foi possivel concluir o cadastro da empresa agora.',
      );
    }
    return success;
  }

  Future<bool> _cadastrarEntregador() async {
    final numero = int.tryParse(_numeroController.text.trim()) ?? 0;
    final success = await EntregadorController.cadastrarCompleto(
      nome: _nomeController.text.trim(),
      cpf: _onlyDigits(_cpfCnpjController.text),
      celular: _onlyDigits(_celularController.text),
      email: _emailController.text.trim(),
      senha: _senhaController.text.trim(),
      cep: _onlyDigits(_cepController.text),
      complemento: '',
      numeroEndereco: numero,
      locomocao: _locomocao ?? '',
      cnh: _usaBicicleta ? '' : _onlyDigits(_cnhController.text),
    );

    if (!success && mounted) {
      _showError(
        EntregadorController.ultimoErroCadastro ??
            'Nao foi possivel concluir o cadastro do entregador agora.',
      );
    }
    return success;
  }

  Future<void> _entrarAutomaticamenteEmpresa() async {
    final empresa = await EmpresaController.login(
      _emailController.text.trim(),
      _senhaController.text.trim(),
    );

    if (!mounted) return;

    if (empresa == null) {
      _showError(
        'Seu cadastro foi criado, mas nao conseguimos entrar automaticamente agora. Tente fazer login.',
      );
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => EmpresaPage(empresa: empresa)),
      (_) => false,
    );
  }

  Future<void> _entrarAutomaticamenteEntregador() async {
    final entregador = await EntregadorController.login(
      _emailController.text.trim(),
      _senhaController.text.trim(),
    );

    if (!mounted) return;

    if (entregador == null) {
      _showError(
        'Seu cadastro foi criado, mas nao conseguimos entrar automaticamente agora. Tente fazer login.',
      );
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => EntregadorPage(entregadorId: entregador.idEntregador),
      ),
      (_) => false,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  String _onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  bool _isCpfValido(String value) {
    final cpf = _onlyDigits(value);
    if (cpf.length != 11) return false;
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;

    int calcularDigito(String base) {
      var soma = 0;
      for (var i = 0; i < base.length; i++) {
        soma += int.parse(base[i]) * (base.length + 1 - i);
      }
      final resto = soma % 11;
      return resto < 2 ? 0 : 11 - resto;
    }

    final primeiroDigito = calcularDigito(cpf.substring(0, 9));
    final segundoDigito = calcularDigito(cpf.substring(0, 10));
    return cpf.endsWith('$primeiroDigito$segundoDigito');
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEntregador
        ? 'Cadastro do entregador'
        : 'Cadastro da empresa';
    final subtitle = _isEntregador
        ? 'Crie seu acesso para receber entregas'
        : 'Crie o acesso da sua loja';
    final icon = _isEntregador ? Icons.delivery_dining : Icons.storefront;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFFEE0084),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFFEE0084),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/logo.png', height: 70),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.pixelifySans(
                          color: const Color(0xFFFF2BA0),
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: const Color(0xFFEE0084), size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF313130),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(
                        color: Color(0xFFFBD0E8),
                        thickness: 0.6,
                        height: 1,
                      ),
                      const SizedBox(height: 24),
                      _buildField(
                        controller: _nomeController,
                        label:
                            _isEntregador ? 'Nome completo:' : 'Nome da empresa:',
                        hint: _isEntregador
                            ? 'Maria da Silva'
                            : 'Doceria QueroDoce',
                        icon: _isEntregador
                            ? Icons.person_outline
                            : Icons.storefront_outlined,
                        validator: (value) {
                          if (value == null || value.trim().length < 3) {
                            return _isEntregador
                                ? 'Informe o nome completo do entregador.'
                                : 'Informe o nome da empresa.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _cpfCnpjController,
                        label: _isEntregador ? 'CPF:' : 'CNPJ:',
                        hint: _isEntregador
                            ? '000.000.000-00'
                            : '00.000.000/0000-00',
                        icon: Icons.badge_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [_isEntregador ? _cpfMask : _cnpjMask],
                        validator: (value) {
                          final digits = _onlyDigits(value ?? '');
                          if (_isEntregador && !_isCpfValido(digits)) {
                            return 'Informe um CPF valido.';
                          }
                          if (!_isEntregador && digits.length != 14) {
                            return 'Informe um CNPJ com 14 digitos.';
                          }
                          return null;
                        },
                      ),
                      if (_isEntregador) ...[
                        const SizedBox(height: 14),
                        _buildField(
                          controller: _celularController,
                          label: 'Celular:',
                          hint: '(00) 00000-0000',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [_celularMask],
                          validator: (value) {
                            if (_onlyDigits(value ?? '').length != 11) {
                              return 'Informe um celular com DDD.';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _emailController,
                        label: 'E-mail:',
                        hint: 'exemplo@gmail.com',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return 'Informe o e-mail.';
                          if (!text.contains('@') || !text.contains('.')) {
                            return 'Informe um e-mail valido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _senhaController,
                        label: 'Senha:',
                        hint: '********',
                        icon: Icons.lock_outline,
                        obscureText: true,
                        validator: (value) {
                          if ((value ?? '').trim().length < 6) {
                            return 'Crie uma senha com pelo menos 6 caracteres.';
                          }
                          return null;
                        },
                      ),
                      if (!_isEntregador) ...[
                        const SizedBox(height: 14),
                        _buildCategoriaField(),
                      ],
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _cepController,
                        label: 'CEP:',
                        hint: '00000-000',
                        icon: Icons.map_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [_cepMask],
                        validator: (value) {
                          if (_onlyDigits(value ?? '').length != 8) {
                            return 'Informe um CEP com 8 digitos.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _numeroController,
                        label: 'Numero do endereco:',
                        hint: '123',
                        icon: Icons.home_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          final numero = int.tryParse((value ?? '').trim());
                          if (numero == null || numero <= 0) {
                            return 'Informe um numero de endereco valido.';
                          }
                          return null;
                        },
                      ),
                      if (_isEntregador) ...[
                        const SizedBox(height: 14),
                        _buildLocomocaoField(),
                        const SizedBox(height: 14),
                        _buildField(
                          controller: _cnhController,
                          label: 'CNH:',
                          hint: 'Somente numeros',
                          icon: Icons.credit_card_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          enabled: !_usaBicicleta,
                          helperText: _usaBicicleta
                              ? 'CNH nao e necessaria para bicicleta.'
                              : null,
                          validator: (value) {
                            if (_usaBicicleta) return null;
                            if (_onlyDigits(value ?? '').length != 11) {
                              return 'Informe uma CNH com 11 digitos.';
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        const SizedBox(height: 14),
                        _buildField(
                          controller: _imagemController,
                          label: 'Logo da empresa:',
                          hint: 'URL ou caminho da imagem',
                          icon: Icons.image_outlined,
                        ),
                      ],
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _cadastrar,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(
                            _loading ? 'Salvando...' : 'Criar cadastro',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEE0084),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _loading ? null : () => Navigator.pop(context),
                        child: Text(
                          'Ja tenho cadastro',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFEE0084),
                            fontWeight: FontWeight.w600,
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
    if (_loadingCategorias) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: CircularProgressIndicator(color: Color(0xFFEE0084)),
        ),
      );
    }

    return FormField<Set<int>>(
      initialValue: _categoriasSelecionadas,
      validator: (_) {
        if (_categoriasSelecionadas.isEmpty) {
          return 'Escolha pelo menos uma categoria da empresa.';
        }
        return null;
      },
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categorias da empresa:',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: field.hasError
                      ? Colors.red.shade700
                      : const Color(0xFFE5E7EB),
                ),
                borderRadius: BorderRadius.circular(12),
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
                    onSelected: _loading
                        ? null
                        : (value) {
                            setState(() {
                              if (value) {
                                _categoriasSelecionadas
                                    .add(categoria.idCategoria);
                              } else {
                                _categoriasSelecionadas
                                    .remove(categoria.idCategoria);
                              }
                            });
                            field.didChange(_categoriasSelecionadas);
                          },
                    selectedColor: const Color(0xFFFFE4F2),
                    checkmarkColor: const Color(0xFFEE0084),
                    side: BorderSide(
                      color: selected
                          ? const Color(0xFFEE0084)
                          : const Color(0xFFE5E7EB),
                    ),
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

  Widget _buildLocomocaoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Como voce faz as entregas?',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _locomocao,
          items: const [
            DropdownMenuItem(value: 'M', child: Text('Moto')),
            DropdownMenuItem(value: 'C', child: Text('Carro')),
            DropdownMenuItem(value: 'B', child: Text('Bicicleta')),
          ],
          onChanged: _loading
              ? null
              : (value) => setState(() {
                    _locomocao = value;
                    if (_usaBicicleta) {
                      _cnhController.clear();
                    }
                  }),
          validator: (value) {
            if ((value ?? '').isEmpty) {
              return 'Escolha como voce faz as entregas.';
            }
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.two_wheeler_outlined,
              color: Color(0xFFEE0084),
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color.fromARGB(255, 196, 201, 209),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    bool enabled = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: GoogleFonts.inter(
            color: const Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            hintStyle: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFFEE0084), size: 20),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color.fromARGB(255, 196, 201, 209),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

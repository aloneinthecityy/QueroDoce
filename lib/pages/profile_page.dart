import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/pessoa.dart';
import '../controllers/pessoa_controller.dart';
import '../services/auth_service.dart';
import '../main.dart';
import '../utils/html_image.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _cpfController;
  late TextEditingController _celController;
  late TextEditingController _emailController;
  late TextEditingController _senhaController;
  late TextEditingController _novaSenhaController;
  late TextEditingController _cepController;
  late TextEditingController _complementoController;
  late TextEditingController _numeroController;

  bool _loading = false;
  bool _mostrarNovaSenha = false;
  bool _consultandoCep = false;
  bool _inicializado = false;
  Pessoa? _usuario;

  @override
  void initState() {
    super.initState();
    _usuario = AuthService.usuarioLogado;
    _nomeController = TextEditingController(text: _usuario?.nmPessoa ?? '');
    _cpfController = TextEditingController(text: _usuario?.nuCpf ?? '');
    _celController = TextEditingController(text: _usuario?.nuCel ?? '');
    _emailController = TextEditingController(text: _usuario?.dsEmail ?? '');
    _senhaController = TextEditingController();
    _novaSenhaController = TextEditingController();
    _cepController = TextEditingController(text: _usuario?.nuCep ?? '');
    _complementoController = TextEditingController(
      text: _usuario?.dsComplemento ?? '',
    );
    _numeroController = TextEditingController(
      text: _usuario?.nuEndereco?.toString() ?? '',
    );

    // Adiciona listener para consultar CEP quando mudar
    _cepController.addListener(_consultarCep);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializado = true; // <-- ATIVA CONSULTA

      final cep = _cepController.text.replaceAll(RegExp(r'\D'), '');
      if (cep.length == 8) {
        _consultarCep();
      }
    });
  }

  Future<void> _consultarCep() async {
    // Não consulta durante a inicialização
    if (!_inicializado) {
      return;
    }

    final cep = _cepController.text.replaceAll(RegExp(r'\D'), '');

    // Só consulta se tiver 8 dígitos
    if (cep.length != 8) {
      return;
    }

    setState(() => _consultandoCep = true);

    try {
      final url = Uri.parse('https://viacep.com.br/ws/$cep/json/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['erro'] == null) {
          // Preenche o campo de logradouro com os dados do CEP
          final logradouro = '${data['logradouro'] ?? ''}'.trim();
          if (logradouro.isNotEmpty) {
            _complementoController.text = logradouro;
          }
        } else {
          // CEP não encontrado
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('CEP não encontrado'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Erro ao consultar CEP: $e');
    } finally {
      setState(() => _consultandoCep = false);
    }
  }

  @override
  void dispose() {
    _cepController.removeListener(_consultarCep);
    _nomeController.dispose();
    _cpfController.dispose();
    _celController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _novaSenhaController.dispose();
    _cepController.dispose();
    _complementoController.dispose();
    _numeroController.dispose();
    super.dispose();
  }

  Future<void> _salvarDados() async {
    if (!_formKey.currentState!.validate()) return;

    if (_usuario == null) return;

    setState(() => _loading = true);

    try {
      // Remove hífen e caracteres não numéricos do CEP (banco espera apenas 8 dígitos)
      final cepLimpo = _cepController.text.replaceAll(RegExp(r'\D'), '');

      final pessoaAtualizada = Pessoa(
        idPessoa: _usuario!.idPessoa,
        nmPessoa: _nomeController.text.trim(),
        nuCpf: _cpfController.text.trim(),
        nuCel: _celController.text.trim(),
        dsEmail: _emailController.text.trim(),
        nuCep: cepLimpo, // CEP sem hífen e apenas números
        dsComplemento:
            _usuario?.dsComplemento ??
            '', // Mantém o valor original do banco, não salva o campo de rua
        nuEndereco: int.tryParse(_numeroController.text.trim()) ?? 0,
      );

      final novaSenha = _novaSenhaController.text.trim().isNotEmpty
          ? _novaSenhaController.text.trim()
          : null;

      final sucesso = await PessoaController.atualizarDados(
        pessoaAtualizada,
        novaSenha: novaSenha,
      );

      if (sucesso) {
        // Se mudou a senha, atualiza o AuthService fazendo login
        if (novaSenha != null) {
          await AuthService.login(pessoaAtualizada.dsEmail, novaSenha);
        } else {
          // Se não mudou senha, apenas atualiza os dados do usuário logado
          AuthService.usuarioLogado = pessoaAtualizada;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dados atualizados com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          // Atualiza o estado local
          setState(() {
            _usuario = AuthService.usuarioLogado;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao atualizar dados'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmacao == true) {
      AuthService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_usuario == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Usuário não encontrado',
            style: GoogleFonts.inter(color: Colors.grey),
          ),
        ),
      );
    }

    final cpfMask = MaskTextInputFormatter(
      mask: '###.###.###-##',
      filter: {"#": RegExp(r'[0-9]')},
    );
    final celMask = MaskTextInputFormatter(
      mask: '(##) #####-####',
      filter: {"#": RegExp(r'[0-9]')},
    );
    final cepMask = MaskTextInputFormatter(
      mask: '#####-###',
      filter: {"#": RegExp(r'[0-9]')},
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Perfil",
          style: GoogleFonts.pixelifySans(
            fontSize: 20,
            color: const Color(0xFFFF2BA0),
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFFF2BA0)),
            onPressed: _logout,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card de informações pessoais
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFF2BA0), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Dados Pessoais",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF2BA0),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nomeController,
                      label: "Nome completo",
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _cpfController,
                      label: "CPF",
                      icon: Icons.badge,
                      inputFormatters: [cpfMask],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _celController,
                      label: "Celular",
                      icon: Icons.phone,
                      inputFormatters: [celMask],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _emailController,
                      label: "E-mail",
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card de senha
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFF2BA0), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Alterar Senha",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF2BA0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Deixe em branco para manter a senha atual",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _novaSenhaController,
                      label: "Nova senha",
                      icon: Icons.lock,
                      obscureText: !_mostrarNovaSenha,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _mostrarNovaSenha
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(
                            () => _mostrarNovaSenha = !_mostrarNovaSenha,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card de endereço
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFF2BA0), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Endereço",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF2BA0),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Stack(
                            children: [
                              _buildTextField(
                                controller: _cepController,
                                label: "CEP",
                                icon: Icons.location_on,
                                inputFormatters: [cepMask],
                              ),
                              if (_consultandoCep)
                                Positioned(
                                  right: 8,
                                  top: 12,
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: const Color(0xFFFF2BA0),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: _buildTextField(
                            controller: _complementoController,
                            label: "Rua/Logradouro",
                            icon: Icons.home,
                            enabled: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _numeroController,
                      label: "Número",
                      icon: Icons.numbers,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botão salvar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _salvarDados,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF2BA0),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          "Salvar Alterações",
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      enabled: enabled,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: enabled ? Colors.black87 : Colors.grey[600],
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: const Color(0xFFFF2BA0)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: enabled ? Colors.grey[50] : Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF2BA0), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          if (label == "Nova senha") return null; // Nova senha é opcional
          if (label == "Rua/Logradouro") {
            return null; // Rua/Logradouro é preenchido automaticamente pelo CEP
          }
          return 'Campo obrigatório';
        }
        if (label == "E-mail" &&
            (!value.contains('@') || !value.contains('.'))) {
          return 'E-mail inválido';
        }
        return null;
      },
    );
  }
}

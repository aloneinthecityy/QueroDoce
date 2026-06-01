import 'package:app/controllers/entregador_controller.dart';
import 'package:app/controllers/empresa_controller.dart';
import 'package:app/entregador_page.dart';
import 'package:app/pages/empresa_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum LoginRole { entregador, empresa }

class RoleLoginPage extends StatefulWidget {
  const RoleLoginPage({super.key, required this.role});

  final LoginRole role;

  @override
  State<RoleLoginPage> createState() => _RoleLoginPageState();
}

class _RoleLoginPageState extends State<RoleLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _loading = false;

  bool get _isEntregador => widget.role == LoginRole.entregador;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      if (_isEntregador) {
        await _loginEntregador();
      } else {
        await _loginEmpresa();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginEntregador() async {
    final entregador = await EntregadorController.login(
      _emailController.text.trim(),
      _senhaController.text.trim(),
    );

    if (!mounted) return;

    if (entregador == null) {
      _showError('Entregador nao encontrado ou senha invalida.');
      return;
    }

    if (entregador.idEntregador <= 0) {
      _showError('Login retornou um ID de entregador invalido.');
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EntregadorPage(entregadorId: entregador.idEntregador),
      ),
    );
  }

  Future<void> _loginEmpresa() async {
    final empresa = await EmpresaController.login(
      _emailController.text.trim(),
      _senhaController.text.trim(),
    );

    if (!mounted) return;

    if (empresa == null) {
      _showError(
        EmpresaController.ultimoErroLogin ??
            'Empresa nao encontrada ou senha invalida.',
      );
      return;
    }

    if (empresa.idEmpresa <= 0) {
      _showError('Login retornou um ID de empresa invalido.');
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => EmpresaPage(empresa: empresa)),
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

  @override
  Widget build(BuildContext context) {
    final title = _isEntregador ? 'Login do entregador' : 'Login da empresa';
    final icon = _isEntregador ? Icons.delivery_dining : Icons.storefront;
    final subtitle = _isEntregador
        ? 'Acesse suas entregas'
        : 'Acesse os pedidos da loja';

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
              constraints: const BoxConstraints(maxWidth: 420),
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
                      Image.asset("assets/images/logo.png", height: 70),
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
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const Divider(
                        color: Color(0xFFFBD0E8),
                        thickness: 0.6,
                        height: 1,
                      ),
                      const SizedBox(height: 24),
                      _buildField(
                        controller: _emailController,
                        label: 'Endereco de email:',
                        hint: 'exemplo@gmail.com',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _senhaController,
                        label: 'Senha:',
                        hint: '****************',
                        icon: Icons.lock_outline,
                        obscureText: true,
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _login,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.login),
                          label: Text(_loading ? 'Entrando...' : 'Entrar'),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
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
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Informe ${label.replaceAll(':', '').toLowerCase()}';
            }
            return null;
          },
          style: GoogleFonts.inter(
            color: const Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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

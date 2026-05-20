import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../services/certiva_api_service.dart';
import 'verification_otp_screen.dart';

class GenerarContrasenaScreen extends StatefulWidget {
  final User user;
  final int prepagaCode;

  const GenerarContrasenaScreen({
    Key? key,
    required this.user,
    required this.prepagaCode,
  }) : super(key: key);

  @override
  State<GenerarContrasenaScreen> createState() => _GenerarContrasenaScreenState();
}

class _GenerarContrasenaScreenState extends State<GenerarContrasenaScreen> {
  final Color _primaryLilac = const Color(0xFFB47EDB);
  final Color _onSurface = const Color(0xFF1F1F1F);
  final Color _onSurfaceVariant = const Color(0xFF6B6E75);
  final Color _inputFillColor = const Color(0xFFF4F6F9);

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repeatPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureRepeatPassword = true;
  bool _isLoading = false;

  double _passwordStrength = 0.0;
  String _passwordStrengthLabel = 'Baja';
  Color _passwordStrengthColor = Colors.red;

  @override
  void initState() {
    super.initState();
    passwordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    passwordController.removeListener(_checkPasswordStrength);
    passwordController.dispose();
    repeatPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    final password = passwordController.text;
    double strength = 0.0;

    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0.0;
        _passwordStrengthLabel = 'Baja';
        _passwordStrengthColor = Colors.grey;
      });
      return;
    }

    if (password.length > 6) strength += 0.25;
    if (password.length > 10) strength += 0.25;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (password.contains(RegExp(r'[A-Z]')) || password.contains(RegExp(r'[!@#\$&*~]'))) {
      strength += 0.25;
    }

    String label;
    Color color;
    if (strength <= 0.25) {
      label = 'Baja';
      color = Colors.red;
    } else if (strength == 0.5) {
      label = 'Media';
      color = Colors.orange;
    } else if (strength == 0.75) {
      label = 'Buena';
      color = Colors.lightGreen;
    } else {
      label = 'Alta';
      color = const Color(0xFF4CAF50);
    }

    setState(() {
      _passwordStrength = strength;
      _passwordStrengthLabel = label;
      _passwordStrengthColor = color;
    });
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? const Color(0xFFBA1A1A) : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _guardarContrasena() async {
    if (passwordController.text.isEmpty || repeatPasswordController.text.isEmpty) {
      _showSnackBar('Por favor completa todos los campos.', isError: true);
      return;
    }

    if (passwordController.text != repeatPasswordController.text) {
      _showSnackBar('Las contraseñas no coinciden.', isError: true);
      return;
    }

    if (_passwordStrength < 0.5) {
      _showSnackBar('La contraseña es muy débil. Agrega números o mayúsculas.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      final apiResult = await CertivaApiService().registrarCliente(
        email: widget.user.email,
        password: passwordController.text.trim(),
        nombre: widget.user.nombres,
        apellido: widget.user.apellidos,
        cedula: widget.user.cedula,
        prepaga: widget.prepagaCode,
        direccion: widget.user.direccion,
        telefono: widget.user.celular,
      );

      if (!mounted) return;

      if (apiResult['success'] == true) {
        final updatedUser = User(
          nombres: widget.user.nombres,
          apellidos: widget.user.apellidos,
          cedula: widget.user.cedula,
          direccion: widget.user.direccion,
          celular: widget.user.celular,
          email: widget.user.email,
          seguro: widget.user.seguro,
          password: passwordController.text.trim(),
        );
        await UserService.saveUser(updatedUser);

        if (apiResult['status'] == 'requires_verification') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationOtpScreen(
                email: widget.user.email,
                password: passwordController.text.trim(),
              ),
            ),
          );
          return;
        }

        UserService.setCurrentUser(updatedUser);
        _showSnackBar(apiResult['message'] ?? 'Usuario registrado correctamente.');
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        _showSnackBar(apiResult['error'] ?? 'Error al registrar la cuenta.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error de conexión. Intenta nuevamente.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggleVisibility,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      enabled: !_isLoading,
      style: TextStyle(color: _onSurface, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w400),
        prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.grey.shade500, size: 22),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey.shade500,
          ),
          onPressed: _isLoading ? null : onToggleVisibility,
        ),
        filled: true,
        fillColor: _isLoading ? Colors.grey.shade200 : _inputFillColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _primaryLilac.withOpacity(0.5), width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _primaryLilac,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: size.height * 0.10,
              child: Center(
                child: Hero(
                  tag: 'logo',
                  child: Image.asset(
                    'assets/logo_blanco-removebg-preview.png',
                    height: 45,
                  ),
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '¡Hola, ${widget.user.nombres}!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _onSurface,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Crea una contraseña segura para tu cuenta',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _onSurfaceVariant, fontSize: 15),
                  ),
                  const SizedBox(height: 36),
                  _buildPasswordField(
                    controller: passwordController,
                    hint: 'Contraseña',
                    obscure: _obscurePassword,
                    onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _passwordStrength,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _passwordStrengthLabel,
                        style: TextStyle(
                          color: _passwordStrengthColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    controller: repeatPasswordController,
                    hint: 'Repetir contraseña',
                    obscure: _obscureRepeatPassword,
                    onToggleVisibility: () =>
                        setState(() => _obscureRepeatPassword = !_obscureRepeatPassword),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _guardarContrasena,
                      style: FilledButton.styleFrom(
                        backgroundColor: _primaryLilac,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'Crear cuenta',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Al continuar, recibirás un código de verificación en tu correo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

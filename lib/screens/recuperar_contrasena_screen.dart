import 'package:flutter/material.dart';
import '../services/client_api_service.dart';
import 'password_reset_success_screen.dart';

class RecuperarContrasenaScreen extends StatefulWidget {
  const RecuperarContrasenaScreen({Key? key}) : super(key: key);

  @override
  State<RecuperarContrasenaScreen> createState() =>
      _RecuperarContrasenaScreenState();
}

class _RecuperarContrasenaScreenState
    extends State<RecuperarContrasenaScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Definición de colores constantes para mantener consistencia
  final Color _primaryColor = const Color(0xFFB47EDB); // Lila (Botón)
  final Color _secondaryColor = const Color(0xFF09D5D6); // Cyan (Texto/Bordes)
  final Color _backgroundColor = const Color(0xFFF7F9FC); // Fondo sutil

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    // Cerrar el teclado al enviar
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ClientApiService.requestPasswordReset(email);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const PasswordResetSuccessScreen(),
          ),
        );
      } else {
        _showSnackBar('No se pudo enviar el email. Verifique que el correo esté registrado.', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Error al solicitar recuperación: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // GestureDetector para cerrar el teclado al tocar cualquier parte blanca
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black54),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Logo con Hero para animación suave si viene del login
                  Hero(
                    tag: 'app_logo',
                    child: Center(
                      child: Image.asset(
                        'assets/icons/logo_color.png',
                        width: 180, // Tamaño ajustado
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Título
                  Text(
                    'Recuperar contraseña',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24, // Más grande
                      fontWeight: FontWeight.bold,
                      color: _secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Descripción
                  Text(
                    'Ingresa el correo electrónico asociado a tu cuenta y te enviaremos las instrucciones para restablecer tu contraseña.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      height: 1.5, // Mejor lectura
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Campo de Email
                  _buildEmailField(),

                  const SizedBox(height: 40),

                  // Botón de Enviar
                  SizedBox(
                    height: 55, // Botón más alto
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: _primaryColor.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // Bordes más redondeados
                        ),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text(
                        'ENVIAR ENLACE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Botón volver texto simple
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Volver al inicio de sesión',
                      style: TextStyle(
                        color: Colors.grey[600],
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
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Correo electrónico',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          enabled: !_isLoading,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'ejemplo@correo.com',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[50], // Fondo sutil para el input
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _secondaryColor, // Color Cyan al enfocar
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            prefixIcon: Icon(
              Icons.email_outlined,
              color: _secondaryColor,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor ingrese su correo';
            }
            // Validación básica de regex para email
            final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
            if (!emailRegex.hasMatch(value)) {
              return 'Ingrese un correo electrónico válido';
            }
            return null;
          },
        ),
      ],
    );
  }
}
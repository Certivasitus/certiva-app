import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../services/certiva_api_service.dart';

class GenerarContrasenaScreen extends StatefulWidget {
  final User user;
  final int prepagaCode;
  const GenerarContrasenaScreen({Key? key, required this.user, required this.prepagaCode}) : super(key: key);

  @override
  State<GenerarContrasenaScreen> createState() => _GenerarContrasenaScreenState();
}

class _GenerarContrasenaScreenState extends State<GenerarContrasenaScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repeatPasswordController = TextEditingController();
  bool showPassword = false;
  bool showRepeatPassword = false;

  // Variables para la complejidad de la contraseña
  double _passwordStrength = 0.0;
  String _passwordStrengthLabel = 'Baja';
  Color _passwordStrengthColor = Colors.red;

  @override
  void initState() {
    super.initState();
    // Escuchar cambios en el controlador de la contraseña
    passwordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    passwordController.removeListener(_checkPasswordStrength);
    passwordController.dispose();
    repeatPasswordController.dispose();
    super.dispose();
  }

  // Lógica para evaluar la contraseña
  void _checkPasswordStrength() {
    String password = passwordController.text;
    double strength = 0.0;

    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0.0;
        _passwordStrengthLabel = 'Baja';
        _passwordStrengthColor = Colors.grey;
      });
      return;
    }

    // Regla 1: Longitud mayor a 6 caracteres
    if (password.length > 6) strength += 0.25;
    // Regla 2: Longitud mayor a 10 caracteres
    if (password.length > 10) strength += 0.25;
    // Regla 3: Contiene al menos un número
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;
    // Regla 4: Contiene al menos una letra mayúscula o un carácter especial
    if (password.contains(RegExp(r'[A-Z]')) || password.contains(RegExp(r'[!@#\$&*~]'))) strength += 0.25;

    // Asignar colores y etiquetas basados en el puntaje
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
      color = const Color(0xFF09D5D6); // Cyan
    }

    setState(() {
      _passwordStrength = strength;
      _passwordStrengthLabel = label;
      _passwordStrengthColor = color;
    });
  }

  void _guardarContrasena() async {
    if (passwordController.text.isEmpty || repeatPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    if (passwordController.text != repeatPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    // Opcional: Validar que la contraseña sea al menos "Media"
    if (_passwordStrength < 0.5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña es muy débil. Intenta agregar números o mayúsculas.')),
      );
      return;
    }

    // Loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

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
      Navigator.pop(context); // cerrar loader

      if (apiResult['success'] == true) {
        // Guardar local
        final updatedUser = User(
          nombres: widget.user.nombres,
          apellidos: widget.user.apellidos,
          cedula: widget.user.cedula,
          direccion: widget.user.direccion,
          celular: widget.user.celular,
          email: widget.user.email,
          seguro: widget.user.seguro,
          password: passwordController.text,
        );
        await UserService.saveUser(updatedUser);
        UserService.setCurrentUser(updatedUser);

        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Registro Exitoso'),
              content: Text(apiResult['message'] ?? 'Usuario registrado correctamente'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            ),
          );
        }
      } else {
        // Error backend
        final errorMsg = apiResult['error'] ?? 'Error desconocido';
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Error en el Registro'),
              content: Text(errorMsg),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Aceptar'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e, stacktrace) {
      if (!mounted) return;
      Navigator.pop(context); // cerrar loader

      print('=== ERROR CAPTURADO EN LA UI ===');
      print(e);
      print(stacktrace);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error de Conexión'),
          content: Text('Revisa la consola para ver el error exacto.\nDetalle: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo a color
                Image.asset(
                  'assets/icons/logo_color.png',
                  width: 180,
                ),
                const SizedBox(height: 18),
                // Título y saludo
                Text(
                  '¡Hola ${widget.user.nombres}!',
                  style: const TextStyle(
                    color: Color(0xFF09D5D6),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Favor generar contraseña',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                // Campo contraseña
                TextField(
                  controller: passwordController,
                  obscureText: !showPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: const TextStyle(color: Colors.black),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF09D5D6)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF09D5D6), width: 2),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          showPassword = !showPassword;
                        });
                      },
                    ),
                  ),
                ),
                // Indicador de contraseña válido DÍNAMICO
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      passwordController.text.isEmpty ? 'Nivel de seguridad' : 'Contraseña ${_passwordStrengthLabel.toLowerCase()}',
                      style: TextStyle(
                        color: _passwordStrengthColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: _passwordStrength,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(4), // Opcional: bordes redondeados
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _passwordStrengthColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _passwordStrengthLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Campo repetir contraseña
                TextField(
                  controller: repeatPasswordController,
                  obscureText: !showRepeatPassword,
                  decoration: InputDecoration(
                    labelText: 'Repetir contraseña',
                    labelStyle: const TextStyle(color: Colors.black),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF09D5D6)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF09D5D6), width: 2),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showRepeatPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          showRepeatPassword = !showRepeatPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Logo animado (simulado con el logo pequeño)
                Image.asset(
                  'assets/icons/logo_color.png',
                  width: 50,
                ),
                const SizedBox(height: 18),
                // Botón de registro
                Center(
                  child: SizedBox(
                    width: 220,
                    child: ElevatedButton(
                      onPressed: _guardarContrasena,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB47EDB),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Registrarme',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
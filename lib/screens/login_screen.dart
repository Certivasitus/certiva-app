import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'register_screen.dart';
import 'bienvenida_screen.dart';
import 'recuperar_contrasena_screen.dart';
import '../services/user_service.dart';
import '../services/client_api_service.dart';
import '../services/security_service.dart';
import '../models/user.dart' as app_user;
import '../screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- Colores ---
  final Color _primaryLilac = const Color(0xFFB47EDB);
  final Color _onSurface = const Color(0xFF1F1F1F);
  final Color _onSurfaceVariant = const Color(0xFF6B6E75);
  final Color _inputFillColor = const Color(0xFFF4F6F9);

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool rememberMe = false;
  bool _obscurePassword = true;

  bool _isLoadingForm = false;
  bool _isLoadingGoogle = false;

  // --- Biometría ---
  bool _showBiometricButton = false;

  // Control para no spamear el diálogo si toca el input varias veces
  bool _biometricPromptShown = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();

    // Auto-lanzar biometría apenas la pantalla termina de cargar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoTriggerBiometrics();
    });
  }

  void _loadSavedCredentials() {
    final savedCredentials = UserService.getSavedLoginCredentials();
    if (savedCredentials != null) {
      setState(() {
        emailController.text = savedCredentials['email'] ?? '';
        passwordController.text = savedCredentials['password'] ?? '';
        rememberMe = true;
      });
    }
  }

  // LÓGICA DE AUTO-LANZAMIENTO ---
  Future<void> _autoTriggerBiometrics() async {
    final isSupported = await SecurityService.isBiometricSupported();
    final isEnabled = await SecurityService.isBiometricEnabled();

    // Si el teléfono tiene huella y el usuario la configuró...
    if (isSupported && isEnabled && mounted) {
      setState(() {
        _showBiometricButton = true; // Mostramos el botón por si cancela
      });

      // Lanzamos el lector automáticamente
      await _loginWithBiometrics();
    }
  }
  // --- LÓGICA DE LOGIN CON HUELLA ---
  Future<void> _loginWithBiometrics() async {
    final didAuthenticate = await SecurityService.authenticateWithBiometrics();
    if (didAuthenticate) {
      final credentials = await SecurityService.getSavedBiometricCredentials();
      if (credentials != null) {
        // Ponemos las credenciales en los inputs y disparamos el login manual
        setState(() {
          emailController.text = credentials['email']!;
          passwordController.text = credentials['password']!;
        });
        _login(); // Inicia sesión silenciosamente
      } else {
        _showErrorSnackBar('No se encontraron credenciales guardadas.');
      }
    }
  }

  Future<void> _checkBiometricStatus() async {
    final isSupported = await SecurityService.isBiometricSupported();
    final isEnabled = await SecurityService.isBiometricEnabled();

    if (isSupported && isEnabled && mounted) {
      setState(() {
        _showBiometricButton = true;
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // --- LOGICA DE INICIO DE SESIÓN MANUAL ---
  Future<void> _login() async {
    setState(() => _isLoadingForm = true);
    FocusScope.of(context).unfocus();

    final email = emailController.text.trim();
    final password = passwordController.text;

    final url = Uri.parse('https://kove.app.kove.com.py/ords/certiva_situs/app/autenticacion');
    final String rawAuth = '${Uri.encodeComponent('CERTIVA_APP')}:${Uri.encodeComponent('CerTiva2028*')}';
    final basicAuth = 'Basic ' + base64Encode(utf8.encode(rawAuth));

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': basicAuth,
        },
        body: jsonEncode({
          'username': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success' && responseData['autenticado'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('google_photo_url');

          if (rememberMe) {
            await UserService.saveLoginCredentials(email, password);
          } else {
            await UserService.clearLoginCredentials();
          }

          app_user.User? userToSet = await ClientApiService.getClientByEmail(email);
          if (userToSet == null) {
            userToSet = await UserService.getUserByEmail(email);
          }

          if (userToSet != null) {
            await UserService.saveUser(userToSet);
            UserService.setCurrentUser(userToSet);

            if (mounted) {
              setState(() => _isLoadingForm = false);
              await _askForBiometricSetup(email, password);
              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
              }
            }
            return;
          } else {
            _showErrorSnackBar('No se pudieron obtener los datos de la cuenta.');
          }
        }
        else if (responseData['status'] == 'blocked') {
          final int idCliente = responseData['id_cliente'];
          setState(() => _isLoadingForm = false);
          final confirmoReactivacion = await _mostrarDialogoReactivacion(idCliente);
          if (confirmoReactivacion) {
            _login();
            return;
          }
        }
        else {
          _showErrorSnackBar(responseData['mensaje'] ?? 'Usuario o contraseña incorrectos');
        }
      } else {
        _showErrorSnackBar('Error de conexión (HTTP ${response.statusCode})');
      }
    } catch (e) {
      _showErrorSnackBar('Error al iniciar sesión: Verifica tu conexión');
    } finally {
      if (mounted) setState(() => _isLoadingForm = false);
    }
  }

  Future<void> _askForBiometricSetup(String email, String password) async {
    final isSupported = await SecurityService.isBiometricSupported();
    final isAlreadyEnabled = await SecurityService.isBiometricEnabled();

    if (isSupported && !isAlreadyEnabled && mounted) {
      final quiereActivar = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(Icons.fingerprint_rounded, color: _primaryLilac, size: 28),
                const SizedBox(width: 10),
                const Text('Inicio rápido', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: const Text(
              '¿Deseas activar el inicio de sesión con huella digital / reconocimiento facial para la próxima vez?',
              style: TextStyle(fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Ahora no', style: TextStyle(color: _onSurfaceVariant)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _primaryLilac),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sí, activar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );

      if (quiereActivar == true) {
        await SecurityService.enableBiometricLogin(email, password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inicio de sesión biométrico activado.'), backgroundColor: Colors.green),
          );
        }
      }
    }
  }

  // --- LÓGICA DE GOOGLE SIGN-IN ---
  Future<void> _loginWithGoogle() async {
    setState(() => _isLoadingGoogle = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        if (mounted) setState(() => _isLoadingGoogle = false);
        return;
      }

      final email = googleUser.email;
      final photoUrl = googleUser.photoUrl;

      if (email.isEmpty) throw Exception('Google no devolvió un email válido.');

      await _handleSuccessfulAuth(email, photoUrl);
    } catch (e) {
      try { await GoogleSignIn().signOut(); } catch (_) {}
      _showErrorSnackBar('Error de Google: $e');
      if (mounted) setState(() => _isLoadingGoogle = false);
    }
  }

  Future<void> _handleSuccessfulAuth(String email, String? photoUrl) async {
    if (photoUrl != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('google_photo_url', photoUrl);
    }

    try {
      final app_user.User? userFromApi = await ClientApiService.getClientByEmail(email);

      if (userFromApi == null) {
        try { await GoogleSignIn().signOut(); } catch (_) {}
        if (mounted) {
          setState(() => _isLoadingGoogle = false);
          _mostrarDialogoRegistro(email);
        }
        return;
      }

      if (userFromApi.idCliente != null) {
        final estaBloqueado = await ClientApiService.isAccountBlocked(userFromApi.idCliente!);
        if (estaBloqueado) {
          setState(() => _isLoadingGoogle = false);
          final confirmoReactivacion = await _mostrarDialogoReactivacion(userFromApi.idCliente!);
          if (!confirmoReactivacion) {
            try { await GoogleSignIn().signOut(); } catch (_) {}
            return;
          } else {
            setState(() => _isLoadingGoogle = true);
          }
        }
      }

      await UserService.saveUser(userFromApi);
      UserService.setCurrentUser(userFromApi);

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    } catch (e) {
      _showErrorSnackBar('Error validando usuario: $e');
      if (mounted) setState(() => _isLoadingGoogle = false);
    }
  }

  void _mostrarDialogoRegistro(String correoInvalido) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Correo no registrado', style: TextStyle(color: _onSurface, fontWeight: FontWeight.bold)),
          content: Text(
            'El correo $correoInvalido no está asociado a ningún paciente.\n\n¿Desea crear una cuenta nueva?',
            style: TextStyle(color: _onSurfaceVariant, fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar', style: TextStyle(color: _onSurfaceVariant)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _primaryLilac),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen(emailPrellenado: correoInvalido)));
              },
              child: const Text('Crear Cuenta', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFBA1A1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<bool> _mostrarDialogoReactivacion(int idCliente) async {
    bool reactivado = false;
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          bool isReactivating = false;
          return StatefulBuilder(
              builder: (context, setStateDialog) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  title: Row(
                    children: [
                      Icon(Icons.restore, color: _primaryLilac),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Cuenta Desactivada', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                    ],
                  ),
                  content: isReactivating
                      ? SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: _primaryLilac)))
                      : const Text('Tu cuenta se encuentra en proceso de eliminación programada.\n\n¿Deseas cancelar la eliminación y reactivar tu cuenta para iniciar sesión?'),
                  actions: isReactivating ? [] : [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancelar', style: TextStyle(color: _onSurfaceVariant)),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: _primaryLilac),
                      onPressed: () async {
                        setStateDialog(() => isReactivating = true);
                        final result = await ClientApiService.reactivateAccount(idCliente);
                        setStateDialog(() => isReactivating = false);

                        if (result['success'] == true) {
                          reactivado = true;
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.green));
                          }
                        } else {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: const Color(0xFFBA1A1A)));
                        }
                      },
                      child: const Text('Sí, reactivar', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                );
              }
          );
        }
    );
    return reactivado;
  }

  // --- WIDGET HELPER PARA INPUTS MINIMALISTAS ---
  // 👇 NUEVO: Se agregó parámetro onTap opcional
  Widget _buildMinimalField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool enabled = true,
    VoidCallback? onTap, // <-- Permite disparar acciones al tocar el campo
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      enabled: enabled,
      onTap: onTap, // <-- Asignamos el evento
      style: TextStyle(color: _onSurface, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w400),
        prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 22),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade500),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        )
            : null,
        filled: true,
        fillColor: enabled ? _inputFillColor : Colors.grey.shade200,
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _primaryLilac.withOpacity(0.5), width: 1.5)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _primaryLilac,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: size.height * 0.22,
                child: Center(
                  child: Hero(
                    tag: 'logo',
                    child: Image.asset('assets/logo_blanco-removebg-preview.png', height: 55),
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
                borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
              ),
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '¡Hola de nuevo!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _onSurface, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Inicia sesión para continuar',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _onSurfaceVariant, fontSize: 15, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 36),

                  // 👇 CAMBIO AQUÍ: Evento onTap en el campo de correo 👇
                  _buildMinimalField(
                    controller: emailController,
                    hint: 'Correo electrónico',
                    icon: Icons.email_outlined,
                    enabled: !_isLoadingForm && !_isLoadingGoogle,
                    onTap: () {
                      // Si la biometría está activa y no se ha mostrado aún el diálogo
                      if (_showBiometricButton && !_biometricPromptShown) {
                        setState(() => _biometricPromptShown = true); // Marcamos como mostrado
                        // Quitamos el foco para que no se levante el teclado si usa la huella
                        FocusScope.of(context).unfocus();
                        _loginWithBiometrics();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildMinimalField(
                    controller: passwordController,
                    hint: 'Contraseña',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    enabled: !_isLoadingForm && !_isLoadingGoogle,
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: rememberMe,
                              activeColor: _primaryLilac,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              side: BorderSide(color: Colors.grey.shade400),
                              onChanged: (_isLoadingForm || _isLoadingGoogle) ? null : (val) => setState(() => rememberMe = val ?? false),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('Recordarme', style: TextStyle(color: _onSurfaceVariant, fontSize: 14)),
                        ],
                      ),
                      TextButton(
                        onPressed: (_isLoadingForm || _isLoadingGoogle) ? null : () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const RecuperarContrasenaScreen()));
                        },
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: Text('¿Olvidaste?', style: TextStyle(color: _primaryLilac, fontWeight: FontWeight.bold, fontSize: 14)),
                      )
                    ],
                  ),

                  const SizedBox(height: 36),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: FilledButton(
                            onPressed: (_isLoadingForm || _isLoadingGoogle) ? null : _login,
                            style: FilledButton.styleFrom(backgroundColor: _primaryLilac, shape: const StadiumBorder(), elevation: 0),
                            child: _isLoadingForm
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : const Text('Iniciar sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          ),
                        ),
                      ),

                      if (_showBiometricButton) ...[
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 56,
                          width: 56,
                          child: FilledButton(
                            onPressed: (_isLoadingForm || _isLoadingGoogle) ? null : _loginWithBiometrics,
                            style: FilledButton.styleFrom(
                              backgroundColor: _inputFillColor,
                              foregroundColor: _primaryLilac,
                              shape: const CircleBorder(),
                              padding: EdgeInsets.zero,
                              elevation: 0,
                            ),
                            child: const Icon(Icons.fingerprint_rounded, size: 28),
                          ),
                        ),
                      ]
                    ],
                  ),

                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1.5)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('O continúa con', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1.5)),
                    ],
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: (_isLoadingForm || _isLoadingGoogle) ? null : _loginWithGoogle,
                      icon: _isLoadingGoogle
                          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: _primaryLilac, strokeWidth: 2.5))
                          : Image.asset('assets/icons/android_light_rd_na@1x.png', height: 24.0, width: 24.0),
                      label: Text('Google', style: TextStyle(color: _onSurface, fontWeight: FontWeight.w600, fontSize: 16)),
                      style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300, width: 1.5), shape: const StadiumBorder(), elevation: 0),
                    ),
                  ),

                  const Spacer(),

                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('¿No tienes una cuenta? ', style: TextStyle(color: _onSurfaceVariant, fontSize: 14)),
                          GestureDetector(
                            onTap: (_isLoadingForm || _isLoadingGoogle) ? null : () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                            },
                            child: Text('Regístrate', style: TextStyle(color: _primaryLilac, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
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
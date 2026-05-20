import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/certiva_api_service.dart';
import '../services/user_service.dart';
import '../services/client_api_service.dart';
import '../services/api_client.dart';
import '../models/user.dart' as app_user;
import 'home_screen.dart';
import 'login_screen.dart';

class VerificationOtpScreen extends StatefulWidget {
  final String email;
  final bool isFromLogin;
  final String? password;

  const VerificationOtpScreen({
    Key? key,
    required this.email,
    this.isFromLogin = false,
    this.password,
  }) : super(key: key);

  @override
  State<VerificationOtpScreen> createState() => _VerificationOtpScreenState();
}

class _VerificationOtpScreenState extends State<VerificationOtpScreen> {
  final Color _primaryLilac = const Color(0xFFB47EDB);
  final Color _onSurface = const Color(0xFF1F1F1F);
  final Color _onSurfaceVariant = const Color(0xFF6B6E75);
  final Color _inputFillColor = const Color(0xFFF4F6F9);

  static const int _codeLength = 6;
  static const int _resendCooldownSeconds = 60;

  final List<TextEditingController> _digitControllers = List.generate(
    _codeLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _codeLength,
    (_) => FocusNode(),
  );

  bool _isLoading = false;
  bool _isResending = false;
  int _resendSecondsLeft = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _digitControllers.map((c) => c.text).join();

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSecondsLeft = _resendCooldownSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSecondsLeft <= 1) {
        timer.cancel();
        setState(() => _resendSecondsLeft = 0);
      } else {
        setState(() => _resendSecondsLeft -= 1);
      }
    });
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (var i = 0; i < digits.length && index + i < _codeLength; i++) {
        _digitControllers[index + i].text = digits[i];
      }
      final nextIndex = (index + digits.length).clamp(0, _codeLength - 1);
      _focusNodes[nextIndex].requestFocus();
      setState(() {});
      return;
    }

    if (value.isNotEmpty && index < _codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  Future<String?> _resolvePassword() async {
    if (widget.password != null && widget.password!.isNotEmpty) {
      return widget.password;
    }
    final localUser = await UserService.getUserByEmail(widget.email);
    if (localUser != null && localUser.password.isNotEmpty) {
      return localUser.password;
    }
    return null;
  }

  Future<bool> _signInWithPassword(String password) async {
    final responseData = await ApiClient.post('/app/autenticacion', {
      'username': widget.email,
      'password': password,
    });

    if (responseData == null ||
        responseData['status'] != 'success' ||
        responseData['autenticado'] != true) {
      return false;
    }

    app_user.User? userToSet = await ClientApiService.getClientByEmail(
      widget.email,
    );
    userToSet ??= await UserService.getUserByEmail(widget.email);

    if (userToSet == null) return false;

    if (userToSet.password.isEmpty) {
      userToSet.password = password;
    }

    await UserService.saveUser(userToSet);
    UserService.setCurrentUser(userToSet);
    return true;
  }

  Future<bool> _completeSessionAfterVerification() async {
    final password = await _resolvePassword();
    if (password != null) {
      return _signInWithPassword(password);
    }

    if (widget.isFromLogin) {
      final user = await ClientApiService.getClientByEmail(widget.email);
      if (user != null) {
        await UserService.saveUser(user);
        UserService.setCurrentUser(user);
        return true;
      }
    }

    return false;
  }

  Future<void> _verifyCode() async {
    final code = _otpCode;
    if (code.length < _codeLength) {
      _showSnackBar('Ingresa el código de 6 dígitos.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      final result = await CertivaApiService().verificarCodigo(
        widget.email,
        code,
      );
      if (!mounted) return;

      if (result['success'] == true) {
        final signedIn = await _completeSessionAfterVerification();
        if (!mounted) return;

        if (signedIn) {
          _showSnackBar('¡Cuenta verificada! Bienvenido.');
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        } else {
          _showSnackBar(
            'Cuenta verificada. Inicia sesión con tu contraseña.',
            isError: false,
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } else {
        _showSnackBar(
          result['message'] ?? 'Código incorrecto o expirado.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Error al verificar el código.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    if (_resendSecondsLeft > 0 || _isResending) return;

    setState(() => _isResending = true);
    try {
      final result = await CertivaApiService().reenviarCodigo(widget.email);
      if (!mounted) return;

      if (result['success'] == true) {
        _showSnackBar(result['message'] ?? 'Nuevo código enviado a su correo.');
        for (final c in _digitControllers) {
          c.clear();
        }
        _focusNodes.first.requestFocus();
        _startResendCooldown();
      } else {
        _showSnackBar(
          result['message'] ?? 'No se pudo reenviar el código.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Error al reenviar el código.', isError: true);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
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

  Widget _buildOtpField(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: _digitControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        enabled: !_isLoading,
        style: TextStyle(
          color: _onSurface,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: _isLoading ? Colors.grey.shade200 : _inputFillColor,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: _primaryLilac.withOpacity(0.6),
              width: 1.5,
            ),
          ),
        ),
        onChanged: (value) => _onDigitChanged(index, value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final canResend = _resendSecondsLeft == 0 && !_isResending;

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
                  Icon(
                    Icons.mark_email_read_outlined,
                    size: 48,
                    color: _primaryLilac,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Verifica tu cuenta',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _onSurface,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ingresa el código de 6 dígitos que enviamos a:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _onSurfaceVariant,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.email,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'El código expira en 15 minutos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                  const SizedBox(height: 36),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_codeLength, _buildOtpField),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _verifyCode,
                      style: FilledButton.styleFrom(
                        backgroundColor: _primaryLilac,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                              : const Text(
                                'Verificar código',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: canResend ? _resendCode : null,
                    child:
                        _isResending
                            ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _primaryLilac,
                              ),
                            )
                            : Text(
                              _resendSecondsLeft > 0
                                  ? 'Reenviar código en ${_resendSecondsLeft}s'
                                  : '¿No recibiste el código? Reenviar',
                              style: TextStyle(
                                color:
                                    canResend
                                        ? _primaryLilac
                                        : _onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                  ),
                  const Spacer(),
                  Text(
                    'Revisa tu carpeta de spam si no encuentras el correo.',
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

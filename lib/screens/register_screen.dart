import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';
import '../services/prepaga_service.dart'; // <--- Ajusta esta ruta si es necesario
import '../models/user.dart';
import '../services/user_service.dart';
import 'generar_contrasena_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String? emailPrellenado;

  const RegisterScreen({
    Key? key,
    this.emailPrellenado,
  }) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // --- Colores estilo Login ---
  final Color _primaryLilac = const Color(0xFFB47EDB); // Lila Certiva
  final Color _onSurface = const Color(0xFF1F1F1F); // Texto oscuro principal
  final Color _onSurfaceVariant = const Color(0xFF6B6E75); // Texto secundario
  final Color _inputFillColor = const Color(0xFFF4F6F9); // Fondo gris claro de inputs

  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController namesCtrl = TextEditingController();
  final TextEditingController surnamesCtrl = TextEditingController();
  final TextEditingController idCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController insuranceCtrl = TextEditingController();

  // --- VARIABLES DE ESTADO ---
  List<Prepaga> _listaPrepagas = [];
  String? _selectedPrepagaId;
  bool _isLoadingPrepagas = true;
  bool _isLoadingSubmit = false;

  @override
  void initState() {
    super.initState();

    if (widget.emailPrellenado != null) {
      emailCtrl.text = widget.emailPrellenado!;
    }

    _cargarPrepagas();
  }

  // Cargar datos del API
  Future<void> _cargarPrepagas() async {
    try {
      final prepagas = await PrepagaService.getPrepagas();
      if (mounted) {
        setState(() {
          _listaPrepagas = prepagas;
          _isLoadingPrepagas = false;
        });
      }
    } catch (e) {
      print('Error cargando prepagas: $e');
      if (mounted) {
        setState(() => _isLoadingPrepagas = false);
      }
    }
  }

  @override
  void dispose() {
    namesCtrl.dispose();
    surnamesCtrl.dispose();
    idCtrl.dispose();
    addressCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    insuranceCtrl.dispose();
    super.dispose();
  }

  void _registrarUsuario() async {
    if (_formKey.currentState!.validate()) {

      if (_selectedPrepagaId == null) {
        _showErrorSnackBar('Por favor, seleccione un seguro médico.');
        return;
      }

      setState(() => _isLoadingSubmit = true);
      FocusScope.of(context).unfocus();

      final int prepagaCodeInt = int.tryParse(_selectedPrepagaId!) ?? 0;

      try {
        await Future.delayed(const Duration(milliseconds: 500));

        final user = User(
          nombres: namesCtrl.text.trim(),
          apellidos: surnamesCtrl.text.trim(),
          cedula: idCtrl.text.trim(),
          direccion: addressCtrl.text.trim(),
          celular: phoneCtrl.text.trim(),
          email: emailCtrl.text.trim(),
          seguro: insuranceCtrl.text,
          password: '',
        );

        await UserService.saveUser(user);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GenerarContrasenaScreen(user: user, prepagaCode: prepagaCodeInt),
            ),
          );
        }
      } catch (e) {
        _showErrorSnackBar('Error: $e');
        if (mounted) setState(() => _isLoadingSubmit = false);
      }
    }
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

  // --- WIDGET HELPER PARA INPUTS MINIMALISTAS ---
  Widget _buildMinimalField({
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool isNumeric = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : keyboardType,
      inputFormatters: isNumeric ? [FilteringTextInputFormatter.digitsOnly] : [],
      enabled: !_isLoadingSubmit,
      style: TextStyle(color: _onSurface, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w400),
        prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 22),
        filled: true,
        fillColor: _isLoadingSubmit ? Colors.grey.shade200 : _inputFillColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _primaryLilac.withOpacity(0.5), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Requerido';
        if (isNumeric && hint.toLowerCase().contains('cédula') && value.length < 5) return 'Inválido';
        return null;
      },
    );
  }

  // --- WIDGET HELPER PARA DROPDOWN MINIMALISTA ---
  Widget _buildMinimalDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedPrepagaId,
      style: TextStyle(color: _onSurface, fontWeight: FontWeight.w500, fontSize: 15),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade500),
      decoration: InputDecoration(
        hintText: _isLoadingPrepagas ? 'Cargando seguros...' : 'Seguro médico / Alianzas',
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w400),
        prefixIcon: _isLoadingPrepagas
            ? Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: _primaryLilac)),
        )
            : Icon(Icons.health_and_safety_outlined, color: Colors.grey.shade500, size: 22),
        filled: true,
        fillColor: _isLoadingSubmit ? Colors.grey.shade200 : _inputFillColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _primaryLilac.withOpacity(0.5), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1),
        ),
      ),
      items: _listaPrepagas.map((prepaga) {
        return DropdownMenuItem<String>(
          value: prepaga.id,
          child: Text(
            prepaga.nombre,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15, color: _onSurface),
          ),
        );
      }).toList(),
      onChanged: _isLoadingSubmit ? null : (val) {
        setState(() {
          _selectedPrepagaId = val;
          if (val != null) {
            final selectedPrepaga = _listaPrepagas.firstWhere((p) => p.id == val, orElse: () => Prepaga(id: '0', nombre: ''));
            insuranceCtrl.text = selectedPrepaga.nombre;
          }
        });
      },
      validator: (val) => val == null ? 'Requerido' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _primaryLilac, // 👇 FONDO LILA SÓLIDO SUPERIOR
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), // Flecha blanca
          onPressed: () {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen())
            );
          },
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. CABECERA CON LOGO
          SliverToBoxAdapter(
            child: SizedBox(
              height: size.height * 0.12, // Menos espacio porque ya tenemos el AppBar arriba
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

          // 2. TARJETA BLANCA INFERIOR TIPO "BOTTOM SHEET"
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Títulos
                    Text(
                      'Crear Cuenta',
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
                      'Complete sus datos para comenzar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _onSurfaceVariant,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Campos de Texto
                    _buildMinimalField(hint: 'Nombres', controller: namesCtrl, icon: Icons.person_outline_rounded),
                    const SizedBox(height: 16),

                    _buildMinimalField(hint: 'Apellidos', controller: surnamesCtrl, icon: Icons.person_outline_rounded),
                    const SizedBox(height: 16),

                    _buildMinimalField(hint: 'Cédula de Identidad', controller: idCtrl, icon: Icons.badge_outlined, isNumeric: true),
                    const SizedBox(height: 16),

                    _buildMinimalField(hint: 'Dirección particular', controller: addressCtrl, icon: Icons.location_on_outlined),
                    const SizedBox(height: 16),

                    _buildMinimalField(hint: 'Número de celular', controller: phoneCtrl, icon: Icons.phone_android_rounded, isNumeric: true),
                    const SizedBox(height: 16),

                    _buildMinimalField(hint: 'Correo Electrónico', controller: emailCtrl, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),

                    _buildMinimalDropdown(),

                    const SizedBox(height: 40),

                    // BOTÓN CONTINUAR (Píldora)
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: _isLoadingSubmit ? null : _registrarUsuario,
                        style: FilledButton.styleFrom(
                          backgroundColor: _primaryLilac,
                          shape: const StadiumBorder(), // Bordes totalmente redondeados
                          elevation: 0,
                        ),
                        child: _isLoadingSubmit
                            ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                            : const Text('Continuar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
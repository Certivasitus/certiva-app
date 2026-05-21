import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../services/client_api_service.dart';
import '../services/prepaga_service.dart';
import '../widgets/custom_snackbar.dart';
import '../screens/login_screen.dart';

class MisDatosScreen extends StatefulWidget {
  const MisDatosScreen({Key? key}) : super(key: key);

  @override
  State<MisDatosScreen> createState() => _MisDatosScreenState();
}

class _MisDatosScreenState extends State<MisDatosScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nombresController;
  late TextEditingController apellidosController;
  late TextEditingController cedulaController;
  late TextEditingController direccionController;
  late TextEditingController celularController;
  late TextEditingController emailController;

  List<Prepaga> _listaPrepagas = [];
  String? _selectedPrepagaId;
  bool _isLoadingPrepagas = false;

  bool isEditing = false;
  bool isSaving = false;
  bool _needsPrepagaSetup = false;
  bool _isLoadingProfile = true;

  // Paleta de Colores Moderna
  final Color primaryPurple = const Color(0xFFB47EDB);
  final Color accentCyan = const Color(0xFF09D5D6);
  final Color textDark = const Color(0xFF2D3142);
  final Color textGrey = const Color(0xFF9E9E9E);
  final Color dangerRed = const Color(0xFFF44336);
  final Color backgroundLight = const Color(0xFFF4F6F9); // Fondo más suave
  final Color inputFillColor = const Color(0xFFF8F9FA); // Fondo de inputs

  @override
  void initState() {
    super.initState();
    _initEmptyControllers();
    final cached = UserService.getCurrentUser();
    if (cached != null) _applyUserToForm(cached);
    _loadProfileAndPrepagas();
  }

  void _initEmptyControllers() {
    nombresController = TextEditingController();
    apellidosController = TextEditingController();
    cedulaController = TextEditingController();
    direccionController = TextEditingController();
    celularController = TextEditingController();
    emailController = TextEditingController();
  }

  String? _normalizePrepagaId(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == 'null' || trimmed == '0') return null;
    return trimmed;
  }

  void _applyUserToForm(User user) {
    nombresController.text = user.nombres;
    apellidosController.text = user.apellidos;
    cedulaController.text = user.cedula;
    direccionController.text = user.direccion;
    celularController.text = user.celular;
    emailController.text = user.email;
    _selectedPrepagaId = _normalizePrepagaId(user.seguro);
  }

  void _mergePrepagasConAsignada(User? user) {
    _listaPrepagas = PrepagaService.mergeAssignedPrepaga(
      prepagas: _listaPrepagas,
      assignedId: _selectedPrepagaId,
      assignedNombre: user?.seguroNombre,
    );
  }

  String _resolvePrepagaNombre() {
    if (_selectedPrepagaId == null) return 'Sin seguro seleccionado';
    if (_listaPrepagas.isEmpty) return 'Cargando...';
    final prepaga = PrepagaService.findById(_listaPrepagas, _selectedPrepagaId);
    if (prepaga != null) return prepaga.nombre;
    return 'Seguro médico asignado';
  }

  void _updatePrepagaSetupState({bool initial = false}) {
    _selectedPrepagaId = _normalizePrepagaId(_selectedPrepagaId);
    _needsPrepagaSetup = _selectedPrepagaId == null;
    if (initial) {
      isEditing = _needsPrepagaSetup;
    }
  }

  Future<void> _loadProfileAndPrepagas() async {
    final email = UserService.getCurrentUser()?.email;
    if (email == null) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
          _isLoadingPrepagas = false;
          _updatePrepagaSetupState(initial: true);
        });
      }
      return;
    }

    setState(() => _isLoadingPrepagas = true);

    try {
      final results = await Future.wait([
        PrepagaService.getPrepagas(),
        ClientApiService.fetchClientProfileByEmail(email),
      ]);

      if (!mounted) return;

      final prepagas = results[0] as List<Prepaga>;
      final apiUser = results[1] as User?;

      User? userForForm = apiUser;
      if (apiUser != null) {
        await UserService.saveUser(apiUser);
        UserService.setCurrentUser(apiUser);
        _applyUserToForm(apiUser);
      } else {
        userForForm = UserService.getCurrentUser();
      }

      _listaPrepagas = prepagas;
      _mergePrepagasConAsignada(userForForm);

      setState(() {
        _isLoadingPrepagas = false;
        _isLoadingProfile = false;
        _updatePrepagaSetupState(initial: true);
      });
    } catch (e) {
      debugPrint('Error al cargar perfil: $e');
      if (mounted) {
        setState(() {
          _isLoadingPrepagas = false;
          _isLoadingProfile = false;
          _updatePrepagaSetupState(initial: true);
        });
      }
    }
  }

  @override
  void dispose() {
    nombresController.dispose();
    apellidosController.dispose();
    cedulaController.dispose();
    direccionController.dispose();
    celularController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void _toggleEditing() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  // --- LÓGICA DE ELIMINACIÓN DE CUENTA ---

  void _showDeleteAccountDialog() {
    final currentUser = UserService.getCurrentUser();
    final expectedEmail = currentUser?.email.trim() ?? '';

    if (expectedEmail.isEmpty) {
      CustomSnackBar.showError(
        context,
        message: 'No se pudo obtener el correo de la sesión activa.',
        title: 'Error de sesión',
      );
      return;
    }

    final TextEditingController confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setStateDialog) {
              final typed = confirmController.text.trim().toLowerCase();
              bool isButtonEnabled = typed == expectedEmail.toLowerCase();

              return AlertDialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                scrollable: true,

                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: dangerRed.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.warning_amber_rounded, color: dangerRed, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Eliminar cuenta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3142))),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Esta acción es irreversible. Perderás el acceso a tus citas, historial médico y datos personales.',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Para confirmar, escribe tu correo electrónico:',
                      style: TextStyle(fontWeight: FontWeight.w600, color: textDark, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      onChanged: (value) => setStateDialog(() {}),
                      decoration: InputDecoration(
                        hintText: 'correo@ejemplo.com',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        isDense: true,
                        filled: true,
                        fillColor: inputFillColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isButtonEnabled ? dangerRed : primaryPurple, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar', style: TextStyle(color: textGrey, fontWeight: FontWeight.w600)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isButtonEnabled ? dangerRed : Colors.grey.shade200,
                      foregroundColor: isButtonEnabled ? Colors.white : Colors.grey.shade500,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: isButtonEnabled
                        ? () {
                      Navigator.pop(context);
                      _handleAccountDeletion();
                    }
                        : null,
                    child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  void _handleAccountDeletion() async {
    final currentUser = UserService.getCurrentUser();

    if (currentUser == null || currentUser.idCliente == null) {
      CustomSnackBar.showError(context, message: 'No se pudo identificar al usuario activo.', title: 'Error de sesión');
      return;
    }

    setState(() => isSaving = true);
    final result = await ClientApiService.requestAccountDeletion(currentUser.idCliente!);

    if (mounted) {
      setState(() => isSaving = false);

      if (result['success'] == true) {
        CustomSnackBar.showSuccess(context, title: 'Solicitud enviada', message: result['message']);
        await Future.delayed(const Duration(milliseconds: 2500));
        await UserService.clearLoginCredentials();

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
          );
        }
      } else {
        CustomSnackBar.showError(context, title: 'Error al eliminar', message: result['message'] ?? 'Ocurrió un problema inesperado.');
      }
    }
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final currentUser = UserService.getCurrentUser();

      if (currentUser == null || currentUser.idCliente == null) {
        CustomSnackBar.showError(context, message: 'No se puede actualizar sin un usuario válido.', title: 'Error de sesión');
        return;
      }

      if (celularController.text.trim().isEmpty || direccionController.text.trim().isEmpty || _selectedPrepagaId == null) {
        CustomSnackBar.showError(context, message: 'Por favor, complete todos los campos obligatorios.', title: 'Faltan datos');
        return;
      }

      setState(() => isSaving = true);

      try {
        final result = await ClientApiService.updateClientData(
          idCliente: currentUser.idCliente!,
          idPrepaga: _selectedPrepagaId!,
          telefono: celularController.text.trim(),
          direccion: direccionController.text.trim(),
          nombre: nombresController.text.trim(),
          apellido: apellidosController.text.trim(),
          email: emailController.text.trim(),
          cedula: cedulaController.text.trim(),
        );

        if (result != null && result['success'] == true) {
          final updatedUser = User(
            nombres: currentUser.nombres,
            apellidos: currentUser.apellidos,
            cedula: currentUser.cedula,
            email: currentUser.email,
            idCliente: currentUser.idCliente,
            password: currentUser.password,
            sexo: currentUser.sexo,
            ruc: currentUser.ruc,
            razonSocial: currentUser.razonSocial,
            direccion: direccionController.text,
            celular: celularController.text,
            seguro: _selectedPrepagaId!,
          );

          await UserService.saveUser(updatedUser);
          UserService.setCurrentUser(updatedUser);

          if (mounted) {
            setState(() {
              isEditing = false;
              isSaving = false;
              _needsPrepagaSetup = false;
            });
            CustomSnackBar.showSuccess(context, title: '¡Todo listo!', message: result['message'] ?? 'Tu perfil ha sido actualizado correctamente.');
          }
        } else {
          if (mounted) {
            setState(() => isSaving = false);
            CustomSnackBar.showError(context, message: result?['message'] ?? 'No se pudieron guardar los cambios.');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => isSaving = false);
          CustomSnackBar.showError(context, message: 'Error de conexión con el servidor. Intente nuevamente.');
        }
      }
    }
  }

  // Obtenemos iniciales para el Avatar
  String _getInitials() {
    String initials = "";
    if (nombresController.text.isNotEmpty) initials += nombresController.text[0].toUpperCase();
    if (apellidosController.text.isNotEmpty) initials += apellidosController.text[0].toUpperCase();
    return initials.isEmpty ? "U" : initials;
  }

  @override
  Widget build(BuildContext context) {
    final nombrePrepagaActual = _resolvePrepagaNombre();

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryPurple),
        title: Text('Mi Perfil', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isEditing ? Icons.close_rounded : Icons.edit_rounded,
                key: ValueKey<bool>(isEditing),
                color: isEditing ? dangerRed : primaryPurple,
              ),
            ),
            onPressed: _toggleEditing,
          ),
        ],
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- CABECERA DE PERFIL ---
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(bottom: 30, top: 20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: primaryPurple.withOpacity(0.1),
                      child: Text(
                        _getInitials(),
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryPurple),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${nombresController.text} ${apellidosController.text}',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      emailController.text,
                      style: TextStyle(fontSize: 14, color: textGrey),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_needsPrepagaSetup) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.health_and_safety_outlined, color: Colors.amber.shade800),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Debes seleccionar tu seguro médico y guardar los cambios para continuar usando la app con normalidad.',
                                style: TextStyle(fontSize: 13, color: Colors.amber.shade900, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Banner de Edición
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: isEditing
                          ? Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: accentCyan.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: accentCyan.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: accentCyan),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _needsPrepagaSetup
                                    ? 'Selecciona tu seguro médico, completa celular y dirección, luego pulsa Guardar.'
                                    : 'Modifica tus datos de contacto y seguro médico.',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      )
                          : const SizedBox.shrink(),
                    ),

                    _buildSectionTitle('Datos Personales'),
                    _buildModernContainer(
                      child: Column(
                        children: [
                          _buildProfileItem(icon: Icons.badge_outlined, label: 'Cédula de Identidad', value: cedulaController.text),
                          Divider(color: Colors.grey.shade200, height: 1),
                          _buildProfileItem(icon: Icons.email_outlined, label: 'Correo Electrónico', value: emailController.text),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    _buildSectionTitle('Contacto y Facturación'),
                    _buildModernContainer(
                      isEditableZone: isEditing,
                      child: Column(
                        children: [
                          isEditing
                              ? _buildEditableField(label: 'Número de celular', controller: celularController, icon: Icons.phone_iphone_outlined, keyboardType: TextInputType.phone)
                              : _buildProfileItem(icon: Icons.phone_iphone_outlined, label: 'Número de celular', value: celularController.text),

                          if (isEditing) const SizedBox(height: 16),
                          if (!isEditing) Divider(color: Colors.grey.shade200, height: 1),

                          isEditing
                              ? _buildPrepagaDropdown()
                              : _buildProfileItem(icon: Icons.health_and_safety_outlined, label: 'Seguro Médico', value: nombrePrepagaActual),

                          if (isEditing) const SizedBox(height: 16),
                          if (!isEditing) Divider(color: Colors.grey.shade200, height: 1),

                          isEditing
                              ? _buildEditableField(label: 'Dirección particular', controller: direccionController, icon: Icons.location_on_outlined, maxLines: 2)
                              : _buildProfileItem(icon: Icons.location_on_outlined, label: 'Dirección particular', value: direccionController.text),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Botón Guardar Cambios
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isEditing ? 1.0 : 0.0,
                      child: Visibility(
                        visible: isEditing,
                        child: Container(
                          height: 55,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: primaryPurple.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: isSaving ? null : _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryPurple,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: isSaving
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                : const Text('Guardar Cambios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ),
                    ),

                    // --- SECCIÓN: ELIMINAR CUENTA ---
                    if (!isEditing) ...[
                      const SizedBox(height: 20),
                      _buildSectionTitle('Privacidad y Seguridad'),
                      GestureDetector(
                        onTap: _showDeleteAccountDialog,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: dangerRed.withOpacity(0.3)),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: dangerRed.withOpacity(0.1), shape: BoxShape.circle),
                                child: Icon(Icons.delete_outline_rounded, color: dangerRed),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Eliminar mi cuenta', style: TextStyle(color: dangerRed, fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 2),
                                    Text('Borrar permanentemente todos tus datos.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 48),

                    // Logo Final
                    Center(
                      child: Opacity(
                        opacity: 0.5,
                        child: Image.asset('assets/icons/logo_color.png', width: 120, fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS MODERNOS DE APOYO ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      ),
    );
  }

  Widget _buildModernContainer({required Widget child, bool isEditableZone = false}) {
    return Container(
      padding: EdgeInsets.all(isEditableZone ? 20 : 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: child,
    );
  }

  // Diseño limpio para datos de solo lectura
  Widget _buildProfileItem({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: textGrey, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value.isEmpty ? 'No especificado' : value, style: TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Icon(Icons.lock_outline_rounded, color: Colors.grey.shade300, size: 16),
        ],
      ),
    );
  }

  // Inputs modernos sin bordes duros
  Widget _buildEditableField({required String label, required TextEditingController controller, required IconData icon, TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textGrey),
        floatingLabelStyle: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, color: primaryPurple),
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryPurple, width: 1.5)),
      ),
      validator: (value) => (value == null || value.trim().isEmpty) ? 'Campo obligatorio' : null,
    );
  }

  Widget _buildPrepagaDropdown() {
    final idsEnLista = _listaPrepagas.map((p) => p.id).toSet();
    final valorDropdown = _selectedPrepagaId != null &&
            idsEnLista.any((id) => PrepagaService.idsMatch(id, _selectedPrepagaId))
        ? _listaPrepagas
            .firstWhere((p) => PrepagaService.idsMatch(p.id, _selectedPrepagaId))
            .id
        : null;

    return DropdownButtonFormField<String>(
      value: valorDropdown,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryPurple),
      items: _listaPrepagas.map((prepaga) {
        return DropdownMenuItem(value: prepaga.id, child: Text(prepaga.nombre, overflow: TextOverflow.ellipsis));
      }).toList(),
      onChanged: (val) => setState(() => _selectedPrepagaId = val),
      decoration: InputDecoration(
        labelText: 'Seguro Médico',
        labelStyle: TextStyle(color: textGrey),
        floatingLabelStyle: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold),
        prefixIcon: Icon(Icons.health_and_safety_outlined, color: primaryPurple),
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryPurple, width: 1.5)),
      ),
      validator: (value) => value == null ? 'Seleccione un seguro' : null,
      hint: _isLoadingPrepagas ? const Text('Cargando...') : const Text('Seleccione...'),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- NUEVO IMPORT
import '../services/user_service.dart';
import 'mis_datos_screen.dart';
import 'mis_resultados_screen.dart';
import 'quiero_consultar_screen.dart';
import 'agendar_analisis_screen.dart';
import 'mi_agenda_screen.dart';
import 'login_screen.dart';
import 'ayuda_soporte_screen.dart';
import '../services/security_service.dart';

// Cambiamos a StatefulWidget para poder manejar el estado de la foto
class MainDrawer extends StatefulWidget {
  const MainDrawer({Key? key}) : super(key: key);

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  final Color _primaryColor = const Color(0xFFB47EDB); // Tu Lila
  final Color _onSurfaceVariant = const Color(0xFF444746); // Gris Material 3
  final Color _onSurface = const Color(0xFF1F1F1F); // Casi negro para textos M3

  String? _photoUrl; // Variable para almacenar la URL de la foto

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto(); // Cargamos la foto al iniciar el Drawer
  }

  // Método para obtener la URL guardada en caché
  Future<void> _loadProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _photoUrl = prefs.getString('google_photo_url');
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = UserService.getCurrentUser();

    // Lógica para iniciales
    String initials = '';
    if (currentUser != null && currentUser.nombres != null && currentUser.nombres!.isNotEmpty) {
      initials = currentUser.nombres![0];
      if (currentUser.apellidos != null && currentUser.apellidos!.isNotEmpty) {
        initials += currentUser.apellidos![0];
      }
    }
    if (initials.isEmpty) initials = 'U';

    return Drawer(
      // M3 usa un borde redondeado solo en el lado derecho
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      backgroundColor: const Color(0xFFF7F9FC), // Fondo Google súper claro
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. CABECERA MATERIAL 3 (Limpia y espaciosa)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 40, 28, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: _primaryColor.withOpacity(0.15),
                    // 👇 Lógica para mostrar la foto o las iniciales
                    backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                    child: _photoUrl == null
                        ? Text(
                      initials.toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    )
                        : null, // Si hay foto, no dibujamos el texto
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentUser?.nombres ?? 'Usuario Invitado',
                    style: TextStyle(
                      color: _onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentUser?.email ?? 'Sin correo registrado',
                    style: TextStyle(
                      color: _onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // 2. LISTA DE OPCIONES
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildSectionTitle('Mi Cuenta'),
                _buildDrawerItem(
                  context,
                  icon: Icons.person_outline_rounded,
                  title: 'Mis datos',
                  onTap: () => _navigate(context, const MisDatosScreen()),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.analytics_outlined,
                  title: 'Mis resultados',
                  onTap: () => _navigate(context, const MisResultadosScreen()),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(height: 1, thickness: 1, indent: 16, endIndent: 16, color: Color(0xFFE0E2E5)),
                ),

                _buildSectionTitle('Servicios'),
                _buildDrawerItem(
                  context,
                  icon: Icons.medical_services_outlined,
                  title: 'Quiero consultar',
                  onTap: () => _navigate(context, const QuieroConsultarScreen()),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.event_note_outlined,
                  title: 'Mi agenda',
                  onTap: () => _navigate(context, const MiAgendaScreen()),
                ),
              ],
            ),
          ),

          // 3. FOOTER
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(color: Color(0xFFE0E2E5), height: 24, indent: 16, endIndent: 16),
                _buildDrawerItem(
                  context,
                  icon: Icons.help_outline_rounded,
                  title: 'Ayuda y Soporte',
                  onTap: () => _navigate(context, const AyudaSoporteScreen()),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout_rounded,
                  title: 'Cerrar sesión',
                  textColor: const Color(0xFFBA1A1A), // Rojo Material 3
                  iconColor: const Color(0xFFBA1A1A),
                  onTap: () => _handleLogout(context),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Certiva App v2.2.0',
                    style: TextStyle(color: _onSurfaceVariant.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        Color? textColor,
        Color? iconColor,
      }) {
    final color = textColor ?? _onSurface;
    final iColor = iconColor ?? _onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: iColor, size: 24),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        shape: const StadiumBorder(),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        hoverColor: _primaryColor.withOpacity(0.08),
        splashColor: _primaryColor.withOpacity(0.12),
      ),
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      debugPrint('Error al cerrar sesión de Google: $e');
    }

    // 👇 NUEVO: Borramos la foto al cerrar sesión
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('google_photo_url');
    } catch (e) {
      debugPrint('Error limpiando caché de foto: $e');
    }

    await SecurityService.disableBiometricLogin();

    UserService.clearCurrentUser();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }
}
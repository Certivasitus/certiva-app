import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/user_service.dart';
import 'main_drawer.dart';
import 'login_screen.dart';
import 'mis_datos_screen.dart';
import 'mis_resultados_screen.dart';
import 'quiero_consultar_screen.dart';
import 'mi_agenda_screen.dart';
import 'chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  /// Consulta con Lyra: oculto temporalmente hasta habilitar el chat IA.
  static const bool _showLyraConsultationCard = false;

  // --- Colores Material 3 ---
  final Color _primaryColor = const Color(0xFFB47EDB); // Lila
  final Color _secondaryColor = const Color(0xFF09D5D6); // Cyan
  final Color _backgroundColor = const Color(0xFFF7F9FC);
  final Color _onSurface = const Color(0xFF1F1F1F);
  final Color _onSurfaceVariant = const Color(0xFF444746);
  final Color _outline = const Color(0xFFE0E2E5);

  late AnimationController _controller;
  late Animation<double> _nameFade;
  late Animation<double> _questionFade;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _nameFade = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOut));
    _questionFade = CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.8, curve: Curves.easeOut));
    _contentFade = CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeOut));

    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = UserService.getCurrentUser();
    final userEmail = currentUser?.email ?? 'Usuario';
    final username = userEmail.contains('@') ? userEmail.split('@')[0] : userEmail;
    final formattedName = username.isNotEmpty ? '${username[0].toUpperCase()}${username.substring(1)}' : username;

    return Scaffold(
      backgroundColor: _backgroundColor,
      drawer: const MainDrawer(),
      // SE ELIMINÓ EL FLOATING ACTION BUTTON
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: _backgroundColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            pinned: true,
            leading: Builder(
              builder: (context) => Container(
                margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _outline)),
                child: IconButton(
                  icon: Icon(Icons.menu_rounded, color: _onSurfaceVariant, size: 22),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeTransition(
                    opacity: _nameFade,
                    child: Text('Hola, $formattedName', style: TextStyle(color: _onSurface, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  ),
                  const SizedBox(height: 6),
                  FadeTransition(
                    opacity: _questionFade,
                    child: Text("¿Qué deseas hacer hoy?", style: TextStyle(fontSize: 16, color: _onSurfaceVariant, fontWeight: FontWeight.w400)),
                  ),

                  const SizedBox(height: 24),

                  if (_showLyraConsultationCard) ...[
                    FadeTransition(
                      opacity: _contentFade,
                      child: _buildAIConsultationCard(context),
                    ),
                    const SizedBox(height: 24),
                  ],

                  FadeTransition(
                    opacity: _contentFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: Column(
                        children: [
                          _buildHeroCard(
                            context,
                            title: "Reservar un Turno",
                            subtitle: "Agendá una nueva consulta médica",
                            iconPath: 'assets/Iconos acceso directo-04.png',
                            color: _primaryColor,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const QuieroConsultarScreen())),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSquareCard(
                                  context,
                                  title: "Mis\nResultados",
                                  iconPath: 'assets/Iconos acceso directo-03.png',
                                  color: _primaryColor,
                                  isOutlined: true,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MisResultadosScreen())),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildSquareCard(
                                  context,
                                  title: "Mi\nAgenda",
                                  iconPath: 'assets/Iconos acceso directo-05.png',
                                  color: _secondaryColor,
                                  isOutlined: false,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MiAgendaScreen())),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildListCard(
                            context,
                            title: "Mi Perfil y Datos",
                            iconPath: 'assets/Iconos acceso directo-02.png',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MisDatosScreen())),
                          ),
                          const SizedBox(height: 48),
                          Center(
                            child: Opacity(
                              opacity: 0.4,
                              child: Image.asset('assets/icons/logo_color.png', width: 90, errorBuilder: (ctx, error, stack) => Icon(Icons.local_hospital_rounded, size: 40, color: Colors.grey.shade300)),
                            ),
                          ),
                          const SizedBox(height: 30),
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

  // --- WIDGET TARJETA DE CONSULTA IA (ESTILO CLARO) ---
  Widget _buildAIConsultationCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _secondaryColor.withOpacity(0.08), // Tonal claro usando el Cyan
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _secondaryColor.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CertivaChatScreen())),
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Icono con fondo circular
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: _secondaryColor.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                      ]
                  ),
                  child: Icon(Icons.auto_awesome_rounded, color: _secondaryColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Consulta con Lyra",
                        style: TextStyle(color: Color(0xFF1F1F1F), fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Nuestra IA asistente para tus dudas.",
                        style: TextStyle(color: _onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: _secondaryColor.withOpacity(0.5), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- RESTO DE WIDGETS DE DISEÑO ---
  Widget _buildHeroCard(BuildContext context, {required String title, required String subtitle, required String iconPath, required Color color, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(32)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: const Text("Recomendado", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                const SizedBox(height: 16),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.3)),
              ])),
              const SizedBox(width: 16),
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: Image.asset(iconPath, width: 40, height: 40, color: Colors.white)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildSquareCard(BuildContext context, {required String title, required String iconPath, required Color color, bool isOutlined = false, required VoidCallback onTap}) {
    return Container(
      height: 170,
      decoration: BoxDecoration(color: isOutlined ? Colors.white : color.withOpacity(0.12), borderRadius: BorderRadius.circular(28), border: isOutlined ? Border.all(color: _outline) : null),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isOutlined ? color.withOpacity(0.1) : Colors.white, shape: BoxShape.circle), child: Image.asset(iconPath, width: 28, height: 28, color: color)),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _onSurface, height: 1.2)),
                Icon(Icons.arrow_forward_rounded, color: isOutlined ? _onSurfaceVariant : color, size: 20),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context, {required String title, required String iconPath, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: _outline)),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _backgroundColor, shape: BoxShape.circle), child: Image.asset(iconPath, width: 22, height: 22, color: _onSurfaceVariant)),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: _onSurface)),
          trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: _onSurfaceVariant),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/support_service.dart';

class AyudaSoporteScreen extends StatefulWidget {
  const AyudaSoporteScreen({Key? key}) : super(key: key);

  @override
  State<AyudaSoporteScreen> createState() => _AyudaSoporteScreenState();
}

class _AyudaSoporteScreenState extends State<AyudaSoporteScreen> {
  // --- Colores Material 3 ---
  final Color _primaryColor = const Color(0xFFB47EDB);
  final Color _secondaryColor = const Color(0xFF09D5D6);
  final Color _backgroundColor = const Color(0xFFF7F9FC); // Surface
  final Color _onSurface = const Color(0xFF1F1F1F);
  final Color _onSurfaceVariant = const Color(0xFF444746);
  final Color _outline = const Color(0xFFE0E2E5);

  // Variables dinámicas para los datos de la API
  String _supportEmail = '';
  String _supportPhone = '';
  bool _isLoadingData = true;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _asuntoController = TextEditingController();
  final TextEditingController _mensajeController = TextEditingController();

  bool _isSending = false;

  final List<Map<String, String>> _faqs = [
    {
      'question': '¿Cómo descargo mis resultados?',
      'answer': 'Ve a la sección "Mis Resultados", selecciona el estudio que deseas y presiona el ícono de descarga (PDF) a la derecha.'
    },
    {
      'question': '¿Cómo cancelo una cita?',
      'answer': 'En "Mi Agenda", busca la cita pendiente y presiona el botón "Cancelar cita". Recuerda que debes hacerlo con al menos 24hs de antelación.'
    },
    {
      'question': '¿Aceptan seguro médico?',
      'answer': 'Sí, trabajamos con la mayoría de los seguros. Puedes verificar o actualizar tu seguro en la sección "Mi Perfil".'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSupportData();
  }

  Future<void> _loadSupportData() async {
    try {
      final service = SupportService();
      final data = await service.getSupportInfo();

      if (mounted) {
        setState(() {
          _supportEmail = data['email']!;
          _supportPhone = data['phone']!;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingData = false);
      debugPrint("Error cargando info de soporte: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: _onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
            'Ayuda y Soporte',
            style: TextStyle(color: _onSurface, fontWeight: FontWeight.w600, fontSize: 20)
        ),
      ),
      body: _isLoadingData
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // 1. SECCIÓN DE CONTACTO RÁPIDO
                  _buildSectionHeader('Canales de atención'),
                  Row(
                    children: [
                      Expanded(
                          child: _buildContactCard(
                              Icons.phone_in_talk_rounded,
                              'Llamar a Soporte',
                                  () => _makePhoneCall(_supportPhone)
                          )
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // 2. PREGUNTAS FRECUENTES
                  _buildSectionHeader('Preguntas frecuentes'),
                  _buildFaqContainer(),

                  const SizedBox(height: 32),

                  // 3. FORMULARIO DE CORREO
                  _buildSectionHeader('Envíanos un correo'),
                  _buildEmailForm(),

                  const SizedBox(height: 48),

                  // Footer Limpio M3
                  Center(
                    child: Column(
                      children: [
                        Opacity(
                          opacity: 0.4,
                          child: Image.asset(
                            'assets/icons/logo_color.png',
                            width: 80,
                            fit: BoxFit.contain,
                            errorBuilder: (c, o, s) => const SizedBox(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _supportEmail.isEmpty ? 'Cargando...' : _supportEmail,
                          style: TextStyle(color: _onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DE ESTRUCTURA M3 ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _onSurfaceVariant,
        ),
      ),
    );
  }

  // Tarjeta Outlined (Bordes Grises en vez de Sombras)
  Widget _buildContactCard(IconData icon, String label, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _outline),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1), // Color Tonal
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: _primaryColor, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _onSurface,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Contenedor de FAQS M3
  Widget _buildFaqContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _outline),
      ),
      child: Column(
        children: _faqs.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == _faqs.length - 1;

          return Column(
            children: [
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  title: Text(
                    item['question']!,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: _onSurface,
                    ),
                  ),
                  iconColor: _primaryColor,
                  collapsedIconColor: _onSurfaceVariant,
                  children: [
                    Text(
                      item['answer']!,
                      style: TextStyle(color: _onSurfaceVariant, fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
              if (!isLast) Divider(height: 1, color: _outline, indent: 20, endIndent: 20),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Formulario Limpio
  Widget _buildEmailForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _outline),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Escríbenos directamente a Administración",
              style: TextStyle(fontSize: 14, color: _onSurfaceVariant, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            _buildModernTextField(
              controller: _asuntoController,
              label: 'Asunto',
              icon: Icons.title_rounded,
              validatorMsg: 'Ingresa un asunto',
            ),
            const SizedBox(height: 16),
            _buildModernTextField(
              controller: _mensajeController,
              label: 'Mensaje',
              icon: Icons.message_rounded,
              validatorMsg: 'Escribe tu mensaje',
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // Botón tipo Stadium de M3
            FilledButton.icon(
              onPressed: _isSending ? null : _sendEmail,
              style: FilledButton.styleFrom(
                backgroundColor: _primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
              ),
              icon: _isSending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, size: 20),
              label: Text(
                _isSending ? "Enviando..." : "Enviar Mensaje",
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Inputs modernos M3 (Fondo gris suave y outline dinámico)
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String validatorMsg,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: _onSurface, fontSize: 15),
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _onSurfaceVariant),
        floatingLabelStyle: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
        filled: true,
        fillColor: _backgroundColor, // Fondo clarito
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 72.0 : 0), // Alinea ícono arriba si es multilínea
          child: Icon(icon, color: _onSurfaceVariant, size: 20),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
      ),
      validator: (v) => v!.trim().isEmpty ? validatorMsg : null,
    );
  }

  // --- LÓGICA DE CORREO Y LLAMADA ---

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;
    if (_supportEmail.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: _supportEmail,
        query: _encodeQueryParameters(<String, String>{
          'subject': _asuntoController.text,
          'body': _mensajeController.text,
        }),
      );

      await Future.delayed(const Duration(seconds: 1));

      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);

        _asuntoController.clear();
        _mensajeController.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Abriendo aplicación de correo...'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw 'No se encontró aplicación de correo';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No pudimos abrir el correo: $e. Verifica tu app de email.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo realizar la llamada')),
        );
      }
    }
  }
}
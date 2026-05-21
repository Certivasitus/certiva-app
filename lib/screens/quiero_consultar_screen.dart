import 'package:flutter/material.dart';
import '../services/consultation_service.dart';
import '../services/user_service.dart';
import 'consulta_agendada_screen.dart';
import '../widgets/avatar_doctor.dart';

String _textoSeguro(dynamic valor, [String fallback = '']) {
  final texto = valor?.toString().trim() ?? '';
  return texto.isEmpty ? fallback : texto;
}

int _parseInt(dynamic valor, {int fallback = 0}) {
  if (valor == null) return fallback;
  if (valor is int) return valor;
  if (valor is num) return valor.toInt();
  return int.tryParse(valor.toString()) ?? fallback;
}

class QuieroConsultarScreen extends StatefulWidget {
  const QuieroConsultarScreen({Key? key}) : super(key: key);

  @override
  State<QuieroConsultarScreen> createState() => _QuieroConsultarScreenState();
}

class _QuieroConsultarScreenState extends State<QuieroConsultarScreen> with SingleTickerProviderStateMixin {
  // --- Colores Material 3 ---
  final Color _primaryColor = const Color(0xFFB47EDB);
  final Color _secondaryColor = const Color(0xFF09D5D6);
  final Color _backgroundColor = const Color(0xFFF7F9FC); // Surface
  final Color _onSurface = const Color(0xFF1F1F1F);
  final Color _onSurfaceVariant = const Color(0xFF444746);
  final Color _outline = const Color(0xFFE0E2E5);

  final ConsultationService _consultationService = ConsultationService();

  // Estados de Filtros
  int? _selectedSpecialtyId;
  String _selectedSpecialtyLabel = '';
  int? _selectedDoctorId;
  String _selectedDoctorLabel = '';
  int? _selectedBranchId;
  String _selectedBranchLabel = '';
  DateTime? _selectedDate;

  // Dropdowns
  bool _showSpecialtyDropdown = false;
  bool _showDoctorDropdown = false;
  bool _showBranchDropdown = false;

  // Control de panel colapsable
  bool _isFiltersExpanded = false;

  // Datos
  bool _isLoading = false;
  List<Map<String, dynamic>> _specialties = [];
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _allDoctors = [];
  List<Map<String, dynamic>> _filteredDoctors = [];
  List<Map<String, dynamic>> _availableTurnos = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _consultationService.getSpecialties(),
        _consultationService.getBranches(),
        _consultationService.getAllDoctors(),
      ]);

      if (!mounted) return;

      setState(() {
        _specialties = results[0] as List<Map<String, dynamic>>;
        _branches = results[1] as List<Map<String, dynamic>>;
        _allDoctors = results[2] as List<Map<String, dynamic>>;
        _filteredDoctors = _allDoctors;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Error cargando datos: $e', isError: true);
      }
    }
  }

  void _filterDoctorsBySpecialty(String specialtyName) {
    if (specialtyName.isEmpty) {
      setState(() => _filteredDoctors = _allDoctors);
    } else {
      setState(() {
        _filteredDoctors = _allDoctors.where((doc) {
          final docSpecs = List<String>.from(doc['especialidades'] ?? []);
          return docSpecs.contains(specialtyName);
        }).toList();
      });
    }
  }

  Future<void> _buscarTurnos() async {
    if (_selectedSpecialtyId == null && _selectedDoctorId == null && _selectedBranchId == null) {
      _showSnack('Por favor, seleccione también una Especialidad, Médico o Sucursal.', isError: true);
      return;
    }

    String fechaStr;
    if (_selectedDate != null) {
      fechaStr = "${_selectedDate!.day.toString().padLeft(2, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.year}";
    } else {
      final hoy = DateTime.now();
      fechaStr = "${hoy.day.toString().padLeft(2, '0')}-${hoy.month.toString().padLeft(2, '0')}-${hoy.year}";
    }

    setState(() => _isLoading = true);

    try {
      final turnos = await _consultationService.getTurnosDisponibles(
        fecha: fechaStr,
        prestador: _selectedDoctorId,
        especialidad: _selectedSpecialtyId,
        sucursal: _selectedBranchId,
      );

      final agrupados = _agruparTurnos(turnos);

      if (!mounted) return;

      setState(() {
        _availableTurnos = agrupados;
        _isLoading = false;
        _showSpecialtyDropdown = false;
        _showDoctorDropdown = false;
        _showBranchDropdown = false;

        if (agrupados.isNotEmpty) {
          _isFiltersExpanded = false;
        }
      });

      if (agrupados.isEmpty) {
        _showSnack('No se encontraron turnos con esos criterios.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Error buscando turnos: $e', isError: true);
      }
    }
  }

  List<Map<String, dynamic>> _agruparTurnos(List<Map<String, dynamic>> rawTurnos) {
    Map<String, Map<String, dynamic>> grouped = {};

    for (var t in rawTurnos) {
      final fecha = _textoSeguro(t['fecha']);
      final profesional = _textoSeguro(t['profesional']);
      final especialidad = _textoSeguro(t['esp_id_especialidad']);
      final sucursal = _textoSeguro(t['cod_sucursal']);
      final key = '${fecha}_${profesional}_${especialidad}_$sucursal';

      if (!grouped.containsKey(key)) {
        grouped[key] = {
          'fecha': fecha,
          'cod_prestador': t['profesional'],
          'nombre_prestador': _textoSeguro(t['raz_soc_nombre'], 'Profesional'),
          'cod_especialidad': t['esp_id_especialidad'],
          'descripcion_especialidad': _textoSeguro(t['descripcion_especialidad'], 'Especialidad'),
          'cod_sucursal': t['cod_sucursal'],
          'descripcion_sucursal': _textoSeguro(t['descripcion_sucursal'], 'Sucursal no indicada'),
          'horarios': <String>[],
          'turnos_data': <Map<String, dynamic>>[],
        };
      }
      final hora = _textoSeguro(t['hora_disponible']);
      if (hora.isNotEmpty) {
        grouped[key]!['horarios'].add(hora);
      }
      grouped[key]!['turnos_data'].add(t);
    }
    return grouped.values.toList();
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        title: Text(
            'Quiero consultar',
            style: TextStyle(fontWeight: FontWeight.w600, color: _onSurface, fontSize: 20)
        ),
        iconTheme: IconThemeData(color: _onSurface),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadInitialData,
            tooltip: 'Recargar datos',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // PANEL DE FILTROS COLAPSABLE M3
                  _buildCollapsiblePanel(
                    title: 'Filtros de búsqueda',
                    icon: Icons.tune_rounded,
                    isExpanded: _isFiltersExpanded,
                    onToggle: () => setState(() => _isFiltersExpanded = !_isFiltersExpanded),
                    child: _buildFilterContent(),
                  ),

                  const SizedBox(height: 32),

                  // HEADER RESULTADOS M3
                  Text(
                    'Resultados disponibles',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // RESULTADOS
                  _isLoading
                      ? Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator(color: _primaryColor))
                  )
                      : _buildResultsList(),

                  const SizedBox(height: 40),

                  Center(
                    child: Opacity(
                      opacity: 0.4,
                      child: Image.asset(
                        'assets/icons/logo_color.png',
                        width: 80,
                        fit: BoxFit.contain,
                        errorBuilder: (c, o, s) => const SizedBox(),
                      ),
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

  // --- WIDGETS DE DISEÑO M3 ---

  Widget _buildCollapsiblePanel({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _outline),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(24),
              bottom: isExpanded ? Radius.zero : const Radius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(icon, color: _onSurfaceVariant, size: 22),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: _onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: _onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Divider(height: 1, color: _outline, indent: 20, endIndent: 20),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: child,
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_availableTurnos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 64, color: _outline),
            const SizedBox(height: 16),
            Text(
              "No se encontraron turnos.",
              style: TextStyle(color: _onSurfaceVariant, fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            )
          ],
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _availableTurnos.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildTurnoCard(_availableTurnos[index]),
    );
  }

  // Tarjeta de Turno M3 (Outlined)
  Widget _buildTurnoCard(Map<String, dynamic> data) {
    final horarios = data['horarios'] as List;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _outline),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatarForCard(data['cod_prestador']),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _textoSeguro(data['nombre_prestador'], 'Profesional'),
                        style: TextStyle(
                            color: _onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _textoSeguro(data['descripcion_especialidad'], 'Especialidad'),
                        style: TextStyle(
                            color: _primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: _outline, indent: 20, endIndent: 20),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 16, color: _onSurfaceVariant),
                    const SizedBox(width: 10),
                    Text(
                        _textoSeguro(data['fecha'], 'Fecha no indicada'),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _onSurface)
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 16, color: _onSurfaceVariant),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _textoSeguro(data['descripcion_sucursal'], 'Sucursal no indicada'),
                        style: TextStyle(fontSize: 13, color: _onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon( // Botón Tonal M3
                onPressed: () => _navigateToSchedule(data),
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryColor.withOpacity(0.1),
                  foregroundColor: _primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.access_time_filled_rounded, size: 18),
                label: Text(
                    'Ver ${horarios.length} horarios',
                    style: const TextStyle(fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarForCard(dynamic codPrestador) {
    String? url;
    try {
      final doc = _allDoctors.firstWhere((d) => d['cod_prestador'] == codPrestador);
      url = doc['avatar_url'];
    } catch (_) {}

    return AvatarDoctor(
      url: url,
      radius: 28,
      primaryColor: _primaryColor,
    );
  }

  void _navigateToSchedule(Map<String, dynamic> data) async {
    String? fotoDoctor;
    try {
      final doctorInfo = _allDoctors.firstWhere(
              (d) => d['cod_prestador'] == data['cod_prestador'],
          orElse: () => {}
      );
      fotoDoctor = doctorInfo['avatar_url'];
    } catch (_) {}

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _DoctorScheduleScreen(
          especialidad: _textoSeguro(data['descripcion_especialidad'], 'Especialidad'),
          codEspecialidad: _parseInt(data['cod_especialidad']),
          medico: _textoSeguro(data['nombre_prestador'], 'Profesional'),
          codMedico: _parseInt(data['cod_prestador']),
          avatarUrl: fotoDoctor,
          sucursal: _textoSeguro(data['descripcion_sucursal'], 'Sucursal no indicada'),
          codSucursal: _parseInt(data['cod_sucursal']),
          fecha: _textoSeguro(data['fecha'], 'Fecha no indicada'),
          horariosDisponibles: List<String>.from(data['horarios']),
          turnosCompletos: List<Map<String, dynamic>>.from(data['turnos_data']),
        ),
      ),
    );

    if (result == true) {
      _buscarTurnos();
    }
  }

  // --- CONTENIDO DEL FILTRO M3 ---
  Widget _buildFilterContent() {
    String txtEsp = _selectedSpecialtyId == null ? 'Todas las especialidades' : _selectedSpecialtyLabel;
    String txtDoc = _selectedDoctorId == null ? 'Todos los profesionales' : _selectedDoctorLabel;
    String txtSuc = _selectedBranchId == null ? 'Todas las sucursales' : _selectedBranchLabel;

    String txtFecha = 'Hoy (Por defecto)';
    if (_selectedDate != null) {
      // Reemplazamos las '/' por '-'
      txtFecha = "${_selectedDate!.day.toString().padLeft(2, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.year}";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFilterField(
            label: 'Especialidad',
            value: txtEsp,
            icon: Icons.local_hospital_rounded,
            isActive: _selectedSpecialtyId != null,
            onTap: () => setState(() {
              _showSpecialtyDropdown = !_showSpecialtyDropdown;
              _showDoctorDropdown = false;
              _showBranchDropdown = false;
            }),
            onClear: () {
              setState(() {
                _selectedSpecialtyId = null;
                _selectedSpecialtyLabel = '';
                _selectedDoctorId = null;
                _selectedDoctorLabel = '';
              });
              _filterDoctorsBySpecialty('');
            }
        ),
        if (_showSpecialtyDropdown)
          _buildGenericDropdown(
              items: _specialties,
              idKey: 'cod_especialidad',
              labelKey: 'descripcion_especialidad',
              selectedId: _selectedSpecialtyId,
              onSelect: (item) {
                setState(() {
                  _selectedSpecialtyId = item['cod_especialidad'];
                  _selectedSpecialtyLabel = item['descripcion_especialidad'];
                  _showSpecialtyDropdown = false;
                  _selectedDoctorId = null;
                  _selectedDoctorLabel = '';
                });
                _filterDoctorsBySpecialty(_selectedSpecialtyLabel);
              }
          ),

        const SizedBox(height: 12),

        _buildFilterField(
            label: 'Profesional',
            value: txtDoc,
            icon: Icons.person_rounded,
            isActive: _selectedDoctorId != null,
            onTap: () => setState(() {
              _showDoctorDropdown = !_showDoctorDropdown;
              _showSpecialtyDropdown = false;
              _showBranchDropdown = false;
            }),
            onClear: () {
              setState(() {
                _selectedDoctorId = null;
                _selectedDoctorLabel = '';
              });
            }
        ),
        if (_showDoctorDropdown) _buildDoctorDropdown(),

        const SizedBox(height: 12),

        _buildFilterField(
            label: 'Sucursal',
            value: txtSuc,
            icon: Icons.location_on_rounded,
            isActive: _selectedBranchId != null,
            onTap: () => setState(() {
              _showBranchDropdown = !_showBranchDropdown;
              _showSpecialtyDropdown = false;
              _showDoctorDropdown = false;
            }),
            onClear: () {
              setState(() {
                _selectedBranchId = null;
                _selectedBranchLabel = '';
              });
            }
        ),
        if (_showBranchDropdown)
          _buildGenericDropdown(
              items: _branches,
              idKey: 'cod_sucursal',
              labelKey: 'descripcion_sucursal',
              selectedId: _selectedBranchId,
              onSelect: (item) {
                setState(() {
                  _selectedBranchId = item['cod_sucursal'];
                  _selectedBranchLabel = item['descripcion_sucursal'];
                  _showBranchDropdown = false;
                });
              }
          ),

        const SizedBox(height: 12),

        _buildFilterField(
            label: 'Fecha',
            value: txtFecha,
            icon: Icons.calendar_today_rounded,
            isActive: _selectedDate != null,
            onTap: () async {
              setState(() {
                _showSpecialtyDropdown = false;
                _showDoctorDropdown = false;
                _showBranchDropdown = false;
              });
              final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.light().copyWith(
                        colorScheme: ColorScheme.light(primary: _primaryColor),
                      ),
                      child: child!,
                    );
                  }
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            onClear: () => setState(() => _selectedDate = null)
        ),

        const SizedBox(height: 24),

        // Botón Stadium M3
        FilledButton.icon(
          onPressed: _buscarTurnos,
          icon: const Icon(Icons.search_rounded, size: 20),
          label: const Text('Buscar Turnos', style: TextStyle(fontWeight: FontWeight.w600)),
          style: FilledButton.styleFrom(
            backgroundColor: _primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: const StadiumBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
    VoidCallback? onClear
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? _primaryColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? _primaryColor : _outline),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? _primaryColor : _onSurfaceVariant, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: isActive ? _primaryColor : _onSurfaceVariant, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 14, color: _onSurface, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)
                ],
              ),
            ),
            if (isActive && onClear != null)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                color: _onSurfaceVariant,
                onPressed: onClear,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            else
              Icon(Icons.arrow_drop_down_rounded, color: _onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildGenericDropdown({
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String labelKey,
    required int? selectedId,
    required Function(Map<String, dynamic>) onSelect
  }) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _outline),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: items.isEmpty
          ? const Padding(padding: EdgeInsets.all(16), child: Text("No hay opciones disponibles", style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center))
          : ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final item = items[i];
          final isSelected = item[idKey] == selectedId;
          return InkWell(
            onTap: () => onSelect(item),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isSelected ? _primaryColor.withOpacity(0.08) : Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item[labelKey],
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? _primaryColor : _onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (isSelected) Icon(Icons.check_rounded, color: _primaryColor, size: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDoctorDropdown() {
    if (_filteredDoctors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(top: 8),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _outline),
        ),
        child: const Text("No hay médicos disponibles", style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
      );
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _outline),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _filteredDoctors.length,
        itemBuilder: (ctx, i) {
          final doc = _filteredDoctors[i];
          final isSelected = doc['cod_prestador'] == _selectedDoctorId;
          final specs = List<String>.from(doc['especialidades'] ?? [doc['especialidad']]).join(', ');

          return InkWell(
            onTap: () {
              setState(() {
                _selectedDoctorId = doc['cod_prestador'];
                _selectedDoctorLabel = doc['nombre_prestador'];
                _showDoctorDropdown = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isSelected ? _primaryColor.withOpacity(0.08) : Colors.transparent,
              child: Row(
                children: [
                  AvatarDoctor(
                    url: doc['avatar_url'],
                    radius: 20,
                    primaryColor: _primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc['nombre_prestador'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? _primaryColor : _onSurface,
                          ),
                        ),
                        Text(
                          specs,
                          style: TextStyle(fontSize: 12, color: _onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected) Icon(Icons.check_rounded, color: _primaryColor, size: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// --------------------------------------------------------------------------
// PANTALLA PRIVADA: Confirmación de Horario
// --------------------------------------------------------------------------

class _DoctorScheduleScreen extends StatefulWidget {
  final String especialidad;
  final int codEspecialidad;
  final String medico;
  final int codMedico;
  final String? avatarUrl;
  final String sucursal;
  final int codSucursal;
  final String fecha;
  final List<String> horariosDisponibles;
  final List<Map<String, dynamic>> turnosCompletos;

  const _DoctorScheduleScreen({
    required this.especialidad,
    required this.codEspecialidad,
    required this.medico,
    required this.codMedico,
    this.avatarUrl,
    required this.sucursal,
    required this.codSucursal,
    required this.fecha,
    required this.horariosDisponibles,
    required this.turnosCompletos,
  });

  @override
  State<_DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<_DoctorScheduleScreen> {
  final Color _primaryColor = const Color(0xFFB47EDB);
  final Color _backgroundColor = const Color(0xFFF7F9FC);
  final Color _onSurface = const Color(0xFF1F1F1F);
  final Color _onSurfaceVariant = const Color(0xFF444746);
  final Color _outline = const Color(0xFFE0E2E5);

  String selectedTime = '';
  int? selectedIdDetAux;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Confirmar Horario', style: TextStyle(fontWeight: FontWeight.w600, color: _onSurface, fontSize: 20)),
        iconTheme: IconThemeData(color: _onSurface),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      // Tarjeta limpia con info del doctor M3 Outlined
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _outline),
                        ),
                        child: Column(
                          children: [
                            AvatarDoctor(
                              url: widget.avatarUrl,
                              radius: 44,
                              primaryColor: _primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                                widget.medico,
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _onSurface),
                                textAlign: TextAlign.center
                            ),
                            const SizedBox(height: 4),
                            Text(
                                widget.especialidad,
                                style: TextStyle(color: _primaryColor, fontSize: 14, fontWeight: FontWeight.w600)
                            ),
                            const SizedBox(height: 24),
                            Divider(color: _outline, height: 1),
                            const SizedBox(height: 20),
                            _buildInfoRow(Icons.calendar_today_rounded, widget.fecha),
                            const SizedBox(height: 16),
                            _buildInfoRow(Icons.location_on_rounded, widget.sucursal),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Selecciona una hora", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _onSurfaceVariant)),
                      ),
                      const SizedBox(height: 16),

                      // Chips Tonales M3 para Horarios
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: widget.horariosDisponibles.map((time) {
                          final turno = widget.turnosCompletos.firstWhere(
                                  (t) => t['hora_disponible'] == time,
                              orElse: () => {'estado': 'DESCONOCIDO'}
                          );

                          final String estado = (turno['estado'] ?? '').toString().trim().toUpperCase();
                          final bool isReserved = estado == 'RESERVADO';
                          final bool isSelected = selectedTime == time;

                          return InkWell(
                            onTap: isReserved
                                ? null
                                : () {
                              setState(() {
                                selectedTime = time;
                                selectedIdDetAux = _parseInt(turno['id_det_aux']);
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                // Fondo Tonal si está disponible, Primario si está seleccionado, Gris si no
                                color: isReserved
                                    ? Colors.grey.shade200
                                    : (isSelected ? _primaryColor : _primaryColor.withOpacity(0.08)),
                                borderRadius: BorderRadius.circular(12),
                                // Borde solo visible si está seleccionado
                                border: Border.all(
                                    color: isReserved
                                        ? Colors.transparent
                                        : (isSelected ? _primaryColor : Colors.transparent)
                                ),
                              ),
                              child: Text(
                                time,
                                style: TextStyle(
                                  color: isReserved
                                      ? Colors.grey.shade500
                                      : (isSelected ? Colors.white : _primaryColor),
                                  fontWeight: FontWeight.bold,
                                  decoration: isReserved ? TextDecoration.lineThrough : null,
                                  decorationColor: Colors.grey.shade500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 100), // Espacio para el bottom bar
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Action Bar inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: _backgroundColor, // Mismo color de fondo
                border: Border(top: BorderSide(color: _outline)), // Borde superior sutil
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: selectedTime.isEmpty || isLoading ? null : _confirmAppointment,
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const StadiumBorder(),
                    ),
                    child: isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                        : const Text("Confirmar Reserva", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 14, color: _onSurface, fontWeight: FontWeight.w500)),
        )
      ],
    );
  }

  Future<void> _confirmAppointment() async {
    if (selectedIdDetAux == null) return;
    setState(() => isLoading = true);

    try {
      final turnoSeleccionado = widget.turnosCompletos.firstWhere(
        (turno) => _parseInt(turno['id_det_aux']) == selectedIdDetAux,
      );
      final fechaFormateada = '${widget.fecha} $selectedTime';

      final currentUser = UserService.getCurrentUser();

      if (currentUser == null || currentUser.idCliente == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error de sesión. Por favor, reinicia la app.')),
          );
        }
        setState(() => isLoading = false);
        return;
      }

      final resultado = await ConsultationService().agendarTurno(
        fechaReserva: fechaFormateada,
        idCliente: currentUser.idCliente!,
        idPersonaProf: widget.codMedico,
        idDetAux: selectedIdDetAux!,
        idBox: _parseInt(turnoSeleccionado['cod_box']),
        idSucursal: widget.codSucursal,
        observacion: 'Agendado desde App Movil',
      );

      if (!mounted) return;

      setState(() => isLoading = false);

      if (resultado['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConsultaAgendadaScreen(
              specialty: widget.especialidad,
              doctor: widget.medico,
              branch: widget.sucursal,
              date: widget.fecha,
              time: selectedTime,
            ),
          ),
          result: true,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultado['message'] ?? 'Error desconocido'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
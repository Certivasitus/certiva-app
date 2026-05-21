import 'package:flutter/material.dart';
import '../services/consultation_service.dart';
import '../services/user_service.dart';
import '../services/client_api_service.dart';
import '../models/consultation.dart';

class MiAgendaScreen extends StatefulWidget {
  const MiAgendaScreen({Key? key}) : super(key: key);

  @override
  State<MiAgendaScreen> createState() => _MiAgendaScreenState();
}

class _MiAgendaScreenState extends State<MiAgendaScreen>
    with SingleTickerProviderStateMixin {
  // --- Colores Material 3 ---
  final Color _primaryColor = const Color(0xFFB47EDB);
  final Color _secondaryColor = const Color(0xFF09D5D6);
  final Color _backgroundColor = const Color(0xFFF7F9FC); // Surface
  final Color _onSurface = const Color(0xFF1F1F1F);
  final Color _onSurfaceVariant = const Color(0xFF444746);
  final Color _outline = const Color(0xFFE0E2E5);
  final Color _errorColor = const Color(0xFFBA1A1A); // Rojo M3

  final ConsultationService _consultationService = ConsultationService();

  // --- VARIABLES ---
  DateTime? _selectedDate;

  String selectedBranch = '';
  int selectedBranchCode = 0;

  final List<Map<String, String>> _statusOptions = [
    {'label': 'Próximas consultas', 'value': 'RESERVADO'},
    {'label': 'Consultas anteriores', 'value': 'CERRADO'},
    {'label': 'Todas las consultas', 'value': 'TODOS'},
  ];

  String _selectedStatusValue = 'TODOS';

  bool showBranchDropdown = false;
  bool showAgendaDropdown = false;

  bool _isLoading = false;
  bool _isFiltersExpanded = false;

  List<Map<String, dynamic>> branches = [];
  List<Consultation> consultations = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  String get _currentStatusLabel {
    final option = _statusOptions.firstWhere(
      (element) => element['value'] == _selectedStatusValue,
      orElse: () => _statusOptions[0],
    );
    return option['label']!;
  }

  // --- LOGICA DE NEGOCIO ---

  Future<List<Consultation>> _fetchConsultationsWrapper({
    String? fecha,
    int? branchId,
    String? status,
  }) async {
    final currentUser = UserService.getCurrentUser();
    if (currentUser != null && currentUser.idCliente != null) {
      final finalIdCliente =
          await ClientApiService.resolveLabClientId(currentUser);
      if (finalIdCliente == null) {
        print('⚠️ [MiAgenda] Sin cli_id; ec=${currentUser.idCliente}');
        return [];
      }

      print('=== GET AGENDA ===');
      print('ec_cliente (sesión): ${currentUser.idCliente}');
      print('cliente.cli_id (header): $finalIdCliente');
      print('==================');

      return await _consultationService.getAgendaFromAPI(
        idCliente: finalIdCliente,
        fecha: fecha,
        idSucursal: branchId,
        estado: status,
      );
    }
    return [];
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String? _formatDateForApi(DateTime? date) {
    if (date == null) return null;
    final shortYear = date.year.toString().substring(
      2,
    ); // Obtiene '23' en lugar de '2023'
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-$shortYear';
  }

  String _formatDateString(String dateStr) {
    try {
      if (dateStr.isEmpty) return '';
      if (dateStr.contains('-')) {
        List<String> parts = dateStr.split('-');
        if (parts.length == 3 && parts[2].length == 2) {
          int day = int.parse(parts[0]);
          int month = int.parse(parts[1]);
          int year = int.parse(parts[2]) + 2000;
          return _formatDate(DateTime(year, month, day));
        }
        return _formatDate(DateTime.parse(dateStr));
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final apiDate = _formatDateForApi(_selectedDate);
      final apiStatus =
          _selectedStatusValue == 'TODOS' ? null : _selectedStatusValue;

      final results = await Future.wait([
        _consultationService.getBranches(),
        _fetchConsultationsWrapper(fecha: apiDate, status: apiStatus),
      ]);

      if (mounted) {
        setState(() {
          branches = results[0] as List<Map<String, dynamic>>;
          consultations = results[1] as List<Consultation>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- UI PRINCIPAL ---

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
          'Mi agenda',
          style: TextStyle(
            color: _onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
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
                  // PANEL DE FILTROS M3
                  _buildCollapsiblePanel(
                    title: 'Filtros de agenda',
                    icon: Icons.tune_rounded,
                    isExpanded: _isFiltersExpanded,
                    onToggle:
                        () => setState(
                          () => _isFiltersExpanded = !_isFiltersExpanded,
                        ),
                    child: _buildFilterContent(),
                  ),

                  const SizedBox(height: 32),

                  // HEADER RESULTADOS M3
                  Text(
                    'Detalle de citas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _isLoading
                      ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: _primaryColor,
                          ),
                        ),
                      )
                      : _buildConsultationsList(),

                  const SizedBox(height: 40),

                  Center(
                    child: Opacity(
                      opacity: 0.4,
                      child: Image.asset(
                        'assets/icons/logo_color.png',
                        width: 80,
                        fit: BoxFit.contain,
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

  // --- WIDGETS ESTRUCTURALES M3 ---

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
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
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
            child:
                isExpanded
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

  // --- CONTENIDO DE FILTROS M3 ---

  Widget _buildFilterContent() {
    String txtFecha =
        _selectedDate == null
            ? 'Todas las fechas'
            : _formatDate(_selectedDate!);
    String txtSucursal =
        selectedBranch.isEmpty ? 'Todas las sucursales' : selectedBranch;
    String txtEstado = _currentStatusLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFilterField(
          label: 'Fecha',
          value: txtFecha,
          icon: Icons.calendar_today_rounded,
          isActive: _selectedDate != null,
          onTap: () async {
            setState(() {
              showBranchDropdown = false;
              showAgendaDropdown = false;
            });
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              builder:
                  (context, child) => Theme(
                    data: ThemeData.light().copyWith(
                      colorScheme: ColorScheme.light(primary: _primaryColor),
                    ),
                    child: child!,
                  ),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          onClear: () {
            setState(() => _selectedDate = null);
          },
        ),
        const SizedBox(height: 12),

        _buildFilterField(
          label: 'Sucursal',
          value: txtSucursal,
          icon: Icons.location_on_rounded,
          isActive: selectedBranch.isNotEmpty,
          onTap:
              () => setState(() {
                showBranchDropdown = !showBranchDropdown;
                showAgendaDropdown = false;
              }),
          onClear: () {
            setState(() {
              selectedBranch = '';
              selectedBranchCode = 0;
            });
          },
        ),
        if (showBranchDropdown) _buildBranchDropdown(),
        const SizedBox(height: 12),

        _buildFilterField(
          label: 'Estado de la cita',
          value: txtEstado,
          icon: Icons.bookmark_border_rounded,
          isActive: _selectedStatusValue != 'TODOS',
          onTap:
              () => setState(() {
                showAgendaDropdown = !showAgendaDropdown;
                showBranchDropdown = false;
              }),
          onClear: () {
            setState(() => _selectedStatusValue = 'TODOS');
          },
        ),
        if (showAgendaDropdown) _buildStatusDropdown(),

        const SizedBox(height: 24),

        // Botón M3 Stadium
        FilledButton.icon(
          onPressed: _isLoading ? null : _verConsultas,
          icon: const Icon(Icons.search_rounded, size: 20),
          label: const Text(
            'Aplicar Filtros',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
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
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              isActive ? _primaryColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? _primaryColor : _outline),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? _primaryColor : _onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isActive ? _primaryColor : _onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: _onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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

  // --- WIDGETS DE LISTA Y TARJETAS ---

  Widget _buildConsultationsList() {
    if (consultations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available_rounded, size: 64, color: _outline),
            const SizedBox(height: 16),
            Text(
              'No hay consultas agendadas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Prueba cambiando los filtros de búsqueda',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: consultations.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
      itemBuilder:
          (context, index) => _buildConsultationCard(consultations[index]),
    );
  }

  // Tarjeta de Consulta M3 Outlined
  Widget _buildConsultationCard(Consultation consultation) {
    final bool canCancel =
        (consultation.status.toUpperCase() == 'RESERVADO' ||
            consultation.status.toUpperCase() == 'SCHEDULED');
    final String formattedCardDate = _formatDateString(consultation.date);

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: _onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formattedCardDate,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: _onSurface,
                      ),
                    ),
                  ],
                ),
                // Tonal Chip para la hora
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    consultation.time,
                    style: TextStyle(
                      color: _primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: _outline, indent: 20, endIndent: 20),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  consultation.doctor,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  consultation.specialty,
                  style: TextStyle(
                    fontSize: 14,
                    color: _primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: _onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        consultation.branch,
                        style: TextStyle(
                          fontSize: 13,
                          color: _onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (canCancel)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                // Botón Outlined Destructivo M3
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelDialog(consultation),
                  icon: Icon(
                    Icons.cancel_outlined,
                    size: 18,
                    color: _errorColor,
                  ),
                  label: Text(
                    'Cancelar cita',
                    style: TextStyle(
                      color: _errorColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _errorColor.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBranchDropdown() {
    if (branches.isEmpty)
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text(
          'Sin sucursales disponibles',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _outline),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: branches.length,
        itemBuilder: (ctx, i) {
          final branch = branches[i];
          final isSelected = branch['descripcion_sucursal'] == selectedBranch;
          return InkWell(
            onTap:
                () => setState(() {
                  selectedBranch = branch['descripcion_sucursal'];
                  selectedBranchCode = branch['cod_sucursal'];
                  showBranchDropdown = false;
                }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color:
                  isSelected
                      ? _primaryColor.withOpacity(0.08)
                      : Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      branch['descripcion_sucursal'],
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? _primaryColor : _onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_rounded, color: _primaryColor, size: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _outline),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _statusOptions.length,
        itemBuilder: (ctx, i) {
          final option = _statusOptions[i];
          final isSelected = option['value'] == _selectedStatusValue;
          return InkWell(
            onTap:
                () => setState(() {
                  _selectedStatusValue = option['value']!;
                  showAgendaDropdown = false;
                }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color:
                  isSelected
                      ? _primaryColor.withOpacity(0.08)
                      : Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option['label']!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? _primaryColor : _onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_rounded, color: _primaryColor, size: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _verConsultas() async {
    setState(() => _isLoading = true);
    try {
      final apiDate = _formatDateForApi(_selectedDate);
      final apiStatus =
          _selectedStatusValue == 'TODOS' ? null : _selectedStatusValue;
      final results = await _fetchConsultationsWrapper(
        fecha: apiDate,
        branchId: selectedBranchCode > 0 ? selectedBranchCode : null,
        status: apiStatus,
      );

      setState(() {
        consultations = results;
        _isLoading = false;
        if (results.isNotEmpty) _isFiltersExpanded = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    }
  }

  // --- DIALOGO DE CANCELACIÓN M3 ---

  Future<void> _showCancelDialog(Consultation consultation) async {
    final TextEditingController motivoController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _errorColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.event_busy_rounded,
                      color: _errorColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cancelar Consulta',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¿Estás seguro de cancelar la cita con ${consultation.doctor}?',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _onSurfaceVariant, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: formKey,
                    child: TextFormField(
                      controller: motivoController,
                      decoration: InputDecoration(
                        labelText: 'Motivo de cancelación (Opcional)',
                        labelStyle: TextStyle(
                          color: _onSurfaceVariant,
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _errorColor),
                        ),
                        filled: true,
                        fillColor: _backgroundColor,
                      ),
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'Volver',
                            style: TextStyle(
                              color: _onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            if (formKey.currentState!.validate())
                              Navigator.pop(context, true);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: _errorColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Confirmar',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
    if (result == true)
      await _cancelConsultation(consultation, motivoController.text.trim());
  }

  Future<void> _cancelConsultation(
    Consultation consultation,
    String motivo,
  ) async {
    setState(() => _isLoading = true);
    try {
      final idReserva = int.tryParse(consultation.id);
      if (idReserva == null) throw Exception("ID inválido");

      String fechaParaServicio = '';
      String visualDate = consultation.date.trim();

      if (visualDate.contains('/')) {
        final parts = visualDate.split('/');
        if (parts.length == 3) {
          String dia = parts[0];
          String mes = parts[1];
          String anio = parts[2];
          if (anio.length == 4) anio = anio.substring(2);
          fechaParaServicio = '$dia-$mes-$anio';
        }
      } else if (visualDate.contains('-')) {
        final parts = visualDate.split('-');
        if (parts.length == 3) {
          String anio = parts[2];
          if (anio.length == 4) anio = anio.substring(2);
          fechaParaServicio = '${parts[0]}-${parts[1]}-$anio';
        }
      }

      if (fechaParaServicio.isEmpty) {
        String raw = consultation.fechaOriginal ?? '';
        if (raw.contains('-')) {
          final parts = raw.split('-');
          if (parts.length == 3) {
            if (parts[0].length == 4) {
              String anio = parts[0].substring(2);
              fechaParaServicio = '${parts[2]}-${parts[1]}-$anio';
            } else if (parts[2].length == 4) {
              String anio = parts[2].substring(2);
              fechaParaServicio = '${parts[0]}-${parts[1]}-$anio';
            } else {
              fechaParaServicio = raw;
            }
          }
        }
      }

      if (fechaParaServicio.isEmpty)
        throw Exception("No se pudo obtener formato DD-MM-YY");

      final res = await _consultationService.cancelConsultation(
        idReservaPaciente: idReserva,
        motivo: motivo,
        fechaReserva: fechaParaServicio,
        horaTurno: consultation.time,
      );

      if (res['success'] == true) {
        await _verConsultas();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Consulta cancelada'),
              backgroundColor: Colors.green,
            ),
          );
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? res['error'] ?? 'Error'),
              backgroundColor: Colors.red,
            ),
          );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

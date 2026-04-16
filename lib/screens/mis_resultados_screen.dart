import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/estudio_model.dart';
import '../models/sucursal_model.dart';
import '../services/user_service.dart';
import '../services/estudios_api_service.dart';
import '../services/post_auth_service.dart';
import '../services/pdf_download_service.dart';
import '../widgets/custom_snackbar.dart';

class MisResultadosScreen extends StatefulWidget {
  const MisResultadosScreen({Key? key}) : super(key: key);

  @override
  State<MisResultadosScreen> createState() => _MisResultadosScreenState();
}

class _MisResultadosScreenState extends State<MisResultadosScreen> with SingleTickerProviderStateMixin {
  // --- Colores Material 3 ---
  final Color _primaryColor = const Color(0xFFB47EDB);
  final Color _secondaryColor = const Color(0xFF09D5D6);
  final Color _backgroundColor = const Color(0xFFF7F9FC); // Surface container lowest
  final Color _onSurface = const Color(0xFF1F1F1F); // Texto principal oscuro
  final Color _onSurfaceVariant = const Color(0xFF444746); // Texto secundario
  final Color _outline = const Color(0xFFE0E2E5); // Bordes de tarjetas M3

  // Estados de Filtros
  DateTime? _selectedDate;
  String? _selectedSucursalId;
  String? _selectedEstudioId;

  // Control de panel colapsable
  bool _isFiltersExpanded = false;

  // Datos
  List<Sucursal> _listaSucursales = [];
  List<DropdownItem> _listaTiposEstudios = [];
  List<Estudio> _resultados = [];

  bool _isLoading = false;

  // Controladores de dropdowns internos
  bool _showStudyDropdown = false;
  bool _showBranchDropdown = false;

  int? _idCliente;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = UserService.getCurrentUser();
      if (currentUser == null) throw Exception("Usuario no logueado.");

      final authRes = await PostAuthService.verifyEmailAndGetClientId(currentUser.email);
      if (authRes['success'] != true) throw Exception("No se pudo obtener ID Cliente.");
      _idCliente = authRes['id_cliente'];

      final results = await Future.wait([
        EstudiosApiService.getSucursales(),
        EstudiosApiService.getEstudiosCliente(_idCliente!)
      ]);

      final sucursales = results[0] as List<Sucursal>;
      final estudiosIniciales = results[1] as List<Estudio>;

      // Extraer tipos de estudios únicos para el filtro
      final uniqueAnalisis = <String, String>{};
      for (var e in estudiosIniciales) {
        if (e.codAnalisis.isNotEmpty) {
          uniqueAnalisis[e.codAnalisis] = e.analisis;
        } else {
          uniqueAnalisis[e.analisis] = e.analisis;
        }
      }

      final listaTipos = uniqueAnalisis.entries
          .map((e) => DropdownItem(id: e.key, label: e.value))
          .toList();

      if (mounted) {
        setState(() {
          _listaSucursales = sucursales;
          _listaTiposEstudios = listaTipos;
          _resultados = estudiosIniciales;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackBar.showError(context, message: 'Error cargando datos: $e');
      }
    }
  }

  Future<void> _applyFilters() async {
    setState(() => _isLoading = true);

    String? fechaStr;
    if (_selectedDate != null) {
      fechaStr = DateFormat('dd-MM-yy').format(_selectedDate!);
    }

    try {
      final resultadosFiltrados = await EstudiosApiService.getEstudiosCliente(
        _idCliente!,
        fecha: fechaStr,
        sucursal: _selectedSucursalId,
        estudio: _selectedEstudioId,
      );

      setState(() {
        _resultados = resultadosFiltrados;
        _isLoading = false;
        _showBranchDropdown = false;
        _showStudyDropdown = false;

        // Auto-colapsar filtros si hay resultados
        if (resultadosFiltrados.isNotEmpty) {
          _isFiltersExpanded = false;
        }
      });

    } catch (e) {
      setState(() => _isLoading = false);
      CustomSnackBar.showError(context, message: 'Error de conexión: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor, // M3 usa el color del fondo
        surfaceTintColor: Colors.transparent, // Evita que cambie de color al hacer scroll
        elevation: 0,
        centerTitle: true,
        title: Text(
            'Mis resultados',
            style: TextStyle(fontWeight: FontWeight.w600, color: _onSurface, fontSize: 20)
        ),
        iconTheme: IconThemeData(color: _onSurface), // Íconos oscuros
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _initializeData,
              tooltip: 'Recargar'
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

                  // 1. PANEL DE FILTROS COLAPSABLE (M3 Filled Card)
                  _buildCollapsiblePanel(
                    title: 'Filtros de búsqueda',
                    icon: Icons.tune_rounded, // Icono más moderno de M3
                    isExpanded: _isFiltersExpanded,
                    onToggle: () => setState(() => _isFiltersExpanded = !_isFiltersExpanded),
                    child: _buildFilterContent(),
                  ),

                  const SizedBox(height: 32),

                  // 2. HEADER RESULTADOS (Limpieza M3)
                  Text(
                    'Resultados recientes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. LISTA DE RESULTADOS
                  _isLoading
                      ? Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator(color: _primaryColor))
                  )
                      : _buildResultsList(),

                  const SizedBox(height: 40),

                  // Logo Footer
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

  // --- WIDGETS DE ESTRUCTURA Y DISEÑO M3 ---

  // Panel Colapsable (M3 Filled Container)
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
        borderRadius: BorderRadius.circular(24), // Radio M3 amplio
        border: Border.all(color: _outline), // Borde sutil en lugar de sombra
      ),
      child: Column(
        children: [
          // Header Interno
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

          if (isExpanded) Divider(height: 1, color: _outline, indent: 20, endIndent: 20),

          // Contenido Animado
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

  // --- CONTENIDO DE LOS FILTROS ---
  Widget _buildFilterContent() {
    String fechaLabel = _selectedDate == null ? 'Todas las fechas' : DateFormat('dd-MM-yy').format(_selectedDate!);
    String sucursalLabel = 'Todas las sucursales';
    if (_selectedSucursalId != null) {
      final suc = _listaSucursales.firstWhere((e) => e.codigo == _selectedSucursalId, orElse: () => Sucursal(codigo: '', descripcion: ''));
      if(suc.codigo.isNotEmpty) sucursalLabel = suc.descripcion;
    }
    String estudioLabel = 'Todos los estudios';
    if (_selectedEstudioId != null) {
      final est = _listaTiposEstudios.firstWhere((e) => e.id == _selectedEstudioId, orElse: () => DropdownItem(id: '', label: ''));
      if(est.label.isNotEmpty) estudioLabel = est.label;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFilterField(
            label: 'Fecha', value: fechaLabel, icon: Icons.calendar_today_rounded,
            isActive: _selectedDate != null,
            onTap: () async {
              setState(() { _showStudyDropdown = false; _showBranchDropdown = false; });
              final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  builder: (context, child) => Theme(
                    data: ThemeData.light().copyWith(
                      colorScheme: ColorScheme.light(primary: _primaryColor, onPrimary: Colors.white),
                    ),
                    child: child!,
                  )
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            onClear: () { setState(() => _selectedDate = null); }
        ),

        const SizedBox(height: 12),

        _buildFilterField(
            label: 'Estudio realizado', value: estudioLabel, icon: Icons.science_rounded,
            isActive: _selectedEstudioId != null,
            onTap: () => setState(() { _showStudyDropdown = !_showStudyDropdown; _showBranchDropdown=false; }),
            onClear: () { setState(() => _selectedEstudioId = null); }
        ),
        if (_showStudyDropdown) _buildGenericDropdown(
            items: _listaTiposEstudios,
            selectedId: _selectedEstudioId,
            onSelect: (id) => setState(() { _selectedEstudioId = id; _showStudyDropdown = false; })
        ),

        const SizedBox(height: 12),

        _buildFilterField(
            label: 'Sucursal', value: sucursalLabel, icon: Icons.location_on_rounded,
            isActive: _selectedSucursalId != null,
            onTap: () => setState(() { _showBranchDropdown = !_showBranchDropdown; _showStudyDropdown=false; }),
            onClear: () { setState(() => _selectedSucursalId = null); }
        ),
        if (_showBranchDropdown) _buildGenericDropdown(
            items: _listaSucursales.map((s) => DropdownItem(id: s.codigo, label: s.descripcion)).toList(),
            selectedId: _selectedSucursalId,
            onSelect: (id) => setState(() { _selectedSucursalId = id; _showBranchDropdown = false; })
        ),

        const SizedBox(height: 24),

        // Botón M3 (Stadium Border)
        FilledButton.icon(
          onPressed: _applyFilters,
          icon: const Icon(Icons.search_rounded, size: 20),
          label: const Text('Aplicar Filtros', style: TextStyle(fontWeight: FontWeight.w600)),
          style: FilledButton.styleFrom(
            backgroundColor: _primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: const StadiumBorder(), // Forma M3
          ),
        ),
      ],
    );
  }

  // --- LISTA DE RESULTADOS ---
  Widget _buildResultsList() {
    if (_resultados.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: _outline),
            const SizedBox(height: 16),
            Text(
              "No se encontraron resultados",
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
      itemCount: _resultados.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildResultItem(_resultados[index]),
    );
  }

  // --- TARJETA DE RESULTADO (Outlined Card M3) ---
  Widget _buildResultItem(Estudio estudio) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _outline), // Sin sombras, puro borde
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // Centrado vertical
          children: [
            // Icono Circular (Tonal)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFBA1A1A).withOpacity(0.08), // Tonalidad roja
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFBA1A1A), size: 24),
            ),
            const SizedBox(width: 16),

            // Información
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    estudio.analisis,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: _onSurface),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: _onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        estudio.fechaSolicitud,
                        style: TextStyle(fontSize: 13, color: _onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 14, color: _onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          estudio.nombreSucursal,
                          style: TextStyle(fontSize: 13, color: _onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Botón Descarga Tonal M3
            IconButton(
              onPressed: () => _downloadEstudio(estudio),
              icon: const Icon(Icons.download_rounded),
              color: _primaryColor,
              style: IconButton.styleFrom(
                backgroundColor: _primaryColor.withOpacity(0.1), // Fondo tonal
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              tooltip: 'Descargar PDF',
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

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
    required List<DropdownItem> items,
    required String? selectedId,
    required Function(String) onSelect
  }) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
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
          ? const Padding(padding: EdgeInsets.all(16), child: Text("Sin opciones", style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center))
          : ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final item = items[i];
          final isSelected = item.id == selectedId;
          return InkWell(
            onTap: () => onSelect(item.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isSelected ? _primaryColor.withOpacity(0.08) : Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                      child: Text(
                          item.label,
                          style: TextStyle(
                              fontSize: 14,
                              color: isSelected ? _primaryColor : _onSurface,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400
                          )
                      )
                  ),
                  if (isSelected) Icon(Icons.check_rounded, color: _primaryColor, size: 18)
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _downloadEstudio(Estudio estudio) async {
    if (estudio.codFirma == null) {
      CustomSnackBar.showError(context, message: 'Este estudio aún no está firmado digitalmente.');
      return;
    }
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
            child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: CircularProgressIndicator(color: _primaryColor)
            )
        )
    );
    try {
      final nombreLimpio = estudio.analisis.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(RegExp(r'\s+'), '_');
      final nombreArchivo = '${nombreLimpio}_${estudio.codSolicitud}.pdf';
      final res = await PdfDownloadService.downloadPdf(idSolicitud: estudio.codSolicitud, idFirma: estudio.codFirma!, nombreArchivo: nombreArchivo);
      if (mounted) Navigator.pop(context);
      if (res['success']) {
        CustomSnackBar.showSuccess(context, message: 'Archivo descargado exitosamente.');
      } else {
        CustomSnackBar.showError(context, message: res['message']);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      CustomSnackBar.showError(context, message: 'Error en la descarga: $e');
    }
  }
}

class DropdownItem {
  final String id;
  final String label;
  DropdownItem({required this.id, required this.label});
}
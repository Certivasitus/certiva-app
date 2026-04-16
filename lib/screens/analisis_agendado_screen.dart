import 'package:flutter/material.dart';

class AnalisisAgendadoScreen extends StatelessWidget {
  final List<String> exams;
  final String branch;
  final String date;
  final String time;

  const AnalisisAgendadoScreen({
    Key? key,
    required this.exams,
    required this.branch,
    required this.date,
    required this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/fondo_consulta_agendada.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header con botón de regreso
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFFB47EDB)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                // Contenido principal centrado y scrolleable
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Ícono de éxito
                          _buildSuccessIcon(),

                          const SizedBox(height: 32),

                          // Mensaje de confirmación
                          const Text(
                            'Exámenes laboratoriales agendados exitosamente',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF09D5D6),
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 24),

                          // Detalles del análisis
                          _buildAnalysisDetails(),

                          const SizedBox(height: 48),

                          // Botones de acción
                          _buildActionButtons(context),
                        ],
                      ),
                    ),
                  ),
                ),

                // Logo de Certiva al final
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Image.asset(
                      'assets/icons/logo_color.png',
                      width: 151,
                      height: 76,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green,
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            spreadRadius: 8,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.check,
        size: 60,
        color: Colors.white,
      ),
    );
  }

  Widget _buildAnalysisDetails() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDetailRow('Sucursal', branch),
          const SizedBox(height: 12),
          _buildDetailRow('Fecha', date),
          const SizedBox(height: 12),
          _buildDetailRow('Hora', '$time hrs'),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF09D5D6)),
          const SizedBox(height: 12),
          _buildExamsList(),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExamsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Exámenes agendados:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ...exams.map((exam) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF09D5D6),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exam,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Botón para ver mis análisis
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Navegar a mis análisis
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB47EDB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Ver mis análisis',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Botón para agendar otro análisis
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB47EDB),
              side: const BorderSide(color: Color(0xFFB47EDB)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Agendar otro análisis.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
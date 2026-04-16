import 'package:flutter/material.dart';
import 'mi_agenda_screen.dart';

class ConsultaAgendadaScreen extends StatelessWidget {
  final String specialty;
  final String doctor;
  final String branch;
  final String date;
  final String time;

  const ConsultaAgendadaScreen({
    Key? key,
    required this.specialty,
    required this.doctor,
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
              
              // Contenido principal centrado
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
                          'Consulta agendada exitosamente',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF09D5D6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Detalles de la consulta
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: _buildConsultationDetails(),
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // Botones de acción
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: _buildActionButtons(context),
                        ),
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

  Widget _buildConsultationDetails() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildDetailRow('Especialidad', specialty),
          const SizedBox(height: 12),
          _buildDetailRow('Médico', doctor),
          const SizedBox(height: 12),
          _buildDetailRow('Sucursal', branch),
          const SizedBox(height: 12),
          _buildDetailRow('Fecha', date),
          const SizedBox(height: 12),
          _buildDetailRow('Hora', '$time hrs'),
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

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Botón para ver mis consultas
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MiAgendaScreen(),
                ),
              );
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
              'Ver mis consultas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Botón para agendar otra consulta
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
              'Agendar otra consulta',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
} 
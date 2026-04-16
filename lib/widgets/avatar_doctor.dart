import 'package:flutter/material.dart';

class AvatarDoctor extends StatelessWidget {
  final String? url;
  final double radius;
  final Color primaryColor;

  const AvatarDoctor({
    Key? key,
    required this.url,
    this.radius = 20,
    required this.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Limpieza de URL
    final String? cleanUrl = url?.trim();

    // 2. Si no hay URL, mostrar Placeholder inmediatamente
    if (cleanUrl == null || cleanUrl.isEmpty) {
      return _buildPlaceholder();
    }

    // 3. Usamos ClipOval + Image.network (Nativo de Flutter)
    // Esto replica lo que hacía el CircleAvatar pero nos deja poner el Spinner
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[200], // Color de fondo mientras carga
      ),
      child: ClipOval(
        child: Image.network(
          cleanUrl,
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,

          // A. Mientras carga: Mostramos el Spinner
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child; // Ya cargó
            return Center(
              child: SizedBox(
                width: radius * 0.8,
                height: radius * 0.8,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    primaryColor.withOpacity(0.5),
                  ),
                  // Barra de progreso opcional (puedes quitar 'value' si quieres spinner infinito)
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },

          // B. Si falla: Mostramos el Placeholder
          errorBuilder: (context, error, stackTrace) {
            // Imprime el error real en consola para que sepas qué pasó
            print('❌ Error Avatar Nativo ($cleanUrl): $error');
            return Container(
              color: Colors.grey[200], // Fondo gris para el icono
              child: Icon(
                Icons.person,
                size: radius * 1.2,
                color: primaryColor.withOpacity(0.8),
              ),
            );
          },
        ),
      ),
    );
  }

  // Widget auxiliar para cuando no hay foto
  Widget _buildPlaceholder() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
      child: Icon(
        Icons.person,
        size: radius * 1.2,
        color: primaryColor.withOpacity(0.8),
      ),
    );
  }
}
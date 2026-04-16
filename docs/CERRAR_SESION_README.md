# Funcionalidad de Cerrar Sesión - Certiva App

## Descripción
Se ha implementado la funcionalidad de cerrar sesión en la aplicación Certiva para permitir a los usuarios salir de su cuenta de forma segura.

## Ubicaciones de la funcionalidad

### 1. Drawer Principal (Menú lateral)
- **Ubicación**: `lib/screens/main_drawer.dart`
- **Acceso**: Deslizar desde el borde izquierdo de la pantalla
- **Posición**: Al final del menú, antes de la opción de "Ayuda"
- **Icono**: 🚪 (logout)
- **Texto**: "Cerrar sesión"

### 2. Pantalla de Bienvenida
- **Ubicación**: `lib/screens/bienvenida_screen.dart`
- **Acceso**: Esquina superior derecha de la pantalla
- **Posición**: Botón flotante con fondo semi-transparente
- **Icono**: 🚪 (logout)

### 3. Pantalla Principal (Home)
- **Ubicación**: `lib/screens/home_screen.dart`
- **Acceso**: Barra superior (AppBar), lado derecho
- **Posición**: Junto al botón de notificaciones
- **Icono**: 🚪 (logout)

## Funcionalidad implementada

### Al cerrar sesión:
1. **Cierre de Firebase Auth**: Se cierra la sesión de Firebase si está activa
2. **Limpieza de datos locales**: Se elimina el usuario actual del almacenamiento local (Hive)
3. **Navegación**: Se redirige al usuario a la pantalla de login
4. **Limpieza de navegación**: Se eliminan todas las pantallas anteriores del stack de navegación

### Métodos del UserService utilizados:
- `clearCurrentUser()`: Limpia el usuario actual del almacenamiento local
- `logout()`: Método alternativo que hace lo mismo

## Archivos modificados

1. **`lib/screens/main_drawer.dart`**
   - Agregado botón de cerrar sesión en el drawer
   - Import de Firebase Auth y LoginScreen

2. **`lib/screens/bienvenida_screen.dart`**
   - Agregado botón de cerrar sesión en esquina superior derecha
   - Import de Firebase Auth y LoginScreen

3. **`lib/screens/home_screen.dart`**
   - Agregado botón de cerrar sesión en el AppBar
   - Import de Firebase Auth y LoginScreen

4. **`lib/services/user_service.dart`**
   - Agregado método `clearCurrentUser()` como alias de `logout()`

## Consideraciones de seguridad

- Se maneja tanto la sesión de Firebase como los datos locales
- Se limpia completamente el estado de la aplicación
- Se previene el acceso a pantallas anteriores después del logout
- Se manejan errores de Firebase de forma segura

## Uso para el usuario

El usuario puede cerrar sesión desde cualquiera de las tres ubicaciones mencionadas. Al hacerlo:
- Será redirigido a la pantalla de login
- Deberá volver a autenticarse para acceder a la aplicación
- Sus datos locales serán limpiados
- No podrá acceder a pantallas anteriores sin volver a iniciar sesión 
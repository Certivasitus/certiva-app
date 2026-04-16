# Integración con API de Clientes - Certiva App

## Descripción
Se ha implementado la integración con la API de clientes para mantener los datos sincronizados entre el servidor y la aplicación local. La API se usa como fuente principal de datos, con Hive como respaldo offline.

## Arquitectura de Datos

### Prioridad de Fuentes de Datos:
1. **API del Servidor** (Fuente Principal)
   - URL: `https://kove.app.kove.com.py/ords/certiva_situs/app/get_cliente/:ID_CLIENTE`
   - Método: GET
   - Autenticación: Basic Auth (CERTIVA_APP / CerTiva2028*)

2. **Hive Local** (Respaldo Offline)
   - Se usa cuando la API no está disponible
   - Mantiene una copia local de los datos del usuario

## Servicios Implementados

### 1. ClientApiService (`lib/services/client_api_service.dart`)
- **getClientById(int idCliente)**: Obtiene cliente por ID desde la API
- **getClientByEmail(String email)**: Búsqueda por email (pendiente de implementar)
- **getClientByCedula(String cedula)**: Búsqueda por cédula (pendiente de implementar)

### 2. PostAuthService (`lib/services/post_auth_service.dart`) - NUEVO
- **verifyEmailAndGetClientId(String email)**: Verifica si el email está registrado y obtiene id_cliente
- **isEmailRegistered(String email)**: Verifica si un email está registrado (método simplificado)
- **getClientIdByEmail(String email)**: Obtiene solo el id_cliente de un email

### 3. EstudiosApiService (`lib/services/estudios_api_service.dart`) - NUEVO
- **getEstudiosCliente(int idCliente)**: Obtiene estudios de laboratorio de un cliente
- **hasEstudios(int idCliente)**: Verifica si un cliente tiene estudios
- **getEstudiosList(int idCliente)**: Obtiene solo la lista de estudios

### 4. UserService Modificado (`lib/services/user_service.dart`)
- **getUserByEmail()**: Ahora es asíncrono, prioriza API sobre Hive
- **syncUserWithApi()**: Sincroniza usuario con la API
- **getUserByCedula()**: Búsqueda por cédula con prioridad API

## Modelo User Actualizado

### Nuevo Campo:
- **idCliente**: ID del cliente en la API del servidor
- **Tipo**: `int?` (opcional para compatibilidad)

### Mapeo API → Modelo User:
```dart
{
  'nombre' → 'nombres',
  'apellido' → 'apellidos', 
  'cedula' → 'cedula',
  'direccion' → 'direccion',
  'telefono' → 'celular',
  'email' → 'email',
  'prepaga' → 'seguro',
  'id_cliente' → 'idCliente'
}
```

## Flujo de Datos

### Al Iniciar Sesión:
1. Usuario se autentica con email/password
2. Si la autenticación es exitosa:
   - Se busca el usuario por email
   - **PRIORIDAD 1**: Intentar obtener desde la API si hay idCliente
   - **PRIORIDAD 2**: Usar datos de Hive como respaldo
3. Los datos se actualizan en Hive para uso offline

### Al Registrar Usuario:
1. Usuario se registra en la API de registro
2. Los datos se guardan también en Hive local
3. Se mantiene sincronización entre ambas fuentes

### Al Consultar Datos:
1. **Primero**: Intentar obtener desde la API
2. **Si falla**: Usar datos de Hive
3. **Actualizar**: Hive se actualiza con datos más recientes de la API

## Endpoints de la API

### POST /app/post_autenticacion - NUEVO
- **Método**: POST
- **Body**: `{"email": "usuario@email.com"}`
- **Autenticación**: Basic Auth (CERTIVA_APP / CerTiva2028*)
- **Respuesta Exitosa**: 200 con id_cliente
- **Respuesta Error**: 404 si el email no está registrado

### GET /app/get_cliente/:ID_CLIENTE
- **Parámetro**: ID del cliente (numérico)
- **Respuesta Exitosa**: 200 con datos del cliente
- **Respuesta Error**: 404 si no se encuentra el cliente

### GET /app/get_estudios_cliente/:ID_CLIENTE - NUEVO
- **Parámetro**: ID del cliente (numérico)
- **Autenticación**: Basic Auth (CERTIVA_APP / CerTiva2028*)
- **Respuesta Exitosa**: 200 con lista de estudios
- **Respuesta Error**: 404 si no se encuentran estudios

### Ejemplo de Respuesta:
```json
{
  "clientes": [
    {
      "id_cliente": 9,
      "nombre": "LUIS CARLOS",
      "apellido": "FERREIRA ESCOBAR",
      "email": "carloslfe83@gmail.com",
      "bloqueado": "NO",
      "autenticacion": "CORREO",
      "sex_id_sexo": null,
      "razon_social": null,
      "ruc": null,
      "id_cliente_final": 13,
      "telefono": "0983794075",
      "cedula": 5009110,
      "direccion": "test1",
      "prepaga": 2
    }
  ]
}
```

## Manejo de Errores

### Errores de API:
- **404**: Cliente no encontrado
- **500+**: Errores del servidor
- **Timeout**: Problemas de conectividad

### Estrategia de Fallback:
1. Intentar obtener datos desde la API
2. Si falla, usar datos locales de Hive
3. Log de errores para debugging
4. Continuidad del servicio offline

## Consideraciones de Seguridad

- **Autenticación**: Basic Auth con credenciales seguras
- **HTTPS**: Todas las comunicaciones son seguras
- **Datos Sensibles**: La contraseña no se devuelve desde la API
- **Validación**: Verificación de datos antes de guardar en Hive

## Uso en la Aplicación

### Para Desarrolladores:
```dart
// Verificar si email está registrado y obtener id_cliente
final result = await PostAuthService.verifyEmailAndGetClientId(email);
if (result['success'] == true) {
  final idCliente = result['id_cliente'];
  // Usar id_cliente para otras operaciones
}

// Verificación simple
final isRegistered = await PostAuthService.isEmailRegistered(email);

// Obtener solo id_cliente
final idCliente = await PostAuthService.getClientIdByEmail(email);

// Obtener usuario (prioriza API)
final user = await UserService.getUserByEmail(email);

// Sincronizar con API
final syncedUser = await UserService.syncUserWithApi(idCliente);

// Buscar por cédula
final userByCedula = await UserService.getUserByCedula(cedula);
```

### Para Usuarios:
- Los datos se mantienen automáticamente sincronizados
- Funciona offline con datos locales
- Se actualiza automáticamente cuando hay conexión

## Próximos Pasos

### Funcionalidades Pendientes:
1. **Búsqueda por Email**: Implementar endpoint en la API
2. **Búsqueda por Cédula**: Implementar endpoint en la API
3. **Sincronización Bidireccional**: Actualizar API con cambios locales
4. **Cache Inteligente**: Implementar expiración de datos

### Mejoras Futuras:
1. **Webhooks**: Notificaciones en tiempo real de cambios
2. **Sincronización Automática**: En segundo plano
3. **Conflictos**: Resolución de datos conflictivos
4. **Auditoría**: Log de cambios y sincronizaciones 
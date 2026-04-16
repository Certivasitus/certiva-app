# 📝 Pasos Detallados para Cambiar el Bundle ID

## 🔍 Ubicaciones del Bundle ID Actual

El Bundle ID `com.example.certivaApp` aparece en **6 lugares** en el archivo `project.pbxproj`:

1. **Línea 371** - Profile (Producción)
2. **Línea 387** - RunnerTests Debug
3. **Línea 404** - RunnerTests Release  
4. **Línea 419** - RunnerTests Profile
5. **Línea 550** - Debug
6. **Línea 572** - Release

## ✅ Pasos para Cambiar Manualmente

### Paso 1: Elige tu nuevo Bundle ID

**Formato válido:** `com.tuempresa.nombreapp`

**Ejemplos:**
- `com.certiva.app`
- `py.com.certiva.app`
- `com.tuempresa.certivaapp`

### Paso 2: Abre el archivo

Abre: `certiva_app/ios/Runner.xcodeproj/project.pbxproj`

### Paso 3: Busca y Reemplaza

Usa la función "Buscar y Reemplazar" de tu editor:

**Buscar:**
```
com.example.certivaApp
```

**Reemplazar con:**
```
com.tuempresa.certivaapp
```
*(Usa tu Bundle ID real)*

**⚠️ IMPORTANTE:** Reemplaza **TODAS** las ocurrencias (6 en total)

### Paso 4: También actualiza codemagic.yaml

Si vas a usar Codemagic, también cambia en `certiva_app/codemagic.yaml`:

```yaml
vars:
  APP_ID: "com.tuempresa.certivaapp"  # Cambia esto
  BUNDLE_ID: "com.tuempresa.certivaapp"  # Y esto
```

### Paso 5: Limpia y reconstruye

```bash
cd certiva_app
flutter clean
flutter pub get
```

## 🎯 Verificación

Después de cambiar:

1. **Si tienes Xcode:**
   - Abre `ios/Runner.xcworkspace`
   - Ve a Runner → Signing & Capabilities
   - Verifica que muestra tu nuevo Bundle ID

2. **Si no tienes Xcode:**
   - Busca en `project.pbxproj` que todas las ocurrencias cambiaron
   - Verifica que no quede ninguna `com.example.certivaApp`

## ⚠️ Importante

- El Bundle ID debe ser **único** (no puede estar en uso)
- Debe coincidir **exactamente** con el de App Store Connect
- No puede tener espacios ni caracteres especiales
- Debe seguir el formato: `com.dominio.app`

## 🚀 Siguiente Paso

Después de cambiar el Bundle ID:
1. Crea la app en App Store Connect con el mismo Bundle ID
2. Configura Codemagic (si lo usas)
3. Construye y sube a TestFlight


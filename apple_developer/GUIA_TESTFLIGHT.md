# Guía para Subir Certiva App a TestFlight

Esta guía te ayudará a subir tu aplicación Flutter a TestFlight para distribución de pruebas.

## 🎯 Opciones Disponibles

Tienes **3 opciones** para subir tu app a TestFlight:

1. **🚀 Codemagic (Recomendado)** - Automatización completa, no necesitas Mac
   - Ver: `GUIA_CODEMAGIC.md` o `INICIO_RAPIDO_CODEMAGIC.md`
   - ✅ Más fácil y rápido
   - ✅ No necesitas Mac
   - ✅ Automatización completa

2. **💻 Xcode Manual** - Proceso tradicional (esta guía)
   - Requiere Mac con Xcode
   - Control total del proceso

3. **📦 Scripts Locales** - Usando los scripts incluidos
   - Ver: `build_ios_release.bat` o `build_ios_release.sh`

## 📋 Requisitos Previos

1. **Cuenta de Apple Developer** activa (membresía anual de $99 USD)
2. **Mac con Xcode** instalado (versión 14.0 o superior) - Solo para opción 2 y 3
3. **Certificados y Perfiles de Aprovisionamiento** configurados
4. **App Store Connect** - App creada con Bundle ID único

## 🔧 Paso 1: Configurar Bundle Identifier Único

El bundle identifier actual es `com.example.certivaApp`. Necesitas cambiarlo por uno único que coincida con tu cuenta de Apple Developer.

**Ejemplo:** `com.tuempresa.certivaapp` o `py.com.certiva.app`

### Cambiar Bundle Identifier:

1. Abre `certiva_app/ios/Runner.xcodeproj` en Xcode
2. Selecciona el proyecto "Runner" en el navegador
3. Selecciona el target "Runner"
4. Ve a la pestaña "Signing & Capabilities"
5. Cambia el Bundle Identifier a tu ID único (ej: `com.tuempresa.certivaapp`)

**O edita manualmente el archivo `project.pbxproj`:**

Busca todas las ocurrencias de `com.example.certivaApp` y reemplázalas con tu bundle ID único.

## 🔐 Paso 2: Configurar Certificados y Perfiles de Aprovisionamiento

### Opción A: Automático (Recomendado)

1. Abre el proyecto en Xcode: `certiva_app/ios/Runner.xcworkspace`
2. Selecciona el target "Runner"
3. En "Signing & Capabilities", marca "Automatically manage signing"
4. Selecciona tu Team de Apple Developer
5. Xcode generará automáticamente los certificados y perfiles necesarios

### Opción B: Manual

1. Ve a [Apple Developer Portal](https://developer.apple.com/account)
2. Crea un App ID con tu Bundle Identifier
3. Crea un certificado de distribución (Distribution Certificate)
4. Crea un perfil de aprovisionamiento de distribución (Distribution Provisioning Profile)
5. Descarga e instala ambos en tu Mac

## 📱 Paso 3: Crear la App en App Store Connect

1. Ve a [App Store Connect](https://appstoreconnect.apple.com)
2. Inicia sesión con tu cuenta de Apple Developer
3. Ve a "Mis Apps" → "+" → "Nueva App"
4. Completa la información:
   - **Plataforma:** iOS
   - **Nombre:** Certiva App
   - **Idioma principal:** Español
   - **Bundle ID:** El mismo que configuraste en Xcode
   - **SKU:** Un identificador único (ej: certiva-app-001)
5. Crea la app

## 🏗️ Paso 4: Construir el Archivo IPA

### Método 1: Usando Flutter (Recomendado)

```bash
# Navega a la carpeta del proyecto
cd certiva_app

# Limpia el proyecto
flutter clean

# Obtén las dependencias
flutter pub get

# Construye el archivo IPA para distribución
flutter build ipa --release
```

El archivo IPA se generará en: `certiva_app/build/ios/ipa/certiva_app.ipa`

### Método 2: Usando Xcode

1. Abre `certiva_app/ios/Runner.xcworkspace` en Xcode
2. Selecciona "Any iOS Device" o un dispositivo genérico en el selector de dispositivos
3. Ve a **Product → Archive**
4. Espera a que se complete el proceso
5. Se abrirá el Organizer de Xcode con tu archivo

## 📤 Paso 5: Subir a App Store Connect

### Opción A: Desde Xcode (Más Fácil)

1. En el Organizer de Xcode, selecciona tu archivo
2. Haz clic en **"Distribute App"**
3. Selecciona **"App Store Connect"**
4. Sigue el asistente:
   - Selecciona "Upload"
   - Revisa la información
   - Selecciona "Automatically manage signing" (si no lo hiciste antes)
   - Haz clic en "Upload"
5. Espera a que termine el proceso (puede tardar varios minutos)

### Opción B: Usando Transporter (App de Mac)

1. Descarga **Transporter** desde el Mac App Store
2. Abre Transporter
3. Arrastra tu archivo `.ipa` a Transporter
4. Haz clic en **"Deliver"**
5. Espera a que termine la carga

### Opción C: Usando Command Line (xcrun altool)

```bash
# Instala Transporter CLI si no lo tienes
# Luego usa:
xcrun altool --upload-app --type ios --file "certiva_app/build/ios/ipa/certiva_app.ipa" --username "tu-email@ejemplo.com" --password "tu-app-specific-password"
```

**Nota:** Necesitas generar una contraseña específica de app en [appleid.apple.com](https://appleid.apple.com)

## ✅ Paso 6: Configurar en App Store Connect

1. Ve a [App Store Connect](https://appstoreconnect.apple.com)
2. Selecciona tu app "Certiva App"
3. Ve a la pestaña **"TestFlight"**
4. Espera a que el procesamiento termine (puede tardar 10-30 minutos)
5. Una vez procesado, verás tu build en la sección "Builds"

## 👥 Paso 7: Agregar Testers

### Testers Internos (hasta 100)

1. En TestFlight, ve a **"Internal Testing"**
2. Crea un grupo de testers (ej: "Equipo Certiva")
3. Agrega los emails de los testers internos
4. Selecciona el build que quieres distribuir
5. Los testers recibirán un email de invitación

### Testers Externos (hasta 10,000)

1. En TestFlight, ve a **"External Testing"**
2. Crea un grupo de testers externos
3. Agrega los emails
4. **IMPORTANTE:** Para testers externos, necesitas:
   - Completar la información de exportación
   - Responder las preguntas de contenido
   - Esperar la revisión de Apple (1-2 días)
5. Una vez aprobado, selecciona el build
6. Los testers recibirán un email de invitación

## 📱 Paso 8: Instalar TestFlight

Los testers necesitan:

1. Instalar la app **TestFlight** desde el App Store
2. Aceptar la invitación por email
3. Abrir el enlace en su iPhone/iPad
4. Instalar la app desde TestFlight

## 🔄 Actualizar la Versión

Cada vez que quieras subir una nueva versión:

1. Actualiza la versión en `pubspec.yaml`:
   ```yaml
   version: 1.0.1+3  # Incrementa el número de versión y build
   ```

2. Sigue los pasos 4 y 5 nuevamente

3. El nuevo build aparecerá en TestFlight automáticamente

## ⚠️ Problemas Comunes

### Error: "No signing certificate found"
- Solución: Configura el signing automático en Xcode o instala los certificados manualmente

### Error: "Bundle identifier already exists"
- Solución: Usa un bundle ID único que no esté en uso

### Error: "Invalid bundle"
- Solución: Asegúrate de que el bundle ID en Xcode coincida exactamente con el de App Store Connect

### El build no aparece en TestFlight
- Solución: Espera 10-30 minutos. Si después de 1 hora no aparece, revisa los emails de App Store Connect para errores

### Error al subir: "Invalid credentials"
- Solución: Genera una nueva contraseña específica de app en appleid.apple.com

## 📝 Checklist Final

- [ ] Bundle Identifier único configurado
- [ ] Certificados y perfiles de aprovisionamiento configurados
- [ ] App creada en App Store Connect
- [ ] Build IPA generado exitosamente
- [ ] Build subido a App Store Connect
- [ ] Build procesado en TestFlight
- [ ] Testers agregados
- [ ] Invitaciones enviadas

## 🆘 Soporte

Si tienes problemas, consulta:
- [Documentación oficial de Flutter iOS](https://docs.flutter.dev/deployment/ios)
- [Guía de TestFlight de Apple](https://developer.apple.com/testflight/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)

---

**Última actualización:** Diciembre 2025


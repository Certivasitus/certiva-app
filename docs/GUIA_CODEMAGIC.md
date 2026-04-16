# 🚀 Guía Completa: Subir Certiva App a TestFlight con Codemagic

Codemagic es una plataforma CI/CD que automatiza completamente el proceso de construcción y distribución de tu app Flutter a TestFlight. ¡No necesitas un Mac!

## ✨ Ventajas de Usar Codemagic

- ✅ **No necesitas Mac**: Todo se hace en la nube
- ✅ **Automatización completa**: Construye y sube automáticamente
- ✅ **Integración con Git**: Se ejecuta automáticamente al hacer push
- ✅ **Gestión de certificados**: Codemagic maneja los certificados por ti
- ✅ **Notificaciones**: Recibe emails cuando el build está listo

## 📋 Requisitos Previos

1. **Cuenta de Apple Developer** activa ($99 USD/año)
2. **Cuenta de Codemagic** (gratis hasta 500 minutos/mes)
3. **Repositorio Git** (GitHub, GitLab, Bitbucket)
4. **App creada en App Store Connect** con Bundle ID único

## 🔧 Paso 1: Configurar Bundle Identifier

Antes de comenzar, asegúrate de tener un Bundle ID único configurado.

1. Abre `certiva_app/ios/Runner.xcworkspace` en Xcode (o edita `project.pbxproj`)
2. Cambia `com.example.certivaApp` por tu Bundle ID único
3. **Ejemplo:** `com.tuempresa.certivaapp` o `py.com.certiva.app`

📖 **Ver guía detallada:** `CAMBIAR_BUNDLE_ID.md`

## 🔐 Paso 2: Crear App en App Store Connect

1. Ve a [App Store Connect](https://appstoreconnect.apple.com)
2. Inicia sesión con tu cuenta de Apple Developer
3. Ve a **"Mis Apps"** → **"+"** → **"Nueva App"**
4. Completa:
   - **Plataforma:** iOS
   - **Nombre:** Certiva App
   - **Idioma:** Español
   - **Bundle ID:** El mismo que configuraste en Xcode
   - **SKU:** Un ID único (ej: `certiva-app-001`)
5. Crea la app

## 🎯 Paso 3: Crear Cuenta en Codemagic

1. Ve a [codemagic.io](https://codemagic.io)
2. Haz clic en **"Sign up"** o **"Get started"**
3. Inicia sesión con tu cuenta de **GitHub**, **GitLab** o **Bitbucket**
4. Autoriza a Codemagic para acceder a tus repositorios

## 📦 Paso 4: Conectar tu Repositorio

1. En Codemagic, haz clic en **"Add application"**
2. Selecciona tu repositorio donde está el proyecto
3. Selecciona **Flutter** como tipo de aplicación
4. Codemagic detectará automáticamente tu proyecto Flutter

## 🔑 Paso 5: Configurar Credenciales de App Store Connect

Codemagic necesita acceso a tu cuenta de App Store Connect para subir builds.

### Opción A: API Key (Recomendado - Más Seguro)

1. Ve a [App Store Connect](https://appstoreconnect.apple.com)
2. Ve a **"Usuarios y acceso"** → **"Claves"**
3. Haz clic en **"+"** para crear una nueva clave
4. Completa:
   - **Nombre:** Codemagic CI/CD
   - **Acceso:** Admin o App Manager
5. Descarga el archivo `.p8` (solo se puede descargar una vez)
6. Anota el **Key ID** y el **Issuer ID**

7. En Codemagic:
   - Ve a **"Settings"** → **"Teams"** → **"App Store Connect"**
   - Haz clic en **"Add credentials"**
   - Selecciona **"App Store Connect API key"**
   - Sube el archivo `.p8`
   - Ingresa el **Key ID** y **Issuer ID**
   - Guarda

### Opción B: Usuario y Contraseña (Más Simple)

1. En Codemagic:
   - Ve a **"Settings"** → **"Teams"** → **"App Store Connect"**
   - Haz clic en **"Add credentials"**
   - Selecciona **"App Store Connect credentials"**
   - Ingresa tu email de Apple Developer
   - Ingresa tu contraseña de App Store Connect
   - **Nota:** Necesitas una contraseña específica de app (no tu contraseña normal)

2. Para crear contraseña específica de app:
   - Ve a [appleid.apple.com](https://appleid.apple.com)
   - Inicia sesión
   - Ve a **"Seguridad"** → **"Contraseñas de app"**
   - Genera una nueva contraseña para "App Store Connect"
   - Úsala en Codemagic

## 📝 Paso 6: Configurar el Archivo codemagic.yaml

El archivo `codemagic.yaml` ya está creado en tu proyecto. Necesitas personalizarlo:

### Editar Variables Importantes:

1. Abre `certiva_app/codemagic.yaml`

2. **Cambia estas líneas:**

```yaml
APP_ID: "com.example.certivaApp"  # ⚠️ Cambia por tu Bundle ID
BUNDLE_ID: "com.example.certivaApp"  # ⚠️ Debe ser igual a APP_ID
```

**Ejemplo:**
```yaml
APP_ID: "com.tuempresa.certivaapp"
BUNDLE_ID: "com.tuempresa.certivaapp"
```

3. **Opcional - Agrega tu App Store ID** (si ya tienes la app creada):
```yaml
APP_STORE_ID: "1234567890"  # Encuéntralo en App Store Connect
```

4. **Cambia el email de notificaciones:**
```yaml
email:
  recipients:
    - tu-email@ejemplo.com  # ⚠️ Cambia por tu email
```

5. **Opcional - Configura grupos de testers:**
```yaml
beta_groups:
  - Equipo Certiva
  - Testers Externos
```

## 🔐 Paso 7: Configurar Certificados y Perfiles de Aprovisionamiento

Codemagic puede generar automáticamente los certificados, pero necesitas configurarlos primero.

### Opción A: Automático (Recomendado)

1. En Codemagic, ve a tu aplicación
2. Ve a **"Code signing"** → **"iOS code signing"**
3. Selecciona **"Automatic"**
4. Codemagic generará automáticamente los certificados y perfiles

### Opción B: Manual

1. Genera certificados manualmente en [Apple Developer Portal](https://developer.apple.com/account)
2. En Codemagic, sube los certificados y perfiles de aprovisionamiento

## 🚀 Paso 8: Configurar el Workflow en Codemagic

1. En Codemagic, ve a tu aplicación
2. Ve a **"Configuration"** → **"Workflow settings"**
3. Selecciona **"Use codemagic.yaml"**
4. Codemagic usará el archivo `codemagic.yaml` de tu repositorio

## 🎬 Paso 9: Ejecutar el Primer Build

### Opción A: Manual

1. En Codemagic, ve a tu aplicación
2. Haz clic en **"Start new build"**
3. Selecciona la rama (ej: `main` o `master`)
4. Haz clic en **"Start build"**
5. Espera a que termine (15-30 minutos)

### Opción B: Automático (Push a Git)

1. Haz commit y push del archivo `codemagic.yaml` a tu repositorio:
```bash
git add certiva_app/codemagic.yaml
git commit -m "Configurar Codemagic para TestFlight"
git push
```

2. Codemagic detectará el push y ejecutará el build automáticamente (si está configurado)

## ✅ Paso 10: Verificar en TestFlight

1. Ve a [App Store Connect](https://appstoreconnect.apple.com)
2. Selecciona tu app "Certiva App"
3. Ve a la pestaña **"TestFlight"**
4. Espera 10-30 minutos para que el build se procese
5. Una vez procesado, verás tu build listo para distribuir

## 👥 Paso 11: Agregar Testers

1. En TestFlight, ve a **"Internal Testing"** o **"External Testing"**
2. Crea un grupo de testers
3. Agrega los emails de los testers
4. Selecciona el build que quieres distribuir
5. Los testers recibirán un email de invitación

## 🔄 Actualizar la Versión

Cada vez que quieras subir una nueva versión:

1. **Actualiza la versión en `pubspec.yaml`:**
```yaml
version: 1.0.1+3  # Incrementa el número
```

2. **Haz commit y push:**
```bash
git add pubspec.yaml
git commit -m "Actualizar versión a 1.0.1+3"
git push
```

3. **Codemagic ejecutará automáticamente el build** (si tienes auto-build activado)

4. O inicia manualmente un nuevo build desde Codemagic

## ⚙️ Configuración Avanzada

### Activar Auto-Build en Push

1. En Codemagic, ve a tu aplicación
2. Ve a **"Configuration"** → **"Build triggers"**
3. Activa **"Build on push"**
4. Selecciona las ramas (ej: `main`, `develop`)

### Configurar Notificaciones

En `codemagic.yaml`, puedes configurar:
```yaml
email:
  recipients:
    - email1@ejemplo.com
    - email2@ejemplo.com
  notify:
    success: true
    failure: true
```

### Builds Condicionales

Puedes configurar builds solo para ciertas ramas:
```yaml
triggering:
  events:
    - push
  branch_patterns:
    - pattern: 'main'
      include: true
      source: true
```

## ⚠️ Problemas Comunes

### Error: "Bundle identifier not found"
- **Solución:** Verifica que el Bundle ID en `codemagic.yaml` coincida exactamente con el de App Store Connect

### Error: "Invalid credentials"
- **Solución:** Verifica que las credenciales de App Store Connect estén correctas en Codemagic

### Error: "No provisioning profile found"
- **Solución:** Activa "Automatic" code signing en Codemagic o sube manualmente los perfiles

### El build no aparece en TestFlight
- **Solución:** Espera 10-30 minutos. Si después de 1 hora no aparece, revisa los logs en Codemagic

### Error: "App Store Connect API error"
- **Solución:** Verifica que la API Key tenga permisos de Admin o App Manager

## 📊 Monitoreo de Builds

1. En Codemagic, ve a tu aplicación
2. Verás el historial de todos los builds
3. Haz clic en un build para ver logs detallados
4. Los builds exitosos se suben automáticamente a TestFlight

## 💰 Costos de Codemagic

- **Plan Gratuito:** 500 minutos/mes (suficiente para ~10-15 builds)
- **Plan Starter:** $75/mes - 1,000 minutos
- **Plan Pro:** $165/mes - 2,500 minutos

**Nota:** Un build de iOS tarda aproximadamente 20-30 minutos

## 📝 Checklist Final

- [ ] Bundle Identifier único configurado
- [ ] App creada en App Store Connect
- [ ] Cuenta de Codemagic creada
- [ ] Repositorio conectado a Codemagic
- [ ] Credenciales de App Store Connect configuradas
- [ ] `codemagic.yaml` personalizado con tu Bundle ID
- [ ] Code signing configurado (automático o manual)
- [ ] Primer build ejecutado exitosamente
- [ ] Build aparece en TestFlight
- [ ] Testers agregados

## 🆘 Soporte

- [Documentación de Codemagic](https://docs.codemagic.io/)
- [Guía de Flutter en Codemagic](https://docs.codemagic.io/getting-started/flutter/)
- [Soporte de Codemagic](https://codemagic.io/contact/)

---

**¡Listo!** Con Codemagic, cada vez que hagas push a tu repositorio, se construirá y subirá automáticamente una nueva versión a TestFlight. 🎉

**Última actualización:** Diciembre 2025


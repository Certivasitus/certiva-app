# 🚀 Inicio Rápido: Codemagic + TestFlight

Guía rápida para subir tu app a TestFlight usando Codemagic en 10 pasos.

## ⚡ Pasos Rápidos

### 1️⃣ Cambiar Bundle ID
Edita `ios/Runner.xcodeproj/project.pbxproj` o usa Xcode:
- Cambia `com.example.certivaApp` → `com.tuempresa.certivaapp`

### 2️⃣ Crear App en App Store Connect
- Ve a [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
- Crea nueva app con tu Bundle ID

### 3️⃣ Crear cuenta Codemagic
- Ve a [codemagic.io](https://codemagic.io)
- Inicia sesión con GitHub/GitLab/Bitbucket

### 4️⃣ Conectar repositorio
- En Codemagic: "Add application"
- Selecciona tu repo

### 5️⃣ Configurar credenciales
- Settings → Teams → App Store Connect
- Agrega API Key o usuario/contraseña

### 6️⃣ Editar codemagic.yaml
```yaml
APP_ID: "com.tuempresa.certivaapp"  # Tu Bundle ID
BUNDLE_ID: "com.tuempresa.certivaapp"
email:
  recipients:
    - tu-email@ejemplo.com
```

### 7️⃣ Configurar code signing
- En tu app en Codemagic: Code signing → iOS
- Selecciona "Automatic"

### 8️⃣ Hacer commit y push
```bash
git add certiva_app/codemagic.yaml
git commit -m "Configurar Codemagic"
git push
```

### 9️⃣ Iniciar build
- En Codemagic: "Start new build"
- O espera auto-build si está activado

### 🔟 Verificar en TestFlight
- Ve a App Store Connect → TestFlight
- Espera 10-30 minutos
- ¡Listo! 🎉

## 📖 Guía Completa
Ver `GUIA_CODEMAGIC.md` para detalles completos.

## ⚠️ Importante
- Bundle ID debe ser único
- Credenciales de App Store Connect necesarias
- Plan gratuito: 500 min/mes (~15 builds)


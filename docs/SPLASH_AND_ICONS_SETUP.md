# Configuración de Splash Screen e Iconos - Certiva App

## 🚀 **Configuración completada**

Se han agregado las siguientes configuraciones al `pubspec.yaml`:

### **1. Splash Screen**
- **Color de fondo**: Morado de Certiva (#B47EDB)
- **Logo**: `assets/icons/logo_color.png`
- **Soporte Android 12+**: Incluido
- **Web**: Deshabilitado

### **2. Iconos de la App**
- **Android**: Icono personalizado
- **iOS**: Habilitado
- **Web**: Con tema morado
- **Windows**: Icono 48x48
- **macOS**: Icono personalizado

## 📋 **Comandos a ejecutar**

### **Paso 1: Instalar dependencias**
```bash
cd certiva_app
flutter pub get
```

### **Paso 2: Generar splash screen**
```bash
flutter pub run flutter_native_splash:create
```

### **Paso 3: Generar iconos**
```bash
flutter pub run flutter_launcher_icons:main
```

### **Paso 4: Limpiar y reconstruir**
```bash
flutter clean
flutter pub get
flutter build apk
```

## 🎯 **Resultado esperado**

### **Splash Screen:**
- ✅ Logo de Certiva centrado
- ✅ Fondo morado (#B47EDB)
- ✅ Duración: 3-5 segundos
- ✅ Transición suave a la app

### **Icono de la App:**
- ✅ Logo de Certiva en el escritorio
- ✅ Todos los tamaños generados automáticamente
- ✅ Soporte para Android 12+
- ✅ Iconos para todas las plataformas

## 🔧 **Archivos generados automáticamente**

### **Splash Screen:**
- `android/app/src/main/res/drawable/splash.xml`
- `android/app/src/main/res/values/styles.xml`
- `ios/Runner/LaunchScreen.storyboard`

### **Iconos:**
- `android/app/src/main/res/mipmap-*/launcher_icon.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- `web/icons/`

## ⚠️ **Notas importantes**

1. **Ejecutar comandos en orden**: Primero splash, luego iconos
2. **Limpiar proyecto**: Después de generar, hacer `flutter clean`
3. **Reconstruir**: Siempre reconstruir después de cambios
4. **Verificar assets**: Asegurar que `logo_color.png` existe en `assets/icons/`

## 🎨 **Personalización**

Si quieres cambiar el logo o colores, edita el `pubspec.yaml`:

```yaml
flutter_native_splash:
  color: "#TU_COLOR"  # Cambiar color de fondo
  image: assets/tu_logo.png  # Cambiar logo

flutter_launcher_icons:
  image_path: "assets/tu_logo.png"  # Cambiar icono
```

¡Listo! Tu app tendrá el logo de Certiva en el splash screen y como icono de la app. 🚀
# 🔥 Pasos para Implementar Crashlytics - Orden Correcto

## ✅ Lo que Ya Está Hecho

- ✅ Dependencias agregadas en `pubspec.yaml`
- ✅ Código modificado en `main.dart` y `user_service.dart`

---

## 📋 Pasos que Debes Completar

### **Paso 1: Agregar App iOS a Firebase**

1. **Ir a Firebase Console:**
   - Ve a: **https://console.firebase.google.com/**
   - Selecciona tu proyecto **"certiva-crashlytics"**

2. **Agregar App iOS:**
   - Haz clic en el **ícono de iOS** 🍎
   - **Bundle ID**: `py.com.certiva.app`
   - **Apodo**: `Certiva App`
   - Haz clic en **"Registrar app"**

3. **Descargar `GoogleService-Info.plist`:**
   - Haz clic en **"Descargar GoogleService-Info.plist"**
   - **Guarda el archivo** en: `certiva_app/ios/Runner/GoogleService-Info.plist`
   - ⚠️ **IMPORTANTE**: Debe estar en esta ubicación exacta

---

### **Paso 2: Instalar Dependencias**

```bash
cd certiva_app
flutter pub get
```

---

### **Paso 3: Instalar Pods de iOS**

```bash
cd certiva_app/ios
pod install
cd ..
```

---

### **Paso 4: Verificar Archivos**

Verifica que estos archivos existan:

- ✅ `certiva_app/ios/Runner/GoogleService-Info.plist` (descargado de Firebase)
- ✅ `certiva_app/pubspec.yaml` (con `firebase_core` y `firebase_crashlytics`)

---

### **Paso 5: Compilar y Probar**

```bash
cd certiva_app
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release
```

---

## 🎯 Qué Hace Crashlytics

Una vez implementado, Crashlytics:

1. **Captura automáticamente** todos los crashes
2. **Registra los logs** que agregamos (🚀 [MAIN], 📦 [UserService], etc.)
3. **Muestra stack traces completos** y simbolizados
4. **Agrupa crashes similares** para facilitar el análisis
5. **Envía alertas** cuando hay nuevos crashes

---

## 📊 Ver Crashes en Firebase

1. **Ir a Firebase Console:**
   - Ve a: **https://console.firebase.google.com/**
   - Selecciona tu proyecto **"certiva-crashlytics"**
   - En el menú lateral, haz clic en **"Crashlytics"**

2. **Ver los Crashes:**
   - Verás una lista de crashes reportados
   - Haz clic en un crash para ver:
     - **Stack trace completo**
     - **Logs personalizados** (los que agregamos)
     - **Información del dispositivo**
     - **Versión de la app**
     - **Timing exacto**

---

## ✅ Checklist

- [ ] App iOS agregada a Firebase con Bundle ID `py.com.certiva.app`
- [ ] `GoogleService-Info.plist` descargado y colocado en `ios/Runner/`
- [ ] `flutter pub get` ejecutado
- [ ] `pod install` ejecutado en `ios/`
- [ ] App compilada exitosamente
- [ ] Crashes visibles en Firebase Console → Crashlytics

---

## 🆘 Si Hay Errores

### **Error: "Target of URI doesn't exist"**
- **Solución:** Ejecuta `flutter pub get` primero

### **Error: "No such file or directory: GoogleService-Info.plist"**
- **Solución:** Descarga el archivo de Firebase y colócalo en `ios/Runner/`

### **Error: "Pod install failed"**
- **Solución:** 
  ```bash
  cd ios
  pod deintegrate
  pod install
  cd ..
  ```

---

## 📝 Próximos Pasos

1. **Completar los pasos** de esta guía
2. **Compilar y distribuir** a testers
3. **Revisar crashes en Firebase Console** → Crashlytics
4. **Analizar los logs** para identificar el problema exacto

---

**¿Puedes empezar con el Paso 1 (Agregar App iOS a Firebase)?** 🚀










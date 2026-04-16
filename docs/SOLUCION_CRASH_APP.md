# 🚨 Solución: App se Cierra (Crash) - Certiva App

## ⚠️ Problema Identificado
La app **"Certiva App"** se está cerrando inmediatamente después de abrirla. El mensaje dice:
- **"Certiva App falló"**
- **"¿Quieres compartir información adicional con el desarrollador?"**

---

## 🔧 Solución Inmediata para el Tester

### **Paso 1: Compartir Información del Crash**

1. **Hacer clic en "Compartir"** (botón azul en el pop-up)
2. Esto enviará automáticamente los logs del crash a App Store Connect
3. Esto ayudará a identificar el problema

### **Paso 2: Intentar Abrir la App Nuevamente**

1. Cerrar completamente la app (deslizar hacia arriba desde la barra inferior y deslizar la app hacia arriba)
2. Abrir la app nuevamente desde el icono
3. Si vuelve a fallar, repetir el paso 1

---

## 🔍 Revisar Logs de Crash en App Store Connect

> 📖 **Guía Detallada:** Ver `VER_LOGS_CRASH_APP_STORE_CONNECT.md` para instrucciones paso a paso con capturas de pantalla.

### **Ruta Rápida:**

1. **App Store Connect** → **Certiva App** → **TestFlight** → **Errores** (Errors)

### **Paso 1: Acceder a los Logs**

1. Ir a **https://appstoreconnect.apple.com**
2. Iniciar sesión con tu cuenta
3. Seleccionar **"Certiva App"**
4. En el menú lateral izquierdo, hacer clic en **"TestFlight"**
5. En el menú lateral izquierdo de TestFlight, hacer clic en **"Errores"** (Errors)

### **Paso 2: Ver los Crashes**

1. Verás una **tabla con los crashes** reportados
2. Buscar el crash más reciente (debería aparecer con fecha de hoy)
3. **Hacer clic en el crash** para ver detalles completos

### **Paso 3: Analizar el Crash**

Los logs mostrarán:
- **Stack trace** (rastro de la pila) - **MUY IMPORTANTE**
  - Muestra exactamente dónde falló el código
  - Incluye nombres de archivos y funciones
  - Muestra la línea de código que causó el crash
- **Dispositivo** (modelo de iPhone)
- **Versión de iOS**
- **Versión de la app**
- **Número de ocurrencias** (cuántas veces ha fallado)

---

## 🔍 Posibles Causas Comunes

### **1. Permisos Faltantes en Info.plist**
- La app intenta acceder a algo sin permiso
- **Solución:** Revisar `ios/Runner/Info.plist`

### **2. Dependencias Faltantes**
- Alguna dependencia no está correctamente instalada
- **Solución:** Revisar `Podfile` y ejecutar `pod install`

### **3. Configuración de Code Signing**
- Problemas con certificados o provisioning profiles
- **Solución:** Verificar configuración en Xcode

### **4. Problemas con Assets o Recursos**
- Archivos faltantes o corruptos
- **Solución:** Verificar que todos los assets estén incluidos

### **5. Problemas con Flutter**
- Versión de Flutter incompatible
- **Solución:** Actualizar Flutter y dependencias

---

## 📋 Pasos para Diagnosticar

### **Paso 1: Revisar Logs en App Store Connect**

1. **Ir a TestFlight → Errores**
2. **Buscar el crash más reciente**
3. **Copiar el stack trace completo**
4. **Identificar la línea de código que falla**

### **Paso 2: Revisar el Código**

1. **Abrir el proyecto en tu editor**
2. **Buscar la línea de código mencionada en el crash**
3. **Revisar qué puede estar causando el problema**

### **Paso 3: Probar Localmente**

1. **Conectar un iPhone físico**
2. **Ejecutar:** `flutter run --release`
3. **Reproducir el crash**
4. **Revisar los logs en la consola**

### **Paso 4: Revisar Configuración iOS**

1. **Verificar `Info.plist`:**
   ```xml
   <!-- Verificar que todos los permisos necesarios estén declarados -->
   <key>NSLocationWhenInUseUsageDescription</key>
   <key>NSCameraUsageDescription</key>
   <!-- etc. -->
   ```

2. **Verificar `Podfile`:**
   ```ruby
   # Asegurarse de que todas las dependencias estén correctas
   ```

3. **Verificar `pubspec.yaml`:**
   ```yaml
   # Revisar que todas las dependencias estén actualizadas
   ```

---

## 🛠️ Soluciones Rápidas a Probar

### **Solución 1: Limpiar y Reconstruir**

```bash
cd certiva_app
flutter clean
cd ios
pod deintegrate
pod install
cd ..
flutter pub get
flutter build ios --release
```

### **Solución 2: Verificar Info.plist**

Asegurarse de que `ios/Runner/Info.plist` tenga todos los permisos necesarios:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para...</string>
<key>NSCameraUsageDescription</key>
<string>Necesitamos acceso a la cámara para...</string>
<!-- Agregar todos los permisos que usa tu app -->
```

### **Solución 3: Revisar Dependencias**

```bash
flutter pub outdated
flutter pub upgrade
```

### **Solución 4: Probar en Simulador**

```bash
flutter run --release
```

Si funciona en simulador pero no en dispositivo físico, puede ser un problema de permisos o configuración del dispositivo.

---

## 📱 Información que Necesitas del Tester

1. **Modelo de iPhone** (ej: iPhone 12, iPhone 13, etc.)
2. **Versión de iOS** (ej: iOS 17.0, iOS 16.5, etc.)
3. **¿Cuándo ocurre el crash?**
   - Al abrir la app
   - Al hacer una acción específica
   - Después de X segundos
4. **¿Hizo clic en "Compartir"?** (para que lleguen los logs)

---

## 🔄 Próximos Pasos

1. **Pedir al tester que haga clic en "Compartir"** para enviar los logs
2. **Revisar los logs en App Store Connect → TestFlight → Errores**
3. **Identificar la causa del crash** usando el stack trace
4. **Corregir el problema** en el código
5. **Subir un nuevo build** a Codemagic
6. **Distribuir el nuevo build** a los testers

---

## 📞 Comunicación con el Tester

**Mensaje para el tester:**
> "Por favor, haz clic en 'Compartir' cuando aparezca el mensaje de error. Esto me ayudará a identificar y corregir el problema. También necesito saber: ¿qué modelo de iPhone tienes y qué versión de iOS?"

---

## ✅ Checklist

- [ ] Tester hizo clic en "Compartir" para enviar logs
- [ ] Revisar logs en App Store Connect → TestFlight → Errores
- [ ] Identificar la causa del crash
- [ ] Corregir el problema en el código
- [ ] Probar localmente antes de subir nuevo build
- [ ] Subir nuevo build a Codemagic
- [ ] Distribuir nuevo build a testers

---

**Una vez que tengas los logs, podremos identificar exactamente qué está causando el crash.** 🔍



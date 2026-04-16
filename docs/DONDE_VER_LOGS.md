# 📊 Dónde Ver los Logs que Agregamos

## ⚠️ Importante

Los logs de Dart/Flutter (los que empiezan con 🚀 [MAIN], 📦 [UserService], etc.) **NO aparecen directamente en el crash log** de iOS.

El crash log solo muestra el **stack trace nativo** (Swift/Objective-C), no los logs de Dart.

---

## 🔍 Dónde Buscar los Logs

### **Opción 1: App Store Connect - System Logs (Recomendado)**

1. **Ir a App Store Connect** → **TestFlight** → **Errores**
2. **Hacer clic en el crash** más reciente
3. **Buscar la sección "System Logs"** o **"Registros del sistema"**
4. **Buscar los logs que empiezan con:**
   - `🚀 [MAIN]`
   - `📦 [UserService]`
   - `⏳ [HIVE_BG]`

**Nota:** Los logs pueden estar en una sección separada, no en el crash log principal.

---

### **Opción 2: App Store Connect - Console Output**

1. **En la página del crash**, busca **"Console Output"** o **"Salida de consola"**
2. **O busca "Device Logs"** o **"Registros del dispositivo"**
3. **Los logs de Dart deberían estar ahí**

---

### **Opción 3: Codemagic Build Logs**

Si el crash ocurre durante la compilación o justo después:

1. **Ir a Codemagic** → Tu app → El build que falló
2. **Revisar los logs** del paso "Building iOS"
3. **Buscar los mensajes de logging** que agregamos

---

### **Opción 4: Xcode Console (Si pruebas localmente)**

Si tienes un iPhone conectado y pruebas localmente:

1. **Abrir Xcode**
2. **Conectar el iPhone**
3. **Ejecutar:** `flutter run --release`
4. **Ver los logs en la consola de Xcode**

---

## 📋 Qué Buscar

### **Logs de Inicialización:**

```
🚀 [MAIN] Inicio de la aplicación - 2025-12-29T11:21:44.753Z
🔧 [MAIN] Llamando WidgetsFlutterBinding.ensureInitialized()...
✅ [MAIN] WidgetsFlutterBinding.ensureInitialized() completado
📱 [MAIN] Llamando runApp()...
✅ [MAIN] runApp() completado - App iniciada
🔄 [MAIN] Iniciando inicialización de Hive en segundo plano...
```

### **Logs de Hive en Segundo Plano:**

```
⏳ [HIVE_BG] Iniciando inicialización diferida de Hive - 2025-12-29T11:21:45.754Z
⏳ [HIVE_BG] Esperando 1000ms para que los plugins nativos estén listos...
✅ [HIVE_BG] Delay completado después de 1000ms
🔄 [HIVE_BG] Intentando inicializar UserService (primer intento)...
```

### **Logs de UserService:**

```
📦 [UserService] Iniciando inicialización de Hive - 2025-12-29T11:21:45.754Z
📦 [UserService] Paso 1/5: Llamando Hive.initFlutter()...
✅ [UserService] Hive.initFlutter() completado en 150ms
```

### **Si Hay Error:**

```
❌ [UserService] Error inicializando Hive después de 50ms
❌ [UserService] Error: EXC_BAD_ACCESS...
❌ [UserService] Stack trace: ...
```

---

## ⚠️ Si No Aparecen los Logs

Si no ves los logs en App Store Connect:

1. **Verificar que el build incluya los logs:**
   - Los logs solo aparecen en builds de **release** si están configurados correctamente
   - Puede que necesitemos usar `debugPrint` en lugar de `print` para que aparezcan en release

2. **Verificar en Codemagic:**
   - Los logs deberían aparecer durante la compilación
   - Revisar el paso "Building iOS"

3. **Probar localmente:**
   - Conectar un iPhone
   - Ejecutar `flutter run --release`
   - Ver los logs en la consola

---

## 🔧 Cambiar a `debugPrint` (Si es Necesario)

Si los logs no aparecen en release, podemos cambiar `print` por `debugPrint`:

```dart
// En lugar de:
print('🚀 [MAIN] Inicio...');

// Usar:
debugPrint('🚀 [MAIN] Inicio...');
```

**Nota:** `debugPrint` siempre imprime, incluso en release mode.

---

## 📍 Pasos para Ver los Logs

1. **Ir a App Store Connect** → **TestFlight** → **Errores**
2. **Hacer clic en el crash** más reciente (build 1.0.0 (4))
3. **Buscar "System Logs"** o **"Console Output"**
4. **Buscar los emojis** (🚀, 📦, ⏳, ✅, ❌)
5. **Revisar el timing** y **dónde falla exactamente**

---

**¿Puedes revisar en App Store Connect si aparecen los logs en "System Logs" o "Console Output"?** 🔍










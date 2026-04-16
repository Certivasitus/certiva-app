# 📍 Dónde Ver los Logs del Crash en App Store Connect

## 🎯 Ubicación Exacta de los Logs

Los logs del crash aparecen en **App Store Connect → TestFlight → Errores**

---

## 📋 Pasos Detallados (Paso a Paso)

### **Paso 1: Acceder a App Store Connect**

1. **Abre tu navegador** y ve a: **https://appstoreconnect.apple.com**
2. **Inicia sesión** con tu cuenta de Apple Developer
3. Deberías ver el **dashboard principal** con tus apps

### **Paso 2: Seleccionar tu App**

1. En la página principal, busca **"Certiva App"** (o el nombre de tu app)
2. **Haz clic en "Certiva App"** para abrir los detalles de la app

### **Paso 3: Ir a TestFlight**

1. En el **menú lateral izquierdo** (sidebar), busca la sección **"TestFlight"**
2. **Haz clic en "TestFlight"**
3. Se abrirá la página de TestFlight con varias pestañas

### **Paso 4: Acceder a la Sección "Errores"**

1. En la página de TestFlight, en el **menú lateral izquierdo**, busca:
   - **"Compilaciones"** (Builds)
   - **"Grupos de prueba"** (Testing Groups)
   - **"Errores"** ← **¡Haz clic aquí!**
   - **"Feedback"**
   - **"Usuarios"** (Users)

2. **Haz clic en "Errores"** (o "Errors" si está en inglés)

### **Paso 5: Ver los Crashes Reportados**

1. Verás una **lista de crashes** reportados por los testers
2. Los crashes aparecen ordenados por:
   - **Fecha** (más recientes primero)
   - **Número de ocurrencias**
   - **Versión de la app**

3. **Busca el crash más reciente** (debería tener la fecha de hoy o ayer)

### **Paso 6: Ver Detalles del Crash**

1. **Haz clic en el crash** que quieres revisar
2. Se abrirá una página con **detalles completos** del crash

---

## 📊 Información que Verás en los Logs

### **Información Básica:**
- **Fecha y hora** del crash
- **Número de ocurrencias** (cuántas veces ha fallado)
- **Versión de la app** que falló
- **Versión de iOS** del dispositivo
- **Modelo del dispositivo** (iPhone 12, iPhone 13, etc.)

### **Información Técnica:**
- **Stack trace** (rastro de la pila) - **MUY IMPORTANTE**
  - Muestra exactamente dónde falló el código
  - Incluye nombres de funciones y archivos
  - Muestra la línea de código que causó el crash

- **Threads** (hilos)
  - Muestra todos los hilos que estaban ejecutándose
  - El hilo que falló estará marcado

- **Registros del sistema** (System logs)
  - Información adicional del sistema operativo

---

## 🔍 Cómo Interpretar los Logs

### **1. Buscar el Stack Trace**

El stack trace es la parte más importante. Se ve así:

```
Thread 0 Crashed:
0   libsystem_kernel.dylib        0x000000018a1b2c4c __pthread_kill + 8
1   libsystem_pthread.dylib       0x000000018a1c3b28 pthread_kill + 228
2   libsystem_c.dylib             0x000000018a12b8a4 abort + 104
3   Runner                         0x0000000100123456 main + 123
4   Runner                         0x0000000100123457 _MyFunction + 456
```

### **2. Identificar el Archivo y Línea**

Busca en el stack trace:
- **Nombres de archivos** (ej: `main.dart`, `client_api_service.dart`)
- **Nombres de funciones** (ej: `_MyFunction`, `initState`)
- **Direcciones de memoria** (los números largos como `0x0000000100123456`)

### **3. Buscar en tu Código**

1. **Abre tu proyecto** en tu editor
2. **Busca el archivo** mencionado en el stack trace
3. **Busca la función** mencionada
4. **Revisa esa línea de código** para ver qué puede estar causando el problema

---

## ⚠️ Si No Ves Crashes en "Errores"

### **Posibles Razones:**

1. **El tester aún no ha compartido los logs**
   - Los logs solo aparecen cuando el tester hace clic en "Compartir" en TestFlight
   - **Solución:** Solicitar al tester que comparta los logs cuando aparezca el error

2. **Los logs pueden tardar unos minutos en aparecer**
   - Puede tardar 5-15 minutos después de que el tester comparte los logs
   - **Solución:** Esperar unos minutos y recargar la página

3. **Estás buscando en la app incorrecta**
   - Verifica que estés en la app correcta
   - **Solución:** Asegúrate de estar en "Certiva App"

4. **No hay crashes reportados aún**
   - Si es la primera vez, puede que no haya crashes
   - **Solución:** Espera a que el tester comparta el crash

---

## 📱 Alternativa: Ver Logs desde el iPhone del Tester

Si no aparecen los logs en App Store Connect, también puedes:

### **Opción 1: Pedir al Tester que Comparta la Captura de Pantalla**

1. **Pedir al tester** que tome una captura de pantalla del error
2. **Pedir información:**
   - Modelo de iPhone
   - Versión de iOS
   - ¿Qué estaba haciendo cuando falló?

### **Opción 2: Usar Xcode para Ver Logs**

Si tienes acceso al iPhone del tester:

1. **Conectar el iPhone** a tu Mac
2. **Abrir Xcode**
3. **Ir a:** Window → Devices and Simulators
4. **Seleccionar el iPhone**
5. **Ver los logs** del dispositivo

---

## 🎯 Ruta Completa (Resumen)

```
App Store Connect
  └── Certiva App (tu app)
      └── TestFlight
          └── Errores (Errors) ← AQUÍ ESTÁN LOS LOGS
              └── [Lista de crashes]
                  └── [Hacer clic en un crash]
                      └── [Ver detalles completos]
```

---

## 📸 Qué Buscar en la Interfaz

Cuando estés en App Store Connect:

1. **Menú lateral izquierdo** debería mostrar:
   ```
   App Store Connect
   ├── Apps
   │   └── Certiva App
   │       ├── App Store
   │       ├── TestFlight ← AQUÍ
   │       │   ├── Compilaciones
   │       │   ├── Grupos de prueba
   │       │   ├── Errores ← HAZ CLIC AQUÍ
   │       │   ├── Feedback
   │       │   └── Usuarios
   │       └── Analytics
   ```

2. **En la página "Errores"**, verás:
   - Una tabla con los crashes
   - Columnas: Fecha, Versión, Dispositivo, Ocurrencias
   - Haz clic en cualquier fila para ver detalles

---

## ✅ Checklist

- [ ] Accedí a App Store Connect
- [ ] Seleccioné "Certiva App"
- [ ] Fui a "TestFlight"
- [ ] Hice clic en "Errores"
- [ ] Vi la lista de crashes
- [ ] Hice clic en el crash más reciente
- [ ] Revisé el stack trace
- [ ] Identifiqué el archivo y función que falló

---

## 🆘 Si No Puedes Encontrar "Errores"

1. **Verifica que tengas permisos de Admin** o **App Manager**
2. **Verifica que la app tenga builds en TestFlight**
3. **Verifica que haya testers que hayan reportado crashes**
4. **Intenta recargar la página** (F5 o Cmd+R)

---










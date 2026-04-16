# 📤 Cómo Agregar el Build al Grupo "Equipo Certiva"

## 🎯 Objetivo

Agregar el build **1.0.0 (3)** al grupo **"Equipo Certiva"** para que los testers reciban las invitaciones.

---

## 📋 Pasos Detallados

### **Paso 1: Ir a la Sección de Compilaciones**

1. En App Store Connect, estás en **TestFlight**
2. En el menú lateral izquierdo, asegúrate de estar en **"Compilaciones"** → **"iOS"**
3. Verás la tabla con los builds de "Versión 1.0.0"

### **Paso 2: Seleccionar el Build**

1. En la tabla "Versión 1.0.0", busca la fila del build **"CERTIVA 3"** (build 1.0.0 (3))
2. **Haz clic en "CERTIVA 3"** o en el número de compilación
3. Se abrirá la página de detalles del build

### **Paso 3: Agregar al Grupo**

1. En la página de detalles del build, busca la sección **"Grupos de prueba"** o **"Testing Groups"**
2. Verás una lista de grupos disponibles:
   - **"PRUEBAS INTERNAS"** (Internal Testing)
     - **"Equipo Certiva"** ← Este es el grupo que quieres
   - **"PRUEBAS EXTERNAS"** (External Testing)
3. **Haz clic en el checkbox** junto a **"Equipo Certiva"**
4. O si hay un botón **"Agregar al grupo"** o **"Add to group"**, haz clic en él y selecciona "Equipo Certiva"

### **Paso 4: Guardar**

1. Después de marcar el checkbox, puede que se guarde automáticamente
2. O busca un botón **"Guardar"** o **"Save"** y haz clic
3. Verás una confirmación de que el build fue agregado al grupo

### **Paso 5: Verificar**

1. Vuelve a la lista de builds (haz clic en "Compilaciones" → "iOS")
2. En la tabla "Versión 1.0.0", busca el build **"CERTIVA 3"**
3. En la columna **"GRUPOS"**, deberías ver **"EC"** (abreviatura de "Equipo Certiva")
4. Esto confirma que el build está agregado al grupo

---

## 🔄 Alternativa: Desde la Página del Grupo

Si no encuentras la opción en la página del build, puedes hacerlo desde el grupo:

### **Paso 1: Ir al Grupo**

1. En el menú lateral izquierdo, ve a **"Testers"** → **"PRUEBAS INTERNAS"**
2. Haz clic en **"Equipo Certiva"**

### **Paso 2: Agregar Build**

1. En la página del grupo, busca la sección **"Builds"** o **"Compilaciones"**
2. Haz clic en **"Agregar compilación"** o **"Add build"**
3. Selecciona el build **"1.0.0 (3)"**
4. Haz clic en **"Agregar"** o **"Add"**

---

## 📧 Invitaciones Automáticas

Después de agregar el build al grupo:

1. **Las invitaciones se enviarán automáticamente** a todos los testers del grupo "Equipo Certiva"
2. Los testers recibirán un **email de TestFlight** con:
   - Instrucciones para instalar la app
   - Código de invitación (si es necesario)
   - Enlace para descargar TestFlight

---

## ✅ Verificación Final

Después de agregar el build, verifica:

1. **En la tabla de builds:**
   - Build "CERTIVA 3" muestra **"EC"** en la columna "GRUPOS"
   - Estado: "Lista para enviar" o "Ready to submit"

2. **En la página del grupo "Equipo Certiva":**
   - El build "1.0.0 (3)" aparece en la lista de builds disponibles
   - Los testers pueden verlo y descargarlo

3. **En la columna "INVITACIONES":**
   - Debería mostrar el número de testers en el grupo
   - Ejemplo: Si hay 2 testers, mostrará "2"

---

## 🎯 Pasos Rápidos (Resumen)

1. **TestFlight** → **"Compilaciones"** → **"iOS"**
2. **Haz clic en "CERTIVA 3"** (build 1.0.0 (3))
3. **Busca "Grupos de prueba"** o **"Testing Groups"**
4. **Marca el checkbox** de **"Equipo Certiva"**
5. **Guarda**
6. **Verifica** que aparezca "EC" en la columna "GRUPOS"

---

## ⚠️ Si No Aparece la Opción

Si no ves la opción de agregar al grupo:

1. **Verifica que el estado del build sea "Lista para enviar"**
   - Si aún dice "Falta información de exportación", completa primero esa información

2. **Verifica que tengas permisos de Admin o App Manager**
   - Solo usuarios con estos permisos pueden agregar builds a grupos

3. **Intenta desde la página del grupo:**
   - Ve a "Testers" → "PRUEBAS INTERNAS" → "Equipo Certiva"
   - Busca "Agregar compilación" o "Add build"

---










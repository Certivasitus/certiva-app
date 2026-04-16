# 📤 Cómo Distribuir el Build a los Testers en TestFlight

## ✅ Estado Actual

Veo que tienes:
- ✅ Build **1.0.0 (3)** con estado "Finalizado" (29 dic 2025)
- ✅ Grupo "PRUEBAS INTERNAS" con "Equipo Certiva"
- ✅ Grupo "PRUEBAS EXTERNAS"

---

## 🎯 Pasos para Distribuir el Build

### **Paso 1: Ir a la Sección de Compilaciones**

1. En App Store Connect, estás en **TestFlight**
2. En el menú lateral izquierdo, haz clic en **"Compilaciones"** → **"iOS"**
3. Verás la lista de builds disponibles

### **Paso 2: Seleccionar el Build**

1. **Busca el build "1.0.0 (3)"** en la lista
2. **Haz clic en "1.0.0 (3)"** para abrir los detalles

### **Paso 3: Agregar el Build al Grupo**

1. En la página de detalles del build, busca la sección **"Grupos de prueba"** o **"Testing Groups"**
2. Verás una lista de grupos disponibles:
   - **"PRUEBAS INTERNAS"** (Internal Testing)
   - **"PRUEBAS EXTERNAS"** (External Testing)
3. **Haz clic en el checkbox** del grupo donde quieres distribuir (ej: "PRUEBAS INTERNAS")
4. **Guarda** o haz clic en **"Agregar"**

### **Paso 4: Activar la Distribución**

1. Si es la primera vez que agregas el build a un grupo, puede que necesites:
   - **Hacer clic en "Iniciar prueba"** o **"Start Testing"**
   - O simplemente **activar el toggle** del grupo

2. **Verifica que el build esté "Activo"** o **"Enabled"** para ese grupo

---

## 👥 Verificar Testers en el Grupo

### **Paso 1: Ir a Testers**

1. En el menú lateral izquierdo, ve a **"Testers"**
2. Haz clic en **"PRUEBAS INTERNAS"** (o el grupo que quieras verificar)

### **Paso 2: Ver Lista de Testers**

1. Verás la lista de testers en ese grupo
2. Verifica que todos los testers que quieres estén ahí
3. Si falta alguno, haz clic en **"+"** para agregar

### **Paso 3: Agregar Nuevos Testers (Si es Necesario)**

1. Haz clic en **"+"** o **"Agregar testers"**
2. Ingresa los **emails** de los testers
3. Haz clic en **"Agregar"** o **"Invite"**

---

## 📧 Enviar Invitaciones

### **Opción 1: Automático (Recomendado)**

Si el build está agregado al grupo y los testers están en el grupo:
- **Las invitaciones se envían automáticamente** cuando:
  - Agregas el build al grupo por primera vez
  - Agregas un nuevo tester a un grupo que ya tiene un build activo

### **Opción 2: Manual**

1. En la página del grupo (ej: "PRUEBAS INTERNAS")
2. Busca el botón **"Enviar invitaciones"** o **"Send invitations"**
3. Haz clic en él
4. Se enviarán emails a todos los testers del grupo

---

## 🔍 Verificar que el Build Esté Disponible

### **Paso 1: Ver Detalles del Grupo**

1. Ve a **"Testers"** → **"PRUEBAS INTERNAS"** (o el grupo que uses)
2. Verifica que el build **"1.0.0 (3)"** aparezca en la lista de builds disponibles

### **Paso 2: Verificar Estado**

El build debe mostrar:
- ✅ **Estado:** "Listo para probar" o "Ready to Test"
- ✅ **Versión:** 1.0.0 (3)
- ✅ **Fecha:** 29 dic 2025

---

## 📱 Lo que Verán los Testers

Una vez distribuido, los testers recibirán:

1. **Email de invitación** de TestFlight
2. **Instrucciones** para instalar la app
3. **Código de redención** (si es necesario)

---

## ⚠️ Importante

### **Para Pruebas Internas:**
- ✅ **No requiere revisión** de Apple
- ✅ **Disponible inmediatamente** después de agregar al grupo
- ✅ **Máximo 100 testers** internos

### **Para Pruebas Externas:**
- ⚠️ **Requiere revisión** de Apple (puede tardar 24-48 horas)
- ⚠️ **Máximo 10,000 testers** externos
- ⚠️ **Debe cumplir** las políticas de App Store

---

## ✅ Checklist

- [ ] Build 1.0.0 (3) está "Finalizado"
- [ ] Build agregado al grupo "PRUEBAS INTERNAS" (o externas)
- [ ] Testers agregados al grupo
- [ ] Build activo/enabled para el grupo
- [ ] Invitaciones enviadas (automático o manual)
- [ ] Testers recibieron el email

---

## 🎯 Pasos Rápidos (Resumen)

1. **TestFlight** → **"Compilaciones"** → **"iOS"**
2. **Haz clic en "1.0.0 (3)"**
3. **Agrega al grupo** "PRUEBAS INTERNAS" (checkbox)
4. **Guarda**
5. **Verifica testers** en "Testers" → "PRUEBAS INTERNAS"
6. **Las invitaciones se enviarán automáticamente**

---










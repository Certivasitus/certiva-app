# 🚀 Cómo Iniciar un Build Manual en Codemagic

## ⚠️ Problema: No se Inicia Automáticamente

Si subiste código a GitHub pero no ves una nueva compilación, puede ser porque:
1. **Auto-build no está activado** (Codemagic no construye automáticamente en cada push)
2. **Necesitas iniciar el build manualmente**

---

## ✅ Solución: Iniciar Build Manualmente

### **Paso 1: Ir a Codemagic**

1. **Abre tu navegador** y ve a: **https://codemagic.io**
2. **Inicia sesión** con tu cuenta
3. **Haz clic en tu aplicación** (ej: "certiva-app")

### **Paso 2: Iniciar Build Manual**

1. **Busca el botón "Start new build"** (botón verde, generalmente en la parte superior derecha)
2. **Haz clic en "Start new build"**
3. **Selecciona:**
   - **Branch:** `main` (o la rama donde subiste el código)
   - **Workflow:** `ios-workflow` (debería detectarse automáticamente desde `codemagic.yaml`)
4. **Haz clic en "Start build"**
5. **Espera** (15-30 minutos)

---

## 🔍 Verificar Builds Existentes

### **Paso 1: Ver Lista de Builds**

1. En Codemagic, en la página de tu app
2. Verás una lista de builds anteriores
3. Busca si hay algún build:
   - **En progreso** (icono de reloj o spinner)
   - **Pendiente** (en cola)
   - **Fallido** (icono rojo)

### **Paso 2: Ver Detalles de un Build**

1. **Haz clic en cualquier build** de la lista
2. Verás los detalles:
   - **Estado:** Success, Failed, In Progress, etc.
   - **Fecha y hora**
   - **Logs** (haz clic en los pasos para ver los logs)

---

## ⚙️ Activar Auto-Build (Opcional)

Si quieres que Codemagic construya automáticamente en cada push:

### **Paso 1: Ir a Configuración**

1. En Codemagic, ve a tu aplicación
2. Ve a **"Configuration"** o **"Settings"**
3. Busca **"Build triggers"** o **"Automatic builds"**

### **Paso 2: Activar Auto-Build**

1. **Activa "Build on push"** o **"Automatic builds"**
2. **Selecciona las ramas** donde quieres que se construya automáticamente:
   - `main`
   - `master`
   - O cualquier otra rama
3. **Guarda** los cambios

### **Paso 3: Verificar**

1. **Haz un nuevo push** a GitHub
2. **Codemagic debería iniciar automáticamente** un nuevo build
3. **Verás una notificación** o el build aparecerá en la lista

---

## 🔧 Verificar Configuración del Workflow

### **Paso 1: Verificar que Codemagic Use el YAML**

1. En Codemagic, ve a tu aplicación
2. Ve a **"Workflow Editor"** o **"Configuration"**
3. **Verifica que diga:**
   - "Using codemagic.yaml from repository" ✅
   - O "YAML configuration" ✅

### **Paso 2: Si No Usa el YAML**

1. **Haz clic en "Switch to YAML configuration"**
2. O **"Use codemagic.yaml"**
3. **Selecciona el archivo** `codemagic.yaml` de tu repositorio

---

## 📋 Checklist

- [ ] Código subido a GitHub
- [ ] `codemagic.yaml` está en el repositorio
- [ ] Credenciales de App Store Connect configuradas
- [ ] Code signing configurado (Automático o Manual)
- [ ] Build iniciado manualmente o auto-build activado
- [ ] Build completado exitosamente
- [ ] Build aparece en TestFlight

---

## 🆘 Si el Build No Aparece

### **Verificar:**

1. **¿Estás en la app correcta?**
   - Verifica que estés viendo la app correcta en Codemagic

2. **¿El código está en la rama correcta?**
   - Verifica que el código esté en `main` o la rama que seleccionaste

3. **¿El `codemagic.yaml` está en el repositorio?**
   - Verifica que el archivo `codemagic.yaml` esté en la raíz de `certiva_app/`

4. **¿Hay errores en el build?**
   - Revisa los logs del build para ver si hay errores

---

## 🎯 Pasos Rápidos (Resumen)

1. **Ir a Codemagic** → Tu app
2. **Clic en "Start new build"** (botón verde)
3. **Seleccionar branch:** `main`
4. **Seleccionar workflow:** `ios-workflow`
5. **Clic en "Start build"**
6. **Esperar 15-30 minutos**
7. **Verificar en TestFlight** (App Store Connect)

---

## 📞 Próximos Pasos

Una vez que el build esté completo:

1. **Revisar logs** en Codemagic para verificar que se subió correctamente
2. **Ir a App Store Connect** → TestFlight
3. **Esperar 10-30 minutos** para que el build se procese
4. **Distribuir a testers**

---

**¿Puedes intentar iniciar un build manualmente ahora?** 🚀










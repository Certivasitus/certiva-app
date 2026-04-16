# 📝 Crear Bundle ID en Apple Developer Portal

## 🎯 Objetivo
Crear el Bundle ID `py.com.certiva.app` en Apple Developer Portal para poder usarlo en App Store Connect.

## 📋 Pasos Detallados

### Opción 1: Desde el Enlace en App Store Connect

1. **Haz clic en el enlace azul:**
   - "Registra un nuevo ID de pack en Certificados, identificadores y perfiles."
   - Este enlace te llevará directamente a Apple Developer Portal

2. **Inicia sesión** si es necesario (con tu cuenta de Apple Developer)

3. **Sigue los pasos de la Opción 2** (abajo)

### Opción 2: Ir Directamente a Apple Developer Portal

1. **Abre una nueva pestaña** en tu navegador

2. **Ve a:** [developer.apple.com/account](https://developer.apple.com/account)

3. **Inicia sesión** con tu cuenta de Apple Developer

4. **En el menú lateral izquierdo**, busca y haz clic en:
   - **"Certificates, Identifiers & Profiles"**
   - O en español: **"Certificados, identificadores y perfiles"**

5. **Haz clic en "Identifiers"** (Identificadores)
   - Verás una lista de identificadores existentes

6. **Haz clic en el botón "+"** (arriba a la izquierda, junto a "Identifiers")
   - Este es el botón para crear un nuevo identificador

7. **Selecciona el tipo:**
   - Selecciona **"App IDs"**
   - Haz clic en **"Continue"** (Continuar)

8. **Selecciona el tipo de App ID:**
   - Selecciona **"App"** (no "App Clip" ni otros)
   - Haz clic en **"Continue"**

9. **Completa el formulario:**

   **Description (Descripción):**
   - Ingresa: `Certiva App`
   - (Solo para identificación interna)

   **Bundle ID:**
   - Selecciona: **"Explicit"** (Explícito)
   - En el campo de texto, ingresa exactamente: `py.com.certiva.app`
   - ⚠️ **IMPORTANTE:** Debe ser exactamente así, sin espacios ni mayúsculas

10. **Capabilities (Capacidades):**
    - Marca las que necesites:
      - **Push Notifications** (si usas notificaciones)
      - **Sign in with Apple** (si usas autenticación con Apple)
      - **Associated Domains** (si usas deep links)
      - **App Groups** (si compartes datos entre apps)
    - Si no estás seguro, puedes dejarlas sin marcar y agregarlas después

11. **Haz clic en "Continue"** (Continuar)

12. **Revisa la información:**
    - Verifica que el Bundle ID sea: `py.com.certiva.app`
    - Haz clic en **"Register"** (Registrar)

13. Verás un mensaje de confirmación
    - El Bundle ID `py.com.certiva.app` está creado

## 🔄 Volver a App Store Connect

1. **Vuelve a la pestaña de App Store Connect** (donde tenías el formulario abierto)

2. **En el campo "ID de pack":**
   - Haz clic en el dropdown "Elegir"
   - **Recarga la página** si es necesario (F5 o Ctrl+R)
   - Ahora deberías ver `py.com.certiva.app` en la lista

3. **Selecciona** `py.com.certiva.app`

4. **Completa el resto del formulario:**
   - SKU: `certiva-app-001`
   - Haz clic en **"Crear"**

## ⚠️ Problemas Comunes

### "El Bundle ID ya existe"
- Significa que ya está registrado (puede ser tuyo o de otra cuenta)
- Si es tuyo, simplemente selecciónalo en App Store Connect
- Si no es tuyo, elige otro Bundle ID (ej: `py.com.certiva.mobile`)

### "Formato inválido"
- Asegúrate de que sea: `py.com.certiva.app`
- No uses mayúsculas, espacios o caracteres especiales
- Debe seguir el formato: `dominio.inverso.nombreapp`

### "No aparece en App Store Connect"
- Espera 1-2 minutos y recarga la página
- Asegúrate de estar usando la misma cuenta de Apple Developer
- Verifica que el Bundle ID esté registrado correctamente

## ✅ Verificación

Para verificar que el Bundle ID está creado:

1. Ve a Apple Developer Portal → Identifiers
2. Busca en la lista: `py.com.certiva.app`
3. Deberías verlo con el nombre "Certiva App"

---













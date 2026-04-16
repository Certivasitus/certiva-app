# 📤 Cómo Subir el IPA Manualmente a App Store Connect

## 📋 Requisitos

### Opción 1: Mac (Recomendado - Más Fácil)
- ✅ **Mac** (cualquier versión reciente)
- ✅ **Transporter** (app gratuita del Mac App Store)
- ✅ O **Xcode** (si ya lo tienes instalado)

### Opción 2: Windows (Más Complejo)
- ⚠️ **No es posible directamente desde Windows**
- Necesitas usar una Mac o un servicio en la nube

## 🚀 Método 1: Usando Transporter (Más Fácil)

### Paso 1: Descargar Transporter
1. **Abre el Mac App Store**
2. **Busca:** "Transporter"
3. **Descarga** (es gratis)
4. **Instala**

### Paso 2: Descargar el IPA desde Codemagic
1. **Ve a Codemagic:** [codemagic.io](https://codemagic.io)
2. **Ve a Builds** → Tu build
3. **Descarga** `certiva_app.ipa` (32.48 MB)

### Paso 3: Subir con Transporter
1. **Abre Transporter**
2. **Arrastra el archivo `.ipa`** a la ventana de Transporter
3. **Haz clic en "Deliver"**
4. **Inicia sesión** con tu Apple ID de desarrollador
5. **Espera** a que termine la carga (5-10 minutos)

### Paso 4: Verificar en App Store Connect
1. **Ve a:** [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. **Tu app** → **TestFlight**
3. **Espera 10-30 minutos** para que se procese
4. El build aparecerá

## 🛠️ Método 2: Usando Xcode (Si tienes Xcode)

### Paso 1: Descargar el IPA
1. **Descarga** `certiva_app.ipa` desde Codemagic

### Paso 2: Abrir Xcode Organizer
1. **Abre Xcode**
2. **Ve a:** Window → Organizer
3. O presiona: `Cmd + Shift + 9`

### Paso 3: Subir el IPA
1. **Arrastra el archivo `.ipa`** al Organizer
2. **Haz clic en "Distribute App"**
3. **Selecciona:** "App Store Connect"
4. **Sigue el asistente:**
   - Selecciona "Upload"
   - Revisa la información
   - Haz clic en "Upload"
5. **Espera** a que termine (5-10 minutos)

## 💻 Método 3: Command Line (Mac - Avanzado)

### Requisitos:
- Mac con Xcode Command Line Tools
- Contraseña específica de app

### Comandos:
```bash
# Instalar altool (si no está instalado)
xcode-select --install

# Subir el IPA
xcrun altool --upload-app \
  --type ios \
  --file "certiva_app.ipa" \
  --username "jaime@komercos.com" \
  --password "tu-app-specific-password"
```

**Nota:** Necesitas crear una contraseña específica de app en [appleid.apple.com](https://appleid.apple.com)

## ⚠️ Si No Tienes Mac

### Opción A: Pedirle a alguien con Mac
1. **Envía el archivo `.ipa`** a alguien con Mac
2. **Que use Transporter** para subirlo
3. **Es el método más simple**

### Opción B: Usar un servicio en la nube
- Algunos servicios ofrecen Macs virtuales
- Pero es más complicado y costoso

## 📝 Resumen de Pasos (Transporter - Más Fácil)

1. ✅ **Descargar Transporter** (Mac App Store - gratis)
2. ✅ **Descargar IPA** desde Codemagic
3. ✅ **Arrastrar IPA a Transporter**
4. ✅ **Hacer clic en "Deliver"**
5. ✅ **Iniciar sesión con Apple ID**
6. ✅ **Esperar carga** (5-10 min)
7. ✅ **Verificar en TestFlight** (10-30 min más)

## 🎯 Tiempo Total

- **Descarga IPA:** 1-2 minutos
- **Subida con Transporter:** 5-10 minutos
- **Procesamiento en App Store Connect:** 10-30 minutos
- **Total:** ~20-40 minutos

## ✅ Verificación

Después de subir, en TestFlight verás:
- El build aparecerá como "Processing" (procesando)
- Después de 10-30 minutos cambiará a "Ready to submit"
- Podrás agregar testers y distribuir

---












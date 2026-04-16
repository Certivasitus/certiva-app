# 👥 Cómo Agregar Testers en TestFlight

## 🎯 Pasos para Agregar Testers

### Paso 1: Ir a TestFlight en App Store Connect

1. **Ve a:** [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. **Inicia sesión** con tu cuenta
3. **Selecciona tu app:** "Certiva App"
4. **Haz clic en la pestaña:** **"TestFlight"** (arriba)

### Paso 2: Elegir Tipo de Testing

Tienes dos opciones:

#### Opción A: Internal Testing (Recomendado para empezar)
- **Hasta 100 usuarios internos**
- **Sin revisión de Apple**
- **Activación inmediata**
- Solo personas de tu organización

#### Opción B: External Testing
- **Hasta 10,000 usuarios**
- **Requiere revisión de Apple** (1-2 días)
- Cualquier persona puede ser tester

### Paso 3: Crear un Grupo de Testers (si no existe)

1. **En TestFlight**, busca la sección **"Internal Testing"** o **"External Testing"**
2. **Haz clic en:** **"+"** o **"Create group"**
3. **Nombre del grupo:** Ejemplo: "Equipo Certiva" o "Beta Testers"
4. **Crea el grupo**

### Paso 4: Agregar Testers al Grupo

1. **Haz clic en el grupo** que creaste (ej: "Equipo Certiva")
2. **Haz clic en:** **"Add testers"** o **"+"**
3. **Agrega los emails:**
   - Puedes agregar uno por uno
   - O importar desde un archivo CSV
   - Ingresa los emails de Apple ID de los testers

### Paso 5: Seleccionar el Build

1. **Después de agregar testers**, vuelve a la página del grupo
2. **Busca la sección:** **"Builds"** o **"Available builds"**
3. **Selecciona el build** que quieres distribuir
4. **Haz clic en:** **"Add to group"** o **"Distribute"**

### Paso 6: Enviar Invitaciones

1. **Los testers recibirán un email** automáticamente
2. **El email contiene:**
   - Un enlace para instalar TestFlight
   - Un código de invitación
   - Instrucciones para instalar la app

## 📋 Requisitos para los Testers

### Para Internal Testing:
- Deben tener un **Apple ID**
- Deben estar en tu **organización** (Apple Developer)
- O ser agregados como **miembros del equipo**

### Para External Testing:
- Solo necesitan un **Apple ID**
- No necesitan estar en tu organización
- Cualquier persona puede ser tester

## 📱 Qué Necesitan los Testers

1. **Instalar TestFlight:**
   - Descargar la app **TestFlight** desde el App Store
   - Es gratuita

2. **Aceptar la invitación:**
   - Abrir el email de invitación
   - O usar el código de invitación
   - Aceptar en TestFlight

3. **Instalar la app:**
   - Abrir TestFlight
   - Verán tu app "Certiva App"
   - Tocar "Install"

## ⚡ Proceso Rápido (Internal Testing)

1. **App Store Connect** → Tu app → **TestFlight**
2. **Internal Testing** → **"+"** → Crear grupo
3. **Agregar testers** → Ingresar emails
4. **Seleccionar build** → Agregar al grupo
5. Los testers reciben email automáticamente

## 🔄 Actualizar Testers

Cada vez que subas un nuevo build:

1. **Ve a TestFlight**
2. **Selecciona el grupo de testers**
3. **Agrega el nuevo build** al grupo
4. Los testers recibirán notificación del nuevo build

## 📧 Email de Invitación

El email que reciben los testers incluye:
- Nombre de la app: "Certiva App"
- Código de invitación
- Enlace para instalar TestFlight
- Instrucciones paso a paso

## ⚠️ Notas Importantes

- **Internal Testing:** Máximo 100 testers
- **External Testing:** Máximo 10,000 testers (requiere revisión)
- Los testers necesitan **iOS 12.0 o superior**
- Los testers necesitan tener **TestFlight instalado**

## 🎯 Ejemplo Práctico

**Agregar 5 testers internos:**

1. TestFlight → Internal Testing
2. Crear grupo: "Equipo Certiva"
3. Agregar emails:
   - tester1@ejemplo.com
   - tester2@ejemplo.com
   - tester3@ejemplo.com
   - tester4@ejemplo.com
   - tester5@ejemplo.com
4. Seleccionar build 1.0.0+2
5. Agregar al grupo
6. Todos reciben email

---












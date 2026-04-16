# 📤 Comandos para Subir Código a GitHub

## 🎯 Repositorio: `jaimeAnazco7/certiva-app`

## 📋 Pasos Rápidos

### 1. Abre PowerShell o CMD
Presiona `Win + R`, escribe `powershell` y presiona Enter

### 2. Navega a tu proyecto
```powershell
cd D:\xampp\htdocs\proyecto_certiva_void\certiva_app
```

### 3. Inicializa Git (si no está inicializado)
```bash
git init
```

### 4. Agrega todos los archivos
```bash
git add .
```

### 5. Haz el primer commit
```bash
git commit -m "Initial commit: Certiva App con Codemagic configurado"
```

### 6. Conecta con GitHub
```bash
git remote add origin https://github.com/jaimeAnazco7/certiva-app.git
```

### 7. Sube el código
```bash
git branch -M main
git push -u origin main
```

## ⚠️ Si te pide autenticación

Si GitHub te pide usuario y contraseña:

1. **Usuario:** `jaimeAnazco7`
2. **Contraseña:** Necesitas un **Personal Access Token** (no tu contraseña normal)

### Crear Personal Access Token:

1. Ve a: https://github.com/settings/tokens
2. Haz clic en **"Generate new token"** → **"Generate new token (classic)"**
3. Nombre: `Codemagic Upload`
4. Selecciona permisos: **`repo`** (marca la casilla)
5. Haz clic en **"Generate token"**
6. **Copia el token** (solo se muestra una vez)
7. Úsalo como contraseña cuando Git te lo pida

## ✅ Verificación

Después de subir, ve a:
https://github.com/jaimeAnazco7/certiva-app

Deberías ver:
- ✅ `codemagic.yaml` en los archivos
- ✅ `pubspec.yaml`
- ✅ Carpetas: `lib/`, `ios/`, `android/`, etc.

## 🚀 Después de Subir

1. Ve a [codemagic.io](https://codemagic.io)
2. Conecta el repositorio `jaimeAnazco7/certiva-app`
3. Codemagic detectará automáticamente el `codemagic.yaml`
4. Configura las credenciales de App Store Connect
5. ¡Ejecuta tu primer build!

---

**¿Listo para ejecutar los comandos?** 🎯













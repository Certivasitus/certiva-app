@echo off
REM Script para construir la app iOS para TestFlight
REM Uso: build_ios_release.bat

echo ========================================
echo Construyendo Certiva App para iOS
echo ========================================
echo.

REM Verificar que estamos en el directorio correcto
if not exist "pubspec.yaml" (
    echo Error: Este script debe ejecutarse desde la carpeta certiva_app
    echo Cambiando al directorio certiva_app...
    cd certiva_app
    if not exist "pubspec.yaml" (
        echo Error: No se encontro pubspec.yaml
        pause
        exit /b 1
    )
)

echo [1/4] Limpiando proyecto anterior...
call flutter clean
if errorlevel 1 (
    echo Error al limpiar el proyecto
    pause
    exit /b 1
)

echo.
echo [2/4] Obteniendo dependencias...
call flutter pub get
if errorlevel 1 (
    echo Error al obtener dependencias
    pause
    exit /b 1
)

echo.
echo [3/4] Verificando configuración de iOS...
if not exist "ios\Runner.xcworkspace" (
    echo Error: No se encontro el workspace de iOS
    echo Asegurate de que la carpeta ios existe y esta configurada correctamente
    pause
    exit /b 1
)

echo.
echo [4/4] Construyendo IPA para distribucion...
echo Esto puede tardar varios minutos...
call flutter build ipa --release
if errorlevel 1 (
    echo.
    echo Error al construir el IPA
    echo.
    echo Posibles soluciones:
    echo 1. Verifica que tienes Xcode instalado
    echo 2. Verifica que los certificados estan configurados en Xcode
    echo 3. Abre ios\Runner.xcworkspace en Xcode y verifica la configuracion de signing
    pause
    exit /b 1
)

echo.
echo ========================================
echo Construccion completada exitosamente!
echo ========================================
echo.
echo El archivo IPA se encuentra en:
echo build\ios\ipa\certiva_app.ipa
echo.
echo Siguiente paso:
echo 1. Abre Xcode
echo 2. Ve a Window -^> Organizer
echo 3. Selecciona tu archivo y haz clic en "Distribute App"
echo 4. O consulta GUIA_TESTFLIGHT.md para mas opciones
echo.
pause













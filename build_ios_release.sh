#!/bin/bash
# Script para construir la app iOS para TestFlight
# Uso: ./build_ios_release.sh

echo "========================================"
echo "Construyendo Certiva App para iOS"
echo "========================================"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    echo "Error: Este script debe ejecutarse desde la carpeta certiva_app"
    echo "Cambiando al directorio certiva_app..."
    cd certiva_app
    if [ ! -f "pubspec.yaml" ]; then
        echo "Error: No se encontró pubspec.yaml"
        exit 1
    fi
fi

echo "[1/4] Limpiando proyecto anterior..."
flutter clean
if [ $? -ne 0 ]; then
    echo "Error al limpiar el proyecto"
    exit 1
fi

echo ""
echo "[2/4] Obteniendo dependencias..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "Error al obtener dependencias"
    exit 1
fi

echo ""
echo "[3/4] Verificando configuración de iOS..."
if [ ! -d "ios/Runner.xcworkspace" ]; then
    echo "Error: No se encontró el workspace de iOS"
    echo "Asegúrate de que la carpeta ios existe y está configurada correctamente"
    exit 1
fi

echo ""
echo "[4/4] Construyendo IPA para distribución..."
echo "Esto puede tardar varios minutos..."
flutter build ipa --release
if [ $? -ne 0 ]; then
    echo ""
    echo "Error al construir el IPA"
    echo ""
    echo "Posibles soluciones:"
    echo "1. Verifica que tienes Xcode instalado"
    echo "2. Verifica que los certificados están configurados en Xcode"
    echo "3. Abre ios/Runner.xcworkspace en Xcode y verifica la configuración de signing"
    exit 1
fi

echo ""
echo "========================================"
echo "Construcción completada exitosamente!"
echo "========================================"
echo ""
echo "El archivo IPA se encuentra en:"
echo "build/ios/ipa/certiva_app.ipa"
echo ""
echo "Siguiente paso:"
echo "1. Abre Xcode"
echo "2. Ve a Window -> Organizer"
echo "3. Selecciona tu archivo y haz clic en 'Distribute App'"
echo "4. O consulta GUIA_TESTFLIGHT.md para más opciones"
echo ""












